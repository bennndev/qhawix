import '../../domain/models/qr_reputation_result.dart';
import '../../domain/repositories/qr_clock.dart';
import '../../domain/repositories/qr_reputation_repository.dart';
import 'web_risk_qr_reputation_repository.dart';

/// Provides clearly labeled, local-only outcomes for the two QR demo URLs.
/// Other URLs continue through the configured reputation repository.
class DemoQrReputationRepository implements QrReputationRepository {
  DemoQrReputationRepository({
    required WebRiskQrReputationRepository fallback,
    required QrClock clock,
  }) : _fallback = fallback,
       _clock = clock;

  static const String _provider = 'Simulación local (solo depuración)';
  static const String _safeResultCode = 'demo_safe_fixture';
  static const String _phishingResultCode = 'demo_phishing_fixture';

  final WebRiskQrReputationRepository _fallback;
  final QrClock _clock;

  @override
  bool get isConfigured => true;

  @override
  String get providerName => _provider;

  @override
  String get privacyDisclosure =>
      'Solo en modo de depuración: https://example.com y la URL oficial de '
      'prueba de phishing usan respuestas locales predefinidas; esas dos URL '
      'no se envían a Google Web Risk. Los demás enlaces usan la consulta '
      'configurada, si está disponible.';

  @override
  Future<QrReputationResult> checkUrl({
    required Uri url,
    required bool userConsented,
    required int inputRevision,
  }) {
    if (!userConsented) {
      return Future.value(
        QrReputationResult.suspiciousOrUnverified(
          'consent_not_granted',
          providerState: QrProviderState.notRequested,
        ),
      );
    }

    final normalizedUrl = url.removeFragment();
    if (_isSafeDemoUrl(normalizedUrl)) {
      return Future.value(
        QrReputationResult(
          status: QrReputationStatus.noKnownThreats,
          reasonCode: _safeResultCode,
          provider: _provider,
          checkedAt: _clock.now().toUtc(),
          expiresAt: null,
          coverageComplete: true,
          categories: const [],
          checkedCategories: const [
            'MALWARE',
            'SOCIAL_ENGINEERING',
            'UNWANTED_SOFTWARE',
          ],
          providerState: QrProviderState.available,
          isSimulation: true,
        ),
      );
    }

    if (_isPhishingDemoUrl(normalizedUrl)) {
      return Future.value(
        QrReputationResult(
          status: QrReputationStatus.knownThreat,
          reasonCode: _phishingResultCode,
          provider: _provider,
          checkedAt: _clock.now().toUtc(),
          expiresAt: _clock.now().toUtc().add(const Duration(minutes: 1)),
          coverageComplete: false,
          categories: const ['Ingeniería social'],
          checkedCategories: const [
            'MALWARE',
            'SOCIAL_ENGINEERING',
            'UNWANTED_SOFTWARE',
          ],
          providerState: QrProviderState.available,
          isSimulation: true,
        ),
      );
    }

    return _fallback.checkUrl(
      url: url,
      userConsented: userConsented,
      inputRevision: inputRevision,
    );
  }

  void close() => _fallback.close();

  bool _isSafeDemoUrl(Uri url) =>
      url.scheme == 'https' &&
      url.host.toLowerCase() == 'example.com' &&
      url.userInfo.isEmpty &&
      (!url.hasPort || url.port == 443) &&
      (url.path.isEmpty || url.path == '/') &&
      !url.hasQuery;

  bool _isPhishingDemoUrl(Uri url) =>
      url.scheme == 'https' &&
      url.host.toLowerCase() == 'testsafebrowsing.appspot.com' &&
      url.userInfo.isEmpty &&
      (!url.hasPort || url.port == 443) &&
      url.path == '/s/phishing.html' &&
      !url.hasQuery;
}
