// Generates the Guardian mascot's Dart data from its sources, deterministically.
//
// Inputs (tool/guardian_mascot/source/):
//   mascot.svg                 rig copied from pet/animated/assets/mascot.svg
//   mascot.spec.json           spec copied from pet/animated/src/mascot.spec.json (4 states)
//   guardian_states.spec.json  the extra states, parts and shapes of this project
//   idle_sleep.spec.json       intentional override of `idle` (sleeping light sleeper) and its parts
// Outputs (lib/core/widgets/guardian_mascot/generated/):
//   guardian_mascot_rig_data.dart   the artwork as path data
//   guardian_mascot_spec_data.dart  the spec of all 8 states
//
// Run from ui/:  dart run tool/guardian_mascot/generate.dart
// The test suite fails when the committed output differs from what this script produces.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

const String _generatedDir = 'lib/core/widgets/guardian_mascot/generated';
const String rigFileName = 'guardian_mascot_rig_data.dart';
const String specFileName = 'guardian_mascot_spec_data.dart';

void main() {
  final toolDir = File.fromUri(Platform.script).parent.path;
  final outDir = Directory('$toolDir/../../$_generatedDir')..createSync(recursive: true);
  final files = generateFiles(toolDir);
  for (final entry in files.entries) {
    File('${outDir.path}/${entry.key}').writeAsStringSync(entry.value);
    stdout.writeln('wrote ${entry.key}');
  }
}

/// Returns the generated files by name. [toolDir] is the `tool/guardian_mascot` directory.
Map<String, String> generateFiles(String toolDir) {
  String read(String name) =>
      File('$toolDir/source/$name').readAsStringSync().replaceAll('\r', '');
  final svg = read('mascot.svg');
  final base = jsonDecode(read('mascot.spec.json')) as Map<String, dynamic>;
  final extra = jsonDecode(read('guardian_states.spec.json')) as Map<String, dynamic>;
  final sleep = jsonDecode(read('idle_sleep.spec.json')) as Map<String, dynamic>;

  final parts = <String, dynamic>{
    ...(base['parts'] as Map<String, dynamic>),
    ...(extra['parts'] as Map<String, dynamic>),
    ...(sleep['parts'] as Map<String, dynamic>),
  };
  final states = <String, dynamic>{
    ...(base['states'] as Map<String, dynamic>),
    ...(extra['states'] as Map<String, dynamic>),
  };
  // Intentional deviations from the Node spec: replace a base state, keeping its position.
  for (final entry in (sleep['overrides'] as Map<String, dynamic>).entries) {
    if (!(base['states'] as Map<String, dynamic>).containsKey(entry.key)) {
      throw FormatException('Override "${entry.key}" does not replace a base state');
    }
    states[entry.key] = entry.value;
  }
  final rigExtras = <String, dynamic>{
    'rigExtras': [
      ...(extra['rigExtras'] as List<dynamic>),
      ...(sleep['rigExtras'] as List<dynamic>),
    ],
  };
  final initialState = base['initialState'] as String;
  return {
    rigFileName: _rigDart(svg, rigExtras, parts.keys.toSet()),
    specFileName: _specDart(initialState, parts, states),
  };
}

// ---------------------------------------------------------------------------------------------
// Path data
// ---------------------------------------------------------------------------------------------

const int _opMove = 0;
const int _opLine = 1;
const int _opCubic = 2;
const int _opQuad = 3;
const int _opClose = 4;

final RegExp _pathToken = RegExp(
  r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?',
);

/// Minimal SVG path parser: absolute and relative M L H V C S Q T Z. Arcs are not supported.
List<num> parsePathData(String d) {
  final tokens = [for (final m in _pathToken.allMatches(d)) m[0]!];
  final ops = <num>[];
  var i = 0;
  var cmd = '';
  var cx = 0.0, cy = 0.0, startX = 0.0, startY = 0.0;
  var ctrlX = 0.0, ctrlY = 0.0;
  var prev = '';

  bool isCommand(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  double number() {
    if (i >= tokens.length || isCommand(tokens[i])) {
      throw FormatException('Path data ended inside a command: $d');
    }
    return double.parse(tokens[i++]);
  }

  while (i < tokens.length) {
    if (isCommand(tokens[i])) {
      cmd = tokens[i++];
    } else if (cmd.isEmpty || cmd == 'z' || cmd == 'Z') {
      throw FormatException('Unexpected number in path data: $d');
    }
    final rel = cmd == cmd.toLowerCase();
    final ox = rel ? cx : 0.0;
    final oy = rel ? cy : 0.0;
    switch (cmd.toUpperCase()) {
      case 'M':
        cx = number() + ox;
        cy = number() + oy;
        startX = cx;
        startY = cy;
        ops.addAll([_opMove, cx, cy]);
        cmd = rel ? 'l' : 'L';
      case 'L':
        cx = number() + ox;
        cy = number() + oy;
        ops.addAll([_opLine, cx, cy]);
      case 'H':
        cx = number() + ox;
        ops.addAll([_opLine, cx, cy]);
      case 'V':
        cy = number() + oy;
        ops.addAll([_opLine, cx, cy]);
      case 'C':
        final x1 = number() + ox, y1 = number() + oy;
        final x2 = number() + ox, y2 = number() + oy;
        final x = number() + ox, y = number() + oy;
        ops.addAll([_opCubic, x1, y1, x2, y2, x, y]);
        ctrlX = x2;
        ctrlY = y2;
        cx = x;
        cy = y;
      case 'S':
        final smooth = 'CS'.contains(prev.toUpperCase()) && prev.isNotEmpty;
        final x1 = smooth ? 2 * cx - ctrlX : cx;
        final y1 = smooth ? 2 * cy - ctrlY : cy;
        final x2 = number() + ox, y2 = number() + oy;
        final x = number() + ox, y = number() + oy;
        ops.addAll([_opCubic, x1, y1, x2, y2, x, y]);
        ctrlX = x2;
        ctrlY = y2;
        cx = x;
        cy = y;
      case 'Q':
        final x1 = number() + ox, y1 = number() + oy;
        final x = number() + ox, y = number() + oy;
        ops.addAll([_opQuad, x1, y1, x, y]);
        ctrlX = x1;
        ctrlY = y1;
        cx = x;
        cy = y;
      case 'T':
        final smooth = 'QT'.contains(prev.toUpperCase()) && prev.isNotEmpty;
        final x1 = smooth ? 2 * cx - ctrlX : cx;
        final y1 = smooth ? 2 * cy - ctrlY : cy;
        final x = number() + ox, y = number() + oy;
        ops.addAll([_opQuad, x1, y1, x, y]);
        ctrlX = x1;
        ctrlY = y1;
        cx = x;
        cy = y;
      case 'Z':
        ops.add(_opClose);
        cx = startX;
        cy = startY;
      default:
        throw UnsupportedError('Path command "$cmd" is not supported: $d');
    }
    prev = cmd;
  }
  return ops;
}

/// Exact bounds (curve extrema included, stroke excluded) as [left, top, right, bottom].
List<double> pathBounds(List<num> ops) {
  var minX = double.infinity, minY = double.infinity;
  var maxX = -double.infinity, maxY = -double.infinity;
  void add(double x, double y) {
    minX = math.min(minX, x);
    maxX = math.max(maxX, x);
    minY = math.min(minY, y);
    maxY = math.max(maxY, y);
  }

  // Roots in (0, 1) of the derivative of a cubic Bezier along one axis.
  List<double> cubicRoots(double p0, double p1, double p2, double p3) {
    final a = -p0 + 3 * p1 - 3 * p2 + p3;
    final b = 2 * (p0 - 2 * p1 + p2);
    final c = p1 - p0;
    final roots = <double>[];
    if (a.abs() < 1e-12) {
      if (b.abs() > 1e-12) roots.add(-c / b);
    } else {
      final disc = b * b - 4 * a * c;
      if (disc >= 0) {
        final sq = math.sqrt(disc);
        roots
          ..add((-b + sq) / (2 * a))
          ..add((-b - sq) / (2 * a));
      }
    }
    return [for (final t in roots) if (t > 0 && t < 1) t];
  }

  double cubicAt(double t, double p0, double p1, double p2, double p3) {
    final u = 1 - t;
    return u * u * u * p0 + 3 * u * u * t * p1 + 3 * u * t * t * p2 + t * t * t * p3;
  }

  double quadAt(double t, double p0, double p1, double p2) {
    final u = 1 - t;
    return u * u * p0 + 2 * u * t * p1 + t * t * p2;
  }

  var i = 0;
  var cx = 0.0, cy = 0.0, startX = 0.0, startY = 0.0;
  while (i < ops.length) {
    final op = ops[i].toInt();
    switch (op) {
      case _opMove:
        cx = ops[i + 1].toDouble();
        cy = ops[i + 2].toDouble();
        startX = cx;
        startY = cy;
        add(cx, cy);
        i += 3;
      case _opLine:
        cx = ops[i + 1].toDouble();
        cy = ops[i + 2].toDouble();
        add(cx, cy);
        i += 3;
      case _opCubic:
        final v = [for (var k = 1; k <= 6; k++) ops[i + k].toDouble()];
        for (final t in cubicRoots(cx, v[0], v[2], v[4])) {
          add(cubicAt(t, cx, v[0], v[2], v[4]), cubicAt(t, cy, v[1], v[3], v[5]));
        }
        for (final t in cubicRoots(cy, v[1], v[3], v[5])) {
          add(cubicAt(t, cx, v[0], v[2], v[4]), cubicAt(t, cy, v[1], v[3], v[5]));
        }
        cx = v[4];
        cy = v[5];
        add(cx, cy);
        i += 7;
      case _opQuad:
        final v = [for (var k = 1; k <= 4; k++) ops[i + k].toDouble()];
        for (final axis in [0, 1]) {
          final p0 = axis == 0 ? cx : cy;
          final denom = p0 - 2 * v[axis] + v[axis + 2];
          if (denom.abs() > 1e-12) {
            final t = (p0 - v[axis]) / denom;
            if (t > 0 && t < 1) {
              add(quadAt(t, cx, v[0], v[2]), quadAt(t, cy, v[1], v[3]));
            }
          }
        }
        cx = v[2];
        cy = v[3];
        add(cx, cy);
        i += 5;
      case _opClose:
        cx = startX;
        cy = startY;
        i += 1;
      default:
        throw StateError('Unknown op $op');
    }
  }
  return [minX, minY, maxX, maxY];
}

// ---------------------------------------------------------------------------------------------
// Rig (SVG -> RigNode tree)
// ---------------------------------------------------------------------------------------------

class _Style {
  _Style(this.props);
  final Map<String, String> props;
}

class _Element {
  _Element({
    required this.shape,
    required this.bounds,
    this.fill,
    this.stroke,
    this.strokeWidth = 0,
    this.dash,
    this.clipId,
    this.maskId,
    this.drawProgress = false,
  });

  final String shape; // Dart expression
  final List<double> bounds;
  final String? fill;
  final String? stroke;
  final double strokeWidth;
  final List<double>? dash;
  final String? clipId;
  final String? maskId;
  final bool drawProgress;
}

class _Node {
  _Node({this.part, this.children, this.element, required this.bounds});
  final String? part;
  final List<_Node>? children;
  final _Element? element;
  final List<double> bounds;
}

class _PathPool {
  final Map<String, String> _names = {};
  final List<MapEntry<String, List<num>>> entries = [];

  /// Returns the constant name for [ops], registering it on first use.
  String name(List<num> ops) {
    final key = ops.join(',');
    return _names.putIfAbsent(key, () {
      final id = '_path${entries.length}';
      entries.add(MapEntry(id, ops));
      return id;
    });
  }
}

final RegExp _tag = RegExp(r'<\s*(/?)\s*([A-Za-z]+)((?:\s+[\w:-]+\s*=\s*"[^"]*")*)\s*(/?)>');
final RegExp _attr = RegExp(r'([\w:-]+)\s*=\s*"([^"]*)"');

Map<String, String> _attrs(String raw) => {
      for (final m in _attr.allMatches(raw)) m[1]!: m[2]!,
    };

String? _color(String? value) {
  if (value == null || value == 'none') return null;
  if (value.contains('--mascot-body')) return 'RigColor.body';
  if (value.contains('--mascot-line')) return 'RigColor.line';
  throw FormatException('Unsupported colour "$value"; use the mascot variables');
}

String _rigDart(String svg, Map<String, dynamic> extra, Set<String> specParts) {
  final pool = _PathPool();

  // Style rules: `.name{prop:value;...}`.
  final styles = <String, _Style>{};
  for (final m in RegExp(r'\.([\w-]+)\{([^}]*)\}').allMatches(svg)) {
    final props = <String, String>{};
    for (final decl in m[2]!.split(';')) {
      final idx = decl.indexOf(':');
      if (idx > 0) props[decl.substring(0, idx).trim()] = decl.substring(idx + 1).trim();
    }
    styles[m[1]!] = _Style(props);
  }

  // Clip paths and the outline mask.
  final clips = <String, String>{};
  for (final m in RegExp(r'<clipPath id="([^"]+)">\s*<path([^>]*)/>').allMatches(svg)) {
    final a = _attrs(m[2]!);
    final evenOdd = a['clip-rule'] == 'evenodd';
    clips[m[1]!] = 'RigClip(${pool.name(parsePathData(a['d']!))}, evenOdd: $evenOdd)';
  }
  final masks = <String, String>{};
  for (final m in RegExp(r'<mask id="([^"]+)"[^>]*>(.*?)</mask>', dotAll: true).allMatches(svg)) {
    final stroke = RegExp(r'<path([^>]*)/>').firstMatch(m[2]!);
    if (stroke == null) throw FormatException('Mask ${m[1]} has no stroke path');
    final a = _attrs(stroke[1]!);
    masks[m[1]!] =
        'RigKnockout(${pool.name(parsePathData(a['d']!))}, ${_n(double.parse(a['stroke-width']!))})';
  }

  String? idOf(String? ref) => ref == null ? null : RegExp(r'#([^)]+)').firstMatch(ref)![1];

  // Visible tree after </defs>.
  final body = svg.substring(svg.indexOf('</defs>') + '</defs>'.length);
  final roots = <_Node>[];
  final stack = <(String?, List<_Node>)>[];
  List<_Node> current() => stack.isEmpty ? roots : stack.last.$2;

  for (final m in _tag.allMatches(body)) {
    final closing = m[1] == '/';
    final name = m[2]!;
    final selfClosing = m[4] == '/';
    final a = _attrs(m[3] ?? '');
    final part = a['data-part'];
    final owned = part != null && specParts.contains(part) ? part : null;
    if (name == 'g') {
      if (closing) {
        final (groupPart, kids) = stack.removeLast();
        current().add(_Node(part: groupPart, children: kids, bounds: _union(kids)));
      } else {
        stack.add((owned, <_Node>[]));
      }
      continue;
    }
    if (closing || (name != 'path' && name != 'circle')) continue;
    if (!selfClosing) throw FormatException('<$name> must be self-closing');

    final style = styles[a['class'] ?? '']?.props ?? const <String, String>{};
    String? prop(String key) => a[key] ?? style[key];
    final fill = _color(prop('fill'));
    final stroke = _color(prop('stroke'));
    final width = double.tryParse(prop('stroke-width') ?? '') ?? 0;
    final dash = a['stroke-dasharray']?.split(RegExp(r'[ ,]+')).map(double.parse).toList();
    if (dash != null && dash.length != 2) {
      throw const FormatException('Only "on off" dash arrays are supported');
    }
    String shape;
    List<double> bounds;
    if (name == 'circle') {
      final cx = double.parse(a['cx']!), cy = double.parse(a['cy']!), r = double.parse(a['r']!);
      shape = 'RigCircleShape(${_n(cx)}, ${_n(cy)}, ${_n(r)})';
      bounds = [cx - r, cy - r, cx + r, cy + r];
    } else {
      final ops = parsePathData(a['d']!);
      shape = 'RigPathShape(${pool.name(ops)})';
      bounds = pathBounds(ops);
    }
    current().add(_Node(
      part: owned,
      bounds: bounds,
      element: _Element(
        shape: shape,
        bounds: bounds,
        fill: fill,
        stroke: stroke,
        strokeWidth: stroke == null ? 0 : width,
        dash: dash,
        clipId: idOf(a['clip-path']),
        maskId: idOf(a['mask']),
        drawProgress: a.containsKey('pathLength'),
      ),
    ));
  }
  if (stack.isNotEmpty) throw const FormatException('Unbalanced <g> in the SVG');

  // Extra shapes of the added states: behind the owl or in front of everything.
  final back = <_Node>[];
  final front = <_Node>[];
  for (final item in extra['rigExtras'] as List<dynamic>) {
    final spec = item as Map<String, dynamic>;
    final kids = <_Node>[];
    for (final raw in spec['elements'] as List<dynamic>) {
      final e = raw as Map<String, dynamic>;
      String shape;
      List<double> bounds;
      if (e.containsKey('circle')) {
        final c = [for (final v in e['circle'] as List<dynamic>) (v as num).toDouble()];
        shape = 'RigCircleShape(${_n(c[0])}, ${_n(c[1])}, ${_n(c[2])})';
        bounds = [c[0] - c[2], c[1] - c[2], c[0] + c[2], c[1] + c[2]];
      } else {
        final ops = parsePathData(e['path'] as String);
        shape = 'RigPathShape(${pool.name(ops)})';
        bounds = pathBounds(ops);
      }
      kids.add(_Node(
        bounds: bounds,
        element: _Element(
          shape: shape,
          bounds: bounds,
          fill: e['fill'] == null ? null : 'RigColor.${e['fill']}',
          stroke: e['stroke'] == null ? null : 'RigColor.${e['stroke']}',
          strokeWidth: (e['strokeWidth'] as num? ?? 0).toDouble(),
          dash: (e['dash'] as List<dynamic>?)?.map((v) => (v as num).toDouble()).toList(),
        ),
      ));
    }
    final node = _Node(part: spec['part'] as String, children: kids, bounds: _union(kids));
    ((spec['layer'] as String) == 'back' ? back : front).add(node);
  }
  final nodes = [...back, ...roots, ...front];

  final out = StringBuffer()
    ..writeln('// GENERATED by tool/guardian_mascot/generate.dart. Do not edit by hand.')
    ..writeln('// Sources: tool/guardian_mascot/source/ (mascot.svg, mascot.spec.json,')
    ..writeln('// guardian_states.spec.json). Run `dart run tool/guardian_mascot/generate.dart`.')
    ..writeln()
    ..writeln("import '../mascot_rig.dart';")
    ..writeln();
  for (final e in pool.entries) {
    out.writeln('const ${e.key} = RigPath([${e.value.map(_numOrOp).join(', ')}]);');
  }
  out
    ..writeln()
    ..writeln('const GuardianMascotRig kGuardianMascotRig = GuardianMascotRig(')
    ..writeln('  viewBox: 2000,')
    ..writeln('  nodes: [');
  for (final n in nodes) {
    _writeNode(out, n, 2, clips, masks);
  }
  out
    ..writeln('  ],')
    ..writeln(');');
  return out.toString();
}

List<double> _union(List<_Node> nodes) {
  final b = [for (final n in nodes) n.bounds];
  return [
    b.map((e) => e[0]).reduce(math.min),
    b.map((e) => e[1]).reduce(math.min),
    b.map((e) => e[2]).reduce(math.max),
    b.map((e) => e[3]).reduce(math.max),
  ];
}

String _boundsDart(List<double> b) => 'RigBounds(${b.map(_n).join(', ')})';

void _writeNode(
  StringBuffer out,
  _Node node,
  int depth,
  Map<String, String> clips,
  Map<String, String> masks,
) {
  final pad = '  ' * (depth + 1);
  final partArgs = node.part == null
      ? ''
      : "part: '${node.part}', bounds: ${_boundsDart(node.bounds)}";
  final e = node.element;
  if (e == null) {
    out.writeln('$pad${'RigNode.group('}$partArgs${partArgs.isEmpty ? '' : ', '}children: [');
    for (final c in node.children!) {
      _writeNode(out, c, depth + 1, clips, masks);
    }
    out.writeln('$pad]),');
    return;
  }
  final args = <String>[
    'shape: ${e.shape}',
    if (e.fill != null) 'fill: ${e.fill}',
    if (e.stroke != null) 'stroke: ${e.stroke}',
    if (e.strokeWidth != 0) 'strokeWidth: ${_n(e.strokeWidth)}',
    if (e.dash != null) 'dash: [${e.dash!.map(_n).join(', ')}]',
    if (e.clipId != null) 'clip: ${clips[e.clipId] ?? (throw FormatException('No clip ${e.clipId}'))}',
    if (e.maskId != null) 'knockout: ${masks[e.maskId] ?? (throw FormatException('No mask ${e.maskId}'))}',
    if (e.drawProgress) 'drawProgress: true',
  ];
  out.writeln(
    '${pad}RigNode.leaf(RigElement(${args.join(', ')})${partArgs.isEmpty ? '' : ', $partArgs'}),',
  );
}

String _numOrOp(num v) => v is int ? '$v' : _n(v.toDouble());

/// Doubles always print with a decimal point so the output is valid, stable Dart.
String _n(double v) {
  if (v == v.roundToDouble() && v.abs() < 1e15) return '${v.toInt()}.0';
  return v.toString();
}

// ---------------------------------------------------------------------------------------------
// Spec (JSON -> const MascotSpec)
// ---------------------------------------------------------------------------------------------

String _specDart(String initialState, Map<String, dynamic> parts, Map<String, dynamic> states) {
  final out = StringBuffer()
    ..writeln('// GENERATED by tool/guardian_mascot/generate.dart. Do not edit by hand.')
    ..writeln('// Sources: tool/guardian_mascot/source/mascot.spec.json (thinking, working, success:')
    ..writeln('// values copied verbatim; idle is replaced by idle_sleep.spec.json on purpose) and')
    ..writeln('// guardian_states.spec.json (listening, scanning, alert, stealth).')
    ..writeln('// Run `dart run tool/guardian_mascot/generate.dart`.')
    ..writeln()
    ..writeln("import '../mascot_spec.dart';")
    ..writeln()
    ..writeln('const MascotSpec kGuardianMascotSpec = MascotSpec(')
    ..writeln("  initialState: '$initialState',")
    ..writeln('  parts: {');
  for (final e in parts.entries) {
    final p = e.value as Map<String, dynamic>;
    final args = <String>[
      if (p['origin'] != null) 'origin: ${_list(p['origin'] as List<dynamic>)}',
      if (p['rest'] != null) 'rest: ${_map(p['rest'] as Map<String, dynamic>)}',
    ];
    out.writeln("    '${e.key}': MascotPartSpec(${args.join(', ')}),");
  }
  out
    ..writeln('  },')
    ..writeln('  states: {');
  for (final e in states.entries) {
    final s = e.value as Map<String, dynamic>;
    out.writeln("    '${e.key}': MascotStateSpec(");
    out.writeln('      loop: ${s['loop']},');
    if (s['next'] != null) out.writeln("      next: '${s['next']}',");
    if (s['hold'] == true) out.writeln('      hold: true,');
    out.writeln('      pose: ${_n((s['pose'] as num).toDouble())},');
    if (s['reducedHoldMs'] != null) {
      out.writeln('      reducedHoldMs: ${_n((s['reducedHoldMs'] as num).toDouble())},');
    }
    if (s['blendMs'] != null) out.writeln('      blendMs: ${_n((s['blendMs'] as num).toDouble())},');
    if (s['exitBlendMs'] != null) {
      out.writeln('      exitBlendMs: ${_n((s['exitBlendMs'] as num).toDouble())},');
    }
    out.writeln('      tracks: [');
    for (final t in s['tracks'] as List<dynamic>) {
      final track = t as Map<String, dynamic>;
      out.writeln("        MascotTrack('${track['part']}', ${_n((track['duration'] as num).toDouble())}, [");
      for (final k in track['keyframes'] as List<dynamic>) {
        final kf = k as Map<String, dynamic>;
        final values = {
          for (final v in kf.entries)
            if (v.key != 'offset' && v.key != 'ease') v.key: v.value,
        };
        final args = <String>[
          _n((kf['offset'] as num).toDouble()),
          if (kf['ease'] != null) "ease: '${kf['ease']}'",
          if (values.isNotEmpty) 'values: ${_map(values)}',
        ];
        out.writeln('          MascotKeyframe(${args.join(', ')}),');
      }
      out.writeln(
        track['easing'] == null ? '        ]),' : "        ], easing: '${track['easing']}'),",
      );
    }
    out.writeln('      ],');
    out.writeln('    ),');
  }
  out
    ..writeln('  },')
    ..writeln(');');
  return out.toString();
}

String _list(List<dynamic> v) => '[${v.map((e) => _n((e as num).toDouble())).join(', ')}]';

String _map(Map<String, dynamic> m) =>
    '{${m.entries.map((e) => "'${e.key}': ${_n((e.value as num).toDouble())}").join(', ')}}';
