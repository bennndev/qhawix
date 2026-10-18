import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/core/widgets/bottom_nav.dart';

import 'test_app.dart';

Widget _nav({
  QhawixTab selected = QhawixTab.inicio,
  ValueChanged<QhawixTab>? onSelected,
  double textScale = 1,
}) => qhawixApp(
  Scaffold(
    body: const SizedBox.expand(),
    bottomNavigationBar: QhawixBottomNav(
      selected: selected,
      onSelected: onSelected ?? (_) {},
    ),
  ),
  textScale: textScale,
  scaffold: false,
);

void main() {
  testWidgets('shows the four tabs with visible labels', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(_nav());
    for (final label in ['Inicio', 'Analizar', 'Red', 'Bitácora']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.group_outlined), findsOneWidget);
  });

  testWidgets('selecting a tab reports it', (tester) async {
    usePhoneSurface(tester);
    QhawixTab? tapped;
    await tester.pumpWidget(_nav(onSelected: (t) => tapped = t));
    await tester.tap(find.text('Red'));
    expect(tapped, QhawixTab.red);
  });

  testWidgets('is at least 80 dp tall and tabs are at least 48 dp', (
    tester,
  ) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(_nav());
    expect(
      tester.getSize(find.byType(QhawixBottomNav)).height,
      greaterThanOrEqualTo(80),
    );
    for (final item in find.byType(InkWell).evaluate()) {
      expect(item.size!.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('exposes selected state to accessibility', (tester) async {
    final handle = tester.ensureSemantics();
    usePhoneSurface(tester);
    await tester.pumpWidget(_nav(selected: QhawixTab.red));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Red')),
      matchesSemantics(
        label: 'Red',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('text at ${(scale * 100).round()}% does not overflow', (
      tester,
    ) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(_nav(textScale: scale));
      expect(tester.takeException(), isNull);
      for (final label in ['Inicio', 'Analizar', 'Red', 'Bitácora']) {
        expect(find.text(label), findsOneWidget);
      }
    });
  }

  testWidgets('grows in height at 200% instead of dropping labels', (
    tester,
  ) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(_nav());
    final normal = tester.getSize(find.byType(QhawixBottomNav)).height;
    await tester.pumpWidget(_nav(textScale: 2));
    final scaled = tester.getSize(find.byType(QhawixBottomNav)).height;
    expect(scaled, greaterThan(normal));
  });
}
