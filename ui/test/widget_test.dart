import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/app/app_router.dart';
import 'package:qhawix/app/qhawix_app.dart';

void main() {
  testWidgets('QHAWIX shell smoke test', (tester) async {
    await tester.pumpWidget(
      QhawixApp(
        router: createAppRouter(),
        forceDisableAnimations: true,
        requireAuthentication: false,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Tu vigía'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
  });
}
