// Pure Dart port of pet/animated/src/mascot-engine.js. It plays a [MascotSpec] with an explicit
// clock: the host calls [MascotEngine.advance] (a ticker, a test, a contact sheet) and reads
// [MascotEngine.poseOf] for every part. No Flutter imports, so every rule runs without a device.

import 'dart:math' as math;

import 'mascot_easing.dart';
import 'mascot_spec.dart';

const double kDefaultBlendMs = 220;
const double kDefaultReducedHoldMs = 1500;

/// Transform and opacity of one part at one instant.
class MascotPose {
  const MascotPose({
    this.x = 0,
    this.y = 0,
    this.r = 0,
    this.sx = 1,
    this.sy = 1,
    this.o = 1,
    this.d = 1,
  });

  static const MascotPose rest = MascotPose();

  final double x;
  final double y;

  /// Rotation in degrees.
  final double r;
  final double sx;
  final double sy;

  /// Opacity, 0-1.
  final double o;

  /// Stroke draw progress, 0-1.
  final double d;

  MascotPose copyWith({
    double? x,
    double? y,
    double? r,
    double? sx,
    double? sy,
    double? o,
    double? d,
  }) =>
      MascotPose(
        x: x ?? this.x,
        y: y ?? this.y,
        r: r ?? this.r,
        sx: sx ?? this.sx,
        sy: sy ?? this.sy,
        o: o ?? this.o,
        d: d ?? this.d,
      );

  static double _l(double a, double b, double t) => a + (b - a) * t;

  static MascotPose lerp(MascotPose a, MascotPose b, double t) => MascotPose(
        x: _l(a.x, b.x, t),
        y: _l(a.y, b.y, t),
        r: _l(a.r, b.r, t),
        sx: _l(a.sx, b.sx, t),
        sy: _l(a.sy, b.sy, t),
        o: _l(a.o, b.o, t),
        d: _l(a.d, b.d, t),
      );

  /// Rotation normalised to (-180, 180], like the angle a browser reads back from a matrix.
  MascotPose normalized() {
    var angle = r % 360;
    if (angle > 180) angle -= 360;
    return angle == r ? this : copyWith(r: angle);
  }

  @override
  String toString() => 'MascotPose(x: $x, y: $y, r: $r, sx: $sx, sy: $sy, o: $o, d: $d)';
}

enum MascotEventKind {
  /// A state started (including automatic transitions and reduced-motion re-entry).
  stateChanged,

  /// A one-shot state finished. `to` is the state playing afterwards (equal to `from` when held).
  oneShotFinished,
}

class MascotEvent {
  const MascotEvent(this.kind, this.from, this.to);

  final MascotEventKind kind;
  final String? from;
  final String to;
}

typedef MascotListener = void Function(MascotEvent event);

class MascotEngine {
  /// Throws [MascotSpecException] when [spec] is invalid or [rigParts] lacks a declared part.
  MascotEngine(
    this.spec, {
    required Iterable<String> rigParts,
    this.speed = 1,
    this.blendMs = kDefaultBlendMs,
    bool reducedMotion = false,
  }) : _reduced = reducedMotion {
    final problems = spec.validate();
    final available = rigParts.toSet();
    for (final part in spec.parts.keys) {
      if (!available.contains(part)) {
        problems.add('Rig has no element for part "$part"');
      }
    }
    if (problems.isNotEmpty) throw MascotSpecException(problems);
    for (final entry in spec.parts.entries) {
      _rest[entry.key] = _restPose(entry.value);
    }
    setState(spec.initialState, blend: false);
  }

  final MascotSpec spec;

  /// Playback multiplier applied to every advance.
  final double speed;

  /// Default cross-state blend in milliseconds (a state may override it).
  final double blendMs;

  final Map<String, MascotPose> _rest = {};
  final Set<MascotListener> _listeners = {};
  Map<String, MascotTrack> _tracked = const {};
  Map<String, MascotPose>? _snapshot;
  late String _current;
  late MascotStateSpec _state;
  double _stateMs = 0;
  double _activeBlendMs = 0;
  double _longest = 0;
  bool _reduced;
  bool _paused = false;
  bool _finished = false;
  bool _destroyed = false;

  String get state => _current;
  MascotStateSpec get stateSpec => _state;
  bool get isPaused => _paused;
  bool get reducedMotion => _reduced;

  /// Milliseconds elapsed in the current state, including its blend phase.
  double get elapsedMs => _stateMs;

  /// True while the engine still has something to advance. A held one-shot, a paused engine and
  /// a reduced-motion loop do not need frames, so a host can stop its ticker.
  bool get needsFrames {
    if (_paused || _destroyed) return false;
    if (_reduced) return !_state.loop && _state.next != null;
    if (_state.loop) return true;
    return !_finished;
  }

  /// Subscribes to engine events; returns the unsubscribe function.
  void Function() on(MascotListener listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  /// Reduced motion freezes every state on its static pose; changing it re-enters the state.
  set reducedMotion(bool value) {
    if (_reduced == value) return;
    _reduced = value;
    setState(_current, blend: false);
  }

  void setState(String name, {bool blend = true}) {
    final next = spec.states[name];
    if (next == null) throw ArgumentError('Unknown mascot state "$name"');
    final fromName = _destroyed || !_hasState ? null : _current;
    final fromSpec = fromName == null ? null : spec.states[fromName];
    final effective = blend && !_reduced
        ? math.max(next.blendMs ?? blendMs, fromSpec?.exitBlendMs ?? 0)
        : 0.0;
    final snapshot = effective > 0
        ? {for (final part in spec.parts.keys) part: poseOf(part)}
        : null;

    _current = name;
    _state = next;
    _hasState = true;
    _stateMs = 0;
    _finished = false;
    _activeBlendMs = effective;
    _snapshot = snapshot;
    _tracked = {for (final t in next.tracks) t.part: t};
    _longest = next.tracks.isEmpty
        ? 0
        : next.tracks.map((t) => t.duration).reduce(math.max);
    _emit(MascotEvent(MascotEventKind.stateChanged, fromName, name));
  }

  bool _hasState = false;

  /// Moves the clock forward by [dtMs] real milliseconds (scaled by [speed]).
  void advance(double dtMs) {
    if (_paused || _destroyed || !(dtMs > 0)) return;
    final state = _state;
    _stateMs += dtMs * speed;
    if (_reduced) {
      final next = state.next;
      if (!state.loop &&
          next != null &&
          _stateMs >= (state.reducedHoldMs ?? kDefaultReducedHoldMs)) {
        _finish(state, next);
      }
      return;
    }
    if (state.loop) return;
    final end = _activeBlendMs + _longest;
    if (_stateMs < end) return;
    _stateMs = end;
    final next = state.next;
    if (next != null) {
      _finish(state, next);
    } else if (!_finished) {
      _finished = true;
      _emit(MascotEvent(MascotEventKind.oneShotFinished, _current, _current));
    }
  }

  void _finish(MascotStateSpec state, String next) {
    final finished = _current;
    setState(next);
    _emit(MascotEvent(MascotEventKind.oneShotFinished, finished, next));
  }

  /// Deterministic control for tests and contact sheets: pauses and jumps to [ms] in the state.
  void seek(double ms) {
    _paused = true;
    _stateMs = ms;
  }

  void pause() => _paused = true;

  void play() => _paused = false;

  void destroy() {
    _destroyed = true;
    _listeners.clear();
  }

  /// Pose of [part] at the current instant.
  MascotPose poseOf(String part) {
    final rest = _rest[part];
    if (rest == null) throw ArgumentError('Unknown mascot part "$part"');
    final track = _tracked[part];
    if (_reduced) {
      return track == null ? rest : _evaluate(track, rest, _state.pose);
    }
    if (_activeBlendMs > 0 && _stateMs < _activeBlendMs) {
      final first = track == null ? rest : _keyframePose(track.keyframes.first, rest);
      final t = easingFor('ease-out')(_stateMs / _activeBlendMs);
      return MascotPose.lerp(_snapshot![part]!.normalized(), first, t);
    }
    if (track == null) return rest;
    final t = _stateMs - _activeBlendMs;
    if (_state.loop) return _evaluate(track, rest, (t % track.duration) / track.duration);
    return _evaluate(track, rest, math.min(t / track.duration, 1));
  }

  MascotPose _evaluate(MascotTrack track, MascotPose rest, double p) {
    final kfs = track.keyframes;
    if (p < 1) {
      for (var i = 0; i < kfs.length - 1; i++) {
        final a = kfs[i];
        final b = kfs[i + 1];
        if (p >= a.offset && p < b.offset) {
          final local = (p - a.offset) / (b.offset - a.offset);
          final eased = easingFor(a.ease ?? track.easing ?? 'ease-in-out')(local);
          return MascotPose.lerp(
            _keyframePose(a, rest),
            _keyframePose(b, rest),
            eased,
          );
        }
      }
    }
    return _keyframePose(kfs.last, rest);
  }

  static MascotPose _keyframePose(MascotKeyframe kf, MascotPose rest) {
    final v = kf.values;
    return MascotPose(
      x: v['x'] ?? rest.x,
      y: v['y'] ?? rest.y,
      r: v['r'] ?? rest.r,
      sx: v['sx'] ?? v['s'] ?? rest.sx,
      sy: v['sy'] ?? v['s'] ?? rest.sy,
      o: v['o'] ?? rest.o,
      d: v['d'] ?? rest.d,
    );
  }

  static MascotPose _restPose(MascotPartSpec part) {
    final r = part.rest;
    if (r == null) return MascotPose.rest;
    return MascotPose(
      x: r['x'] ?? 0,
      y: r['y'] ?? 0,
      r: r['r'] ?? 0,
      sx: r['sx'] ?? 1,
      sy: r['sy'] ?? 1,
      o: r['o'] ?? 1,
      d: r['d'] ?? 1,
    );
  }

  void _emit(MascotEvent event) {
    for (final fn in List.of(_listeners)) {
      fn(event);
    }
  }
}
