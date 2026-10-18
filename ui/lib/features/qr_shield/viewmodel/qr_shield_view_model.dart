import 'package:flutter/foundation.dart';

import '../../../core/clock.dart';
import '../domain/config/qr_shield_policy.dart';
import '../domain/models/qr_reputation_result.dart';
import '../domain/models/qr_scan_payload.dart';
import '../domain/models/qr_url_assessment.dart';
import '../domain/repositories/external_browser.dart';
import '../domain/repositories/qr_reputation_repository.dart';
import '../domain/use_cases/inspect_qr_payload.dart';

enum QrOpenResult {
  opened,
  blockedByKnownThreat,
  notAUrl,
  localPolicyBlocked,
  confirmationRequired,
  reputationExpired,
  reputationPending,
  browserUnavailable,
}

class QrShieldReview {
  const QrShieldReview({
    required this.inspection,
    required this.revision,
    this.reputation,
    this.isCheckingReputation = false,
  });

  final QrInspection inspection;
  final int revision;
  final QrReputationResult? reputation;
  final bool isCheckingReputation;

  QrScanPayload get payload => inspection.payload;
  QrUrlAssessment? get urlAssessment => inspection.urlAssessment;
}

class QrShieldViewModel extends ChangeNotifier {
  QrShieldViewModel({
    required InspectQrPayload inspectPayload,
    required QrReputationRepository reputationRepository,
    required ExternalBrowser externalBrowser,
    required Clock clock,
  })  : _inspectPayload = inspectPayload,
        _reputationRepository = reputationRepository,
        _externalBrowser = externalBrowser,
        _clock = clock;

  final InspectQrPayload _inspectPayload;
  final QrReputationRepository _reputationRepository;
  final ExternalBrowser _externalBrowser;
  final Clock _clock;

  QrShieldReview? _review;
  int _revision = 0;
  int _activeRequest = 0;
  bool _disposed = false;

  QrShieldReview? get review => _review;
  bool get canRequestReputation => _reputationRepository.isConfigured;
  String? get reputationProviderName => _reputationRepository.providerName;
  String? get reputationPrivacyDisclosure => _reputationRepository.privacyDisclosure;

  @override
  void dispose() {
    _disposed = true;
    _activeRequest++;
    super.dispose();
  }

  void inspect(String rawValue) {
    _revision++;
    final inspection = _inspectPayload.inspect(rawValue);
    QrReputationResult? reputation;
    final assessment = inspection.urlAssessment;
    if (assessment != null) {
      if (!assessment.isEligibleForReputation) {
        reputation = QrReputationResult.unverifiable(
          assessment.blockReasonCode ?? 'url_not_eligible',
        );
      } else if (!_reputationRepository.isConfigured) {
        reputation = QrReputationResult.unverifiable('provider_not_configured');
      } else {
        reputation = QrReputationResult.unverifiable('check_not_requested');
      }
    }
    _review = QrShieldReview(
      inspection: inspection,
      revision: _revision,
      reputation: reputation,
    );
    notifyListeners();
  }

  Future<void> checkReputation({required bool userConsented}) async {
    final current = _review;
    final assessment = current?.urlAssessment;
    if (current == null ||
        current.isCheckingReputation ||
        assessment == null ||
        !assessment.isEligibleForReputation) {
      return;
    }
    if (!userConsented) {
      _replaceReputation(
        current,
        QrReputationResult.unverifiable('consent_not_granted'),
      );
      return;
    }
    if (!_reputationRepository.isConfigured) {
      _replaceReputation(
        current,
        QrReputationResult.unverifiable('provider_not_configured'),
      );
      return;
    }

    final revisionAtStart = current.revision;
    final requestId = ++_activeRequest;
    _review = QrShieldReview(
      inspection: current.inspection,
      revision: current.revision,
      reputation: current.reputation,
      isCheckingReputation: true,
    );
    notifyListeners();

    QrReputationResult result;
    try {
      final urlForProvider = Uri.parse(assessment.originalValue).replace(fragment: '');
      result = await _reputationRepository.checkUrl(
        url: urlForProvider,
        userConsented: true,
        inputRevision: revisionAtStart,
      );
    } catch (_) {
      result = QrReputationResult.unverifiable('provider_error');
    }

    if (result.status == QrReputationStatus.noKnownThreats && assessment.hasWarnings) {
      result = QrReputationResult.unverifiable(
        assessment.signals.contains(QrUrlSignal.knownShortener)
            ? 'redirect_not_resolved'
            : 'local_warning_present',
      );
    }

    if (_disposed || _review?.revision != revisionAtStart || requestId != _activeRequest) return;
    _review = QrShieldReview(
      inspection: current.inspection,
      revision: current.revision,
      reputation: result,
    );
    notifyListeners();
  }

  Future<QrOpenResult> openExternally({required bool userConfirmed}) async {
    final current = _review;
    if (current == null || current.urlAssessment == null) return QrOpenResult.notAUrl;
    if (current.isCheckingReputation) return QrOpenResult.reputationPending;
    if (!userConfirmed) return QrOpenResult.confirmationRequired;

    final originalAssessment = current.urlAssessment!;
    if (!originalAssessment.canOpenExternally) return QrOpenResult.localPolicyBlocked;
    if (current.reputation?.status == QrReputationStatus.knownThreat) {
      return QrOpenResult.blockedByKnownThreat;
    }

    final freshInspection = _inspectPayload.inspect(current.payload.rawValue);
    final freshAssessment = freshInspection.urlAssessment;
    if (freshAssessment == null ||
        freshAssessment.originalValue != originalAssessment.originalValue ||
        !freshAssessment.canOpenExternally) {
      return QrOpenResult.localPolicyBlocked;
    }

    final reputation = current.reputation;
    if (reputation?.status == QrReputationStatus.noKnownThreats) {
      final checkedAt = reputation?.checkedAt;
      final expiresAt = reputation?.expiresAt;
      final age = checkedAt == null ? null : _clock.now().difference(checkedAt);
      if (checkedAt == null ||
          expiresAt == null ||
          !expiresAt.isAfter(_clock.now()) ||
          age == null ||
          age.isNegative ||
          age > QrShieldPolicy.maxNegativeReputationAge) {
        _replaceReputation(
          current,
          QrReputationResult.unverifiable('reputation_expired'),
        );
        return QrOpenResult.reputationExpired;
      }
    }

    try {
      final launched = await _externalBrowser.openHttpUrl(
        Uri.parse(originalAssessment.originalValue),
      );
      return launched ? QrOpenResult.opened : QrOpenResult.browserUnavailable;
    } catch (_) {
      return QrOpenResult.browserUnavailable;
    }
  }

  void clearReview() {
    _revision++;
    _activeRequest++;
    _review = null;
    notifyListeners();
  }

  void _replaceReputation(QrShieldReview current, QrReputationResult result) {
    if (_review?.revision != current.revision) return;
    _review = QrShieldReview(
      inspection: current.inspection,
      revision: current.revision,
      reputation: result,
    );
    notifyListeners();
  }
}
