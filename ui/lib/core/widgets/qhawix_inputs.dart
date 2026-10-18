import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';
import 'qhawix_buttons.dart';

/// Single-line field with a persistent label above, helper text below and an
/// error shown with an icon and message (never red text alone).
class QhawixTextField extends StatelessWidget {
  const QhawixTextField({
    super.key,
    required this.label,
    this.controller,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.onChanged,
    this.enabled = true,
    this.obscureText = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool obscureText;

  @override
  Widget build(BuildContext context) => _LabeledField(
    label: label,
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      enabled: enabled,
      obscureText: obscureText,
      style: context.text.bodyMedium?.copyWith(
        color: context.qColors.onSurfaceStrong,
      ),
      decoration: _decoration(context, helperText, errorText),
    ),
  );
}

/// Sentinel paste field: at least 160 dp, grows to 8 lines then scrolls, with a
/// "Pegar" action, a character counter and a one-line privacy note.
class MultilinePasteField extends StatelessWidget {
  const MultilinePasteField({
    super.key,
    required this.controller,
    this.label = 'Texto a analizar',
    this.privacyNote = 'El texto se analiza en tu teléfono',
    this.maxLength,
    this.onPaste,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String privacyNote;
  final int? maxLength;

  /// Called when the person taps "Pegar"; the caller reads the clipboard.
  final VoidCallback? onPaste;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final muted = context.text.bodySmall?.copyWith(
      color: context.qColors.onSurfaceMuted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LabeledField(
          label: label,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: space.multilineHeight),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.multiline,
              minLines: 1,
              maxLines: space.multilineMaxLines,
              textAlignVertical: TextAlignVertical.top,
              style: context.text.bodyMedium?.copyWith(
                color: context.qColors.onSurfaceStrong,
              ),
              decoration: _decoration(context, null, errorText).copyWith(
                contentPadding: EdgeInsets.all(space.md),
                constraints: BoxConstraints(minHeight: space.multilineHeight),
              ),
            ),
          ),
        ),
        SizedBox(height: space.xs),
        Row(
          children: [
            if (onPaste != null)
              TertiaryButton(
                label: 'Pegar',
                icon: Icons.content_paste_outlined,
                onPressed: onPaste,
              ),
            const Spacer(),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final count = value.text.characters.length;
                final text = maxLength == null
                    ? '$count caracteres'
                    : '$count de $maxLength caracteres';
                return Text(text, style: muted);
              },
            ),
          ],
        ),
        Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: space.iconSm,
              color: context.qColors.onSurfaceMuted,
            ),
            SizedBox(width: space.sm),
            Expanded(child: Text(privacyNote, style: muted)),
          ],
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: context.text.labelMedium),
      SizedBox(height: context.space.xs + context.space.xs),
      child,
    ],
  );
}

InputDecoration _decoration(
  BuildContext context,
  String? helperText,
  String? errorText,
) {
  final space = context.space;
  final scheme = context.scheme;
  return InputDecoration(
    helperText: helperText,
    helperMaxLines: 3,
    error: errorText == null
        ? null
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: space.iconSm, color: scheme.error),
              SizedBox(width: space.xs + space.xs),
              Expanded(
                child: Text(
                  errorText,
                  style: context.text.bodySmall?.copyWith(color: scheme.error),
                ),
              ),
            ],
          ),
    errorMaxLines: 3,
  );
}
