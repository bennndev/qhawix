import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/core/widgets/guardian_mascot/guardian_mascot.dart';
import 'package:qhawix/features/trust_circle/data/mock/mock_trust_circle_repository.dart';
import 'package:qhawix/features/trust_circle/domain/action_result.dart';
import 'package:qhawix/features/trust_circle/domain/clock.dart';
import 'package:qhawix/features/trust_circle/domain/sos.dart';
import 'package:qhawix/features/trust_circle/view/sos_screen.dart';

import 'test_support.dart';

class _PendingSosRepository extends MockTrustCircleRepository {
  _PendingSosRepository({required Clock clock, required this.result})
    : super(clock: clock);

  final Completer<ActionResult> result;

  @override
  Future<ActionResult> sendSos({
    required Set<String> contactIds,
    required SosDuration duration,
  }) =>
      result.future;
}

Future<void> _startSos(
  WidgetTester tester,
  Completer<ActionResult> result,
) async {
  final clock = FixedClock();
  await pumpModule(
    tester,
    const SosScreen(),
    clock: clock,
    repository: _PendingSosRepository(clock: clock, result: result),
  );

  final consent = find.text(
    'Acepto compartir mi ubicación durante 30 minutos',
  );
  await tester.ensureVisible(consent);
  await tester.tap(consent);
  await tester.pump();
  final send = find.text('Enviar SOS');
  await tester.ensureVisible(send);
  await tester.tap(send);
  await tester.pump();
}

void main() {
  testWidgets(
    'ambiguous saved SOS result does not imply success',
    (tester) async {
    final result = Completer<ActionResult>();
    await _startSos(tester, result);

    expect(
      tester.widget<GuardianMascot>(find.byType(GuardianMascot)).state,
      GuardianMascotState.working,
    );
    result.complete(
      const ActionResult(
        ActionOutcome.saved,
        'Operación completada.',
      ),
    );
    await tester.pump();

    expect(find.byType(GuardianMascot), findsNothing);
    expect(tester.takeException(), isNull);
    },
  );

  testWidgets('SOS mascot shows attention for a rejected operation', (
    tester,
  ) async {
    final result = Completer<ActionResult>();
    await _startSos(tester, result);
    result.complete(
      const ActionResult(ActionOutcome.rejected, 'No hay contactos válidos.'),
    );
    await tester.pump();

    final mascot = tester.widget<GuardianMascot>(find.byType(GuardianMascot));
    expect(mascot.state, GuardianMascotState.alert);
    expect(mascot.semanticLabel, 'No se pudo preparar el aviso SOS');
    expect(tester.takeException(), isNull);
  });

  testWidgets('example-only SOS result does not imply success', (tester) async {
    final result = Completer<ActionResult>();
    await _startSos(tester, result);
    result.complete(
      const ActionResult(ActionOutcome.exampleOnly, 'Solo ejemplo.'),
    );
    await tester.pump();

    expect(find.byType(GuardianMascot), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
