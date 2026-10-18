import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';

void _noop() {}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, textAlign: TextAlign.center);
    if (icon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: context.space.iconMd),
        SizedBox(width: context.space.sm),
        Flexible(child: text),
      ],
    );
  }
}

/// Ink pill for the single decision of a screen (one per screen).
///
/// While [loading] the label is replaced by a progress indicator and the
/// button keeps its width. A loading button ignores taps.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? Stack(
            alignment: Alignment.center,
            children: [
              Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: _ButtonLabel(label: label, icon: icon),
              ),
              SizedBox(
                width: context.space.progressSm,
                height: context.space.progressSm,
                child: CircularProgressIndicator(
                  strokeWidth: context.space.focusRing,
                  color: context.scheme.onPrimary,
                  semanticsLabel: label,
                ),
              ),
            ],
          )
        : _ButtonLabel(label: label, icon: icon);
    return FilledButton(
      autofocus: autofocus,
      onPressed: loading && onPressed != null ? _noop : onPressed,
      child: child,
    );
  }
}

/// Transparent pill with a strong border: the alternate path.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    autofocus: autofocus,
    onPressed: onPressed,
    child: _ButtonLabel(label: label, icon: icon),
  );
}

/// Text button in the accent color: links and low-priority actions.
class TertiaryButton extends StatelessWidget {
  const TertiaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    child: _ButtonLabel(label: label, icon: icon),
  );
}

/// Error-filled pill. Only inside a confirmation dialog, never as the resting
/// button of a screen.
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final sunken = context.qColors.surfaceSunken;
    final muted = context.qColors.onSurfaceMuted;
    return FilledButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? sunken : scheme.error,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? muted : scheme.onError,
        ),
        overlayColor: WidgetStatePropertyAll(
          scheme.onError.withValues(alpha: 0.12),
        ),
      ),
      child: _ButtonLabel(label: label),
    );
  }
}
