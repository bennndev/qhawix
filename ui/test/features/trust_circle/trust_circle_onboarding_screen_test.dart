import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/trust_circle/view/trust_circle_onboarding_screen.dart';

import 'test_support.dart';

void main() {
  testWidgets('notification rationale shows three clear permission bullets', (
    tester,
  ) async {
    await pumpModule(tester, const TrustCircleOnboardingScreen());

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.circle), findsNWidgets(3));
    expect(
      find.text(
        'Usamos notificaciones para avisarte de alertas de tu círculo, incluso si la app no está abierta.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Este permiso solo permite mostrar notificaciones; no activa el acceso a tus contactos, mensajes ni ubicación.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Si no las permites, puedes usar el círculo igual, pero no recibirás avisos cuando la app no esté abierta.',
      ),
      findsOneWidget,
    );
  });
}
