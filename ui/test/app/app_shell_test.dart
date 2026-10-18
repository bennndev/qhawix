import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/app/app_router.dart';
import 'package:qhawix/app/qhawix_app.dart';

Widget _shellUnderTest() => QhawixApp(
      router: createAppRouter(),
      forceDisableAnimations: true,
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('Inicio lists modules and opens per-module onboarding', (
    tester,
  ) async {
    await tester.pumpWidget(_shellUnderTest());
    await _settle(tester);

    expect(find.text('Tu vigía'), findsOneWidget);
    expect(find.text('Sentinel'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Sentinel'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Sentinel').first);
    await _settle(tester);

    expect(find.text('Activar Sentinel'), findsOneWidget);
    expect(find.text('Permisos de este módulo'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);

    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Activar Sentinel'), findsNothing);
    expect(find.textContaining('construcción'), findsOneWidget);
  });

  testWidgets('bottom nav switches to Analizar', (tester) async {
    await tester.pumpWidget(_shellUnderTest());
    await _settle(tester);

    await tester.tap(find.text('Analizar'));
    await _settle(tester);

    expect(find.text('Escudo QR'), findsOneWidget);
    expect(find.text('EchoTrap'), findsOneWidget);
  });

  testWidgets('Red tab opens Trust Circle without activation gate', (
    tester,
  ) async {
    await tester.pumpWidget(_shellUnderTest());
    await _settle(tester);

    await tester.tap(find.text('Red'));
    await _settle(tester);

    expect(find.text('Activar Red de Confianza'), findsNothing);
    expect(find.text('Red de Confianza'), findsWidgets);
  });
}
