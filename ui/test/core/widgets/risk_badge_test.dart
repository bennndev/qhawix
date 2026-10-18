import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/core/domain/risk_level.dart';
import 'package:qhawix/core/theme/app_theme.dart';
import 'package:qhawix/core/theme/theme_extensions.dart';
import 'package:qhawix/core/widgets/risk_badge.dart';

import 'test_app.dart';

const _labels = {
  RiskLevel.notAssessed: 'Sin evaluar',
  RiskLevel.noneDetected: 'Sin señales detectadas',
  RiskLevel.caution: 'Precaución',
  RiskLevel.high: 'Riesgo alto',
  RiskLevel.abstain: 'Sin base suficiente',
};

const _icons = {
  RiskLevel.notAssessed: Icons.radio_button_unchecked,
  RiskLevel.noneDetected: Icons.search_off,
  RiskLevel.caution: Icons.warning_amber_rounded,
  RiskLevel.high: Icons.report_outlined,
  RiskLevel.abstain: Icons.help_outline,
};

void main() {
  for (final entry in {
    'light': AppTheme.light(),
    'dark': AppTheme.dark(),
  }.entries) {
    group('RiskBadge (${entry.key})', () {
      for (final level in RiskLevel.values) {
        testWidgets('${level.name} shows its label and icon', (tester) async {
          await tester.pumpWidget(
            qhawixApp(RiskBadge(level: level), theme: entry.value),
          );
          expect(find.text(_labels[level]!), findsOneWidget);
          expect(find.byIcon(_icons[level]!), findsOneWidget);
          expect(
            find.bySemanticsLabel(_labels[level]!),
            findsOneWidget,
          );
        });
      }

      testWidgets('noneDetected is neutral: no check icon, no "seguro"', (
        tester,
      ) async {
        await tester.pumpWidget(
          qhawixApp(
            const RiskBadge(level: RiskLevel.noneDetected),
            theme: entry.value,
          ),
        );
        for (final check in [
          Icons.check,
          Icons.check_circle,
          Icons.check_circle_outline,
          Icons.verified,
          Icons.verified_user,
        ]) {
          expect(find.byIcon(check), findsNothing);
        }
        expect(find.textContaining('seguro'), findsNothing);
        expect(find.textContaining('legítimo'), findsNothing);
      });

      testWidgets('every level has a distinct icon and fill', (tester) async {
        late RiskPalette palette;
        await tester.pumpWidget(
          qhawixApp(
            Builder(
              builder: (context) {
                palette = context.riskPalette;
                return const SizedBox();
              },
            ),
            theme: entry.value,
          ),
        );
        final styles = [for (final l in RiskLevel.values) palette.of(l)];
        expect({for (final s in styles) s.icon}, hasLength(5));
        expect({for (final s in styles) s.label}, hasLength(5));
        expect({for (final s in styles) s.background}, hasLength(5));
      });
    });
  }

  testWidgets('discreet appearance renders every level as "Sin evaluar"', (
    tester,
  ) async {
    await tester.pumpWidget(
      qhawixApp(
        Column(
          children: [
            for (final level in RiskLevel.values) RiskBadge(level: level),
          ],
        ),
        theme: AppTheme.light(discreet: true),
      ),
    );
    expect(find.text('Sin evaluar'), findsNWidgets(RiskLevel.values.length));
    expect(find.text('Riesgo alto'), findsNothing);
  });

  testWidgets('a tappable badge has a 48 dp hit area', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      qhawixApp(
        RiskBadge(level: RiskLevel.caution, onTap: () => taps++),
      ),
    );
    final size = tester.getSize(find.byType(InkWell));
    expect(size.height, greaterThanOrEqualTo(48));
    await tester.tap(find.byType(InkWell));
    expect(taps, 1);
  });
}
