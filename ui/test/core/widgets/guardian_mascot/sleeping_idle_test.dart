import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/core/widgets/guardian_mascot/generated/guardian_mascot_rig_data.dart';
import 'package:qhawix/core/widgets/guardian_mascot/generated/guardian_mascot_spec_data.dart';
import 'package:qhawix/core/widgets/guardian_mascot/mascot_engine.dart';
import 'package:qhawix/core/widgets/guardian_mascot/mascot_spec.dart';

MascotEngine _engine({bool reduced = false}) => MascotEngine(
      kGuardianMascotSpec,
      rigParts: kGuardianMascotRig.partNames,
      reducedMotion: reduced,
    );

MascotTrack _track(String part) =>
    kGuardianMascotSpec.states['idle']!.tracks.firstWhere((t) => t.part == part);

List<double> _values(MascotTrack track, String key) =>
    [for (final k in track.keyframes) k.values[key] ?? 0];

/// Largest difference between two poses over every animated component.
double _distance(MascotPose a, MascotPose b) => [
      (a.x - b.x).abs(),
      (a.y - b.y).abs(),
      (a.r - b.r).abs(),
      (a.sx - b.sx).abs() * 100,
      (a.sy - b.sy).abs() * 100,
      (a.o - b.o).abs() * 100,
    ].reduce(math.max);

void main() {
  const closedEyeScale = 0.08; // the rig's blink pose from the Node idle (sy 0.08, y 4)

  group('sleeping idle', () {
    test('its static (reduced-motion) pose is asleep: eyes closed, head neutral, no z marks', () {
      final e = _engine(reduced: true);
      expect(e.state, 'idle');
      for (final eye in ['eyeL', 'eyeR']) {
        final pose = e.poseOf(eye);
        expect(pose.sy, closedEyeScale, reason: eye);
        expect(pose.y, 4, reason: eye);
      }
      expect(e.poseOf('root').r, 0, reason: 'head neutral');
      for (final z in ['z1', 'z2', 'z3']) {
        expect(e.poseOf(z).o, 0, reason: z);
      }
      e.advance(60000);
      expect(e.poseOf('root').r, 0, reason: 'frozen');
      expect(e.needsFrames, isFalse);
    });

    test('eyes stay closed except for a brief crack on the side it turns toward', () {
      for (final side in ['eyeL', 'eyeR']) {
        final sy = _values(_track(side), 'sy');
        expect(sy.first, closedEyeScale);
        expect(sy.last, closedEyeScale);
        expect(sy.reduce(math.max), lessThan(0.5), reason: '$side only cracks open');
        expect(sy.reduce(math.max), greaterThan(closedEyeScale));
      }
    });

    test('slow breathing and a sound every 7 to 10 seconds', () {
      final root = _track('root');
      expect(root.duration, 16800);
      // 3 breaths of 5.6 s: lows (y 6) at 0, 11.2 s and the end of the cycle.
      final lows = [
        for (final k in root.keyframes)
          if ((k.values['y'] ?? 0) == 6) k.offset * root.duration,
      ];
      for (final ms in [0, 11200, 16800]) {
        expect(lows.any((v) => (v - ms).abs() < 0.1), isTrue, reason: 'breath low at $ms ms');
      }
      // Events start at the anticipation keyframes (the ones that ease out into the turn).
      final starts = [
        for (final k in root.keyframes)
          if (k.ease == 'ease-out') k.offset * root.duration,
      ];
      expect(starts, hasLength(2));
      final gap = starts[1] - starts[0];
      expect(gap, inInclusiveRange(7000, 10000));
      expect(root.duration - gap, inInclusiveRange(7000, 10000), reason: 'the wrap-around gap too');
    });

    test('the head turns a few degrees, alternating sides, with a small lift', () {
      final r = _values(_track('root'), 'r');
      double peak(Iterable<double> v) => v.reduce((a, b) => a.abs() > b.abs() ? a : b);
      final firstPeak = peak(r.take(r.length ~/ 2));
      final secondPeak = peak(r.skip(r.length ~/ 2));
      expect(firstPeak, greaterThan(0), reason: 'first to the right');
      expect(secondPeak, lessThan(0), reason: 'then to the left');
      expect(firstPeak.abs(), inInclusiveRange(3, 8));
      expect(firstPeak, -secondPeak, reason: 'mirror images');
      expect(_values(_track('root'), 'y').reduce(math.min), lessThan(0));
    });

    test('one tuft perks per event, asymmetric, under 10 degrees, alternating with the side', () {
      final l = _values(_track('browL'), 'r');
      final r = _values(_track('browR'), 'r');
      for (final v in [...l, ...r]) {
        expect(v.abs(), lessThan(10));
      }
      expect(r.reduce(math.max), greaterThan(6), reason: 'right tuft perks in the first event');
      expect(l.reduce(math.min), lessThan(-6), reason: 'left tuft perks in the second');
      final e = _engine()..seek(6000);
      expect((e.poseOf('browR').r - e.poseOf('browL').r).abs(), greaterThan(3), reason: 'asymmetric');
    });

    test('while turned toward a side, the tuft on that side is the raised one', () {
      final e = _engine()..seek(6000);
      expect(e.poseOf('root').r, greaterThan(3), reason: 'turned right');
      expect(e.poseOf('browR').r, greaterThan(5));
      e.seek(14700);
      expect(e.poseOf('root').r, lessThan(-3), reason: 'turned left');
      expect(e.poseOf('browL').r, lessThan(-5));
    });

    test('z marks are faint, slow and drift upward only', () {
      for (final z in ['z1', 'z2', 'z3']) {
        final track = _track(z);
        expect(track.duration, greaterThanOrEqualTo(3000));
        expect(_values(track, 'o').reduce(math.max), lessThanOrEqualTo(0.4));
        final y = _values(track, 'y');
        expect(y.reduce(math.max), lessThanOrEqualTo(0));
        expect(y.last, lessThan(y.first));
        expect(track.keyframes.first.values['o'], 0);
        expect(track.keyframes.last.values['o'], 0);
      }
    });

    test('it breathes slower than the Node idle and only moves the expected parts', () {
      expect(_track('root').duration / 3, greaterThan(5000), reason: 'a breath is 5.6 s (Node: 4.2 s)');
      final parts = kGuardianMascotSpec.states['idle']!.tracks.map((t) => t.part).toSet();
      expect(parts, {'root', 'eyeL', 'eyeR', 'browL', 'browR', 'z1', 'z2', 'z3'});
    });
  });

  group('transitions are continuous', () {
    const others = ['thinking', 'working', 'success', 'listening', 'scanning', 'alert', 'stealth'];
    const dtMs = 16.0;
    final allParts = kGuardianMascotSpec.parts.keys.toList();

    /// Steps through a blend and asserts that no frame jumps more than the eased blend allows.
    void expectContinuousBlend(MascotEngine e, String target) {
      final before = {for (final p in allParts) p: e.poseOf(p)};
      final blend = math.max(
        kGuardianMascotSpec.states[target]!.blendMs ?? kDefaultBlendMs,
        kGuardianMascotSpec.states[e.state]!.exitBlendMs ?? 0,
      );
      e.play();
      e.setState(target);
      for (final part in allParts) {
        expect(_distance(before[part]!, e.poseOf(part)), lessThan(1e-9), reason: '$target.$part start');
      }
      final frames = <String, List<MascotPose>>{
        for (final p in allParts) p: [e.poseOf(p)],
      };
      final steps = (blend / dtMs).floor(); // stay inside the blend: tracks move at their own pace after
      for (var i = 0; i < steps; i++) {
        e.advance(dtMs);
        for (final part in allParts) {
          frames[part]!.add(e.poseOf(part));
        }
      }
      for (final part in allParts) {
        final poses = frames[part]!;
        final span = poses.map((p) => _distance(before[part]!, p)).reduce(math.max);
        // Eased blend (ease-out starts at slope ~1.7): a frame never moves more than 3x the
        // average speed of the whole blend.
        final limit = 3 * span * (dtMs / blend) + 1e-6;
        for (var i = 1; i < poses.length; i++) {
          expect(_distance(poses[i - 1], poses[i]), lessThanOrEqualTo(limit), reason: '$target.$part step $i');
        }
      }
    }

    for (final target in others) {
      test('idle to $target at several moments of the loop', () {
        for (final ms in <double>[0, 1500, 5500, 6200, 7400, 13900, 15500]) {
          expectContinuousBlend(_engine()..seek(ms), target);
        }
      });
    }

    test('every blend ends exactly on the first keyframe of the new state', () {
      for (final target in others) {
        final e = _engine()..seek(6000);
        e.play();
        e.setState(target);
        // idle exits over 400 ms; a state may blend in for longer (stealth: 700 ms).
        e.advance(math.max(kGuardianMascotSpec.states[target]!.blendMs ?? kDefaultBlendMs, 400));
        final track = kGuardianMascotSpec.states[target]!.tracks.firstWhere((t) => t.part == 'root');
        expect(e.poseOf('root').y, closeTo(track.keyframes.first.values['y'] ?? 0, 1e-6), reason: target);
      }
    });

    test('eyes open smoothly when waking: no frame covers more than a third of the way', () {
      final e = _engine()..seek(0);
      e.play();
      e.setState('listening');
      var prev = e.poseOf('eyeL').sy;
      var maxStep = 0.0;
      for (var i = 0; i < 40; i++) {
        e.advance(16);
        final now = e.poseOf('eyeL').sy;
        maxStep = math.max(maxStep, (now - prev).abs());
        prev = now;
      }
      expect(prev, closeTo(1.1, 1e-6));
      expect(maxStep, lessThan((1.1 - 0.08) / 3));
    });

    test('success returns to the sleeping idle without a pop and falls asleep again', () {
      final e = _engine()
        ..setState('success', blend: false)
        ..advance(2799);
      final last = {for (final p in allParts) p: e.poseOf(p)};
      e.advance(5);
      expect(e.state, 'idle');
      for (final part in allParts) {
        expect(_distance(last[part]!, e.poseOf(part)), lessThan(1e-3), reason: part);
      }
      e.advance(600);
      expect(e.poseOf('eyeL').sy, closeTo(closedEyeScale, 1e-6));
      expect(e.poseOf('root').y, closeTo(6, 0.1));
    });

    test('success to idle in reduced motion lands on the sleeping pose', () {
      final e = _engine(reduced: true)..setState('success');
      e.advance(1800);
      expect(e.state, 'idle');
      expect(e.poseOf('eyeL').sy, closeTo(closedEyeScale, 1e-9));
      expect(e.poseOf('root').r, 0);
    });
  });
}
