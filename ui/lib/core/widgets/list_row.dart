import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';

/// 56 dp minimum row: 24 dp leading icon, title, optional muted subtitle and a
/// trailing chevron or [trailing] widget (for example a badge). The whole row
/// is the tap target; a 1 dp Mist divider sits below, inset 16 dp.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.leadingIcon,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final String title;
  final IconData? leadingIcon;
  final String? subtitle;

  /// Replaces the chevron.
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final colors = context.qColors;
    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: space.rowHeight),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: space.sm + space.xs),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: space.iconMd, color: context.scheme.onSurface),
              SizedBox(width: space.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.bodyMedium?.copyWith(
                      color: colors.onSurfaceStrong,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: context.text.bodySmall?.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[SizedBox(width: space.sm), trailing!],
            if (trailing == null && onTap != null)
              Icon(
                Icons.chevron_right,
                size: space.iconMd,
                color: colors.onSurfaceMuted,
              ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: onTap != null,
          child: InkWell(onTap: onTap, child: row),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsetsDirectional.only(start: space.md),
            child: Divider(color: colors.mist, height: space.hairline),
          ),
      ],
    );
  }
}
