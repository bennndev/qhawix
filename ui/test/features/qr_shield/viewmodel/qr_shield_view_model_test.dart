import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/qr_shield/domain/models/qr_image_scan_result.dart';
import 'package:qhawix/features/qr_shield/domain/models/qr_reputation_result.dart';
import 'package:qhawix/features/qr_shield/domain/repositories/external_browser.dart';
import 'package:qhawix/features/qr_shield/domain/repositories/qr_clock.dart';
import 'package:qhawix/features/qr_shield/domain/repositories/qr_image_decoder.dart';
import 'package:qhawix/features/qr_shield/domain/repositories/qr_reputation_repository.dart';
import 'package:qhawix/features/qr_shield/domain/services/qr_reputation_policy.dart';
import 'package:qhawix/features/qr_shield/domain/services/qr_url_inspector.dart';
import 'package:qhawix/features/qr_shield/domain/use_cases/inspect_qr_payload.dart';
import 'package:qhawix/features/qr_shield/viewmodel/qr_shield_view_model.dart';

const _webRiskProviderName = 'Google Web Risk Lookup';

void main() {
  final now = DateTime.utc(2026, 10, 17, 12);

  late _FakeReputationRepository reputationRepository;
  late _FakeExternalBrowser externalBrowser;
  late _FakeClock clock;
  late _FakeQrImageDecoder imageDecoder;
  late QrShieldViewModel viewModel;

  setUp(() {
    reputationRepository = _FakeReputationRepository();
    externalBrowser = _FakeExternalBrowser();
    clock = _FakeClock(now);
    imageDecoder = _FakeQrImageDecoder();
    viewModel = QrShieldViewModel(
      inspectPayload: InspectQrPayload(urlInspector: QrUrlInspector()),
      reputationRepository: reputationRepository,
      externalBrowser: externalBrowser,
      clock: clock,
      imageDecoder: imageDecoder,
      reputationPolicy: const QrReputationPolicy(),
    );
  });

  tearDown(() => viewModel.dispose());

  test(
    'inspection neither requests reputation nor opens a link automatically',
    () async {
      reputationRepository.isConfigured = true;
      viewModel.inspect('https://shop.example.org/menu');

      expect(reputationRepository.callCount, 0);
      expect(externalBrowser.openedUrls, isEmpty);
      expect(viewModel.review?.reputation?.reasonCode, 'check_not_requested');

      final result = await viewModel.openExternally(
        userConfirmed: false,
        expectedRevision: viewModel.review!.revision,
      );
      expect(result, QrOpenResult.confirmationRequired);
      expect(externalBrowser.openedUrls, isEmpty);

      final unverifiedResult = await viewModel.openExternally(
        userConfirmed: true,
        expectedRevision: viewModel.review!.revision,
      );
      expect(unverifiedResult, QrOpenResult.blockedByUnverified);
      expect(externalBrowser.openedUrls, isEmpty);
    },
  );

  test('declined consent does not call the repository', () async {
    reputationRepository.isConfigured = true;
    viewModel.inspect('https://shop.example.org/menu');
    final revision = viewModel.review!.revision;

    await viewModel.checkReputation(
      userConsented: false,
      expectedRevision: revision,
    );

    expect(reputationRepository.callCount, 0);
    expect(viewModel.review!.reputation!.reasonCode, 'consent_not_granted');
  });

  test(
    'missing provider configuration stays unverified without a repository call',
    () async {
      viewModel.inspect('https://shop.example.org/menu');

      await viewModel.checkReputation(
        userConsented: true,
        expectedRevision: viewModel.review!.revision,
      );

      expect(reputationRepository.callCount, 0);
      expect(
        viewModel.review!.reputation!.status,
        QrReputationStatus.suspiciousOrUnverified,
      );
      expect(
        viewModel.review!.reputation!.reasonCode,
        'provider_not_configured',
      );
      expect(
        viewModel.review!.reputation!.providerState,
        QrProviderState.notConfigured,
      );
      expect(viewModel.reputationProviderName, isNull);
      expect(viewModel.reputationPrivacyDisclosure, isNull);
    },
  );

  test(
    'consented lookup sends only the URL without its local fragment',
    () async {
      reputationRepository.isConfigured = true;
      reputationRepository.response = _noMatch(now);
      viewModel.inspect('https://shop.example.org/menu#local-token');
      final revision = viewModel.review!.revision;

      expect(viewModel.reputationProviderName, _webRiskProviderName);
      expect(viewModel.reputationPrivacyDisclosure, isNotNull);

      await viewModel.checkReputation(
        userConsented: true,
        expectedRevision: revision,
      );

      expect(reputationRepository.callCount, 1);
      expect(
        reputationRepository.lastUrl.toString(),
        'https://shop.example.org/menu',
      );
      expect(reputationRepository.lastInputRevision, revision);
      expect(
        viewModel.review!.reputation!.status,
        QrReputationStatus.suspiciousOrUnverified,
      );
      expect(viewModel.review!.reputation!.reasonCode, 'local_signal');
      expect(viewModel.review!.reputation!.expiresAt, isNull);
    },
  );

  test(
    'repository failures remain unverified and are never treated as a negative',
    () async {
      reputationRepository.isConfigured = true;
      reputationRepository.error = StateError('provider unavailable');
      viewModel.inspect('https://shop.example.org/menu');

      await viewModel.checkReputation(
        userConsented: true,
        expectedRevision: viewModel.review!.revision,
      );

      final reputation = viewModel.review!.reputation!;
      expect(reputationRepository.callCount, 1);
      expect(reputation.status, QrReputationStatus.suspiciousOrUnverified);
      expect(reputation.reasonCode, 'provider_error');
      expect(reputation.providerState, QrProviderState.failed);

      expect(
        await viewModel.openExternally(
          userConfirmed: true,
          expectedRevision: viewModel.review!.revision,
        ),
        QrOpenResult.blockedByUnverified,
      );
      expect(externalBrowser.openedUrls, isEmpty);
    },
  );

  test('expires a no-match review after its local 60-second window', () async {
    reputationRepository.isConfigured = true;
    reputationRepository.response = _noMatch(now);
    viewModel.inspect('https://shop.example.org/menu');
    await viewModel.checkReputation(
      userConsented: true,
      expectedRevision: viewModel.review!.revision,
    );

    expect(
      viewModel.review!.reputationReviewExpiresAt,
      now.add(QrReputationPolicy.negativeResultMaxAge),
    );
    clock.currentTime = now.add(const Duration(seconds: 61));

    final result = await viewModel.openExternally(
      userConfirmed: true,
      expectedRevision: viewModel.review!.revision,
    );

    expect(result, QrOpenResult.reputationExpired);
    expect(viewModel.review!.reputation!.reasonCode, 'negative_review_expired');
    expect(externalBrowser.openedUrls, isEmpty);

    expect(
      await viewModel.openExternally(
        userConfirmed: true,
        expectedRevision: viewModel.review!.revision,
      ),
      QrOpenResult.reputationExpired,
    );
    expect(externalBrowser.openedUrls, isEmpty);

    reputationRepository.response = _noMatch(clock.currentTime);
    await viewModel.checkReputation(
      userConsented: true,
      expectedRevision: viewModel.review!.revision,
    );
    expect(
      await viewModel.openExternally(
        userConfirmed: true,
        expectedRevision: viewModel.review!.revision,
      ),
      QrOpenResult.opened,
    );
    expect(externalBrowser.openedUrls, hasLength(1));
  });

  test(
    'a response arriving after URL replacement cannot update the new review',
    () async {
      reputationRepository.isConfigured = true;
      final response = Completer<QrReputationResult>();
      reputationRepository.responseFuture = response.future;
      viewModel.inspect('https://first.example.org/menu');
      final lookup = viewModel.checkReputation(
        userConsented: true,
        expectedRevision: viewModel.review!.revision,
      );

      viewModel.inspect('https://second.example.org/menu');
      response.complete(_noMatch(now));
      await lookup;

      expect(
        viewModel.review!.payload.rawValue,
        'https://second.example.org/menu',
      );
      expect(viewModel.review!.reputation!.reasonCode, 'check_not_requested');
      expect(externalBrowser.openedUrls, isEmpty);
    },
  );

  test(
    'a current known-threat result is blocked from external opening',
    () async {
      reputationRepository.isConfigured = true;
      reputationRepository.response = QrReputationResult(
        status: QrReputationStatus.knownThreat,
        reasonCode: null,
        provider: _webRiskProviderName,
        checkedAt: now,
        expiresAt: now.add(const Duration(minutes: 5)),
        coverageComplete: true,
        categories: const ['MALWARE'],
        checkedCategories: const ['MALWARE', 'SOCIAL_ENGINEERING'],
        providerState: QrProviderState.available,
      );
      viewModel.inspect('https://shop.example.org/menu');
      await viewModel.checkReputation(
        userConsented: true,
        expectedRevision: viewModel.review!.revision,
      );

      final result = await viewModel.openExternally(
        userConfirmed: true,
        expectedRevision: viewModel.review!.revision,
      );

      expect(result, QrOpenResult.blockedByKnownThreat);
      expect(externalBrowser.openedUrls, isEmpty);
    },
  );

  test(
    'deduplicates repeated frames and requires selecting among unique QR values',
    () {
      viewModel.setCandidates([
        'https://first.example.org',
        'https://first.example.org',
        'https://second.example.org',
      ]);

      expect(viewModel.pendingCandidates, hasLength(2));
      expect(viewModel.review, isNull);
      expect(externalBrowser.openedUrls, isEmpty);

      viewModel.selectCandidate(1);
      expect(viewModel.review!.payload.rawValue, 'https://second.example.org');
      expect(viewModel.pendingCandidates, isEmpty);
    },
  );

  test('reviews one QR decoded from an image without opening it', () async {
    imageDecoder.result = QrImageScanResult.decoded([
      'https://image.example.org/menu',
    ]);

    final action = await viewModel.inspectPickedImage();

    expect(action, QrImageScanAction.review);
    expect(
      viewModel.review!.payload.rawValue,
      'https://image.example.org/menu',
    );
    expect(reputationRepository.callCount, 0);
    expect(externalBrowser.openedUrls, isEmpty);
  });

  test(
    'requires selecting when an image contains multiple QR values',
    () async {
      imageDecoder.result = QrImageScanResult.decoded([
        'https://first.example.org/menu',
        'https://first.example.org/menu',
        'WIFI:T:WPA;S:casa;P:clave;;',
      ]);

      final action = await viewModel.inspectPickedImage();

      expect(action, QrImageScanAction.chooseCandidate);
      expect(viewModel.review, isNull);
      expect(viewModel.pendingCandidates, hasLength(2));
      expect(reputationRepository.callCount, 0);
      expect(externalBrowser.openedUrls, isEmpty);
    },
  );
}

QrReputationResult _noMatch(DateTime checkedAt) => QrReputationResult(
  status: QrReputationStatus.noKnownThreats,
  reasonCode: null,
  provider: _webRiskProviderName,
  checkedAt: checkedAt,
  expiresAt: null,
  coverageComplete: true,
  categories: const [],
  checkedCategories: const ['MALWARE', 'SOCIAL_ENGINEERING'],
  providerState: QrProviderState.available,
);

class _FakeReputationRepository implements QrReputationRepository {
  @override
  bool isConfigured = false;
  QrReputationResult response = QrReputationResult.suspiciousOrUnverified(
    'not_set',
  );
  Future<QrReputationResult>? responseFuture;
  Object? error;
  int callCount = 0;
  Uri? lastUrl;
  int? lastInputRevision;

  @override
  String? get providerName => isConfigured ? _webRiskProviderName : null;

  @override
  String? get privacyDisclosure => isConfigured
      ? 'La URL se envía a Google Web Risk después del consentimiento.'
      : null;

  @override
  Future<QrReputationResult> checkUrl({
    required Uri url,
    required bool userConsented,
    required int inputRevision,
  }) {
    callCount++;
    lastUrl = url;
    lastInputRevision = inputRevision;
    if (!userConsented) {
      throw StateError(
        'The view model must not call the repository without consent.',
      );
    }
    if (error != null) return Future.error(error!);
    return responseFuture ?? Future.value(response);
  }
}

class _FakeExternalBrowser implements ExternalBrowser {
  final openedUrls = <Uri>[];

  @override
  Future<bool> openHttpUrl(Uri url) async {
    openedUrls.add(url);
    return true;
  }
}

class _FakeClock implements QrClock {
  _FakeClock(this.currentTime);

  DateTime currentTime;

  @override
  DateTime now() => currentTime;
}

class _FakeQrImageDecoder implements QrImageDecoder {
  QrImageScanResult result = const QrImageScanResult.cancelled();

  @override
  Future<QrImageScanResult> decodePickedImage() async => result;
}
