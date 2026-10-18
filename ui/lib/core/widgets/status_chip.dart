import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';
import '../theme/tokens.dart';

/// Meaning of a [StatusChip]. These are neutral states of a thing (waiting,
/// active, paused, overdue), not request risk: risk keeps using `RiskBadge`.
enum StatusTone { neutral, accent, caution, alert, unverifiable }

/// Pill with an icon and a Spanish label. Never color alone: the icon and the
/// text always carry the state. Mirrors the prototype's `SeverityChip`.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.icon,
    this.tone = StatusTone.neutral,
  });

  final String label;
  final IconData icon;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.qColors;
    final risk = context.riskPalette;
    final (Color fill, Color fg) = switch (tone) {
      StatusTone.neutral => (
        risk.notAssessed.background,
        risk.notAssessed.foreground,
      ),
      StatusTone.accent => (colors.accentTint, colors.accentDeep),
      StatusTone.caution => (risk.caution.background, risk.caution.foreground),
      StatusTone.alert => (risk.high.background, risk.high.foreground),
      StatusTone.unverifiable => (
        risk.abstain.background,
        risk.abstain.foreground,
      ),
    };
    final space = context.space;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: fill,
          shape: StadiumBorder(
            side: BorderSide(
              color: fg.withValues(
                alpha: QhawixMotionTokens.riskOutlineOpacity,
              ),
              width: space.hairline,
            ),
          ),
        ),
        child: Padding(
          padding: space.badgePadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: space.iconSm, color: fg),
              SizedBox(width: space.xs + space.xs),
              Flexible(
                child: Text(
                  label,
                  style: context.text.labelSmall?.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
