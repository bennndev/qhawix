// Declarative animation spec for the Guardian mascot. Pure Dart, mirrors the JSON format of
// pet/animated/src/mascot.spec.json (see README.md in this folder).

/// Keyframe properties understood by the engine.
///
/// `x`/`y` are SVG units, `r` is degrees, `s`/`sx`/`sy` scale, `o` opacity and `d` stroke draw
/// progress (0-1). Anything omitted falls back to the part's rest pose.
const Set<String> kMascotKeyframeProps = {
  'x',
  'y',
  'r',
  's',
  'sx',
  'sy',
  'o',
  'd',
};

/// Thrown when a spec is invalid or the rig lacks a part the spec declares.
class MascotSpecException implements Exception {
  const MascotSpecException(this.problems);

  final List<String> problems;

  @override
  String toString() => 'Invalid mascot spec:\n- ${problems.join('\n- ')}';
}

class MascotPartSpec {
  const MascotPartSpec({this.origin, this.rest});

  /// Transform origin as a fraction of the part's fill box. Defaults to the centre.
  final List<double>? origin;

  /// Rest pose overrides (`o`, `d`, `sx`, `sy`, ...).
  final Map<String, double>? rest;

  Map<String, Object?> toJson() => {
        if (origin != null) 'origin': origin,
        if (rest != null) 'rest': rest,
      };
}

class MascotKeyframe {
  const MascotKeyframe(this.offset, {this.ease, this.values = const {}});

  final double offset;

  /// Easing of the interval that starts at this keyframe; falls back to the track easing.
  final String? ease;
  final Map<String, double> values;

  Map<String, Object?> toJson() => {
        'offset': offset,
        if (ease != null) 'ease': ease,
        ...values,
      };
}

class MascotTrack {
  const MascotTrack(
    this.part,
    this.duration,
    this.keyframes, {
    this.easing,
  });

  final String part;

  /// Duration in milliseconds.
  final double duration;
  final List<MascotKeyframe> keyframes;
  final String? easing;

  Map<String, Object?> toJson() => {
        'part': part,
        'duration': duration,
        'keyframes': [for (final k in keyframes) k.toJson()],
        if (easing != null) 'easing': easing,
      };
}

class MascotStateSpec {
  const MascotStateSpec({
    required this.loop,
    required this.tracks,
    this.next,
    this.hold = false,
    this.pose = 0,
    this.reducedHoldMs,
    this.blendMs,
    this.exitBlendMs,
  });

  /// Loops forever. A one-shot state needs [next] or [hold].
  final bool loop;

  /// State entered when a one-shot finishes.
  final String? next;

  /// One-shot that stays on its last pose instead of moving to [next].
  final bool hold;

  /// Fraction of each track at which the state is frozen under reduced motion.
  final double pose;

  /// Reduced motion: how long a one-shot with [next] holds its pose before moving on.
  final double? reducedHoldMs;

  /// Blend duration when entering this state (overrides the engine default).
  final double? blendMs;

  /// Blend duration when leaving this state (the longer of enter and exit wins).
  final double? exitBlendMs;
  final List<MascotTrack> tracks;

  Map<String, Object?> toJson() => {
        'loop': loop,
        if (next != null) 'next': next,
        if (hold) 'hold': true,
        'pose': pose,
        if (reducedHoldMs != null) 'reducedHoldMs': reducedHoldMs,
        if (blendMs != null) 'blendMs': blendMs,
        if (exitBlendMs != null) 'exitBlendMs': exitBlendMs,
        'tracks': [for (final t in tracks) t.toJson()],
      };
}

class MascotSpec {
  const MascotSpec({
    required this.initialState,
    required this.parts,
    required this.states,
  });

  final String initialState;
  final Map<String, MascotPartSpec> parts;
  final Map<String, MascotStateSpec> states;

  Map<String, Object?> toJson() => {
        'initialState': initialState,
        'parts': {for (final e in parts.entries) e.key: e.value.toJson()},
        'states': {for (final e in states.entries) e.key: e.value.toJson()},
      };

  /// Returns every contract violation; an empty list means the spec is valid.
  List<String> validate() {
    final errors = <String>[];
    if (!states.containsKey(initialState)) {
      errors.add('initialState "$initialState" is not a state');
    }
    for (final entry in states.entries) {
      final name = entry.key;
      final state = entry.value;
      final seen = <String>{};
      if (state.next != null && !states.containsKey(state.next)) {
        errors.add('$name: next "${state.next}" is not a state');
      }
      if (state.loop && (state.next != null || state.hold)) {
        errors.add('$name: a loop cannot have "next" or "hold"');
      }
      if (!state.loop && state.next == null && !state.hold) {
        errors.add('$name: one-shot state needs "next" or "hold"');
      }
      if (state.next != null && state.hold) {
        errors.add('$name: "next" and "hold" are mutually exclusive');
      }
      if (state.pose < 0 || state.pose > 1) {
        errors.add('$name: pose must be between 0 and 1');
      }
      for (final track in state.tracks) {
        final where = '$name.${track.part}';
        if (!parts.containsKey(track.part)) {
          errors.add('$where: part is not declared in "parts"');
        }
        if (!seen.add(track.part)) {
          errors.add('$where: more than one track for the same part');
        }
        if (!(track.duration > 0)) {
          errors.add('$where: duration must be > 0');
        }
        final kfs = track.keyframes;
        if (kfs.length < 2) errors.add('$where: needs at least 2 keyframes');
        if (kfs.isNotEmpty &&
            (kfs.first.offset != 0 || kfs.last.offset != 1)) {
          errors.add('$where: offsets must start at 0 and end at 1');
        }
        for (var i = 0; i < kfs.length; i++) {
          if (i > 0 && !(kfs[i].offset >= kfs[i - 1].offset)) {
            errors.add('$where: offsets must not decrease');
          }
          for (final key in kfs[i].values.keys) {
            if (!kMascotKeyframeProps.contains(key)) {
              errors.add('$where: unknown keyframe property "$key"');
            }
          }
        }
      }
    }
    return errors;
  }
}
