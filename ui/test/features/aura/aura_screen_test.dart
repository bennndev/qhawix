import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/core/theme/app_theme.dart';
import 'package:qhawix/core/widgets/guardian_mascot/guardian_mascot.dart';
import 'package:qhawix/features/aura/view/aura_screen.dart';

Widget _host({bool reducedMotion = true, bool dark = false, double scale = 1}) {
  return MaterialApp(
    theme: dark ? AppTheme.dark() : AppTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: reducedMotion,
        textScaler: TextScaler.linear(scale),
      ),
      child: child!,
    ),
    home: const AuraScreen(),
  );
}

void main() {
  testWidgets('offers labelled help actions with minimum touch targets', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host());

    expect(find.text('¿En qué te ayudo?'), findsOneWidget);
    expect(
      tester.widget<GuardianMascot>(find.byType(GuardianMascot)).state,
      GuardianMascotState.idle,
    );
    for (final label in ['Me piden un código', 'Me presionan para pagar']) {
      final button = find.widgetWithText(OutlinedButton, label);
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      expect(tester.getSemantics(button).flagsCollection.isButton, isTrue);
    }
    semantics.dispose();
  });

  testWidgets('shows a local code guide and resets to the resting mascot', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('Me piden un código'));
    await tester.pump();

    expect(find.text('Cuida tus códigos'), findsOneWidget);
    expect(
      find.textContaining('No compartas códigos de acceso'),
      findsOneWidget,
    );
    expect(find.textContaining('Base: Sentinel'), findsOneWidget);
    expect(
      tester.widget<GuardianMascot>(find.byType(GuardianMascot)).state,
      GuardianMascotState.alert,
    );
    expect(find.textContaining('ni confirma identidades'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Volver a las opciones'), 200);
    await tester.pump();
    await tester.tap(find.text('Volver a las opciones'));
    await tester.pump();
    expect(find.text('Cuida tus códigos'), findsNothing);
    expect(
      tester.widget<GuardianMascot>(find.byType(GuardianMascot)).state,
      GuardianMascotState.idle,
    );
  });

  testWidgets(
    'payment help gives independent verification without a safety verdict',
    (tester) async {
      await tester.pumpWidget(_host(reducedMotion: false));
      await tester.tap(find.text('Me presionan para pagar'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Verifica por otro canal'), findsOneWidget);
      expect(find.textContaining('reverso de tu tarjeta'), findsOneWidget);
      expect(find.textContaining('No uses el contacto'), findsOneWidget);
      expect(find.textContaining('Base: Guardian Pago'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'guidance scrolls at narrow width and 200 percent text with reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_host(dark: true, scale: 2));
      final mascotContext = tester.element(find.byType(GuardianMascot));
      expect(MediaQuery.disableAnimationsOf(mascotContext), isTrue);
      await tester.scrollUntilVisible(
        find.text('Me presionan para pagar').hitTestable(),
        200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Me presionan para pagar'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Volver a las opciones').hitTestable(),
        200,
      );
      await tester.pumpAndSettle();

      expect(find.text('Verifica por otro canal'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Volver a las opciones'));
      await tester.pump();
      expect(find.text('Verifica por otro canal'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
