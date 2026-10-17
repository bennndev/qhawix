// CSS timing functions used by the mascot spec (`linear`, `ease-in`, `ease-out`,
// `ease-in-out`, `ease`, `cubic-bezier(a, b, c, d)`).

typedef MascotEasing = double Function(double t);

double _linear(double t) => t;

/// Cubic Bezier easing with fixed end points (0,0) and (1,1), solved like browsers do:
/// Newton iterations first, bisection as a fallback.
MascotEasing cubicBezier(double x1, double y1, double x2, double y2) {
  if (x1 == y1 && x2 == y2) return _linear;
  final cx = 3 * x1;
  final bx = 3 * (x2 - x1) - cx;
  final ax = 1 - cx - bx;
  final cy = 3 * y1;
  final by = 3 * (y2 - y1) - cy;
  final ay = 1 - cy - by;

  double sampleX(double t) => ((ax * t + bx) * t + cx) * t;
  double sampleY(double t) => ((ay * t + by) * t + cy) * t;
  double sampleDx(double t) => (3 * ax * t + 2 * bx) * t + cx;

  double solve(double x) {
    var t = x;
    for (var i = 0; i < 8; i++) {
      final err = sampleX(t) - x;
      if (err.abs() < 1e-7) return t;
      final d = sampleDx(t);
      if (d.abs() < 1e-6) break;
      t -= err / d;
    }
    var lo = 0.0;
    var hi = 1.0;
    t = x;
    while (lo < hi) {
      final v = sampleX(t);
      if ((v - x).abs() < 1e-7) return t;
      if (x > v) {
        lo = t;
      } else {
        hi = t;
      }
      final next = (hi - lo) / 2 + lo;
      if (next == t) break;
      t = next;
    }
    return t;
  }

  return (t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    return sampleY(solve(t));
  };
}

final MascotEasing _ease = cubicBezier(0.25, 0.1, 0.25, 1);
final MascotEasing _easeIn = cubicBezier(0.42, 0, 1, 1);
final MascotEasing _easeOut = cubicBezier(0, 0, 0.58, 1);
final MascotEasing _easeInOut = cubicBezier(0.42, 0, 0.58, 1);
final Map<String, MascotEasing> _custom = {};

final RegExp _bezier = RegExp(
  r'^cubic-bezier\(\s*([-\d.]+)\s*,\s*([-\d.]+)\s*,\s*([-\d.]+)\s*,\s*([-\d.]+)\s*\)$',
);

/// Resolves a CSS easing name. Throws [FormatException] for unknown values.
MascotEasing easingFor(String name) {
  switch (name) {
    case 'linear':
      return _linear;
    case 'ease':
      return _ease;
    case 'ease-in':
      return _easeIn;
    case 'ease-out':
      return _easeOut;
    case 'ease-in-out':
      return _easeInOut;
  }
  final cached = _custom[name];
  if (cached != null) return cached;
  final m = _bezier.firstMatch(name);
  if (m == null) throw FormatException('Unknown easing "$name"');
  final v = [for (var i = 1; i <= 4; i++) double.parse(m.group(i)!)];
  return _custom[name] = cubicBezier(v[0], v[1], v[2], v[3]);
}
