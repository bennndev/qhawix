import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';
import 'qhawix_buttons.dart';

/// Content of a bottom sheet: 32 x 4 drag handle, a title, the body and a
/// visible "Cerrar" button (the handle is never the only way to close).
class QhawixSheet extends StatelessWidget {
  const QhawixSheet({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.qColors.borderStrong,
                    borderRadius: context.shapes.pillRadius,
                  ),
                  child: SizedBox(
                    width: space.dragHandleWidth,
                    height: space.dragHandleHeight,
                  ),
                ),
              ),
            ),
            SizedBox(height: space.md),
            Semantics(
              header: true,
              child: Text(title, style: context.text.headlineMedium),
            ),
            SizedBox(height: space.md),
            child,
            SizedBox(height: space.md),
            Align(
              alignment: Alignment.centerRight,
              child: TertiaryButton(
                label: 'Cerrar',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows [QhawixSheet] with the design-system scrim and motion.
Future<T?> showQhawixBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  showDragHandle: false,
  barrierColor: context.qColors.scrim,
  sheetAnimationStyle: AnimationStyle(
    duration: context.motion.resolve(context, context.motion.emphasized),
    curve: context.motion.emphasizedIn,
    reverseDuration: context.motion.resolve(context, context.motion.emphasized),
    reverseCurve: context.motion.emphasizedOut,
  ),
  builder: (_) => QhawixSheet(title: title, child: child),
);

/// Confirmation for a destructive or irreversible action.
///
/// "Cancelar" has the initial focus. The confirm button is destructive when
/// [destructive] is true and primary otherwise (for example restoring wallets,
/// which is followed by the person's biometric or PIN verification).
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.consequence,
    required this.confirmLabel,
    this.cancelLabel = 'Cancelar',
    this.destructive = true,
  });

  final String title;

  /// What is lost and that it cannot be undone.
  final String consequence;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    void close(bool result) => Navigator.of(context).pop(result);
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: space.maxContentWidth),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: context.text.headlineMedium),
              ),
              SizedBox(height: space.sm),
              Text(consequence, style: context.text.bodyMedium),
              SizedBox(height: space.lg),
              SecondaryButton(
                label: cancelLabel,
                autofocus: true,
                onPressed: () => close(false),
              ),
              SizedBox(height: space.sm),
              if (destructive)
                DestructiveButton(
                  label: confirmLabel,
                  onPressed: () => close(true),
                )
              else
                PrimaryButton(label: confirmLabel, onPressed: () => close(true)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows [ConfirmationDialog]; completes with true only on explicit confirm.
Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String consequence,
  required String confirmLabel,
  String cancelLabel = 'Cancelar',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: context.qColors.scrim,
    animationStyle: AnimationStyle(
      duration: context.motion.resolve(context, context.motion.emphasized),
      curve: context.motion.emphasizedIn,
      reverseDuration: context.motion.resolve(
        context,
        context.motion.emphasized,
      ),
      reverseCurve: context.motion.emphasizedOut,
    ),
    builder: (_) => ConfirmationDialog(
      title: title,
      consequence: consequence,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
  return result ?? false;
}
