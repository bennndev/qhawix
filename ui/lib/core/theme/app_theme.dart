import 'package:flutter/material.dart';

import 'theme_extensions.dart';
import 'tokens.dart';

/// Assembles `ThemeData` from the tokens in `DESIGN.md`.
///
/// [discreet] is the discreet appearance flag: it keeps the active light or
/// dark theme, maps every risk entry to `notAssessed` and forces reduced motion.
abstract final class AppTheme {
  static ThemeData light({bool discreet = false}) =>
      _build(QhawixPalette.light, discreet: discreet);

  static ThemeData dark({bool discreet = false}) =>
      _build(QhawixPalette.dark, discreet: discreet);

  /// Builds the text style of one typography token with [color].
  static TextStyle style(TypeToken t, Color color) => TextStyle(
    fontFamily: t.family,
    fontFamilyFallback: QhawixFonts.fallback,
    fontSize: t.size,
    fontWeight: t.weight,
    height: t.lineHeight,
    letterSpacing: t.letterSpacingEm * t.size,
    color: color,
  );

  static ThemeData _build(QhawixPalette p, {required bool discreet}) {
    final colors = QhawixColors.fromPalette(p);
    const shapes = QhawixShapes();
    const dims = QhawixDimensions.touchMin;

    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.accentTint,
      onPrimaryContainer: p.accentDeep,
      secondary: p.secondary,
      onSecondary: p.onPrimary,
      secondaryContainer: p.accentTint,
      onSecondaryContainer: p.accentDeep,
      tertiary: p.mist,
      onTertiary: p.onSurfaceStrong,
      error: p.error,
      onError: p.onError,
      errorContainer: p.errorTint,
      onErrorContainer: p.error,
      surface: p.surface,
      onSurface: p.onSurface,
      onSurfaceVariant: p.onSurfaceMuted,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: p.canvas,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surfaceSunken,
      surfaceContainerHighest: p.surfaceSunken,
      outline: p.borderStrong,
      outlineVariant: p.mist,
      shadow: Colors.transparent,
      scrim: colors.scrim,
      inverseSurface: p.primary,
      onInverseSurface: p.onPrimary,
      inversePrimary: p.accent,
    );

    final text = TextTheme(
      displayLarge: style(QhawixType.headlineDisplay, p.onSurfaceStrong),
      displayMedium: style(QhawixType.headlineDisplay, p.onSurfaceStrong),
      displaySmall: style(QhawixType.headlineDisplay, p.onSurfaceStrong),
      headlineLarge: style(QhawixType.headlineLg, p.onSurfaceStrong),
      headlineMedium: style(QhawixType.headlineMd, p.onSurfaceStrong),
      headlineSmall: style(QhawixType.headlineSm, p.onSurfaceStrong),
      titleLarge: style(QhawixType.headlineSm, p.onSurfaceStrong),
      titleMedium: style(QhawixType.headlineSm, p.onSurfaceStrong),
      // Body emphasis (Inter 500, 16) has no Material slot of its own.
      titleSmall: style(QhawixType.bodyEmphasis, p.onSurfaceStrong),
      bodyLarge: style(QhawixType.bodyLg, p.onSurface),
      bodyMedium: style(QhawixType.bodyMd, p.onSurface),
      bodySmall: style(QhawixType.bodySm, p.onSurface),
      labelLarge: style(QhawixType.labelLg, p.onSurfaceStrong),
      labelMedium: style(QhawixType.labelMd, p.onSurfaceStrong),
      labelSmall: style(QhawixType.labelSm, p.onSurfaceStrong),
    );

    final focusSide = BorderSide(color: p.accent, width: QhawixDimensions.focusRing);
    const minSize = Size(dims, dims);
    const stadium = StadiumBorder();

    WidgetStateProperty<Color?> overlay(Color tint) =>
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return tint.withValues(alpha: 0.12);
          }
          return null;
        });

    final filledStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(minSize),
      padding: WidgetStatePropertyAll(const QhawixSpacing().buttonPadding),
      shape: const WidgetStatePropertyAll(stadium),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(text.labelLarge),
      tapTargetSize: MaterialTapTargetSize.padded,
      backgroundColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return p.surfaceSunken;
        if (s.contains(WidgetState.pressed)) return p.pressedPrimary;
        return p.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? p.onSurfaceMuted : p.onPrimary,
      ),
      side: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.focused) ? focusSide : null,
      ),
      overlayColor: overlay(p.onPrimary),
    );

    final outlinedStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(minSize),
      padding: WidgetStatePropertyAll(const QhawixSpacing().buttonPadding),
      shape: const WidgetStatePropertyAll(stadium),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: WidgetStatePropertyAll(text.labelLarge),
      tapTargetSize: MaterialTapTargetSize.padded,
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? p.surfaceSunken : null,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled)
            ? p.onSurfaceMuted
            : p.onSurfaceStrong,
      ),
      side: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.focused)) return focusSide;
        if (s.contains(WidgetState.disabled)) {
          return BorderSide(color: p.mist, width: QhawixDimensions.hairline);
        }
        return BorderSide(
          color: p.borderStrong,
          width: QhawixDimensions.hairline,
        );
      }),
      overlayColor: overlay(p.accent),
    );

    final textStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(minSize),
      padding: WidgetStatePropertyAll(const QhawixSpacing().textButtonPadding),
      shape: const WidgetStatePropertyAll(stadium),
      textStyle: WidgetStatePropertyAll(text.labelLarge),
      tapTargetSize: MaterialTapTargetSize.padded,
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? p.onSurfaceMuted : p.accent,
      ),
      side: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.focused) ? focusSide : null,
      ),
      overlayColor: overlay(p.accent),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: shapes.mdRadius,
      borderSide: BorderSide(
        color: p.borderStrong,
        width: QhawixDimensions.hairline,
      ),
    );

    // Snack bar action on the inverse surface uses the other brightness' accent.
    final inverseAccent = p.brightness == Brightness.light
        ? QhawixPalette.dark.accent
        : QhawixPalette.light.accent;

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.canvas,
      canvasColor: p.canvas,
      textTheme: text,
      primaryTextTheme: text,
      fontFamily: QhawixFonts.reading,
      fontFamilyFallback: QhawixFonts.fallback,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      dividerColor: p.mist,
      extensions: <ThemeExtension<dynamic>>[
        colors,
        RiskPalette.fromPalette(p, discreet: discreet),
        shapes,
        const QhawixSpacing(),
        QhawixMotion(forceReduced: discreet),
      ],
      filledButtonTheme: FilledButtonThemeData(style: filledStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: filledStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedStyle),
      textButtonTheme: TextButtonThemeData(style: textStyle),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(minSize),
          tapTargetSize: MaterialTapTargetSize.padded,
          foregroundColor: WidgetStatePropertyAll(p.onSurfaceStrong),
          side: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused) ? focusSide : null,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: shapes.rounded(
          QhawixRadii.lg,
          side: BorderSide(color: p.mist, width: QhawixDimensions.hairline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        isDense: false,
        constraints: const BoxConstraints(minHeight: QhawixDimensions.inputHeight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: QhawixDimensions.md,
          vertical: QhawixDimensions.md - QhawixDimensions.xs,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
        helperStyle: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
        errorStyle: text.bodySmall?.copyWith(color: p.error),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: p.mist,
            width: QhawixDimensions.hairline,
          ),
        ),
        focusedBorder: inputBorder.copyWith(borderSide: focusSide),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: p.error,
            width: QhawixDimensions.focusRing,
          ),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: p.error,
            width: QhawixDimensions.focusRing,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.mist,
        selectedColor: p.accentTint,
        disabledColor: p.surfaceSunken,
        checkmarkColor: p.accentDeep,
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium?.copyWith(color: p.accentDeep),
        padding: const EdgeInsets.symmetric(
          horizontal: QhawixDimensions.sm,
          vertical: QhawixDimensions.sm,
        ),
        side: BorderSide.none,
        shape: stadium,
        elevation: 0,
        pressElevation: 0,
        surfaceTintColor: Colors.transparent,
        showCheckmark: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: QhawixDimensions.bottomNavHeight,
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        indicatorColor: p.accentTint,
        indicatorShape: stadium,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelSmall?.copyWith(
            color: s.contains(WidgetState.selected)
                ? p.accentDeep
                : p.onSurfaceMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: QhawixDimensions.iconMd,
            color: s.contains(WidgetState.selected)
                ? p.accentDeep
                : p.onSurfaceMuted,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.canvas,
        foregroundColor: p.onSurfaceStrong,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: QhawixDimensions.appBarHeight,
        titleTextStyle: text.titleMedium,
        iconTheme: IconThemeData(
          color: p.onSurfaceStrong,
          size: QhawixDimensions.iconMd,
        ),
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: QhawixDimensions.rowHeight,
        contentPadding: EdgeInsets.zero,
        iconColor: p.onSurface,
        textColor: p.onSurfaceStrong,
        titleTextStyle: text.bodyMedium?.copyWith(color: p.onSurfaceStrong),
        subtitleTextStyle: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
        shape: const RoundedRectangleBorder(),
      ),
      dividerTheme: DividerThemeData(
        color: p.mist,
        thickness: QhawixDimensions.hairline,
        space: QhawixDimensions.hairline,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        modalBackgroundColor: p.surface,
        modalBarrierColor: colors.scrim,
        showDragHandle: false,
        shape: RoundedRectangleBorder(borderRadius: shapes.sheetRadius),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        barrierColor: colors.scrim,
        shape: shapes.rounded(QhawixRadii.xl),
        titleTextStyle: text.headlineMedium,
        contentTextStyle: text.bodyMedium,
        insetPadding: const EdgeInsets.all(QhawixDimensions.lg),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.mist,
        circularTrackColor: Colors.transparent,
        linearMinHeight: QhawixDimensions.xs,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.primary,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.onPrimary),
        actionTextColor: inverseAccent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: shapes.rounded(QhawixRadii.md),
      ),
    );
  }
}
