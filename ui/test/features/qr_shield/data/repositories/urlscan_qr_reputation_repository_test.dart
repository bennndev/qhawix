import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/qr_shield/data/repositories/urlscan_qr_reputation_repository.dart';
import 'package:qhawix/features/qr_shield/domain/models/qr_reputation_result.dart';

void main() {
  final checkedAt = DateTime.utc(2026, 10, 18, 12);

  Future<QrReputationResult> lookup({
    Map<String, dynamic> overrides = const {},
    int status = 200,
    void Function(Map<String, dynamic>, HttpHeaders)? inspectRequest,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final repository = UrlscanQrReputationRepository(
      supabaseUrl: 'http://127.0.0.1:${server.port}',
      supabaseAnonKey: 'public-test-key',
    );
    server.listen((request) async {
      final body =
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>;
      inspectRequest?.call(body, request.headers);
      request.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'schemaVersion': 2,
            'requestId': body['requestId'],
            'inputRevision': body['inputRevision'],
            'provider': 'urlscan_v1',
            'providerVerdict': 'no_match',
            'checkedCategories': ['URLSCAN_VERDICT'],
            'matchingCategories': <String>[],
            'providerCheckedAt': checkedAt.toIso8601String(),
            'reviewExpiresAt': null,
            'servedFromCache': false,
            'redirectResolution': 'not_performed',
            'coverageComplete': true,
            'isFixture': false,
            ...overrides,
          }),
        );
      await request.response.close();
    });
    try {
      return await repository.checkUrl(
        url: Uri.parse('https://example.com/#local'),
        userConsented: true,
        inputRevision: 7,
      );
    } finally {
      repository.close();
      await server.close(force: true);
    }
  }

  test(
    'sends contract v2 and private-scan consent to the gateway without the fragment',
    () async {
      final result = await lookup(
        inspectRequest: (body, headers) {
          expect(body['schemaVersion'], 2);
          expect(body['consentVersion'], 'qr-urlscan-private-consent-v2');
          expect(body['url'], 'https://example.com/');
          expect(body['inputRevision'], 7);
          expect(headers.value('apikey'), 'public-test-key');
          expect(headers.value('api-key'), isNull);
        },
      );
      expect(result.status, QrReputationStatus.noKnownThreats);
      expect(result.provider, 'urlscan.io');
      expect(result.checkedCategories, ['Análisis de urlscan']);
    },
  );

  test('maps a phishing match with explicitly local review validity', () async {
    final result = await lookup(
      overrides: {
        'providerVerdict': 'match',
        'matchingCategories': ['URLSCAN_PHISHING'],
        'reviewExpiresAt': checkedAt
            .add(const Duration(minutes: 5))
            .toIso8601String(),
      },
    );
    expect(result.status, QrReputationStatus.knownThreat);
    expect(result.categories, ['Phishing señalado por urlscan']);
  });

  for (final invalid in <Map<String, dynamic>>[
    {'schemaVersion': 1},
    {'provider': 'different-provider'},
    {'inputRevision': 8},
    {'requestId': 'different-request'},
    {'checkedCategories': <String>[]},
    {
      'checkedCategories': ['MALWARE'],
    },
    {'coverageComplete': false},
    {'isFixture': true},
    {'providerVerdict': 'pending'},
    {
      'providerVerdict': 'match',
      'matchingCategories': ['UNKNOWN'],
    },
    {
      'providerVerdict': 'match',
      'matchingCategories': ['URLSCAN_PHISHING'],
      'reviewExpiresAt': checkedAt
          .add(const Duration(hours: 1))
          .toIso8601String(),
    },
  ]) {
    test('invalid gateway contract stays unverifiable: $invalid', () async {
      final result = await lookup(overrides: invalid);
      expect(result.status, QrReputationStatus.suspiciousOrUnverified);
      expect(result.providerState, QrProviderState.invalidResponse);
    });
  }

  test('quota exhaustion is never a negative result', () async {
    final result = await lookup(
      status: 429,
      overrides: {'code': 'quota_exhausted'},
    );
    expect(result.status, QrReputationStatus.suspiciousOrUnverified);
    expect(result.providerState, QrProviderState.quotaExceeded);
  });

  test('private scan denial stays unverifiable with its reason', () async {
    final result = await lookup(
      status: 503,
      overrides: {'code': 'private_scan_unavailable'},
    );
    expect(result.status, QrReputationStatus.suspiciousOrUnverified);
    expect(result.reasonCode, 'private_scan_unavailable');
  });

  for (final code in [
    'scan_incomplete',
    'scan_inconclusive',
    'analysis_expired',
    'scan_deleted',
  ]) {
    test(
      'completed provider response stays unverifiable with accurate availability: $code',
      () async {
        final result = await lookup(status: 503, overrides: {'code': code});
        expect(result.status, QrReputationStatus.suspiciousOrUnverified);
        expect(result.reasonCode, code);
        expect(result.providerState, QrProviderState.available);
      },
    );
  }

  test(
    'a rejected provider credential is reported as configuration failure',
    () async {
      final result = await lookup(
        status: 503,
        overrides: {'code': 'provider_auth_failed'},
      );
      expect(result.status, QrReputationStatus.suspiciousOrUnverified);
      expect(result.providerState, QrProviderState.notConfigured);
    },
  );

  test('declining consent never contacts a provider', () async {
    final repository = UrlscanQrReputationRepository();
    try {
      final result = await repository.checkUrl(
        url: Uri.parse('https://example.com/'),
        userConsented: false,
        inputRevision: 1,
      );
      expect(result.reasonCode, 'consent_not_granted');
    } finally {
      repository.close();
    }
  });
}
