import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/qr_shield/data/repositories/supabase_qr_site_note_repository.dart';
import 'package:qhawix/features/qr_shield/domain/models/qr_site_note.dart';

void main() {
  late List<Map<String, Object?>> requests;

  SupabaseQrSiteNoteRepository repository(
    FutureOr<({int status, Object? body})> Function() respond, {
    bool enabled = true,
    bool session = true,
  }) {
    return SupabaseQrSiteNoteRepository(
      enabled: enabled,
      hasSession: () => session,
      invoker: (body) async {
        requests.add(body);
        return respond();
      },
    );
  }

  setUp(() => requests = []);

  test('sends only the host, action and schema version', () async {
    final repo = repository(
      () => (status: 200, body: {'schemaVersion': 1, 'status': 'none'}),
    );
    final result = await repo.find('pagos.mitienda.pe');
    expect(result.outcome, QrSiteNoteOutcome.none);
    expect(requests.single, {
      'schemaVersion': 1,
      'action': 'get',
      'host': 'pagos.mitienda.pe',
    });
  });

  test('maps a found note', () async {
    final repo = repository(
      () => (
        status: 200,
        body: {
          'schemaVersion': 1,
          'status': 'found',
          'note': {
            'id': 'a1',
            'text': 'Lo verifiqué en la app oficial.',
            'savedAt': '2026-10-20T12:00:00Z',
          },
        },
      ),
    );
    final result = await repo.find('mitienda.pe');
    expect(result.outcome, QrSiteNoteOutcome.found);
    expect(result.note!.text, 'Lo verifiqué en la app oficial.');
    expect(result.note!.savedAt, DateTime.utc(2026, 10, 20, 12));
  });

  test(
    'is unavailable without a session or when the build disables it',
    () async {
      expect(
        repository(() => (status: 200, body: null), session: false).isAvailable,
        isFalse,
      );
      expect(
        repository(() => (status: 200, body: null), enabled: false).isAvailable,
        isFalse,
      );
      final result = await repository(
        () => (status: 200, body: null),
        session: false,
      ).find('mitienda.pe');
      expect(result.failure, QrSiteNoteFailure.notConfigured);
      expect(requests, isEmpty);
    },
  );

  test('refuses a host that is not an exact lowercase key', () async {
    final repo = repository(
      () => (status: 200, body: {'schemaVersion': 1, 'status': 'none'}),
    );
    final result = await repo.find('MiTienda.pe');
    expect(result.failure, QrSiteNoteFailure.invalidInput);
    expect(requests, isEmpty);
  });

  test('a save without a confirmed note is never reported as saved', () async {
    final repo = repository(
      () => (status: 200, body: {'schemaVersion': 1, 'status': 'saved'}),
    );
    final result = await repo.save('mitienda.pe', 'Nota');
    expect(result.outcome, QrSiteNoteOutcome.failed);
    expect(result.failure, QrSiteNoteFailure.saveUnconfirmed);
  });

  test('maps gateway errors to typed failures', () async {
    final cases = <({int status, Object? body}), QrSiteNoteFailure>{
      (status: 503, body: {'schemaVersion': 1, 'code': 'not_configured'}):
          QrSiteNoteFailure.notConfigured,
      (status: 401, body: null): QrSiteNoteFailure.unauthorized,
      (status: 429, body: {'code': 'rate_limited'}):
          QrSiteNoteFailure.rateLimited,
      (status: 504, body: 'gateway timeout'): QrSiteNoteFailure.timeout,
      (status: 502, body: {'code': 'provider_unavailable'}):
          QrSiteNoteFailure.unavailable,
      (status: 502, body: {'code': 'correction_not_applied'}):
          QrSiteNoteFailure.correctionNotApplied,
      (status: 500, body: '<html>'): QrSiteNoteFailure.unavailable,
    };
    for (final entry in cases.entries) {
      final result = await repository(() => entry.key).delete('mitienda.pe');
      expect(result.failure, entry.value, reason: '${entry.key}');
    }
  });

  test(
    'invalid or unexpected JSON is a failure, not an empty result',
    () async {
      for (final body in <Object?>[
        null,
        'texto',
        [],
        {'status': 'none'},
        {'schemaVersion': 1, 'status': 'otro'},
      ]) {
        final result = await repository(
          () => (status: 200, body: body),
        ).find('mitienda.pe');
        expect(result.outcome, QrSiteNoteOutcome.failed, reason: '$body');
      }
    },
  );

  test('a thrown transport error is a failure', () async {
    final repo = repository(() => throw Exception('offline'));
    final result = await repo.find('mitienda.pe');
    expect(result.failure, QrSiteNoteFailure.unavailable);
  });

  test(
    'host key uses the exact ASCII host and rejects IPs and local names',
    () {
      expect(qrSiteNoteHostKey('Pagos.MiTienda.pe.'), 'pagos.mitienda.pe');
      expect(qrSiteNoteHostKey('xn--bcp-pea.com'), 'xn--bcp-pea.com');
      expect(qrSiteNoteHostKey('192.168.0.1'), isNull);
      expect(qrSiteNoteHostKey('localhost'), isNull);
      expect(qrSiteNoteHostKey(''), isNull);
    },
  );
}
