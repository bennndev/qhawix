import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../domain/models/qr_reputation_result.dart';
import '../../domain/repositories/qr_reputation_repository.dart';

class WebRiskQrReputationRepository implements QrReputationRepository {
  WebRiskQrReputationRepository({
    String supabaseUrl = _defaultSupabaseUrl,
    String supabaseAnonKey = _defaultSupabaseAnonKey,
    HttpClient? httpClient,
  }) : _supabaseUrl = supabaseUrl.trim(),
       _supabaseAnonKey = supabaseAnonKey.trim(),
       _httpClient = httpClient ?? HttpClient() {
    _httpClient.connectionTimeout = const Duration(seconds: 5);
  }

  static const String _defaultSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );
  static const String _defaultSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String _provider = 'Google Web Risk Lookup';
  static const String _providerId = 'google_web_risk_lookup';
  static const String _consentVersion = 'qr-reputation-consent-v1';
  static const int _maxUrlBytes = 8 * 1024;
  static const int _maxResponseBytes = 16 * 1024;
  static const Duration _requestTimeout = Duration(seconds: 7);
  static const List<String> _expectedCategories = [
    'MALWARE',
    'SOCIAL_ENGINEERING',
    'UNWANTED_SOFTWARE',
  ];

  final String _supabaseUrl;
  final String _supabaseAnonKey;
  final HttpClient _httpClient;

  @override
  bool get isConfigured {
    final base = Uri.tryParse(_supabaseUrl);
    return base != null &&
        (base.scheme == 'https' ||
            (base.scheme == 'http' &&
                const {
                  'localhost',
                  '127.0.0.1',
                  '10.0.2.2',
                }.contains(base.host))) &&
        base.host.isNotEmpty &&
        _supabaseAnonKey.isNotEmpty &&
        !_supabaseAnonKey.startsWith('replace-with-');
  }

  @override
  String? get providerName => isConfigured ? _provider : null;

  @override
  String? get privacyDisclosure => isConfigured
      ? 'La URL completa, incluidos ruta y parámetros y sin el fragmento, pasa '
            'por Supabase para consultarse con Google Web Risk. Si se bloquea '
            'por una política local o una coincidencia de riesgo, QHAWIX guarda '
            'en este dispositivo la fecha, el destino saneado (sin credenciales, '
            'parámetros ni fragmento; las rutas sensibles se ocultan) y la '
            'categoría. El historial no se envía a Supabase. Revisa las '
            'condiciones de ambos servicios.'
      : null;

  @override
  Future<QrReputationResult> checkUrl({
    required Uri url,
    required bool userConsented,
    required int inputRevision,
  }) async {
    if (!userConsented) {
      return QrReputationResult.suspiciousOrUnverified(
        'consent_not_granted',
        providerState: QrProviderState.notRequested,
      );
    }
    if (!isConfigured) return _unconfigured();

    final lookupUrl = url.removeFragment();
    final urlText = lookupUrl.toString();
    if (utf8.encode(urlText).length > _maxUrlBytes ||
        lookupUrl.scheme != 'https' && lookupUrl.scheme != 'http' ||
        lookupUrl.userInfo.isNotEmpty ||
        lookupUrl.hasFragment ||
        !lookupUrl.hasAuthority ||
        lookupUrl.host.isEmpty) {
      return QrReputationResult.suspiciousOrUnverified(
        'invalid_input',
        providerState: QrProviderState.invalidResponse,
      );
    }

    final requestId = _newRequestId();
    final endpoint = Uri.parse(_supabaseUrl).replace(
      path: '/functions/v1/qr-reputation/v1/reputation/check',
      query: null,
      fragment: null,
    );

    try {
      final request = await _httpClient
          .postUrl(endpoint)
          .timeout(_requestTimeout);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set('apikey', _supabaseAnonKey);
      request.add(
        utf8.encode(
          jsonEncode({
            'schemaVersion': 1,
            'requestId': requestId,
            'inputRevision': inputRevision,
            'url': urlText,
            'consentVersion': _consentVersion,
          }),
        ),
      );

      final response = await request.close().timeout(_requestTimeout);
      final responseBytes = <int>[];
      await for (final chunk in response.timeout(_requestTimeout)) {
        if (responseBytes.length + chunk.length > _maxResponseBytes) {
          return _unverified(
            'invalid_provider_response',
            QrProviderState.invalidResponse,
          );
        }
        responseBytes.addAll(chunk);
      }
      final bodyText = utf8.decode(responseBytes, allowMalformed: false);
      final decoded = jsonDecode(bodyText);
      if (decoded is! Map<String, dynamic>) {
        return _unverified(
          'invalid_provider_response',
          QrProviderState.invalidResponse,
        );
      }

      if (response.statusCode != HttpStatus.ok) {
        return _mapError(response.statusCode, decoded);
      }
      return _mapSuccess(decoded, requestId, inputRevision);
    } on TimeoutException {
      return _unverified('provider_timeout', QrProviderState.timeout);
    } on SocketException {
      return _unverified('provider_unavailable', QrProviderState.offline);
    } on HandshakeException {
      return _unverified('provider_unavailable', QrProviderState.offline);
    } on HttpException {
      return _unverified('provider_unavailable', QrProviderState.offline);
    } on FormatException {
      return _unverified(
        'invalid_provider_response',
        QrProviderState.invalidResponse,
      );
    } catch (_) {
      return _unverified('provider_error', QrProviderState.failed);
    }
  }

  QrReputationResult _mapSuccess(
    Map<String, dynamic> body,
    String requestId,
    int inputRevision,
  ) {
    if (body['schemaVersion'] != 1 ||
        body['requestId'] != requestId ||
        body['inputRevision'] != inputRevision ||
        body['provider'] != _providerId ||
        body['isFixture'] != false ||
        body['redirectResolution'] != 'not_performed' ||
        body['coverageComplete'] != true ||
        body['servedFromCache'] is! bool) {
      return _unverified(
        'invalid_provider_response',
        QrProviderState.invalidResponse,
      );
    }

    final checkedCategories = body['checkedCategories'];
    final matchingCategories = body['matchingCategories'];
    final checkedAt = DateTime.tryParse(
      body['providerCheckedAt'] as String? ?? '',
    );
    if (checkedCategories is! List ||
        matchingCategories is! List ||
        checkedCategories.any((value) => value is! String) ||
        matchingCategories.any((value) => value is! String) ||
        checkedAt == null) {
      return _unverified(
        'invalid_provider_response',
        QrProviderState.invalidResponse,
      );
    }

    final checked = checkedCategories.cast<String>();
    final matches = matchingCategories.cast<String>();
    if (!_sameCategorySet(checked, _expectedCategories) ||
        matches.any((category) => !_expectedCategories.contains(category)) ||
        matches.toSet().length != matches.length) {
      return _unverified(
        'invalid_provider_response',
        QrProviderState.invalidResponse,
      );
    }

    final verdict = body['providerVerdict'];
    final providerExpiresAt = body['providerExpiresAt'];
    if (verdict == 'no_match' && matches.isEmpty && providerExpiresAt == null) {
      return QrReputationResult(
        status: QrReputationStatus.noKnownThreats,
        reasonCode: null,
        provider: _provider,
        checkedAt: checkedAt.toUtc(),
        expiresAt: null,
        coverageComplete: true,
        categories: const [],
        checkedCategories: checked.map(_categoryLabel).toList(growable: false),
        providerState: QrProviderState.available,
      );
    }

    if (verdict == 'match' &&
        matches.isNotEmpty &&
        providerExpiresAt is String) {
      final expiresAt = DateTime.tryParse(providerExpiresAt);
      if (expiresAt == null || !expiresAt.isAfter(checkedAt)) {
        return _unverified(
          'invalid_provider_response',
          QrProviderState.invalidResponse,
        );
      }
      return QrReputationResult(
        status: QrReputationStatus.knownThreat,
        reasonCode: null,
        provider: _provider,
        checkedAt: checkedAt.toUtc(),
        expiresAt: expiresAt.toUtc(),
        coverageComplete: true,
        categories: matches.map(_categoryLabel).toList(growable: false),
        checkedCategories: checked.map(_categoryLabel).toList(growable: false),
        providerState: QrProviderState.available,
      );
    }

    return _unverified(
      'invalid_provider_response',
      QrProviderState.invalidResponse,
    );
  }

  QrReputationResult _mapError(int statusCode, Map<String, dynamic> body) {
    final code = body['code'];
    if (code is! String || code.isEmpty) {
      return _unverified(
        'invalid_provider_response',
        QrProviderState.invalidResponse,
      );
    }
    if (const {
      'invalid_input',
      'payload_too_large',
      'invalid_provider_response',
    }.contains(code)) {
      return _unverified(code, QrProviderState.invalidResponse);
    }
    if (statusCode == HttpStatus.tooManyRequests) {
      return _unverified(code, QrProviderState.quotaExceeded);
    }
    if (statusCode == HttpStatus.serviceUnavailable &&
        code == 'not_configured') {
      return _unverified(code, QrProviderState.notConfigured);
    }
    if (statusCode == HttpStatus.serviceUnavailable) {
      return _unverified(code, QrProviderState.offline);
    }
    if (statusCode == HttpStatus.gatewayTimeout) {
      return _unverified(code, QrProviderState.timeout);
    }
    return _unverified(code, QrProviderState.failed);
  }

  QrReputationResult _unconfigured() =>
      _unverified('provider_not_configured', QrProviderState.notConfigured);

  QrReputationResult _unverified(String reason, QrProviderState state) =>
      QrReputationResult.suspiciousOrUnverified(
        reason,
        provider: _provider,
        providerState: state,
      );

  bool _sameCategorySet(List<String> left, List<String> right) =>
      left.length == right.length &&
      left.toSet().length == left.length &&
      left.toSet().containsAll(right);

  String _categoryLabel(String category) => switch (category) {
    'MALWARE' => 'Malware',
    'SOCIAL_ENGINEERING' => 'Ingeniería social',
    'UNWANTED_SOFTWARE' => 'Software no deseado',
    _ => category,
  };

  String _newRequestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  }

  void close() => _httpClient.close(force: true);
}
