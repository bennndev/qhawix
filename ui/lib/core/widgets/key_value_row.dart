import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';

/// A muted label on the left and its value on the right. Both wrap instead of
/// overflowing at large text scales.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: space.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: context.text.bodySmall?.copyWith(
                  color: context.qColors.onSurfaceMuted,
                ),
              ),
            ),
            SizedBox(width: space.md),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: context.text.bodyMedium?.copyWith(
                  color: context.qColors.onSurfaceStrong,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
