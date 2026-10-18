import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qhawix/core/theme/app_theme.dart';
import 'package:qhawix/features/qr_shield/domain/models/qr_image_scan_result.dart';
import 'package:qhawix/features/qr_shield/domain/models/qr_reputation_result.dart';
import 'package:qhawix/features/qr_shield/domain/repositories/external_browser.dart';
import 'package:qhawix/features/qr_shield/domain/repositories/qr_clock.dart';
import 'package:qhawix/features/qr_shield/domain/repositories/qr_image_decoder.dart';
import 'package:qhawix/features/qr_shield/domain/repositories/qr_reputation_repository.dart';
import 'package:qhawix/features/qr_shield/domain/services/qr_reputation_policy.dart';
import 'package:qhawix/features/qr_shield/domain/services/qr_url_inspector.dart';
import 'package:qhawix/features/qr_shield/domain/use_cases/inspect_qr_payload.dart';
import 'package:qhawix/features/qr_shield/view/qr_candidate_selection_screen.dart';
import 'package:qhawix/features/qr_shield/view/qr_review_screen.dart';
import 'package:qhawix/features/qr_shield/view/qr_shield_screen.dart';
import 'package:qhawix/features/qr_shield/viewmodel/qr_shield_view_model.dart';

void main() {
  late _FakeExternalBrowser externalBrowser;
  late _FakeReputationRepository reputationRepository;
  late QrShieldViewModel viewModel;

  setUp(() {
    externalBrowser = _FakeExternalBrowser();
    reputationRepository = _FakeReputationRepository();
    viewModel = QrShieldViewModel(
      inspectPayload: InspectQrPayload(urlInspector: QrUrlInspector()),
      reputationRepository: reputationRepository,
      externalBrowser: externalBrowser,
      clock: _FakeClock(),
      imageDecoder: _FakeQrImageDecoder(),
      reputationPolicy: const QrReputationPolicy(),
    );
  });

  tearDown(() => viewModel.dispose());

  Future<void> pumpReview(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<QrShieldViewModel>.value(
        value: viewModel,
        child: const MaterialApp(home: QrReviewScreen()),
      ),
    );
  }

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<QrShieldViewModel>.value(
        value: viewModel,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const QrShieldScreen(),
        ),
      ),
    );
  }

  Future<void> pumpCandidates(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<QrShieldViewModel>.value(
        value: viewModel,
        child: const MaterialApp(home: QrCandidateSelectionScreen()),
      ),
    );
  }

  testWidgets('QR module offers manual review without activating the camera', (
    tester,
  ) async {
    await pumpHome(tester);
    expect(find.byKey(const Key('qr-payload-input')), findsOneWidget);
    expect(find.byKey(const Key('open-scanner')), findsOneWidget);
    expect(find.byKey(const Key('activate-camera')), findsNothing);
  });

  testWidgets('candidate list shows only the redacted URL preview', (
    tester,
  ) async {
    viewModel.setCandidates([
      'https://shop.example.org/menu?token=secret-fixture',
      'https://other.example.org/menu',
    ]);
    await pumpCandidates(tester);

    expect(find.textContaining('token=[oculto]'), findsOneWidget);
    expect(find.textContaining('secret-fixture'), findsNothing);
  });

  testWidgets('hides a previously revealed URL when the QR changes', (
    tester,
  ) async {
    viewModel.inspect('https://first.example.org/menu?token=first-secret');
    await pumpReview(tester);

    await tester.tap(find.text('Mostrar URL completa'));
    await tester.pump();
    expect(find.text('Ocultar URL completa'), findsOneWidget);

    viewModel.inspect('https://second.example.org/menu?token=second-secret');
    await tester.pumpAndSettle();

    expect(find.text('Mostrar URL completa'), findsOneWidget);
    expect(find.text('Ocultar URL completa'), findsNothing);
  });

  testWidgets('hides previously revealed static content when the QR changes', (
    tester,
  ) async {
    viewModel.inspect('WIFI:T:WPA;S:casa;P:primer-secreto;;');
    await pumpReview(tester);

    await tester.tap(find.text('Mostrar contenido'));
    await tester.pump();
    expect(find.text('Ocultar contenido'), findsOneWidget);

    viewModel.inspect('WIFI:T:WPA;S:oficina;P:segundo-secreto;;');
    await tester.pumpAndSettle();

    expect(find.text('Mostrar contenido'), findsOneWidget);
    expect(find.text('Ocultar contenido'), findsNothing);
  });

  testWidgets(
    'requires a complete reputation check before showing the open action',
    (tester) async {
      reputationRepository
        ..isConfigured = true
        ..providerName = 'Google Web Risk Lookup'
        ..privacyDisclosure = 'La URL se enviará para revisar su reputación.'
        ..response = _cleanResult();
      viewModel.inspect('https://shop.example.org/menu');
      await pumpReview(tester);

      expect(find.byKey(const Key('check-url-reputation')), findsOneWidget);
      expect(find.byKey(const Key('open-external-url')), findsNothing);
      expect(
        find.textContaining('Enlace bloqueado: no se pudo confirmar'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('check-url-reputation')));
      await tester.pumpAndSettle();
      expect(find.text('¿Autorizas esta consulta?'), findsOneWidget);
      await tester.tap(find.text('Autorizar consulta'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('open-external-url')), findsOneWidget);
      expect(
        find.textContaining('Enlace bloqueado: no se pudo confirmar'),
        findsNothing,
      );
      expect(externalBrowser.openedUrls, isEmpty);
      viewModel.clearReview();
    },
  );

  testWidgets('alerts and blocks when reputation reports a known threat', (
    tester,
  ) async {
    reputationRepository
      ..isConfigured = true
      ..providerName = 'Google Web Risk Lookup'
      ..privacyDisclosure = 'La URL se enviará para revisar su reputación.'
      ..response = QrReputationResult(
        status: QrReputationStatus.knownThreat,
        reasonCode: null,
        provider: 'Google Web Risk Lookup',
        checkedAt: DateTime.utc(2026, 10, 17),
        expiresAt: DateTime.utc(2026, 10, 17, 0, 5),
        coverageComplete: true,
        categories: const ['Malware'],
        checkedCategories: const ['Malware', 'Ingeniería social'],
        providerState: QrProviderState.available,
      );
    viewModel.inspect('https://malicious.example.org/');
    await pumpReview(tester);

    expect(find.byKey(const Key('open-external-url')), findsNothing);
    await tester.tap(find.byKey(const Key('check-url-reputation')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autorizar consulta'));
    await tester.pumpAndSettle();

    expect(find.text('Alerta: amenaza conocida'), findsOneWidget);
    expect(
      find.textContaining('reportó este destino como una amenaza'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('open-external-url')), findsNothing);
    expect(find.text('Enlace bloqueado: amenaza conocida'), findsOneWidget);
    expect(externalBrowser.openedUrls, isEmpty);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    viewModel.clearReview();
    await tester.pumpAndSettle();
  });

  testWidgets('does not apply an open confirmation to a replaced QR', (
    tester,
  ) async {
    reputationRepository
      ..isConfigured = true
      ..providerName = 'Google Web Risk Lookup'
      ..privacyDisclosure = 'La URL se enviará para revisar su reputación.'
      ..response = _cleanResult();
    viewModel.inspect('https://first.example.org/menu');
    await pumpReview(tester);

    expect(find.byKey(const Key('open-external-url')), findsNothing);
    await tester.tap(find.byKey(const Key('check-url-reputation')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autorizar consulta'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-external-url')));
    await tester.tap(find.byKey(const Key('open-external-url')));
    await tester.pumpAndSettle();
    expect(find.text('Antes de abrir'), findsOneWidget);

    viewModel.inspect('https://second.example.org/menu');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(externalBrowser.openedUrls, isEmpty);
    expect(
      find.text('La revisión cambió. Revisa el QR actual antes de abrirlo.'),
      findsOneWidget,
    );
    viewModel.clearReview();
  });
}

class _FakeReputationRepository implements QrReputationRepository {
  @override
  bool isConfigured = false;

  @override
  String? providerName;

  @override
  String? privacyDisclosure;

  QrReputationResult? response;

  @override
  Future<QrReputationResult> checkUrl({
    required Uri url,
    required bool userConsented,
    required int inputRevision,
  }) async => response ?? _cleanResult();
}

QrReputationResult _cleanResult() => QrReputationResult(
  status: QrReputationStatus.noKnownThreats,
  reasonCode: null,
  provider: 'Google Web Risk Lookup',
  checkedAt: DateTime.utc(2026, 10, 17),
  expiresAt: null,
  coverageComplete: true,
  categories: const [],
  checkedCategories: const [
    'Malware',
    'Ingeniería social',
    'Software no deseado',
  ],
  providerState: QrProviderState.available,
);

class _FakeExternalBrowser implements ExternalBrowser {
  final openedUrls = <Uri>[];

  @override
  Future<bool> openHttpUrl(Uri url) async {
    openedUrls.add(url);
    return true;
  }
}

class _FakeClock implements QrClock {
  @override
  DateTime now() => DateTime.utc(2026, 10, 17);
}

class _FakeQrImageDecoder implements QrImageDecoder {
  @override
  Future<QrImageScanResult> decodePickedImage() async =>
      const QrImageScanResult.cancelled();
}
