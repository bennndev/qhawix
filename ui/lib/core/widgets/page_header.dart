import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';

/// Screen heading: Headline large title and an optional muted Body medium
/// sentence below it. Mirrors the prototype's `PageHeader`, without motion.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: context.text.headlineLarge),
        ),
        if (subtitle != null) ...[
          SizedBox(height: space.sm),
          Text(
            subtitle!,
            style: context.text.bodyMedium?.copyWith(
              color: context.qColors.onSurfaceMuted,
            ),
          ),
        ],
      ],
    );
  }
}
