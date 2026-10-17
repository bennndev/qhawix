import 'package:flutter/material.dart';

import '../domain/risk_level.dart';
import '../theme/theme_extensions.dart';
import 'risk_badge.dart';
import 'section_card.dart';

/// Whole-card entry to a module: 24 dp accent icon, module name, one line of
/// purpose and optionally one risk badge.
///
/// A platform limit is shown as a neutral [limitNote] line, never a padlock.
class ModuleCard extends StatelessWidget {
  const ModuleCard({
    super.key,
    required this.icon,
    required this.name,
    required this.purpose,
    required this.onTap,
    this.risk,
    this.limitNote,
  });

  final IconData icon;
  final String name;
  final String purpose;
  final VoidCallback onTap;
  final RiskLevel? risk;
  final String? limitNote;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final colors = context.qColors;
    return QhawixCard(
      onTap: onTap,
      minHeight: space.moduleCardHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: space.iconMd, color: colors.accent),
          SizedBox(width: space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(name, style: context.text.titleMedium),
                ),
                SizedBox(height: space.xs),
                Text(purpose, style: context.text.bodySmall),
                if (limitNote != null) ...[
                  SizedBox(height: space.xs),
                  Text(
                    limitNote!,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ],
                if (risk != null) ...[
                  SizedBox(height: space.sm),
                  RiskBadge(level: risk!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
