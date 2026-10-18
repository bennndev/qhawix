import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/core/domain/voice_verdict.dart';
import 'package:qhawix/core/theme/app_theme.dart';
import 'package:qhawix/core/theme/theme_extensions.dart';
import 'package:qhawix/core/widgets/voice_light.dart';

import 'test_app.dart';

const _labels = {
  VoiceVerdict.human: 'Voz probablemente humana',
  VoiceVerdict.doubtful: 'Voz dudosa',
  VoiceVerdict.cloned: 'Posible voz clonada',
  VoiceVerdict.inconclusive: 'Sin resultado concluyente',
};

void main() {
  test('the verdicts map to the documented risk styles', () {
    final palette = AppTheme.light().extension<RiskPalette>()!;
    expect(voiceRiskStyle(palette, VoiceVerdict.human), palette.noneDetected);
    expect(voiceRiskStyle(palette, VoiceVerdict.doubtful), palette.caution);
    expect(voiceRiskStyle(palette, VoiceVerdict.cloned), palette.high);
    expect(
      voiceRiskStyle(palette, VoiceVerdict.inconclusive),
      palette.abstain,
    );
  });

  for (final verdict in VoiceVerdict.values) {
    testWidgets('${verdict.name} shows verdict, glyph and score', (
      tester,
    ) async {
      await tester.pumpWidget(
        qhawixApp(
          VoiceLight(verdict: verdict, scoreText: 'Puntuación 0,62'),
        ),
      );
      expect(find.text(_labels[verdict]!), findsOneWidget);
      expect(find.text('Puntuación 0,62'), findsOneWidget);
      late RiskPalette palette;
      await tester.pumpWidget(
        qhawixApp(
          Builder(
            builder: (context) {
              palette = context.riskPalette;
              return VoiceLight(verdict: verdict, scoreText: 'Puntuación 0,62');
            },
          ),
        ),
      );
      expect(find.byIcon(voiceVerdictIcon(palette, verdict)), findsOneWidget);
    });
  }

  testWidgets('human uses a person glyph, not a check', (tester) async {
    await tester.pumpWidget(
      qhawixApp(
        const VoiceLight(verdict: VoiceVerdict.human, scoreText: 'Puntuación 0,10'),
      ),
    );
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('"Cómo se calcula" calls back and is only shown when set', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      qhawixApp(
        VoiceLight(
          verdict: VoiceVerdict.doubtful,
          scoreText: 'Puntuación 0,50',
          onExplain: () => taps++,
        ),
      ),
    );
    await tester.tap(find.text('Cómo se calcula'));
    expect(taps, 1);
    await tester.pumpWidget(
      qhawixApp(
        const VoiceLight(
          verdict: VoiceVerdict.doubtful,
          scoreText: 'Puntuación 0,50',
        ),
      ),
    );
    expect(find.text('Cómo se calcula'), findsNothing);
  });

  testWidgets('discreet appearance renders the neutral style', (tester) async {
    await tester.pumpWidget(
      qhawixApp(
        const VoiceLight(verdict: VoiceVerdict.cloned, scoreText: 'Puntuación 0,95'),
        theme: AppTheme.light(discreet: true),
      ),
    );
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(VoiceLight),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final palette = AppTheme.light(discreet: true).extension<RiskPalette>()!;
    expect(
      (box.decoration as ShapeDecoration).color,
      palette.notAssessed.background,
    );
  });

  testWidgets('listening row says "Escuchando"', (tester) async {
    await tester.pumpWidget(qhawixApp(const ListeningRow()));
    expect(find.text('Escuchando'), findsOneWidget);
  });
}
