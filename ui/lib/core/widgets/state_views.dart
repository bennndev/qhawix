import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/theme_extensions.dart';
import 'qhawix_buttons.dart';

/// Centered empty state: 48 dp outlined icon, title, one sentence and one
/// action. No illustration.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.primaryAction = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool primaryAction;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final muted = context.qColors.onSurfaceMuted;
    return Center(
      child: Padding(
        padding: space.screenPadding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: space.maxContentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: space.iconXl, color: muted),
              SizedBox(height: space.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.text.titleMedium,
              ),
              SizedBox(height: space.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: muted),
              ),
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: space.lg),
                primaryAction
                    ? PrimaryButton(label: actionLabel!, onPressed: onAction)
                    : TertiaryButton(label: actionLabel!, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A request failed: Error tint card, what failed and "Reintentar".
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Algo salió mal',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final error = context.scheme.error;
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: context.qColors.errorTint,
          shape: context.shapes.rounded(context.shapes.lg),
        ),
        child: Padding(
          padding: space.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: space.iconMd, color: error),
              SizedBox(width: space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.text.titleMedium?.copyWith(color: error),
                    ),
                    SizedBox(height: space.xs),
                    Text(
                      message,
                      style: context.text.bodyMedium?.copyWith(color: error),
                    ),
                    if (onRetry != null) ...[
                      SizedBox(height: space.md),
                      SecondaryButton(label: 'Reintentar', onPressed: onRetry),
                    ],
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

/// A check could not complete (offline, timeout, 429, 5xx, invalid JSON).
///
/// Uses the `abstain` style and never says "sin coincidencias": unverifiable is
/// not safe.
class UnverifiableState extends StatelessWidget {
  const UnverifiableState({
    super.key,
    required this.reason,
    this.advice,
    this.onRetry,
  });

  /// One sentence: why the check could not complete.
  final String reason;

  /// What the person can do instead.
  final String? advice;
  final VoidCallback? onRetry;

  static const title = 'No se pudo verificar';

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final style = context.riskPalette.abstain;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: style.background,
          shape: context.shapes.rounded(context.shapes.lg),
        ),
        child: Padding(
          padding: space.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(style.icon, size: space.iconMd, color: style.foreground),
              SizedBox(width: space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.text.titleMedium?.copyWith(
                        color: style.foreground,
                      ),
                    ),
                    SizedBox(height: space.xs),
                    Text(
                      reason,
                      style: context.text.bodyMedium?.copyWith(
                        color: style.foreground,
                      ),
                    ),
                    if (advice != null) ...[
                      SizedBox(height: space.xs),
                      Text(
                        advice!,
                        style: context.text.bodyMedium?.copyWith(
                          color: style.foreground,
                        ),
                      ),
                    ],
                    if (onRetry != null) ...[
                      SizedBox(height: space.md),
                      SecondaryButton(label: 'Reintentar', onPressed: onRetry),
                    ],
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

/// One skeleton block (Sunken fill, 8 dp radius) with an optional sweep.
///
/// The sweep animates a translation only, and only when motion is allowed;
/// with reduce motion the block is static.
class SkeletonBlock extends StatefulWidget {
  const SkeletonBlock({super.key, required this.height, this.width});

  final double height;
  final double? width;

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with TickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = context.motion;
    if (motion.reduced(context)) {
      _controller?.dispose();
      _controller = null;
    } else {
      _controller ??= AnimationController(vsync: this, duration: motion.skeleton)
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.qColors;
    final shapes = context.shapes;
    final controller = _controller;
    Widget block = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: shapes.smRadius,
      ),
      child: SizedBox(width: widget.width, height: widget.height),
    );
    if (controller != null) {
      final curve = CurvedAnimation(
        parent: controller,
        curve: context.motion.skeletonCurve,
      );
      block = ClipRRect(
        borderRadius: shapes.smRadius,
        child: Stack(
          children: [
            block,
            Positioned.fill(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1, 0),
                  end: const Offset(1, 0),
                ).animate(curve),
                child: FractionallySizedBox(
                  widthFactor: 0.4,
                  alignment: Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.canvas.withValues(alpha: 0),
                          colors.canvas.withValues(alpha: 0.6),
                          colors.canvas.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return ExcludeSemantics(child: block);
  }
}

/// Skeleton placeholder for a list or result. After [timeout] without being
/// replaced it turns into the unverifiable state instead of waiting forever.
class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({
    super.key,
    this.lines = 3,
    this.lineHeight,
    this.timeout,
    this.timeoutReason = 'La comprobación tardó demasiado.',
    this.onRetry,
  });

  final int lines;
  final double? lineHeight;

  /// Defaults to the motion token (8 s).
  final Duration? timeout;
  final String timeoutReason;
  final VoidCallback? onRetry;

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton> {
  Timer? _timer;
  bool _timedOut = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer ??= Timer(widget.timeout ?? context.motion.loadingTimeout, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timedOut) {
      return UnverifiableState(
        reason: widget.timeoutReason,
        onRetry: widget.onRetry,
      );
    }
    final space = context.space;
    return Semantics(
      label: 'Cargando',
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widget.lines; i++) ...[
            if (i > 0) SizedBox(height: space.sm),
            SkeletonBlock(height: widget.lineHeight ?? space.rowHeight),
          ],
        ],
      ),
    );
  }
}
