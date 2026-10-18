import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';
import 'qhawix_buttons.dart';

enum StatusBannerKind { information, caution, error, unverifiable }

/// Full-width rounded row: icon, one sentence and an optional tertiary action.
/// It states what is true and what the app cannot do, in plain words.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.kind = StatusBannerKind.information,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final StatusBannerKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.qColors;
    final risk = context.riskPalette;
    final (Color fill, Color fg, IconData icon) = switch (kind) {
      StatusBannerKind.information => (
        colors.surfaceSunken,
        colors.onSurfaceStrong,
        Icons.info_outline,
      ),
      StatusBannerKind.caution => (
        risk.caution.background,
        risk.caution.foreground,
        risk.caution.icon,
      ),
      StatusBannerKind.error => (
        colors.errorTint,
        context.scheme.error,
        Icons.error_outline,
      ),
      StatusBannerKind.unverifiable => (
        risk.abstain.background,
        risk.abstain.foreground,
        risk.abstain.icon,
      ),
    };
    final space = context.space;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: fill,
          shape: context.shapes.rounded(context.shapes.md),
        ),
        child: Padding(
          padding: space.bannerPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: space.iconMd, color: fg),
              SizedBox(width: space.sm + space.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: context.text.bodySmall?.copyWith(color: fg),
                    ),
                    if (actionLabel != null && onAction != null)
                      TertiaryButton(label: actionLabel!, onPressed: onAction),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
