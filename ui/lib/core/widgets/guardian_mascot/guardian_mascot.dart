import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'generated/guardian_mascot_rig_data.dart';
import 'generated/guardian_mascot_spec_data.dart';
import 'guardian_mascot_state.dart';
import 'mascot_engine.dart';
import 'mascot_painter.dart';

export 'guardian_mascot_state.dart';

const double _kMinTapTarget = 48;
final double _kClockPeriodMs = const Duration(days: 1).inMilliseconds.toDouble();

/// "Guardian de Comportamiento": the animated owl.
///
/// Decorative by default (excluded from the semantics tree). Pass a Spanish [semanticLabel] to
/// expose it, as a button when [onTap] is also set. Colours default to the theme's
/// `colorScheme.primary` (body) and `colorScheme.onPrimary` (lines).
///
/// The mascot honours `MediaQuery.disableAnimations` (freezes on a static pose) and stops
/// animating while the app is in the background or the subtree's tickers are disabled.
class GuardianMascot extends StatefulWidget {
  const GuardianMascot({
    super.key,
    required this.state,
    this.size = 120,
    this.bodyColor,
    this.lineColor,
    this.semanticLabel,
    this.onTap,
    this.onStateEnd,
  });

  /// The state to play. Changing it blends from the current pose.
  final GuardianMascotState state;

  /// Side of the square the mascot is drawn in, in logical pixels.
  final double size;

  /// Body colour; defaults to `Theme.of(context).colorScheme.primary`.
  final Color? bodyColor;

  /// Colour of the lines and eyes; defaults to `Theme.of(context).colorScheme.onPrimary`.
  final Color? lineColor;

  /// Spanish label for assistive technology. Without it the mascot is excluded from semantics.
  final String? semanticLabel;

  /// Makes the mascot tappable (48 dp minimum target). Provide [semanticLabel] with it.
  final VoidCallback? onTap;

  /// Called when a one-shot state finishes, with the state the mascot is in afterwards: `idle`
  /// after `success`, or `alert` itself when its held pose is reached. Use it to keep the
  /// parent's `state` in sync with what is playing.
  final ValueChanged<GuardianMascotState>? onStateEnd;

  @override
  State<GuardianMascot> createState() => _GuardianMascotState();
}

class _GuardianMascotState extends State<GuardianMascot>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final MascotEngine _engine;
  late final AnimationController _controller;
  late final void Function() _unsubscribe;
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  double _lastMs = 0;
  bool _appActive = true;
  bool _tickerEnabled = true;

  @override
  void initState() {
    super.initState();
    _engine = MascotEngine(kGuardianMascotSpec, rigParts: kGuardianMascotRig.partNames);
    _unsubscribe = _engine.on(_onEngineEvent);
    if (widget.state != GuardianMascotState.idle) {
      _engine.setState(widget.state.name, blend: false);
    }
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _kClockPeriodMs.toInt()),
    )..addListener(_tick);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _appActive = lifecycle == null ||
        lifecycle == AppLifecycleState.resumed ||
        lifecycle == AppLifecycleState.inactive;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    _engine.reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncTicker();
  }

  @override
  void didUpdateWidget(GuardianMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      _engine.setState(widget.state.name);
      _syncTicker();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive =
        state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;
    _syncTicker();
  }

  void _onEngineEvent(MascotEvent event) {
    if (event.kind == MascotEventKind.stateChanged) {
      _frame.value++;
      return;
    }
    final callback = widget.onStateEnd;
    if (callback != null) callback(GuardianMascotState.values.byName(event.to));
  }

  void _tick() {
    final ms = _controller.value * _kClockPeriodMs;
    var dt = ms - _lastMs;
    if (dt < 0) dt += _kClockPeriodMs;
    _lastMs = ms;
    _engine.advance(dt);
    _frame.value++;
    _syncTicker();
  }

  /// Runs the clock only while something is moving, the app is visible and tickers are enabled.
  void _syncTicker() {
    final run = _appActive && _tickerEnabled && _engine.needsFrames;
    if (run && !_controller.isAnimating) {
      _lastMs = _controller.value * _kClockPeriodMs;
      _controller.repeat();
    } else if (!run && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unsubscribe();
    _engine.destroy();
    _controller.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final art = RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        isComplex: true,
        painter: GuardianMascotPainter(
          engine: _engine,
          rig: kGuardianMascotRig,
          bodyColor: widget.bodyColor ?? scheme.primary,
          lineColor: widget.lineColor ?? scheme.onPrimary,
          repaint: _frame,
        ),
      ),
    );
    final label = widget.semanticLabel;
    final onTap = widget.onTap;
    if (onTap == null) {
      if (label == null) return ExcludeSemantics(child: art);
      return Semantics(
        label: label,
        image: true,
        excludeSemantics: true,
        child: art,
      );
    }
    final side = math.max(widget.size, _kMinTapTarget);
    final target = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(width: side, height: side, child: Center(child: art)),
    );
    if (label == null) return ExcludeSemantics(child: target);
    return Semantics(
      label: label,
      button: true,
      onTap: onTap,
      excludeSemantics: true,
      child: target,
    );
  }
}
