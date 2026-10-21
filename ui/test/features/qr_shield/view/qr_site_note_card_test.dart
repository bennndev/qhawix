import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qhawix/features/qr_shield/domain/models/qr_image_scan_result.dart';
import 'package:qhawix/features/qr_shield/domain/models/qr_reputation_result.dart';
import 'package:qhawix/features/qr_shield/domain/models/qr_site_note.dart';
import 'package:qhawix/features/qr_shield/domain/repositories/external_browser.dart';
import 'package:qhawix/features/qr_shield/domain/repositories/qr_clock.dart';
import 'package:qhawix/features/qr_shield/domain/repositories/qr_image_decoder.dart';
import 'package:qhawix/features/qr_shield/domain/repositories/qr_reputation_repository.dart';
import 'package:qhawix/features/qr_shield/domain/repositories/qr_site_note_repository.dart';
import 'package:qhawix/features/qr_shield/domain/services/qr_reputation_policy.dart';
import 'package:qhawix/features/qr_shield/domain/services/qr_url_inspector.dart';
import 'package:qhawix/features/qr_shield/domain/use_cases/inspect_qr_payload.dart';
import 'package:qhawix/features/qr_shield/view/qr_review_screen.dart';
import 'package:qhawix/features/qr_shield/viewmodel/qr_shield_view_model.dart';
import 'package:qhawix/features/qr_shield/viewmodel/qr_site_note_view_model.dart';

void main() {
  late _FakeSiteNoteRepository notes;
  late QrShieldViewModel shield;
  late QrSiteNoteViewModel siteNotes;

  setUp(() {
    notes = _FakeSiteNoteRepository();
    shield = QrShieldViewModel(
      inspectPayload: InspectQrPayload(urlInspector: QrUrlInspector()),
      reputationRepository: _UnconfiguredReputation(),
      externalBrowser: _NoBrowser(),
      clock: _FixedClock(),
      imageDecoder: _NoDecoder(),
      reputationPolicy: const QrReputationPolicy(),
    );
    siteNotes = QrSiteNoteViewModel(repository: notes);
  });

  tearDown(() {
    shield.dispose();
    siteNotes.dispose();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<QrShieldViewModel>.value(value: shield),
          ChangeNotifierProvider<QrSiteNoteViewModel>.value(value: siteNotes),
        ],
        child: const MaterialApp(home: QrReviewScreen()),
      ),
    );
    await tester.pump();
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  testWidgets('sends nothing until the person taps, then saves a note', (
    tester,
  ) async {
    shield.inspect('https://pagos.mitienda.pe/checkout?token=secreto');
    await pump(tester);

    expect(find.byKey(const Key('qr-site-note-card')), findsOneWidget);
    expect(notes.calls, isEmpty);

    await tapVisible(tester, const Key('qr-site-note-load'));
    expect(notes.calls, ['get pagos.mitienda.pe']);

    await tester.enterText(
      find.byKey(const Key('qr-site-note-input')),
      'Lo verifiqué en la app oficial.',
    );
    await tapVisible(tester, const Key('qr-site-note-save'));

    expect(notes.calls.last, 'save pagos.mitienda.pe');
    expect(find.text('Lo verifiqué en la app oficial.'), findsOneWidget);
    // The note never unlocks opening: the link is still unverified.
    expect(find.byKey(const Key('open-external-url')), findsNothing);
  });

  testWidgets('deletes only after confirmation', (tester) async {
    notes.stored['mitienda.pe'] = 'Mi tienda.';
    shield.inspect('https://mitienda.pe/');
    await pump(tester);
    await tapVisible(tester, const Key('qr-site-note-load'));
    expect(find.text('Mi tienda.'), findsOneWidget);

    await tapVisible(tester, const Key('qr-site-note-delete'));
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(notes.stored, contains('mitienda.pe'));

    await tapVisible(tester, const Key('qr-site-note-delete'));
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();
    expect(notes.stored, isEmpty);
    expect(
      find.text('Aún no tienes una nota para este sitio.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a failure instead of a saved note', (tester) async {
    shield.inspect('https://mitienda.pe/');
    await pump(tester);
    await tapVisible(tester, const Key('qr-site-note-load'));
    notes.failNext = QrSiteNoteFailure.unavailable;
    await tester.enterText(find.byKey(const Key('qr-site-note-input')), 'Hola');
    await tapVisible(tester, const Key('qr-site-note-save'));

    expect(find.byKey(const Key('qr-site-note-failure')), findsOneWidget);
    expect(find.byKey(const Key('qr-site-note-text')), findsNothing);
  });

  testWidgets('a different host never shows the previous note', (tester) async {
    notes.stored['bcp.com.pe'] = 'Mi banco.';
    shield.inspect('https://bcp.com.pe/');
    await pump(tester);
    await tapVisible(tester, const Key('qr-site-note-load'));
    expect(find.text('Mi banco.'), findsOneWidget);

    shield.inspect('https://bcp.com.pe.example.org/');
    await tester.pumpAndSettle();
    expect(find.text('Mi banco.'), findsNothing);
    expect(find.byKey(const Key('qr-site-note-load')), findsOneWidget);
  });

  testWidgets('hidden when notes are unavailable or the host is an IP', (
    tester,
  ) async {
    notes.isAvailable = false;
    shield.inspect('https://mitienda.pe/');
    await pump(tester);
    expect(find.byKey(const Key('qr-site-note-card')), findsNothing);

    notes.isAvailable = true;
    shield.inspect('https://192.168.0.10/');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('qr-site-note-card')), findsNothing);
  });
}

class _FakeSiteNoteRepository implements QrSiteNoteRepository {
  final calls = <String>[];
  final stored = <String, String>{};
  QrSiteNoteFailure? failNext;

  @override
  bool isAvailable = true;

  QrSiteNoteResult? _failure() {
    final failure = failNext;
    failNext = null;
    return failure == null ? null : QrSiteNoteResult.failed(failure);
  }

  @override
  Future<QrSiteNoteResult> find(String host) async {
    calls.add('get $host');
    final text = stored[host];
    return _failure() ??
        (text == null
            ? const QrSiteNoteResult.none()
            : QrSiteNoteResult.found(QrSiteNote(id: host, text: text)));
  }

  @override
  Future<QrSiteNoteResult> save(String host, String note) async {
    calls.add('save $host');
    final failed = _failure();
    if (failed != null) return failed;
    stored[host] = note;
    return QrSiteNoteResult.saved(QrSiteNote(id: host, text: note));
  }

  @override
  Future<QrSiteNoteResult> delete(String host) async {
    calls.add('delete $host');
    final failed = _failure();
    if (failed != null) return failed;
    stored.remove(host);
    return const QrSiteNoteResult.deleted();
  }
}

class _UnconfiguredReputation implements QrReputationRepository {
  @override
  bool get isConfigured => false;
  @override
  String? get providerName => null;
  @override
  String? get privacyDisclosure => null;
  @override
  Future<QrReputationResult> checkUrl({
    required Uri url,
    required bool userConsented,
    required int inputRevision,
  }) async => QrReputationResult.suspiciousOrUnverified(
    'provider_not_configured',
    providerState: QrProviderState.notConfigured,
  );
}

class _NoBrowser implements ExternalBrowser {
  @override
  Future<bool> openHttpUrl(Uri url) async => false;
}

class _FixedClock implements QrClock {
  @override
  DateTime now() => DateTime.utc(2026, 10, 20);
}

class _NoDecoder implements QrImageDecoder {
  @override
  Future<QrImageScanResult> decodePickedImage() async =>
      const QrImageScanResult.cancelled();
}
