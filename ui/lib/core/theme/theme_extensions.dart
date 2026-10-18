import 'package:flutter/material.dart';

import '../domain/risk_level.dart';
import 'tokens.dart';

/// Colors that have no slot in [ColorScheme].
@immutable
class QhawixColors extends ThemeExtension<QhawixColors> {
  const QhawixColors({
    required this.canvas,
    required this.accent,
    required this.accentTint,
    required this.accentDeep,
    required this.onSurfaceStrong,
    required this.onSurfaceMuted,
    required this.borderStrong,
    required this.mist,
    required this.surfaceSunken,
    required this.errorTint,
    required this.scrim,
  });

  factory QhawixColors.fromPalette(QhawixPalette p) => QhawixColors(
    canvas: p.canvas,
    accent: p.accent,
    accentTint: p.accentTint,
    accentDeep: p.accentDeep,
    onSurfaceStrong: p.onSurfaceStrong,
    onSurfaceMuted: p.onSurfaceMuted,
    borderStrong: p.borderStrong,
    mist: p.mist,
    surfaceSunken: p.surfaceSunken,
    errorTint: p.errorTint,
    scrim: p.primary.withValues(alpha: QhawixMotionTokens.scrimOpacity),
  );

  final Color canvas;
  final Color accent;
  final Color accentTint;
  final Color accentDeep;
  final Color onSurfaceStrong;
  final Color onSurfaceMuted;
  final Color borderStrong;
  final Color mist;
  final Color surfaceSunken;
  final Color errorTint;
  final Color scrim;

  @override
  QhawixColors copyWith({
    Color? canvas,
    Color? accent,
    Color? accentTint,
    Color? accentDeep,
    Color? onSurfaceStrong,
    Color? onSurfaceMuted,
    Color? borderStrong,
    Color? mist,
    Color? surfaceSunken,
    Color? errorTint,
    Color? scrim,
  }) => QhawixColors(
    canvas: canvas ?? this.canvas,
    accent: accent ?? this.accent,
    accentTint: accentTint ?? this.accentTint,
    accentDeep: accentDeep ?? this.accentDeep,
    onSurfaceStrong: onSurfaceStrong ?? this.onSurfaceStrong,
    onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
    borderStrong: borderStrong ?? this.borderStrong,
    mist: mist ?? this.mist,
    surfaceSunken: surfaceSunken ?? this.surfaceSunken,
    errorTint: errorTint ?? this.errorTint,
    scrim: scrim ?? this.scrim,
  );

  @override
  QhawixColors lerp(ThemeExtension<QhawixColors>? other, double t) {
    if (other is! QhawixColors) return this;
    return QhawixColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentTint: Color.lerp(accentTint, other.accentTint, t)!,
      accentDeep: Color.lerp(accentDeep, other.accentDeep, t)!,
      onSurfaceStrong: Color.lerp(onSurfaceStrong, other.onSurfaceStrong, t)!,
      onSurfaceMuted: Color.lerp(onSurfaceMuted, other.onSurfaceMuted, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      mist: Color.lerp(mist, other.mist, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      errorTint: Color.lerp(errorTint, other.errorTint, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

/// Foreground, fill, icon and Spanish label of one risk state.
@immutable
class RiskStyle {
  const RiskStyle({
    required this.foreground,
    required this.background,
    required this.icon,
    required this.label,
  });

  final Color foreground;
  final Color background;
  final IconData icon;
  final String label;
}

/// One [RiskStyle] per [RiskLevel]. Domain stays free of colors: the mapping
/// lives here, in the view layer.
@immutable
class RiskPalette extends ThemeExtension<RiskPalette> {
  const RiskPalette({
    required this.notAssessed,
    required this.noneDetected,
    required this.caution,
    required this.high,
    required this.abstain,
    this.discreet = false,
  });

  factory RiskPalette.fromPalette(QhawixPalette p, {bool discreet = false}) {
    final palette = RiskPalette(
      notAssessed: RiskStyle(
        foreground: p.notAssessed.foreground,
        background: p.notAssessed.background,
        icon: Icons.radio_button_unchecked,
        label: 'Sin evaluar',
      ),
      noneDetected: RiskStyle(
        foreground: p.noneDetected.foreground,
        background: p.noneDetected.background,
        icon: Icons.search_off,
        label: 'Sin señales detectadas',
      ),
      caution: RiskStyle(
        foreground: p.caution.foreground,
        background: p.caution.background,
        icon: Icons.warning_amber_rounded,
        label: 'Precaución',
      ),
      high: RiskStyle(
        foreground: p.high.foreground,
        background: p.high.background,
        icon: Icons.report_outlined,
        label: 'Riesgo alto',
      ),
      abstain: RiskStyle(
        foreground: p.abstain.foreground,
        background: p.abstain.background,
        icon: Icons.help_outline,
        label: 'Sin base suficiente',
      ),
    );
    return discreet ? palette.asDiscreet() : palette;
  }

  final RiskStyle notAssessed;
  final RiskStyle noneDetected;
  final RiskStyle caution;
  final RiskStyle high;
  final RiskStyle abstain;

  /// True when every entry renders as `notAssessed`.
  final bool discreet;

  RiskStyle of(RiskLevel level) => switch (level) {
    RiskLevel.notAssessed => notAssessed,
    RiskLevel.noneDetected => noneDetected,
    RiskLevel.caution => caution,
    RiskLevel.high => high,
    RiskLevel.abstain => abstain,
  };

  /// Discreet appearance: no risk colors anywhere until the person verifies.
  RiskPalette asDiscreet() => RiskPalette(
    notAssessed: notAssessed,
    noneDetected: notAssessed,
    caution: notAssessed,
    high: notAssessed,
    abstain: notAssessed,
    discreet: true,
  );

  @override
  RiskPalette copyWith({
    RiskStyle? notAssessed,
    RiskStyle? noneDetected,
    RiskStyle? caution,
    RiskStyle? high,
    RiskStyle? abstain,
    bool? discreet,
  }) => RiskPalette(
    notAssessed: notAssessed ?? this.notAssessed,
    noneDetected: noneDetected ?? this.noneDetected,
    caution: caution ?? this.caution,
    high: high ?? this.high,
    abstain: abstain ?? this.abstain,
    discreet: discreet ?? this.discreet,
  );

  @override
  RiskPalette lerp(ThemeExtension<RiskPalette>? other, double t) =>
      other is RiskPalette && t >= 0.5 ? other : this;
}

/// Corner shapes by role.
@immutable
class QhawixShapes extends ThemeExtension<QhawixShapes> {
  const QhawixShapes();

  double get sm => QhawixRadii.sm;
  double get md => QhawixRadii.md;
  double get lg => QhawixRadii.lg;
  double get xl => QhawixRadii.xl;

  BorderRadius get smRadius => BorderRadius.circular(QhawixRadii.sm);
  BorderRadius get mdRadius => BorderRadius.circular(QhawixRadii.md);
  BorderRadius get lgRadius => BorderRadius.circular(QhawixRadii.lg);
  BorderRadius get pillRadius => BorderRadius.circular(QhawixRadii.full);
  BorderRadius get sheetRadius =>
      const BorderRadius.vertical(top: Radius.circular(QhawixRadii.xl));

  OutlinedBorder get pill => const StadiumBorder();

  RoundedRectangleBorder rounded(double radius, {BorderSide? side}) =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: side ?? BorderSide.none,
      );

  @override
  QhawixShapes copyWith() => const QhawixShapes();

  @override
  QhawixShapes lerp(ThemeExtension<QhawixShapes>? other, double t) => this;
}

/// 4 dp grid, touch target and fixed component sizes.
@immutable
class QhawixSpacing extends ThemeExtension<QhawixSpacing> {
  const QhawixSpacing();

  double get xs => QhawixDimensions.xs;
  double get sm => QhawixDimensions.sm;
  double get md => QhawixDimensions.md;
  double get lg => QhawixDimensions.lg;
  double get xl => QhawixDimensions.xl;
  double get xxl => QhawixDimensions.xxl;
  double get gutter => QhawixDimensions.gutter;
  double get section => QhawixDimensions.section;
  double get touchMin => QhawixDimensions.touchMin;

  double get iconSm => QhawixDimensions.iconSm;
  double get iconMd => QhawixDimensions.iconMd;
  double get iconXl => QhawixDimensions.iconXl;
  double get progressSm => QhawixDimensions.progressSm;
  double get voiceGlyph => QhawixDimensions.voiceGlyph;
  double get bottomNavHeight => QhawixDimensions.bottomNavHeight;
  double get rowHeight => QhawixDimensions.rowHeight;
  double get inputHeight => QhawixDimensions.inputHeight;
  double get multilineHeight => QhawixDimensions.multilineHeight;
  double get moduleCardHeight => QhawixDimensions.moduleCardHeight;
  double get fab => QhawixDimensions.fab;
  double get dragHandleWidth => QhawixDimensions.dragHandleWidth;
  double get dragHandleHeight => QhawixDimensions.dragHandleHeight;
  double get hairline => QhawixDimensions.hairline;
  double get focusRing => QhawixDimensions.focusRing;
  double get maxContentWidth => QhawixDimensions.maxContentWidth;
  double get compactBreakpoint => QhawixDimensions.compactBreakpoint;
  double get expandedBreakpoint => QhawixDimensions.expandedBreakpoint;
  int get multilineMaxLines => QhawixDimensions.multilineMaxLines;

  EdgeInsets get gutterInsets =>
      const EdgeInsets.symmetric(horizontal: QhawixDimensions.gutter);
  EdgeInsets get cardPadding => const EdgeInsets.all(QhawixDimensions.md);
  EdgeInsets get buttonPadding => const EdgeInsets.symmetric(
    horizontal: QhawixDimensions.lg,
    vertical: QhawixDimensions.md - QhawixDimensions.xs,
  );
  EdgeInsets get textButtonPadding => const EdgeInsets.symmetric(
    horizontal: QhawixDimensions.md,
    vertical: QhawixDimensions.md - QhawixDimensions.xs,
  );
  EdgeInsets get bannerPadding => const EdgeInsets.symmetric(
    horizontal: QhawixDimensions.md,
    vertical: QhawixDimensions.md - QhawixDimensions.xs,
  );
  EdgeInsets get compactBannerPadding => const EdgeInsets.symmetric(
    horizontal: QhawixDimensions.md,
    vertical: QhawixDimensions.sm,
  );
  EdgeInsets get badgePadding => const EdgeInsets.symmetric(
    horizontal: QhawixDimensions.md - QhawixDimensions.xs,
    vertical: QhawixDimensions.xs,
  );
  EdgeInsets get screenPadding => const EdgeInsets.symmetric(
    horizontal: QhawixDimensions.lg,
    vertical: QhawixDimensions.xl,
  );

  @override
  QhawixSpacing copyWith() => const QhawixSpacing();

  @override
  QhawixSpacing lerp(ThemeExtension<QhawixSpacing>? other, double t) => this;
}

/// Durations and curves, plus the reduce-motion rule.
@immutable
class QhawixMotion extends ThemeExtension<QhawixMotion> {
  const QhawixMotion({this.forceReduced = false});

  /// Discreet appearance reduces motion regardless of the system setting.
  final bool forceReduced;

  Duration get press => QhawixMotionTokens.press;
  Duration get standard => QhawixMotionTokens.standard;
  Duration get emphasized => QhawixMotionTokens.emphasized;
  Duration get skeleton => QhawixMotionTokens.skeleton;
  Duration get loadingTimeout => QhawixMotionTokens.loadingTimeout;

  Curve get pressCurve => QhawixMotionTokens.pressCurve;
  Curve get standardCurve => QhawixMotionTokens.standardCurve;
  Curve get emphasizedIn => QhawixMotionTokens.emphasizedIn;
  Curve get emphasizedOut => QhawixMotionTokens.emphasizedOut;
  Curve get skeletonCurve => QhawixMotionTokens.skeletonCurve;

  /// True when animation must not run.
  bool reduced(BuildContext context) =>
      forceReduced || MediaQuery.maybeDisableAnimationsOf(context) == true;

  /// [duration], or [Duration.zero] when motion is reduced.
  Duration resolve(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;

  @override
  QhawixMotion copyWith({bool? forceReduced}) =>
      QhawixMotion(forceReduced: forceReduced ?? this.forceReduced);

  @override
  QhawixMotion lerp(ThemeExtension<QhawixMotion>? other, double t) =>
      other is QhawixMotion && t >= 0.5 ? other : this;
}

/// Short accessors so widgets never reach for literals.
extension QhawixThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  QhawixColors get qColors => Theme.of(this).extension<QhawixColors>()!;
  RiskPalette get riskPalette => Theme.of(this).extension<RiskPalette>()!;
  QhawixShapes get shapes => Theme.of(this).extension<QhawixShapes>()!;
  QhawixSpacing get space => Theme.of(this).extension<QhawixSpacing>()!;
  QhawixMotion get motion => Theme.of(this).extension<QhawixMotion>()!;
}
