import 'package:flutter/widgets.dart';

/// Raw design tokens transcribed from the front matter of `DESIGN.md`.
///
/// This is the only place (with `app_theme.dart`) where literal colors,
/// sizes and durations may appear. Widgets read everything through the theme.

/// A foreground/background pair for one risk or voice state.
class RiskColorPair {
  const RiskColorPair({required this.foreground, required this.background});

  final Color foreground;
  final Color background;
}

/// Every color role of one brightness.
class QhawixPalette {
  const QhawixPalette({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.pressedPrimary,
    required this.secondary,
    required this.mist,
    required this.canvas,
    required this.surface,
    required this.surfaceSunken,
    required this.onSurface,
    required this.onSurfaceStrong,
    required this.onSurfaceMuted,
    required this.borderStrong,
    required this.accent,
    required this.accentTint,
    required this.accentDeep,
    required this.error,
    required this.errorTint,
    required this.onError,
    required this.notAssessed,
    required this.noneDetected,
    required this.caution,
    required this.high,
    required this.abstain,
  });

  final Brightness brightness;

  /// Ink: filled primary button and strongest text.
  final Color primary;
  final Color onPrimary;

  /// Fill of the primary button while pressed.
  final Color pressedPrimary;

  /// Body-text slate (light) and secondary actions.
  final Color secondary;

  /// Decorative dividers and card borders (`tertiary` / `border`).
  final Color mist;
  final Color canvas;
  final Color surface;
  final Color surfaceSunken;
  final Color onSurface;
  final Color onSurfaceStrong;
  final Color onSurfaceMuted;

  /// Edge of any control (inputs, secondary button).
  final Color borderStrong;
  final Color accent;
  final Color accentTint;
  final Color accentDeep;
  final Color error;
  final Color errorTint;
  final Color onError;
  final RiskColorPair notAssessed;
  final RiskColorPair noneDetected;
  final RiskColorPair caution;
  final RiskColorPair high;
  final RiskColorPair abstain;

  static const light = QhawixPalette(
    brightness: Brightness.light,
    primary: Color(0xFF11141A),
    onPrimary: Color(0xFFFBF9FC),
    pressedPrimary: Color(0xFF444A58),
    secondary: Color(0xFF444A58),
    mist: Color(0xFFE5E7EB),
    canvas: Color(0xFFFBF9FC),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFF3F1F5),
    onSurface: Color(0xFF444A58),
    onSurfaceStrong: Color(0xFF11141A),
    onSurfaceMuted: Color(0xFF5B6170),
    borderStrong: Color(0xFF7C8190),
    accent: Color(0xFF0B5D6B),
    accentTint: Color(0xFFE3F0F2),
    accentDeep: Color(0xFF084550),
    error: Color(0xFFB42318),
    errorTint: Color(0xFFFDEAE7),
    onError: Color(0xFFFFFFFF),
    notAssessed: RiskColorPair(
      foreground: Color(0xFF4B5160),
      background: Color(0xFFECEEF1),
    ),
    noneDetected: RiskColorPair(
      foreground: Color(0xFF2F4A6B),
      background: Color(0xFFE8EEF6),
    ),
    caution: RiskColorPair(
      foreground: Color(0xFF7A4A00),
      background: Color(0xFFFFF1D6),
    ),
    high: RiskColorPair(
      foreground: Color(0xFF8F1D14),
      background: Color(0xFFFDE8E5),
    ),
    abstain: RiskColorPair(
      foreground: Color(0xFF4F4A7A),
      background: Color(0xFFEEECF7),
    ),
  );

  /// Dark values. Roles the spec does not define for dark are derived and
  /// listed in the contrast test: `secondary` reuses `dark-on-surface`,
  /// `pressedPrimary` reuses `dark-on-surface-muted`, `surfaceSunken` reuses
  /// `dark-surface-raised`, `mist` reuses `dark-border`, `errorTint` reuses the
  /// high-risk fill, `onError` reuses the canvas, and `accentTint` is a new
  /// deep teal with `accentDeep` set to `dark-accent`.
  static const dark = QhawixPalette(
    brightness: Brightness.dark,
    primary: Color(0xFFF2F3F7),
    onPrimary: Color(0xFF0F1115),
    pressedPrimary: Color(0xFFA9AFBD),
    secondary: Color(0xFFE6E8EE),
    mist: Color(0xFF2A2F3A),
    canvas: Color(0xFF0F1115),
    surface: Color(0xFF171A21),
    surfaceSunken: Color(0xFF1E222B),
    onSurface: Color(0xFFE6E8EE),
    onSurfaceStrong: Color(0xFFF2F3F7),
    onSurfaceMuted: Color(0xFFA9AFBD),
    borderStrong: Color(0xFF8B91A0),
    accent: Color(0xFF6CC3D0),
    accentTint: Color(0xFF12343A),
    accentDeep: Color(0xFF6CC3D0),
    error: Color(0xFFFFB4AB),
    errorTint: Color(0xFF46201C),
    onError: Color(0xFF0F1115),
    notAssessed: RiskColorPair(
      foreground: Color(0xFFC4C9D4),
      background: Color(0xFF262A33),
    ),
    noneDetected: RiskColorPair(
      foreground: Color(0xFFB8CCE8),
      background: Color(0xFF1E2B3F),
    ),
    caution: RiskColorPair(
      foreground: Color(0xFFF2C879),
      background: Color(0xFF3A2C12),
    ),
    high: RiskColorPair(
      foreground: Color(0xFFFFB4AB),
      background: Color(0xFF46201C),
    ),
    abstain: RiskColorPair(
      foreground: Color(0xFFCCC6F2),
      background: Color(0xFF2C2A45),
    ),
  );
}

/// Font families bundled under `assets/fonts/`.
abstract final class QhawixFonts {
  static const display = 'DM Sans';
  static const reading = 'Inter';
  static const fallback = ['Roboto', 'sans-serif'];
}

/// One entry of the typography scale. Sizes are logical pixels (dp).
class TypeToken {
  const TypeToken({
    required this.family,
    required this.size,
    required this.weight,
    required this.lineHeight,
    this.letterSpacingEm = 0,
  });

  final String family;
  final double size;
  final FontWeight weight;
  final double lineHeight;
  final double letterSpacingEm;
}

abstract final class QhawixType {
  static const headlineDisplay = TypeToken(
    family: QhawixFonts.display,
    size: 36,
    weight: FontWeight.w700,
    lineHeight: 1.1,
    letterSpacingEm: -0.02,
  );
  static const headlineLg = TypeToken(
    family: QhawixFonts.display,
    size: 28,
    weight: FontWeight.w700,
    lineHeight: 1.2,
  );
  static const headlineMd = TypeToken(
    family: QhawixFonts.display,
    size: 22,
    weight: FontWeight.w700,
    lineHeight: 1.25,
  );
  static const headlineSm = TypeToken(
    family: QhawixFonts.display,
    size: 18,
    weight: FontWeight.w700,
    lineHeight: 1.3,
  );
  static const bodyLg = TypeToken(
    family: QhawixFonts.reading,
    size: 18,
    weight: FontWeight.w400,
    lineHeight: 1.5,
  );
  static const bodyMd = TypeToken(
    family: QhawixFonts.reading,
    size: 16,
    weight: FontWeight.w400,
    lineHeight: 1.5,
  );
  static const bodySm = TypeToken(
    family: QhawixFonts.reading,
    size: 14,
    weight: FontWeight.w400,
    lineHeight: 1.45,
  );
  static const bodyEmphasis = TypeToken(
    family: QhawixFonts.reading,
    size: 16,
    weight: FontWeight.w500,
    lineHeight: 1.5,
  );
  static const labelLg = TypeToken(
    family: QhawixFonts.display,
    size: 16,
    weight: FontWeight.w500,
    lineHeight: 1.25,
  );
  static const labelMd = TypeToken(
    family: QhawixFonts.display,
    size: 14,
    weight: FontWeight.w500,
    lineHeight: 1.25,
  );
  static const labelSm = TypeToken(
    family: QhawixFonts.display,
    size: 13,
    weight: FontWeight.w500,
    lineHeight: 1.25,
  );
}

/// Corner radii (`rounded` in the front matter).
abstract final class QhawixRadii {
  static const none = 0.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 28.0;
  static const full = 9999.0;
}

/// Spacing grid and fixed component sizes (`spacing` in the front matter).
abstract final class QhawixDimensions {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const gutter = 20.0;
  static const touchMin = 48.0;
  static const section = 32.0;

  static const iconSm = 16.0;
  static const iconMd = 24.0;
  static const iconXl = 48.0;
  static const progressSm = 20.0;
  static const voiceGlyph = 40.0;
  static const bottomNavHeight = 80.0;
  static const appBarHeight = 56.0;
  static const rowHeight = 56.0;
  static const inputHeight = 56.0;
  static const multilineHeight = 160.0;
  static const moduleCardHeight = 96.0;
  static const fab = 56.0;
  static const dragHandleWidth = 32.0;
  static const dragHandleHeight = 4.0;
  static const hairline = 1.0;
  static const focusRing = 2.0;
  static const maxContentWidth = 560.0;
  static const compactBreakpoint = 600.0;
  static const expandedBreakpoint = 840.0;
  static const multilineMaxLines = 8;
}

/// Motion durations and opacity constants.
abstract final class QhawixMotionTokens {
  static const press = Duration(milliseconds: 100);
  static const standard = Duration(milliseconds: 200);
  static const emphasized = Duration(milliseconds: 300);
  static const skeleton = Duration(milliseconds: 1400);
  static const loadingTimeout = Duration(seconds: 8);

  static const pressCurve = Curves.linear;
  static const standardCurve = Curves.easeOutCubic;
  static const emphasizedIn = Curves.easeOutCubic;
  static const emphasizedOut = Curves.easeInCubic;
  static const skeletonCurve = Curves.easeInOut;

  /// Ink at 40% behind sheets and dialogs.
  static const scrimOpacity = 0.4;

  /// Foreground-colored outline of a risk badge.
  static const riskOutlineOpacity = 0.4;
}
