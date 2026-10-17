import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/core/theme/tokens.dart';

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

/// WCAG 2.x contrast ratio, recomputed here independently of Flutter.
double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

class _Pair {
  const _Pair(this.name, this.fg, this.bg, this.min, [this.documented]);

  final String name;
  final Color fg;
  final Color bg;

  /// 4.5 for text, 3 for large text, icons and control edges.
  final double min;

  /// Ratio printed in the DESIGN.md contrast table, when the pair is listed.
  final double? documented;
}

const _text = 4.5;
const _graphic = 3.0;

final _l = QhawixPalette.light;
final _d = QhawixPalette.dark;

final _pairs = <_Pair>[
  // Light, documented in DESIGN.md.
  _Pair('L ink on canvas', _l.onSurfaceStrong, _l.canvas, _text, 17.61),
  _Pair('L canvas on ink (primary btn)', _l.onPrimary, _l.primary, _text, 17.61),
  _Pair('L slate on canvas', _l.onSurface, _l.canvas, _text, 8.48),
  _Pair('L slate on surface', _l.onSurface, _l.surface, _text, 8.87),
  _Pair('L muted on canvas', _l.onSurfaceMuted, _l.canvas, _text, 5.92),
  _Pair('L muted on sunken', _l.onSurfaceMuted, _l.surfaceSunken, _text, 5.52),
  _Pair('L ink on sunken', _l.onSurfaceStrong, _l.surfaceSunken, _text, 16.43),
  _Pair('L accent on canvas', _l.accent, _l.canvas, _text, 7.18),
  _Pair('L accent on surface', _l.accent, _l.surface, _text, 7.52),
  _Pair('L accent focus ring vs canvas', _l.accent, _l.canvas, _graphic, 7.18),
  _Pair('L input border vs surface', _l.borderStrong, _l.surface, _graphic, 3.89),
  _Pair('L input border vs canvas', _l.borderStrong, _l.canvas, _graphic, 3.71),
  _Pair('L accentDeep on accentTint', _l.accentDeep, _l.accentTint, _text, 9.11),
  _Pair('L error on canvas', _l.error, _l.canvas, _text, 6.28),
  _Pair('L error on errorTint', _l.error, _l.errorTint, _text, 5.67),
  _Pair('L white on error (destructive btn)', _l.onError, _l.error, _text, 6.57),
  _Pair('L risk notAssessed fg/bg', _l.notAssessed.foreground, _l.notAssessed.background, _text, 6.83),
  _Pair('L risk noneDetected fg/bg', _l.noneDetected.foreground, _l.noneDetected.background, _text, 7.78),
  _Pair('L risk caution fg/bg', _l.caution.foreground, _l.caution.background, _text, 6.70),
  _Pair('L risk high fg/bg', _l.high.foreground, _l.high.background, _text, 7.58),
  _Pair('L risk abstain fg/bg', _l.abstain.foreground, _l.abstain.background, _text, 6.93),
  _Pair('L pressed primary', _l.onPrimary, _l.pressedPrimary, _text, 8.48),
  _Pair('L chip text on mist', _l.onSurfaceStrong, _l.mist, _text, 14.89),
  _Pair('L bottom-nav muted on surface', _l.onSurfaceMuted, _l.surface, _text, 6.20),
  _Pair('L mascot body vs canvas', _l.accent, _l.canvas, _graphic, 7.18),
  _Pair('L mascot lines on body', _l.surface, _l.accent, _graphic, 7.52),
  // Dark, documented in DESIGN.md.
  _Pair('D text on canvas', _d.onSurface, _d.canvas, _text, 15.42),
  _Pair('D text on surface', _d.onSurface, _d.surface, _text, 14.21),
  _Pair('D muted on canvas', _d.onSurfaceMuted, _d.canvas, _text, 8.60),
  _Pair('D muted on surface', _d.onSurfaceMuted, _d.surface, _text, 7.92),
  _Pair('D muted on raised', _d.onSurfaceMuted, _d.surfaceSunken, _text, 7.24),
  _Pair('D canvas on ink (primary btn)', _d.onPrimary, _d.primary, _text, 17.04),
  _Pair('D accent on canvas', _d.accent, _d.canvas, _text, 9.32),
  _Pair('D accent on surface', _d.accent, _d.surface, _text, 8.58),
  _Pair('D error on canvas', _d.error, _d.canvas, _text, 11.13),
  _Pair('D border vs surface', _d.borderStrong, _d.surface, _graphic, 5.52),
  _Pair('D risk notAssessed fg/bg', _d.notAssessed.foreground, _d.notAssessed.background, _text, 8.66),
  _Pair('D risk notAssessed fg on surface', _d.notAssessed.foreground, _d.surface, _text, 10.49),
  _Pair('D risk noneDetected fg/bg', _d.noneDetected.foreground, _d.noneDetected.background, _text, 8.72),
  _Pair('D risk noneDetected fg on surface', _d.noneDetected.foreground, _d.surface, _text, 10.65),
  _Pair('D risk caution fg/bg', _d.caution.foreground, _d.caution.background, _text, 8.60),
  _Pair('D risk caution fg on surface', _d.caution.foreground, _d.surface, _text, 11.04),
  _Pair('D risk high fg/bg', _d.high.foreground, _d.high.background, _text, 8.34),
  _Pair('D risk high fg on surface', _d.high.foreground, _d.surface, _text, 10.25),
  _Pair('D risk abstain fg/bg', _d.abstain.foreground, _d.abstain.background, _text, 8.48),
  _Pair('D risk abstain fg on surface', _d.abstain.foreground, _d.surface, _text, 10.72),
  _Pair('D mascot lines on body', _d.canvas, _d.accent, _graphic, 9.32),
  // Not in the DESIGN.md table: light risk foregrounds on cards, and values
  // that the spec leaves undefined for dark and this implementation derives.
  _Pair('L risk notAssessed fg on surface', _l.notAssessed.foreground, _l.surface, _text),
  _Pair('L risk noneDetected fg on surface', _l.noneDetected.foreground, _l.surface, _text),
  _Pair('L risk caution fg on surface', _l.caution.foreground, _l.surface, _text),
  _Pair('L risk high fg on surface', _l.high.foreground, _l.surface, _text),
  _Pair('L risk abstain fg on surface', _l.abstain.foreground, _l.surface, _text),
  _Pair('L muted on mist (disabled chip text)', _l.onSurfaceMuted, _l.mist, _text),
  _Pair('L input border vs sunken', _l.borderStrong, _l.surfaceSunken, _graphic),
  _Pair('L snackbar action (dark accent) on ink', _d.accent, _l.primary, _text),
  _Pair('L snackbar text on ink', _l.onPrimary, _l.primary, _text),
  _Pair('D accentDeep on accentTint (derived)', _d.accentDeep, _d.accentTint, _text),
  _Pair('D accent on accentTint (derived)', _d.accent, _d.accentTint, _text),
  _Pair('D muted on accentTint (nav unselected)', _d.onSurfaceMuted, _d.accentTint, _text),
  _Pair('D ink on raised (derived sunken)', _d.onSurfaceStrong, _d.surfaceSunken, _text),
  _Pair('D onError on error (derived)', _d.onError, _d.error, _text),
  _Pair('D error on errorTint (derived)', _d.error, _d.errorTint, _text),
  _Pair('D pressed primary (derived)', _d.onPrimary, _d.pressedPrimary, _text),
  _Pair('D ink on mist (derived chip)', _d.onSurfaceStrong, _d.mist, _text),
  _Pair('D focus ring accent vs canvas', _d.accent, _d.canvas, _graphic),
  _Pair('D snackbar action (light accent) on ink', _l.accent, _d.primary, _text),
  _Pair('D snackbar text on ink', _d.onPrimary, _d.primary, _text),
];

void main() {
  group('WCAG AA contrast recomputed from the tokens', () {
    for (final pair in _pairs) {
      test(pair.name, () {
        final ratio = contrast(pair.fg, pair.bg);
        expect(
          ratio,
          greaterThanOrEqualTo(pair.min),
          reason: '${pair.name} measures ${ratio.toStringAsFixed(2)}:1, '
              'needs ${pair.min}:1',
        );
        final documented = pair.documented;
        if (documented != null) {
          expect(
            ratio,
            closeTo(documented, 0.011),
            reason: 'DESIGN.md lists ${documented.toStringAsFixed(2)}:1',
          );
        }
      });
    }
  });

  test('the contrast helper matches known WCAG values', () {
    expect(
      contrast(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 1e-9),
    );
    expect(
      contrast(const Color(0xFF777777), const Color(0xFFFFFFFF)),
      closeTo(4.48, 0.01),
    );
  });
}
