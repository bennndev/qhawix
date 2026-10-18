import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/app/analyze_screen.dart';
import 'package:qhawix/core/theme/theme_extensions.dart';
import 'package:qhawix/core/widgets/module_card.dart';
import 'package:qhawix/core/widgets/guardian_mascot/guardian_mascot.dart';

import '../core/widgets/test_app.dart';

void main() {
  testWidgets('analyze index shows AURA without implying an active scan', (
    tester,
  ) async {
    usePhoneSurface(tester, size: const Size(320, 640));
    await tester.pumpWidget(
      qhawixApp(
        const AnalyzeScreen(),
        scaffold: false,
        textScale: 1.5,
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(find.text('Analizar'), findsOneWidget);
    expect(find.text('QHAWIX'), findsOneWidget);
    expect(find.text('Mensajes, QR y llamadas.'), findsOneWidget);

    final subtitleRect = tester.getRect(
      find.text('Mensajes, QR y llamadas.'),
    );
    final firstCardRect = tester.getRect(find.byType(ModuleCard).first);
    expect(firstCardRect.top - subtitleRect.bottom, greaterThanOrEqualTo(16));

    final mascot = tester.widget<GuardianMascot>(find.byType(GuardianMascot));
    expect(mascot.state, GuardianMascotState.stealth);
    expect(mascot.semanticLabel, 'AURA, guía disponible');
    final theme = Theme.of(tester.element(find.byType(AnalyzeScreen)));
    final scheme = theme.colorScheme;
    final accent = theme.extension<QhawixColors>()!.accent;
    expect(mascot.bodyColor, scheme.onPrimary);
    expect(mascot.lineColor, scheme.onPrimary);

    final tile = tester.widget<Container>(
      find.ancestor(
        of: find.byType(GuardianMascot),
        matching: find.byType(Container),
      ).first,
    );
    expect((tile.decoration! as BoxDecoration).color, accent);
    expect(
      _contrastRatio(scheme.onPrimary, accent),
      greaterThan(3),
    );
    expect(
      _contrastRatio(mascot.lineColor!, accent),
      greaterThan(3),
    );
    expect(tester.takeException(), isNull);
  });
}

double _contrastRatio(Color foreground, Color background) {
  final luminances = [
    foreground.computeLuminance(),
    background.computeLuminance(),
  ]..sort();
  return (luminances[1] + 0.05) / (luminances[0] + 0.05);
}
