import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/core/widgets/guardian_mascot/mascot_easing.dart';
import 'package:qhawix/core/widgets/guardian_mascot/mascot_engine.dart';
import 'package:qhawix/core/widgets/guardian_mascot/mascot_spec.dart';

MascotKeyframe _kf(double offset, {double? x, String? ease}) =>
    MascotKeyframe(offset, ease: ease, values: {'x': ?x});

final MascotSpec _spec = MascotSpec(
  initialState: 'a',
  parts: const {
    'p': MascotPartSpec(),
    'q': MascotPartSpec(rest: {'o': 0}),
  },
  states: {
    'a': MascotStateSpec(
      loop: true,
      tracks: [
        MascotTrack('p', 1000, [_kf(0, x: 0), _kf(1, x: 100)], easing: 'linear'),
      ],
    ),
    'b': MascotStateSpec(
      loop: false,
      next: 'a',
      pose: 0.5,
      tracks: [
        MascotTrack('p', 500, [_kf(0, x: 80), _kf(1, x: 80)]),
      ],
    ),
    'h': MascotStateSpec(
      loop: false,
      hold: true,
      pose: 1,
      tracks: [
        MascotTrack('p', 400, [_kf(0, x: 0), _kf(1, x: 40)], easing: 'linear'),
      ],
    ),
    'slow': MascotStateSpec(
      loop: true,
      blendMs: 1000,
      exitBlendMs: 1000,
      tracks: [
        MascotTrack('p', 1000, [_kf(0, x: 10), _kf(1, x: 10)]),
      ],
    ),
  },
);

MascotEngine _engine({bool reduced = false, double speed = 1}) => MascotEngine(
      _spec,
      rigParts: const ['p', 'q'],
      reducedMotion: reduced,
      speed: speed,
    );

void main() {
  group('easing', () {
    test('linear and CSS keywords', () {
      expect(easingFor('linear')(0.3), 0.3);
      expect(easingFor('ease-in-out')(0.5), closeTo(0.5, 1e-6));
      expect(easingFor('ease-in-out')(0.25), lessThan(0.25));
      expect(easingFor('ease-out')(0.5), greaterThan(0.5));
      expect(easingFor('ease-in')(0.5), lessThan(0.5));
      expect(easingFor('ease')(0), 0);
      expect(easingFor('ease')(1), 1);
    });

    test('cubic-bezier() strings and unknown names', () {
      expect(
        easingFor('cubic-bezier(0.42, 0, 0.58, 1)')(0.3),
        closeTo(easingFor('ease-in-out')(0.3), 1e-9),
      );
      expect(() => easingFor('bounce'), throwsFormatException);
    });
  });

  group('interpolation', () {
    test('linear track, loop wraps and untracked parts stay at rest', () {
      final e = _engine()..seek(250);
      expect(e.poseOf('p').x, closeTo(25, 1e-9));
      e.seek(1250);
      expect(e.poseOf('p').x, closeTo(25, 1e-9));
      expect(e.poseOf('q').o, 0);
      expect(e.poseOf('q').sx, 1);
    });

    test('keyframe ease applies to the interval that starts at the keyframe', () {
      final spec = MascotSpec(
        initialState: 'a',
        parts: const {'p': MascotPartSpec()},
        states: {
          'a': MascotStateSpec(loop: true, tracks: [
            MascotTrack('p', 1000, [_kf(0, x: 0, ease: 'ease-in'), _kf(1, x: 100)], easing: 'linear'),
          ]),
        },
      );
      final e = MascotEngine(spec, rigParts: const ['p'])..seek(500);
      expect(e.poseOf('p').x, lessThan(50));
    });

    test('s sets both scales, sx and sy win over s', () {
      const spec = MascotSpec(
        initialState: 'a',
        parts: {'p': MascotPartSpec()},
        states: {
          'a': MascotStateSpec(loop: true, tracks: [
            MascotTrack('p', 1000, [
              MascotKeyframe(0, values: {'s': 2, 'sy': 3}),
              MascotKeyframe(1, values: {'s': 2, 'sy': 3}),
            ]),
          ]),
        },
      );
      final pose = (MascotEngine(spec, rigParts: const ['p'])..seek(0)).poseOf('p');
      expect(pose.sx, 2);
      expect(pose.sy, 3);
    });

    test('speed scales every advance', () {
      final e = _engine(speed: 2)..advance(250);
      expect(e.poseOf('p').x, closeTo(50, 1e-9));
    });

    test('pause freezes the clock and play resumes it', () {
      final e = _engine()
        ..advance(100)
        ..pause()
        ..advance(500);
      expect(e.elapsedMs, 100);
      e
        ..play()
        ..advance(50);
      expect(e.elapsedMs, 150);
    });
  });

  group('states', () {
    test('a one-shot returns to its next state and reports it', () {
      final e = _engine();
      final events = <MascotEvent>[];
      e.on(events.add);
      e.setState('b', blend: false);
      e.advance(499);
      expect(e.state, 'b');
      e.advance(1);
      expect(e.state, 'a');
      expect(
        [for (final ev in events) '${ev.kind.name}:${ev.from}>${ev.to}'],
        ['stateChanged:a>b', 'stateChanged:b>a', 'oneShotFinished:b>a'],
      );
    });

    test('a held one-shot stays on its last pose and stops needing frames', () {
      final e = _engine();
      final finished = <MascotEvent>[];
      e.on((ev) {
        if (ev.kind == MascotEventKind.oneShotFinished) finished.add(ev);
      });
      e.setState('h', blend: false);
      expect(e.needsFrames, isTrue);
      e.advance(400);
      e.advance(400);
      expect(e.state, 'h');
      expect(e.poseOf('p').x, 40);
      expect(e.needsFrames, isFalse);
      expect(finished, hasLength(1));
      expect(finished.single.to, 'h');
    });

    test('blend starts at the captured pose and ends on the first keyframe', () {
      final e = _engine()..seek(500);
      e.play();
      e.setState('b');
      expect(e.poseOf('p').x, closeTo(50, 1e-9));
      var last = 50.0;
      for (var i = 0; i < 4; i++) {
        e.advance(55);
        final x = e.poseOf('p').x;
        expect(x, greaterThan(last));
        expect(x, lessThanOrEqualTo(80));
        last = x;
      }
      expect(e.poseOf('p').x, closeTo(80, 1e-9));
    });

    test('blend wraps rotation like a matrix read-back', () {
      final spec = MascotSpec(
        initialState: 'a',
        parts: const {'p': MascotPartSpec()},
        states: {
          'a': const MascotStateSpec(loop: true, tracks: [
            MascotTrack('p', 1000, [
              MascotKeyframe(0, values: {'r': 0}),
              MascotKeyframe(1, values: {'r': 360}),
            ], easing: 'linear'),
          ]),
          'b': const MascotStateSpec(loop: true, tracks: []),
        },
      );
      final e = MascotEngine(spec, rigParts: const ['p'])..seek(750);
      e.play();
      e.setState('b');
      expect(e.poseOf('p').r, closeTo(-90, 1e-9));
    });

    test('per-state blend durations apply on enter and exit', () {
      final e = _engine()..setState('slow');
      e.advance(500);
      expect(e.poseOf('p').x, isNot(10), reason: 'still blending after 500 ms');
      e.advance(500);
      expect(e.poseOf('p').x, 10);
      e.setState('a');
      e.advance(300);
      expect(e.poseOf('p').x, isNot(0), reason: 'exit blend outlasts the default 220 ms');
    });

    test('unknown state throws', () {
      expect(() => _engine().setState('nope'), throwsArgumentError);
    });
  });

  group('reduced motion', () {
    test('freezes on the state pose with no blend', () {
      final e = _engine(reduced: true)..setState('b');
      expect(e.poseOf('p').x, 80);
      e.advance(100);
      expect(e.poseOf('p').x, 80);
    });

    test('loops are frozen at pose 0 and never advance', () {
      final e = _engine(reduced: true)..advance(5000);
      expect(e.state, 'a');
      expect(e.poseOf('p').x, 0);
      expect(e.needsFrames, isFalse);
    });

    test('a one-shot holds about 1500 ms by default, then continues', () {
      final e = _engine(reduced: true)..setState('b');
      expect(e.needsFrames, isTrue);
      e.advance(1499);
      expect(e.state, 'b');
      e.advance(1);
      expect(e.state, 'a');
    });

    test('a held one-shot freezes on its final pose', () {
      final e = _engine(reduced: true)..setState('h');
      expect(e.poseOf('p').x, 40);
      e.advance(10000);
      expect(e.state, 'h');
    });

    test('toggling the setting re-enters the current state without blending', () {
      final e = _engine()..setState('b');
      e.reducedMotion = true;
      expect(e.poseOf('p').x, 80);
      e.reducedMotion = false;
      expect(e.state, 'b');
    });
  });

  group('validation', () {
    test('rejects every broken contract rule', () {
      final bad = MascotSpec(
        initialState: 'missing',
        parts: const {'p': MascotPartSpec()},
        states: {
          'x': MascotStateSpec(loop: false, tracks: [
            MascotTrack('p', 0, [_kf(0.2), _kf(0.1)]),
            const MascotTrack('p', 100, [
              MascotKeyframe(0, values: {'zz': 1}),
              MascotKeyframe(1),
            ]),
            MascotTrack('ghost', 100, [_kf(0), _kf(1)]),
          ]),
          'y': const MascotStateSpec(loop: true, next: 'x', tracks: []),
        },
      );
      final errors = bad.validate().join('\n');
      expect(errors, contains('initialState "missing"'));
      expect(errors, contains('one-shot state needs "next" or "hold"'));
      expect(errors, contains('duration must be > 0'));
      expect(errors, contains('offsets must start at 0 and end at 1'));
      expect(errors, contains('offsets must not decrease'));
      expect(errors, contains('more than one track'));
      expect(errors, contains('unknown keyframe property "zz"'));
      expect(errors, contains('part is not declared'));
      expect(errors, contains('a loop cannot have'));
    });

    test('the engine throws on an invalid spec', () {
      const bad = MascotSpec(initialState: 'nope', parts: {}, states: {});
      expect(() => MascotEngine(bad, rigParts: const []), throwsA(isA<MascotSpecException>()));
    });

    test('the engine throws when the rig lacks a declared part', () {
      expect(
        () => MascotEngine(_spec, rigParts: const ['p']),
        throwsA(isA<MascotSpecException>().having((e) => e.toString(), 'message', contains('"q"'))),
      );
    });
  });
}
