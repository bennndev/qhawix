import 'package:flutter/material.dart';

import '../domain/voice_verdict.dart';
import '../theme/theme_extensions.dart';
import 'qhawix_buttons.dart';

/// Maps a [VoiceVerdict] to a risk style: human uses `noneDetected`, doubtful
/// `caution`, cloned `high`, inconclusive `abstain`. Under the discreet
/// appearance the palette already renders all of them as `notAssessed`.
RiskStyle voiceRiskStyle(RiskPalette palette, VoiceVerdict verdict) =>
    switch (verdict) {
      VoiceVerdict.human => palette.noneDetected,
      VoiceVerdict.doubtful => palette.caution,
      VoiceVerdict.cloned => palette.high,
      VoiceVerdict.inconclusive => palette.abstain,
    };

String voiceVerdictLabel(VoiceVerdict verdict) => switch (verdict) {
  VoiceVerdict.human => 'Voz probablemente humana',
  VoiceVerdict.doubtful => 'Voz dudosa',
  VoiceVerdict.cloned => 'Posible voz clonada',
  VoiceVerdict.inconclusive => 'Sin resultado concluyente',
};

IconData voiceVerdictIcon(RiskPalette palette, VoiceVerdict verdict) =>
    switch (verdict) {
      VoiceVerdict.human => Icons.person_outline,
      _ => voiceRiskStyle(palette, verdict).icon,
    };

/// EchoTrap result: a horizontal card with a 40 dp glyph, the verdict, the
/// score (always shown) and a "Cómo se calcula" link.
class VoiceLight extends StatelessWidget {
  const VoiceLight({
    super.key,
    required this.verdict,
    required this.scoreText,
    this.onExplain,
  });

  final VoiceVerdict verdict;

  /// For example `Puntuación 0,62`.
  final String scoreText;
  final VoidCallback? onExplain;

  @override
  Widget build(BuildContext context) {
    final palette = context.riskPalette;
    final style = voiceRiskStyle(palette, verdict);
    final space = context.space;
    final label = voiceVerdictLabel(verdict);
    return Semantics(
      container: true,
      label: '$label. $scoreText',
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: style.background,
          shape: context.shapes.rounded(context.shapes.lg),
        ),
        child: Padding(
          padding: space.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: ShapeDecoration(
                  shape: CircleBorder(
                    side: BorderSide(
                      color: style.foreground,
                      width: space.hairline,
                    ),
                  ),
                ),
                child: SizedBox.square(
                  dimension: space.voiceGlyph,
                  child: Icon(
                    voiceVerdictIcon(palette, verdict),
                    size: space.iconMd,
                    color: style.foreground,
                  ),
                ),
              ),
              SizedBox(width: space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.text.titleMedium?.copyWith(
                        color: style.foreground,
                      ),
                    ),
                    SizedBox(height: space.xs),
                    Text(
                      scoreText,
                      style: context.text.bodySmall?.copyWith(
                        color: style.foreground,
                      ),
                    ),
                    if (onExplain != null)
                      TertiaryButton(
                        label: 'Cómo se calcula',
                        onPressed: onExplain,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Persistent status row shown above the voice light while the microphone is
/// active. Text and icon, not color.
class ListeningRow extends StatelessWidget {
  const ListeningRow({super.key, this.label = 'Escuchando'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.qColors;
    final space = context.space;
    return Semantics(
      liveRegion: true,
      label: label,
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(Icons.mic_none, size: space.iconMd, color: colors.accent),
          SizedBox(width: space.sm),
          Text(
            label,
            style: context.text.labelLarge?.copyWith(color: colors.accent),
          ),
        ],
      ),
    );
  }
}
