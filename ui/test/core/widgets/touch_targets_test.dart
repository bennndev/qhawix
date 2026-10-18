import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/core/domain/risk_level.dart';
import 'package:qhawix/core/theme/app_theme.dart';
import 'package:qhawix/core/widgets/list_row.dart';
import 'package:qhawix/core/widgets/module_card.dart';
import 'package:qhawix/core/widgets/qhawix_buttons.dart';
import 'package:qhawix/core/widgets/qhawix_chip.dart';
import 'package:qhawix/core/widgets/qhawix_inputs.dart';
import 'package:qhawix/core/widgets/risk_badge.dart';
import 'package:qhawix/core/widgets/state_views.dart';

import 'test_app.dart';

void main() {
  void noop() {}

  Future<void> expectMinHeight(
    WidgetTester tester,
    Finder finder,
    double min,
  ) async {
    expect(finder, findsOneWidget);
    expect(tester.getSize(finder).height, greaterThanOrEqualTo(min));
  }

  group('minimum 48 dp targets', () {
    testWidgets('buttons', (tester) async {
      await tester.pumpWidget(
        qhawixApp(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(label: 'Continuar', onPressed: noop),
              SecondaryButton(label: 'Ahora no', onPressed: noop),
              TertiaryButton(label: 'Pegar', onPressed: noop),
              DestructiveButton(label: 'Eliminar', onPressed: noop),
            ],
          ),
        ),
      );
      await expectMinHeight(tester, find.byType(FilledButton).first, 48);
      await expectMinHeight(tester, find.byType(OutlinedButton), 48);
      await expectMinHeight(tester, find.byType(TextButton), 48);
      expect(
        tester.getSize(find.byType(FilledButton).last).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('chip, list row, module card and badge hit area', (
      tester,
    ) async {
      await tester.pumpWidget(
        qhawixApp(
          SingleChildScrollView(
            child: Column(
              children: [
                QhawixChip(label: 'SMS', selected: false, onSelected: (_) {}),
                ListRow(title: 'Privacidad', onTap: noop),
                ModuleCard(
                  icon: Icons.qr_code_scanner,
                  name: 'Escudo QR',
                  purpose: 'Revisa un código antes de abrirlo.',
                  onTap: noop,
                ),
                RiskBadge(level: RiskLevel.caution, onTap: noop),
              ],
            ),
          ),
        ),
      );
      await expectMinHeight(tester, find.byType(QhawixChip), 48);
      await expectMinHeight(tester, find.byType(ListRow), 56);
      await expectMinHeight(tester, find.byType(ModuleCard), 96);
      await expectMinHeight(
        tester,
        find.descendant(
          of: find.byType(RiskBadge),
          matching: find.byType(InkWell),
        ),
        48,
      );
    });

    testWidgets('text field and paste field meet field heights', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        qhawixApp(
          SingleChildScrollView(
            child: Column(
              children: [
                const QhawixTextField(label: 'URL'),
                MultilinePasteField(controller: controller, onPaste: noop),
              ],
            ),
          ),
        ),
      );
      final fields = find.byType(TextField);
      expect(
        tester.getSize(fields.first).height,
        greaterThanOrEqualTo(56),
      );
      expect(
        tester.getSize(fields.last).height,
        greaterThanOrEqualTo(160),
      );
    });

    testWidgets('android tap-target guideline holds across the set', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      usePhoneSurface(tester);
      await tester.pumpWidget(
        qhawixApp(
          SingleChildScrollView(
            child: Column(
              children: [
                PrimaryButton(label: 'Continuar', onPressed: noop),
                const SizedBox(height: 8),
                SecondaryButton(label: 'Ahora no', onPressed: noop),
                const SizedBox(height: 8),
                TertiaryButton(label: 'Pegar', onPressed: noop),
                const SizedBox(height: 8),
                QhawixChip(label: 'SMS', selected: true, onSelected: (_) {}),
                const SizedBox(height: 8),
                ListRow(title: 'Privacidad', onTap: noop),
              ],
            ),
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('loading primary button', () {
    testWidgets('keeps its width and ignores taps', (tester) async {
      var taps = 0;
      Widget build(bool loading) => qhawixApp(
        PrimaryButton(
          label: 'Analizar',
          loading: loading,
          onPressed: () => taps++,
        ),
      );
      await tester.pumpWidget(build(false));
      final idle = tester.getSize(find.byType(FilledButton));
      await tester.pumpWidget(build(true));
      expect(tester.getSize(find.byType(FilledButton)), idle);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
    });
  });

  group('skeleton and reduced motion', () {
    testWidgets('sweeps when motion is allowed, static when reduced', (
      tester,
    ) async {
      await tester.pumpWidget(qhawixApp(const SkeletonBlock(height: 24, width: 200)));
      expect(find.byType(SlideTransition), findsWidgets);
      await tester.pumpWidget(
        qhawixApp(
          const SkeletonBlock(height: 24, width: 200),
          disableAnimations: true,
        ),
      );
      expect(
        find.descendant(
          of: find.byType(SkeletonBlock),
          matching: find.byType(SlideTransition),
        ),
        findsNothing,
      );
      // Fresh tree: MaterialApp animates theme changes over 200 ms.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        qhawixApp(
          const SkeletonBlock(height: 24, width: 200),
          theme: AppTheme.light(discreet: true),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(SkeletonBlock),
          matching: find.byType(SlideTransition),
        ),
        findsNothing,
      );
    });

    testWidgets('turns into the unverifiable state after the timeout', (
      tester,
    ) async {
      await tester.pumpWidget(
        qhawixApp(
          LoadingSkeleton(timeout: const Duration(seconds: 1), onRetry: noop),
          disableAnimations: true,
        ),
      );
      expect(find.text('No se pudo verificar'), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('No se pudo verificar'), findsOneWidget);
      expect(find.textContaining('sin coincidencias'), findsNothing);
    });
  });
}
