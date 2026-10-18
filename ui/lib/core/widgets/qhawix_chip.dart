import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';

/// Pill filter chip with a 48 dp touch height. Selected: teal tint fill, Deep
/// teal text and a leading check icon.
class QhawixChip extends StatelessWidget {
  const QhawixChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.qColors;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: context.space.touchMin),
      child: Center(
        widthFactor: 1,
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: onSelected,
          showCheckmark: true,
          labelStyle: context.text.labelMedium?.copyWith(
            color: selected ? colors.accentDeep : colors.onSurfaceStrong,
          ),
          materialTapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
    );
  }
}
