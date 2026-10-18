import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/core/widgets/qhawix_buttons.dart';
import 'package:qhawix/core/widgets/toggle_row.dart';
import 'package:qhawix/core/widgets/guardian_mascot/guardian_mascot.dart';
import 'package:qhawix/features/trust_circle/data/mock/mock_trust_circle_repository.dart';
import 'package:qhawix/features/trust_circle/domain/action_result.dart';
import 'package:qhawix/features/trust_circle/domain/sos.dart';
import 'package:qhawix/features/trust_circle/view/sos_screen.dart';

import 'test_support.dart';

class _PendingSosRepository extends MockTrustCircleRepository {
  _PendingSosRepository({required super.clock, required this.result});

  final Completer<ActionResult> result;
  int sendSosCalls = 0;

  @override
  Future<ActionResult> sendSos({
    required Set<String> contactIds,
    required SosDuration duration,
  }) {
    sendSosCalls++;
    return result.future;
  }
}

Future<void> _startSos(
  WidgetTester tester,
  Completer<ActionResult> result,
) async {
  final clock = FixedClock();
  final repository = _PendingSosRepository(clock: clock, result: result);
  await pumpModule(
    tester,
    const SosScreen(),
    clock: clock,
    repository: repository,
  );

  final consent = find.text('Acepto compartir mi ubicación durante 30 minutos');
  final consentRow = find.ancestor(
    of: consent,
    matching: find.byType(ToggleRow),
  );
  await tester.scrollUntilVisible(
    consentRow,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(consentRow);
  await tester.pumpAndSettle();
  await tester.tap(consentRow);
  await tester.pump();
  expect(tester.widget<ToggleRow>(consentRow).value, isTrue);
  final send = find.text('Enviar SOS');
  final sendButton = find.ancestor(
    of: send,
    matching: find.byType(PrimaryButton),
  );
  await tester.scrollUntilVisible(
    sendButton,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(sendButton);
  await tester.pumpAndSettle();
  expect(tester.widget<PrimaryButton>(sendButton).onPressed, isNotNull);
  await tester.tap(find.byType(FilledButton));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  expect(repository.sendSosCalls, 1);
  tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .jumpTo(0);
  await tester.pump();
}

void main() {
  testWidgets('ambiguous saved SOS result does not imply success', (
    tester,
  ) async {
    final result = Completer<ActionResult>();
    await _startSos(tester, result);

    expect(
      tester.widget<GuardianMascot>(find.byType(GuardianMascot)).state,
      GuardianMascotState.working,
    );
    result.complete(
      const ActionResult(ActionOutcome.saved, 'Operación completada.'),
    );
    await tester.pump();

    expect(find.byType(GuardianMascot), findsNothing);
    expect(tester.takeException(), isNull);
  });

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
