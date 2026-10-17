import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/core/domain/risk_level.dart';
import 'package:qhawix/core/theme/app_theme.dart';
import 'package:qhawix/core/theme/theme_extensions.dart';
import 'package:qhawix/core/theme/tokens.dart';

void main() {
  for (final entry in {
    'light': AppTheme.light(),
    'dark': AppTheme.dark(),
  }.entries) {
    group('${entry.key} theme', () {
      final theme = entry.value;

      test('builds with Material 3 and an explicit scheme', () {
        expect(theme.useMaterial3, isTrue);
        final palette = entry.key == 'light'
            ? QhawixPalette.light
            : QhawixPalette.dark;
        expect(theme.colorScheme.primary, palette.primary);
        expect(theme.colorScheme.surface, palette.surface);
        expect(theme.scaffoldBackgroundColor, palette.canvas);
      });

      test('registers every extension', () {
        expect(theme.extension<QhawixColors>(), isNotNull);
        expect(theme.extension<RiskPalette>(), isNotNull);
        expect(theme.extension<QhawixShapes>(), isNotNull);
        expect(theme.extension<QhawixSpacing>(), isNotNull);
        expect(theme.extension<QhawixMotion>(), isNotNull);
      });

      test('uses the bundled font families', () {
        expect(theme.textTheme.headlineMedium?.fontFamily, 'DM Sans');
        expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
        expect(theme.textTheme.labelLarge?.fontFamily, 'DM Sans');
      });

      test('buttons are at least 48 dp and pill shaped', () {
        final styles = [
          theme.filledButtonTheme.style!,
          theme.outlinedButtonTheme.style!,
          theme.textButtonTheme.style!,
        ];
        for (final style in styles) {
          final size = style.minimumSize!.resolve(<WidgetState>{})!;
          expect(size.height, greaterThanOrEqualTo(48));
          expect(style.shape!.resolve(<WidgetState>{}), isA<StadiumBorder>());
        }
      });

      test('surfaces are flat', () {
        expect(theme.cardTheme.elevation, 0);
        expect(theme.dialogTheme.elevation, 0);
        expect(theme.bottomSheetTheme.elevation, 0);
        expect(theme.appBarTheme.elevation, 0);
        expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
      });
    });
  }

  test('risk palette lookup returns one style per level with label and icon', () {
    final palette = AppTheme.light().extension<RiskPalette>()!;
    final labels = {
      for (final level in RiskLevel.values) palette.of(level).label,
    };
    final icons = {
      for (final level in RiskLevel.values) palette.of(level).icon,
    };
    expect(labels, hasLength(RiskLevel.values.length));
    expect(icons, hasLength(RiskLevel.values.length));
    expect(palette.of(RiskLevel.noneDetected).label, 'Sin señales detectadas');
    expect(palette.of(RiskLevel.noneDetected).icon, Icons.search_off);
  });

  test('discreet appearance renders every level as notAssessed', () {
    for (final theme in [
      AppTheme.light(discreet: true),
      AppTheme.dark(discreet: true),
    ]) {
      final palette = theme.extension<RiskPalette>()!;
      expect(palette.discreet, isTrue);
      for (final level in RiskLevel.values) {
        expect(palette.of(level).label, 'Sin evaluar');
        expect(palette.of(level).foreground, palette.notAssessed.foreground);
      }
      expect(theme.extension<QhawixMotion>()!.forceReduced, isTrue);
    }
    expect(
      AppTheme.light().extension<RiskPalette>()!.of(RiskLevel.high).label,
      'Riesgo alto',
    );
  });

  group('QhawixMotion', () {
    Future<Duration> resolved(
      WidgetTester tester, {
      required bool disableAnimations,
      bool discreet = false,
    }) async {
      late Duration result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(discreet: discreet),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: disableAnimations),
            child: child!,
          ),
          home: Builder(
            builder: (context) {
              result = context.motion.resolve(
                context,
                context.motion.emphasized,
              );
              return const SizedBox();
            },
          ),
        ),
      );
      return result;
    }

    testWidgets('keeps the duration when motion is allowed', (tester) async {
      expect(
        await resolved(tester, disableAnimations: false),
        QhawixMotionTokens.emphasized,
      );
    });

    testWidgets('returns zero when disableAnimations is true', (tester) async {
      expect(
        await resolved(tester, disableAnimations: true),
        Duration.zero,
      );
    });

    testWidgets('returns zero under the discreet appearance', (tester) async {
      expect(
        await resolved(tester, disableAnimations: false, discreet: true),
        Duration.zero,
      );
    });

    test('no token exceeds 300 ms except the skeleton loop and timeout', () {
      expect(QhawixMotionTokens.press, const Duration(milliseconds: 100));
      expect(QhawixMotionTokens.standard, const Duration(milliseconds: 200));
      expect(QhawixMotionTokens.emphasized, const Duration(milliseconds: 300));
      expect(QhawixMotionTokens.skeleton, const Duration(milliseconds: 1400));
    });
  });
}
