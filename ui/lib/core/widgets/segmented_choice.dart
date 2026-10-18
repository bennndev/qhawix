import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';

/// One option of a [SegmentedChoice].
class SegmentOption<T> {
  const SegmentOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Single-choice group of pills, each at least 48 dp tall. The selected pill
/// shows a check, a teal tint and Deep teal text; the others keep a strong
/// border. They wrap onto more lines instead of overflowing.
class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.semanticLabel,
  });

  final List<SegmentOption<T>> options;
  final T? selected;
  final ValueChanged<T>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Wrap(
        spacing: space.sm,
        runSpacing: space.sm,
        children: [
          for (final option in options)
            _Segment<T>(
              option: option,
              selected: option.value == selected,
              onTap: onChanged == null ? null : () => onChanged!(option.value),
            ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final SegmentOption<T> option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final colors = context.qColors;
    final fg = selected ? colors.accentDeep : colors.onSurfaceStrong;
    final icon = selected ? Icons.check : option.icon;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: option.label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? colors.accentTint : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? colors.accent : colors.borderStrong,
            width: space.hairline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: space.touchMin,
              minWidth: space.touchMin,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: space.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: space.iconSm, color: fg),
                    SizedBox(width: space.sm),
                  ],
                  Flexible(
                    child: Text(
                      option.label,
                      style: context.text.labelMedium?.copyWith(color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
