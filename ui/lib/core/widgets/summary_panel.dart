import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';
import 'section_card.dart';

/// Summary block: a muted label, a Headline medium value and an optional
/// caption, with an optional leading icon. Mirrors the prototype's stat
/// `panel`. The value is text, so state never depends on color alone.
class SummaryPanel extends StatelessWidget {
  const SummaryPanel({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final colors = context.qColors;
    return QhawixCard(
      onTap: onTap,
      semanticLabel: '$label: $value',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: space.iconMd, color: colors.accentDeep),
              SizedBox(width: space.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.text.labelMedium?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                  SizedBox(height: space.xs),
                  Text(value, style: context.text.headlineMedium),
                  if (caption != null) ...[
                    SizedBox(height: space.xs),
                    Text(
                      caption!,
                      style: context.text.bodySmall?.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
