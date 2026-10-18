import 'package:flutter/material.dart';

import '../domain/risk_level.dart';
import '../theme/theme_extensions.dart';
import '../theme/tokens.dart';

/// A pill showing one [RiskStyle]: icon, Spanish label and fill.
///
/// Never shows a number alone and never relies on color alone. A 1 dp outline
/// in the foreground color at 40% keeps the shape visible against the quiet fill.
class RiskStyleBadge extends StatelessWidget {
  const RiskStyleBadge({super.key, required this.style, this.onTap});

  final RiskStyle style;

  /// When set, the badge becomes a button wrapped in a 48 dp hit area.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final badge = DecoratedBox(
      decoration: ShapeDecoration(
        color: style.background,
        shape: StadiumBorder(
          side: BorderSide(
            color: style.foreground.withValues(
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
            Icon(style.icon, size: space.iconSm, color: style.foreground),
            SizedBox(width: space.xs + space.xs),
            Flexible(
              child: Text(
                style.label,
                style: context.text.labelSmall?.copyWith(
                  color: style.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) {
      return Semantics(label: style.label, excludeSemantics: true, child: badge);
    }
    return Semantics(
      button: true,
      label: style.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: space.touchMin),
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: badge,
          ),
        ),
      ),
    );
  }
}

/// The badge of one [RiskLevel], read from the theme's `RiskPalette`.
///
/// "Sin señales detectadas" is neutral blue-gray with a magnifier-off icon:
/// never green and never a check mark.
class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.level, this.onTap});

  final RiskLevel level;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) =>
      RiskStyleBadge(style: context.riskPalette.of(level), onTap: onTap);
}
