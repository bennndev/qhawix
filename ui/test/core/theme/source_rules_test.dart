import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// DESIGN.md (Flutter mapping): a check forbids literal colors, font sizes and
/// numeric durations outside `core/theme/`. Shared provider timeouts live in
/// `core/timeouts.dart`; the mascot rig is the other duration exemption.
final _rules = <String, RegExp>{
  'Color(0x...)': RegExp(r'\bColor\(\s*0x', caseSensitive: true),
  'TextStyle(fontSize: ...)': RegExp(r'TextStyle\(\s*fontSize\s*:'),
  'numeric Duration literal': RegExp(
    r'\bDuration\(\s*(days|hours|minutes|seconds|milliseconds|microseconds)'
    r'\s*:\s*\d',
  ),
};

bool _exempt(String path) {
  final p = path.replaceAll('\\', '/');
  return p.contains('/core/theme/') ||
      p.endsWith('/core/timeouts.dart') ||
      p.contains('/core/widgets/guardian_mascot/');
}

List<String> violations(Map<String, String> sources) {
  final found = <String>[];
  for (final entry in sources.entries) {
    if (_exempt(entry.key)) continue;
    for (final rule in _rules.entries) {
      if (rule.value.hasMatch(entry.value)) {
        found.add('${entry.key}: ${rule.key}');
      }
    }
  }
  return found;
}

void main() {
  test('the rules catch each forbidden literal', () {
    expect(
      violations({
        '/lib/a.dart': 'const c = Color(0xFF112233);',
        '/lib/b.dart': 'const s = TextStyle(fontSize: 12);',
        '/lib/c.dart': 'const d = Duration(milliseconds: 100);',
      }),
      hasLength(3),
    );
  });

  test('the rules allow derived values and exempt folders', () {
    expect(
      violations({
        '/lib/a.dart': 'final d = Duration.zero; final c = Colors.transparent;',
        '/lib/core/theme/t.dart': 'const c = Color(0xFF112233);',
        '/lib/core/timeouts.dart': 'const d = Duration(seconds: 8);',
        '/lib/core/widgets/guardian_mascot/m.dart':
            'const c = Color(0xFF112233);',
      }),
      isEmpty,
    );
  });

  test('no hard-coded color, font size or duration under lib/', () {
    final sources = {
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File && file.path.endsWith('.dart'))
          file.path: file.readAsStringSync(),
    };
    expect(sources, isNotEmpty);
    expect(violations(sources), isEmpty);
  });
}
