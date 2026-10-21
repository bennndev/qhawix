import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/app/qhawix_app.dart';

void main() {
  testWidgets(
    'existing shell opens the QR module without starting the camera',
    (tester) async {
      const historyChannel = MethodChannel(
        'pe.qhawix.qhawix/qr_security_history',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(historyChannel, (call) async {
            return call.method == 'isUrlAllowed' ? false : null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(historyChannel, null);
      });
      await tester.pumpWidget(const QhawixApp(forceDisableAnimations: true));
      await tester.pumpAndSettle();

      expect(find.text('Tu vigía'), findsOneWidget);
      await tester.tap(find.text('Analizar'));
      await tester.pumpAndSettle();
      expect(find.text('Escudo QR'), findsOneWidget);
      await tester.tap(find.text('Escudo QR'));
      await tester.pumpAndSettle();

      expect(find.text('Activar Escudo QR'), findsOneWidget);
      expect(find.byKey(const Key('activate-camera')), findsNothing);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('open-scanner')), findsOneWidget);
      expect(find.byKey(const Key('activate-camera')), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(const Key('qr-payload-input')),
        250,
      );
      expect(find.byKey(const Key('qr-payload-input')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('qr-payload-input')),
        'https://shop.example.org/menu',
      );
      await tester.ensureVisible(
        find.byKey(const Key('inspect-pasted-content')),
      );
      await tester.tap(find.byKey(const Key('inspect-pasted-content')));
      await tester.pumpAndSettle();

      expect(find.text('Revisión del QR'), findsOneWidget);
      expect(find.text('shop.example.org'), findsOneWidget);
      expect(find.text('Sospechoso o no verificable'), findsOneWidget);
      expect(find.text('Sin amenazas detectadas'), findsNothing);
      expect(find.byKey(const Key('open-external-url')), findsNothing);
      expect(
        find.textContaining('Enlace bloqueado: no se pudo confirmar'),
        findsOneWidget,
      );
      expect(find.text('Antes de abrir'), findsNothing);

      await tester.tap(find.byTooltip('Volver a Escudo QR'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('qr-payload-input')),
        250,
      );
      await tester.enterText(
        find.byKey(const Key('qr-payload-input')),
        'WIFI:T:WPA;S:casa;P:secreto;;',
      );
      await tester.ensureVisible(
        find.byKey(const Key('inspect-pasted-content')),
      );
      await tester.tap(find.byKey(const Key('inspect-pasted-content')));
      await tester.pumpAndSettle();

      expect(find.text('Datos de red Wi-Fi'), findsOneWidget);
      expect(
        find.textContaining('puede incluir datos personales'),
        findsOneWidget,
      );
      expect(find.textContaining('secreto'), findsNothing);
      expect(find.byKey(const Key('open-external-url')), findsNothing);
    },
  );
}
