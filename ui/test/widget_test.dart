import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/app/qhawix_app.dart';

void main() {
  testWidgets('QHAWIX opens its local safety dashboard', (tester) async {
    await tester.pumpWidget(const QhawixApp());
    await tester.pumpAndSettle();

    expect(find.text('QHAWIX'), findsOneWidget);
    expect(find.text('Revisa antes de actuar'), findsOneWidget);
    expect(find.text('Escudo QR'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Guardian Pago'), 200);
    expect(find.text('Guardian Pago'), findsOneWidget);
  });
}
