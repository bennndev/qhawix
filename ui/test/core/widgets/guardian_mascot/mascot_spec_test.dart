import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/core/widgets/guardian_mascot/generated/guardian_mascot_rig_data.dart';
import 'package:qhawix/core/widgets/guardian_mascot/generated/guardian_mascot_spec_data.dart';
import 'package:qhawix/core/widgets/guardian_mascot/guardian_mascot_state.dart';

import '../../../../tool/guardian_mascot/generate.dart';

const _toolDir = 'tool/guardian_mascot';
const _widgetDir = 'lib/core/widgets/guardian_mascot';
// `idle` is NOT here on purpose: the owner asked for a sleeping idle (see the deviation test).
const _nodeStates = ['thinking', 'working', 'success'];
const _newStates = ['listening', 'scanning', 'alert', 'stealth'];

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

String _lf(String text) => text.replaceAll('\r', '');

void main() {
  final dartJson = kGuardianMascotSpec.toJson();
  final nodeSpec = _json('$_toolDir/source/mascot.spec.json');

  group('spec', () {
    test('all eight states are valid', () {
      expect(kGuardianMascotSpec.validate(), isEmpty);
      expect(kGuardianMascotSpec.states.keys, ['idle', ..._nodeStates, ..._newStates]);
    });

    test('the enum matches the spec states one to one', () {
      expect(
        GuardianMascotState.values.map((s) => s.name).toList(),
        kGuardianMascotSpec.states.keys.toList(),
      );
    });

    test('idle is an intentional, documented deviation from the Node spec (owner request)', () {
      // The owner asked for the resting state to be a light sleeper that listens, so `idle`
      // no longer equals pet/animated's idle. The Node copy stays untouched; the override lives
      // in tool/guardian_mascot/source/idle_sleep.spec.json and is applied by the generator.
      final dartStates = dartJson['states']! as Map<String, Object?>;
      final nodeStates = nodeSpec['states'] as Map<String, dynamic>;
      expect(dartStates['idle'], isNot(equals(nodeStates['idle'])));
      final override = _json('$_toolDir/source/idle_sleep.spec.json');
      final idle = (override['overrides'] as Map<String, dynamic>)['idle'] as Map<String, dynamic>;
      expect(idle['intent'], contains('OWNER-REQUESTED DEVIATION'));
      expect(File('$_widgetDir/README.md').readAsStringSync(), contains('intentional deviation'));
    });

    test('thinking, working and success equal mascot.spec.json value for value', () {
      final dartStates = dartJson['states']! as Map<String, Object?>;
      final nodeStates = nodeSpec['states'] as Map<String, dynamic>;
      for (final name in _nodeStates) {
        expect(dartStates[name], equals(nodeStates[name]), reason: name);
      }
      expect(dartJson['initialState'], nodeSpec['initialState']);
      final dartParts = dartJson['parts']! as Map<String, Object?>;
      final nodeParts = nodeSpec['parts'] as Map<String, dynamic>;
      for (final entry in nodeParts.entries) {
        expect(dartParts[entry.key], equals(entry.value), reason: entry.key);
      }
    });

    test('the copied source is identical to the Node rig when the repo has it', () {
      final original = File('../pet/animated/src/mascot.spec.json');
      if (!original.existsSync()) return;
      expect(_lf(original.readAsStringSync()), _lf(File('$_toolDir/source/mascot.spec.json').readAsStringSync()));
      final svg = File('../pet/animated/assets/mascot.svg');
      expect(_lf(svg.readAsStringSync()), _lf(File('$_toolDir/source/mascot.svg').readAsStringSync()));
    });

    test('offsets stay within 0 and 1 and every part is declared and in the rig', () {
      final rigParts = kGuardianMascotRig.partNames;
      for (final entry in kGuardianMascotSpec.states.entries) {
        for (final track in entry.value.tracks) {
          expect(kGuardianMascotSpec.parts, contains(track.part), reason: '${entry.key}.${track.part}');
          expect(rigParts, contains(track.part), reason: '${entry.key}.${track.part}');
          for (final kf in track.keyframes) {
            expect(kf.offset, inInclusiveRange(0, 1));
          }
        }
      }
      for (final part in kGuardianMascotSpec.parts.keys) {
        expect(rigParts, contains(part));
      }
    });

    test('tuft rotation stays under 10 degrees in every state', () {
      for (final entry in kGuardianMascotSpec.states.entries) {
        for (final track in entry.value.tracks.where((t) => t.part.startsWith('brow'))) {
          for (final kf in track.keyframes) {
            expect((kf.values['r'] ?? 0).abs(), lessThan(10), reason: '${entry.key}.${track.part}');
          }
        }
      }
    });

    test('only transform and opacity are animated', () {
      for (final state in kGuardianMascotSpec.states.values) {
        for (final track in state.tracks) {
          for (final kf in track.keyframes) {
            expect(kf.values.keys.toSet().difference({'x', 'y', 'r', 's', 'sx', 'sy', 'o', 'd'}), isEmpty);
          }
        }
      }
    });
  });

  group('new states', () {
    final states = kGuardianMascotSpec.states;

    test('no new loop cycles faster than "working"', () {
      final workingFastest = states['working']!.tracks.map((t) => t.duration).reduce((a, b) => a < b ? a : b);
      for (final name in _newStates.where((n) => states[n]!.loop)) {
        for (final track in states[name]!.tracks) {
          expect(track.duration, greaterThanOrEqualTo(workingFastest), reason: '$name.${track.part}');
        }
      }
    });

    test('alert is a held one-shot that freezes on its final pose', () {
      final alert = states['alert']!;
      expect(alert.loop, isFalse);
      expect(alert.hold, isTrue);
      expect(alert.next, isNull);
      expect(alert.pose, 1);
    });

    test('stealth is a faint, near-still loop with smooth enter and exit', () {
      final stealth = states['stealth']!;
      expect(stealth.loop, isTrue);
      final root = stealth.tracks.single;
      for (final kf in root.keyframes) {
        expect(kf.values['o'], inInclusiveRange(0.1, 0.2));
        expect((kf.values['y'] ?? 0).abs(), lessThanOrEqualTo(2));
      }
      expect(stealth.blendMs, greaterThanOrEqualTo(500));
      expect(stealth.exitBlendMs, greaterThanOrEqualTo(500));
    });

    test('listening, scanning and alert animate body, eyes and tufts', () {
      for (final name in ['listening', 'scanning', 'alert']) {
        final parts = states[name]!.tracks.map((t) => t.part).toSet();
        expect(parts, containsAll(['root', 'eyeL', 'eyeR', 'browL', 'browR']), reason: name);
      }
    });

    test('each new state documents its intent in the source spec', () {
      final extra = _json('$_toolDir/source/guardian_states.spec.json');
      final extraStates = extra['states'] as Map<String, dynamic>;
      for (final name in _newStates) {
        expect((extraStates[name] as Map<String, dynamic>)['intent'], isA<String>(), reason: name);
      }
    });
  });

  group('generated code', () {
    test('committed output equals what the generator produces', () {
      final generated = generateFiles(_toolDir);
      for (final entry in generated.entries) {
        final committed = File('$_widgetDir/generated/${entry.key}').readAsStringSync();
        expect(_lf(committed), _lf(entry.value), reason: '${entry.key} is stale: run the generator');
      }
    });

    test('the mascot code has no colour literals', () {
      final literal = RegExp(r'Color\(0x|Colors\.|Color\.from');
      final files = Directory(_widgetDir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final file in files) {
        expect(literal.hasMatch(file.readAsStringSync()), isFalse, reason: file.path);
      }
    });

    test('path parser handles relative, implicit and smooth commands', () {
      expect(parsePathData('M1,2 l3,4 5,6 z'), [0, 1.0, 2.0, 1, 4.0, 6.0, 1, 9.0, 12.0, 4]);
      expect(parsePathData('M0,0H10V5'), [0, 0.0, 0.0, 1, 10.0, 0.0, 1, 10.0, 5.0]);
      expect(parsePathData('M0,0C1,1 2,2 3,0S5,-2 6,0'), [
        0, 0.0, 0.0, 2, 1.0, 1.0, 2.0, 2.0, 3.0, 0.0, 2, 4.0, -2.0, 5.0, -2.0, 6.0, 0.0,
      ]);
      expect(() => parsePathData('M0,0 A5,5 0 0 1 10,10'), throwsUnsupportedError);
    });

    test('bounds include curve extrema, not just control points', () {
      final quad = pathBounds(parsePathData('M0,10Q5,0 10,10'));
      expect(quad[1], closeTo(5, 1e-9));
      final cubic = pathBounds(parsePathData('M0,0C0,10 10,10 10,0'));
      expect(cubic[3], closeTo(7.5, 1e-9));
    });
  });
}
