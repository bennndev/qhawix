import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';

/// Marks a screen that reads mock or fixture data.
///
/// Every screen that reads a repository under `data/mock/` shows this banner at
/// the top, above the content. It cannot be dismissed and must be absent from
/// any screen that shows real data. Developer builds and tests only.
class MockDataBanner extends StatelessWidget {
  const MockDataBanner({super.key});

  static const label = 'Datos de ejemplo';

  @override
  Widget build(BuildContext context) {
    final colors = context.qColors;
    final space = context.space;
    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: colors.accentTint,
          shape: context.shapes.rounded(context.shapes.md),
        ),
        child: Padding(
          padding: space.compactBannerPadding,
          child: Row(
            children: [
              Icon(
                Icons.science_outlined,
                size: space.iconMd,
                color: colors.accentDeep,
              ),
              SizedBox(width: space.sm),
              Expanded(
                child: Text(
                  label,
                  style: context.text.labelMedium?.copyWith(
                    color: colors.accentDeep,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
