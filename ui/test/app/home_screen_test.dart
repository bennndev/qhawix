import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/app/home_screen.dart';
import 'package:qhawix/core/widgets/guardian_mascot/guardian_mascot.dart';

import '../core/widgets/test_app.dart';

void main() {
  testWidgets('home keeps Guardian in its documented idle state', (
    tester,
  ) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      qhawixApp(const HomeScreen(), scaffold: false, disableAnimations: true),
    );
    await tester.pump();

    final mascot = tester.widget<GuardianMascot>(find.byType(GuardianMascot));
    expect(mascot.state, GuardianMascotState.idle);
    expect(find.text('Tu vigía'), findsOneWidget);
    expect(find.text('Elige qué quieres cuidar hoy.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
