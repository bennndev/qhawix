import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';

/// Row with a title, a muted description and a switch. The whole row toggles
/// (at least 56 dp tall) and the switch thumb carries a check or a cross, so
/// the state never depends on color alone. Mirrors the prototype's settings
/// rows. A null [onChanged] disables the row.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
    this.showDivider = true,
  });

  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final colors = context.qColors;
    final enabled = onChanged != null;
    final row = ConstrainedBox(
      constraints: BoxConstraints(minHeight: space.rowHeight),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: space.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.bodyMedium?.copyWith(
                      color: enabled
                          ? colors.onSurfaceStrong
                          : colors.onSurfaceMuted,
                    ),
                  ),
                  if (description != null)
                    Text(
                      description!,
                      style: context.text.bodySmall?.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: space.md),
            ExcludeSemantics(
              child: Switch(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                thumbIcon: WidgetStateProperty.resolveWith(
                  (states) => Icon(
                    states.contains(WidgetState.selected)
                        ? Icons.check
                        : Icons.close,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          toggled: value,
          enabled: enabled,
          label: description == null ? title : '$title. $description',
          onTap: enabled ? () => onChanged!(!value) : null,
          excludeSemantics: true,
          child: InkWell(
            onTap: enabled ? () => onChanged!(!value) : null,
            child: row,
          ),
        ),
        if (showDivider) Divider(color: colors.mist, height: space.hairline),
      ],
    );
  }
}
