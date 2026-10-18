import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qhawix/app/qhawix_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('manual QR review stays available without activating camera', (
    tester,
  ) async {
    await tester.pumpWidget(const QhawixApp(forceDisableAnimations: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Analizar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escudo QR'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('qr-payload-input')), findsOneWidget);
    expect(find.byKey(const Key('activate-camera')), findsNothing);

    await tester.tap(find.byKey(const Key('open-scanner')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('activate-camera')), findsOneWidget);
    expect(find.textContaining('La cámara se usa solo para leer'), findsOneWidget);

    await tester.tap(find.text('Pegar el contenido en su lugar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('activate-camera')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('qr-payload-input')));
    await tester.enterText(
      find.byKey(const Key('qr-payload-input')),
      'https://shop.example.org/menu',
    );
    await tester.ensureVisible(find.byKey(const Key('inspect-pasted-content')));
    await tester.tap(find.byKey(const Key('inspect-pasted-content')));
    await tester.pumpAndSettle();

    expect(find.text('Sospechoso o no verificable'), findsOneWidget);
    expect(find.text('Sin amenazas detectadas'), findsNothing);
    expect(find.byKey(const Key('open-external-url')), findsNothing);
    expect(
      find.textContaining('Enlace bloqueado: no se pudo confirmar'),
      findsOneWidget,
    );
  });
}
