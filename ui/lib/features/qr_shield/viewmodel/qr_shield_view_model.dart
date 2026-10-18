import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/models/qr_image_scan_result.dart';
import '../domain/models/qr_reputation_result.dart';
import '../domain/models/qr_scan_payload.dart';
import '../domain/models/qr_security_incident.dart';
import '../domain/models/qr_url_assessment.dart';
import '../domain/repositories/external_browser.dart';
import '../domain/repositories/qr_clock.dart';
import '../domain/repositories/qr_image_decoder.dart';
import '../domain/repositories/qr_reputation_repository.dart';
import '../domain/repositories/qr_security_history_repository.dart';
import '../domain/services/qr_reputation_policy.dart';
import '../domain/use_cases/inspect_qr_payload.dart';

enum QrOpenResult {
  opened,
  blockedByKnownThreat,
  blockedByUnverified,
  reviewChanged,
  notAUrl,
  localPolicyBlocked,
  confirmationRequired,
  reputationPending,
  reputationExpired,
  browserUnavailable,
}

enum QrImageScanAction {
  cancelled,
  review,
  chooseCandidate,
}

class QrShieldReview {
  const QrShieldReview({
    required this.inspection,
    required this.revision,
    this.reputation,
    this.reputationReviewExpiresAt,
    this.isCheckingReputation = false,
  });

  final QrInspection inspection;
  final int revision;
  final QrReputationResult? reputation;
  final DateTime? reputationReviewExpiresAt;
  final bool isCheckingReputation;

  QrScanPayload get payload => inspection.payload;
  QrUrlAssessment? get urlAssessment => inspection.urlAssessment;
}

class QrCandidateOption {
  const QrCandidateOption({required this.rawValue, required this.inspection});

  final String rawValue;
  final QrInspection inspection;
}

class QrShieldViewModel extends ChangeNotifier {
  QrShieldViewModel({
    required InspectQrPayload inspectPayload,
    required QrReputationRepository reputationRepository,
    required ExternalBrowser externalBrowser,
    required QrClock clock,
    required QrImageDecoder imageDecoder,
    required QrReputationPolicy reputationPolicy,
    QrSecurityHistoryRepository? securityHistoryRepository,
  })  : _inspectPayload = inspectPayload,
        _reputationRepository = reputationRepository,
        _externalBrowser = externalBrowser,
        _clock = clock,
        _imageDecoder = imageDecoder,
        _reputationPolicy = reputationPolicy,
        _securityHistoryRepository = securityHistoryRepository;

  final InspectQrPayload _inspectPayload;
  final QrReputationRepository _reputationRepository;
  final ExternalBrowser _externalBrowser;
  final QrClock _clock;
  final QrImageDecoder _imageDecoder;
  final QrReputationPolicy _reputationPolicy;
  final QrSecurityHistoryRepository? _securityHistoryRepository;

  QrShieldReview? _review;
  int _revision = 0;
  int _activeRequest = 0;
  bool _isSelectingImage = false;
  String? _imageScanMessage;
  List<QrCandidateOption> _pendingCandidates = const [];
  Timer? _reputationExpiryTimer;
  bool _isDisposed = false;

  QrShieldReview? get review => _review;
  bool get canOpenCurrentReview {
    final current = _review;
    final assessment = current?.urlAssessment;
    if (current == null || current.isCheckingReputation || assessment == null) {
      return false;
    }
    final freshAssessment = _inspectPayload
        .inspect(current.payload.rawValue)
        .urlAssessment;
    return _reputationPolicy.decideOpening(
          reviewedAssessment: assessment,
          currentAssessment: freshAssessment,
          reputation: current.reputation,
          now: _clock.now(),
        ) ==
        QrOpenPolicyDecision.allowAfterConfirmation;
  }
  bool get canRequestReputation => _reputationRepository.isConfigured;
  String? get reputationProviderName => _reputationRepository.providerName;
  String? get reputationPrivacyDisclosure => _reputationRepository.privacyDisclosure;
  bool get isSelectingImage => _isSelectingImage;
  String? get imageScanMessage => _imageScanMessage;
  List<QrCandidateOption> get pendingCandidates => _pendingCandidates;

  void inspect(String rawValue) {
    if (_isDisposed) return;
    _activeRequest++;
    _isSelectingImage = false;
    _imageScanMessage = null;
    _pendingCandidates = const [];
    _setInspection(rawValue);
  }

  Future<QrImageScanAction> inspectPickedImage() async {
    if (_isDisposed) return QrImageScanAction.cancelled;
    if (_isSelectingImage) return QrImageScanAction.cancelled;
    final requestId = ++_activeRequest;
    _isSelectingImage = true;
    _imageScanMessage = null;
    _pendingCandidates = const [];
    _notifyListenersIfAlive();

    try {
      final result = await _imageDecoder.decodePickedImage();
      if (requestId != _activeRequest) return QrImageScanAction.cancelled;
      switch (result.status) {
        case QrImageScanStatus.cancelled:
          return QrImageScanAction.cancelled;
        case QrImageScanStatus.noQrCode:
          _imageScanMessage = 'No se encontró un código QR en la imagen.';
          return QrImageScanAction.cancelled;
        case QrImageScanStatus.decoded:
          if (result.payloads.isEmpty) {
            _imageScanMessage = 'No se pudo leer el contenido de la imagen.';
            return QrImageScanAction.cancelled;
          }
          if (result.payloads.length == 1) {
            _setInspection(result.payloads.single);
            return QrImageScanAction.review;
          }
          setCandidates(result.payloads);
          return QrImageScanAction.chooseCandidate;
        case QrImageScanStatus.failed:
          _imageScanMessage = switch (result.reasonCode) {
            'image_too_large' => 'La imagen supera el límite de 20 MiB.',
            'image_scan_unsupported' => 'Este dispositivo no permite leer QR desde imágenes.',
            _ => 'No se pudo procesar la imagen. Prueba con otra o pega el contenido.',
          };
          return QrImageScanAction.cancelled;
      }
    } catch (_) {
      if (requestId == _activeRequest) {
        _imageScanMessage = 'No se pudo procesar la imagen. Prueba con otra o pega el contenido.';
      }
      return QrImageScanAction.cancelled;
    } finally {
      if (requestId == _activeRequest) {
        _isSelectingImage = false;
        _notifyListenersIfAlive();
      }
    }
  }

  void _setInspection(String rawValue) {
    if (_isDisposed) return;
    _cancelReputationExpiryTimer();
    _revision++;
    final inspection = _inspectPayload.inspect(rawValue);
    QrReputationResult? reputation;
    final assessment = inspection.urlAssessment;
    if (assessment != null) {
      if (!assessment.isEligibleForReputation) {
        reputation = QrReputationResult.suspiciousOrUnverified(
          assessment.blockReasonCode ?? 'url_not_eligible',
          providerState: QrProviderState.notRequested,
        );
      } else if (!_reputationRepository.isConfigured) {
        reputation = QrReputationResult.suspiciousOrUnverified(
          'provider_not_configured',
          providerState: QrProviderState.notConfigured,
        );
      } else {
        reputation = QrReputationResult.suspiciousOrUnverified(
          'check_not_requested',
          providerState: QrProviderState.notRequested,
        );
      }
    }
    _review = QrShieldReview(
      inspection: inspection,
      revision: _revision,
      reputation: reputation,
    );
    _notifyListenersIfAlive();
  }

  void setCandidates(List<String> rawValues) {
    if (_isDisposed) return;
    final uniqueValues = rawValues.toSet().toList(growable: false);
    if (uniqueValues.length < 2) {
      if (uniqueValues.isNotEmpty) inspect(uniqueValues.single);
      return;
    }
    _activeRequest++;
    _cancelReputationExpiryTimer();
    _isSelectingImage = false;
    _imageScanMessage = null;
    _review = null;
    _pendingCandidates = List.unmodifiable(
      uniqueValues.map(
        (rawValue) => QrCandidateOption(
          rawValue: rawValue,
          inspection: _inspectPayload.inspect(rawValue),
        ),
      ),
    );
    _revision++;
    _notifyListenersIfAlive();
  }

  void selectCandidate(int index) {
    if (index < 0 || index >= _pendingCandidates.length) return;
    final selected = _pendingCandidates[index].rawValue;
    inspect(selected);
  }

  Future<void> checkReputation({
    required bool userConsented,
    required int expectedRevision,
  }) async {
    if (_isDisposed) return;
    final current = _review;
    final assessment = current?.urlAssessment;
    if (current == null ||
        current.revision != expectedRevision ||
        current.isCheckingReputation ||
        assessment == null ||
        !assessment.isEligibleForReputation) {
      return;
    }
    if (!userConsented) {
      _replaceReputation(
        current,
        QrReputationResult.suspiciousOrUnverified(
          'consent_not_granted',
          providerState: QrProviderState.notRequested,
        ),
      );
      return;
    }
    if (!_reputationRepository.isConfigured) {
      _replaceReputation(
        current,
        QrReputationResult.suspiciousOrUnverified(
          'provider_not_configured',
          providerState: QrProviderState.notConfigured,
        ),
      );
      return;
    }

    final revisionAtStart = current.revision;
    final requestId = ++_activeRequest;
    _cancelReputationExpiryTimer();
    _review = QrShieldReview(
      inspection: current.inspection,
      revision: current.revision,
      reputation: current.reputation,
      reputationReviewExpiresAt: current.reputationReviewExpiresAt,
      isCheckingReputation: true,
    );
    _notifyListenersIfAlive();

    QrReputationResult result;
    try {
      final urlForProvider = assessment.reputationUri;
      if (urlForProvider == null) {
        result = QrReputationResult.suspiciousOrUnverified(
          'invalid_url',
          providerState: QrProviderState.invalidResponse,
        );
      } else {
        result = await _reputationRepository
            .checkUrl(
              url: urlForProvider,
              userConsented: true,
              inputRevision: revisionAtStart,
            )
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () => QrReputationResult.suspiciousOrUnverified(
                'provider_timeout',
                providerState: QrProviderState.timeout,
              ),
            );
      }
    } catch (_) {
      result = QrReputationResult.suspiciousOrUnverified(
        'provider_error',
        providerState: QrProviderState.failed,
      );
    }

    if (_isDisposed ||
        _review?.revision != revisionAtStart ||
        requestId != _activeRequest) {
      return;
    }
    result = _reputationPolicy.applyProviderResponse(
      result,
      assessment: assessment,
      now: _clock.now(),
    );
    _review = QrShieldReview(
      inspection: current.inspection,
      revision: current.revision,
      reputation: result,
      reputationReviewExpiresAt: _reputationPolicy.reviewExpiryDeadline(result),
    );
    _scheduleReputationExpiry(current.revision, result);
    _notifyListenersIfAlive();
  }

  Future<QrOpenResult> openExternally({
    required bool userConfirmed,
    required int expectedRevision,
  }) async {
    if (_isDisposed) return QrOpenResult.localPolicyBlocked;
    final current = _review;
    if (current == null || current.revision != expectedRevision) {
      return QrOpenResult.reviewChanged;
    }
    if (current.urlAssessment == null) return QrOpenResult.notAUrl;
    if (!userConfirmed) return QrOpenResult.confirmationRequired;
    if (current.isCheckingReputation) return QrOpenResult.reputationPending;

    final originalAssessment = current.urlAssessment!;
    final reputation = current.reputation;
    final freshInspection = _inspectPayload.inspect(current.payload.rawValue);
    final freshAssessment = freshInspection.urlAssessment;
    switch (_reputationPolicy.decideOpening(
      reviewedAssessment: originalAssessment,
      currentAssessment: freshAssessment,
      reputation: reputation,
      now: _clock.now(),
    )) {
      case QrOpenPolicyDecision.blockedByLocalPolicy:
        unawaited(
          _recordBlockedIncident(
            current,
            category: originalAssessment.signals.isEmpty
                ? 'local_policy'
                : originalAssessment.signals.map((signal) => signal.name).join(','),
            source: QrSecurityDetectionSource.localPolicy,
          ),
        );
        return QrOpenResult.localPolicyBlocked;
      case QrOpenPolicyDecision.blockedByKnownThreat:
        unawaited(
          _recordBlockedIncident(
            current,
            category: reputation!.categories.join(','),
            source: QrSecurityDetectionSource.googleWebRisk,
          ),
        );
        return QrOpenResult.blockedByKnownThreat;
      case QrOpenPolicyDecision.blockedByUnverified:
        return QrOpenResult.blockedByUnverified;
      case QrOpenPolicyDecision.reputationExpired:
        if (reputation != null) _markReputationExpired(current, reputation);
        return QrOpenResult.reputationExpired;
      case QrOpenPolicyDecision.allowAfterConfirmation:
        break;
    }

    try {
      final browserUri = freshAssessment?.parsedUri;
      if (browserUri == null) return QrOpenResult.localPolicyBlocked;
      final launched = await _externalBrowser.openHttpUrl(browserUri);
      return launched ? QrOpenResult.opened : QrOpenResult.browserUnavailable;
    } catch (_) {
      return QrOpenResult.browserUnavailable;
    }
  }

  Future<void> _recordBlockedIncident(
    QrShieldReview current, {
    required String category,
    required QrSecurityDetectionSource source,
  }) async {
    final repository = _securityHistoryRepository;
    final safeUrl = current.urlAssessment?.historySafeValue;
    if (repository == null || safeUrl == null) return;
    try {
      await repository.recordBlockedIncident(
        QrSecurityIncident(
          timestamp: _clock.now(),
          blockedUrl: safeUrl,
          threatCategory: category,
          detectionSource: source,
        ),
      );
    } catch (_) {
      // A history-write failure must never allow a blocked URL to open.
    }
  }

  void clearReview() {
    if (_isDisposed) return;
    _cancelReputationExpiryTimer();
    _revision++;
    _activeRequest++;
    _isSelectingImage = false;
    _imageScanMessage = null;
    _pendingCandidates = const [];
    _review = null;
    _notifyListenersIfAlive();
  }

  void _replaceReputation(QrShieldReview current, QrReputationResult result) {
    if (_isDisposed || _review?.revision != current.revision) return;
    _cancelReputationExpiryTimer();
    _review = QrShieldReview(
      inspection: current.inspection,
      revision: current.revision,
      reputation: result,
      reputationReviewExpiresAt: _reputationPolicy.reviewExpiryDeadline(result),
    );
    _notifyListenersIfAlive();
  }

  void _scheduleReputationExpiry(int revision, QrReputationResult result) {
    _cancelReputationExpiryTimer();
    final deadline = _reputationPolicy.reviewExpiryDeadline(result);
    if (deadline == null) return;

    var delay = deadline.difference(_clock.now());
    if (delay.isNegative) delay = Duration.zero;
    _reputationExpiryTimer = Timer(delay, () {
      if (_isDisposed) return;
      final latest = _review;
      if (latest == null ||
          latest.revision != revision ||
          latest.isCheckingReputation) {
        return;
      }
      final latestResult = latest.reputation;
      if (latestResult == null) return;
      final latestDeadline = _reputationPolicy.reviewExpiryDeadline(latestResult);
      if (latestDeadline == null) return;
      if (latestDeadline.isAfter(_clock.now())) {
        _scheduleReputationExpiry(revision, latestResult);
        return;
      }
      _markReputationExpired(latest, latestResult);
    });
  }

  void _markReputationExpired(
    QrShieldReview current,
    QrReputationResult previous,
  ) {
    _replaceReputation(current, _reputationPolicy.expired(previous));
  }

  void _cancelReputationExpiryTimer() {
    _reputationExpiryTimer?.cancel();
    _reputationExpiryTimer = null;
  }

  void _notifyListenersIfAlive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _activeRequest++;
    _cancelReputationExpiryTimer();
    super.dispose();
  }
}
