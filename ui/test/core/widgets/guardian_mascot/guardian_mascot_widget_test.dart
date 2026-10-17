import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/core/widgets/guardian_mascot/guardian_mascot.dart';

const _body = Color(0xFF0B5D6B);
const _line = Color(0xFFFFFFFF);

Widget _host(
  Widget child, {
  bool disableAnimations = false,
  Brightness brightness = Brightness.light,
}) =>
    MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData(brightness: brightness),
          child: Center(child: child),
        ),
      ),
    );

Future<ui.Image> _render(
  WidgetTester tester,
  GlobalKey key, {
  double pixelRatio = 1,
}) async {
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() => boundary.toImage(pixelRatio: pixelRatio)))!;
}

Future<Uint8List> _rgba(WidgetTester tester, ui.Image image) async {
  final data = await tester.runAsync(() => image.toByteData(format: ui.ImageByteFormat.rawRgba));
  return data!.buffer.asUint8List();
}

void main() {
  group('rendering', () {
    for (final state in GuardianMascotState.values) {
      testWidgets('${state.name} renders and animates without errors', (tester) async {
        await tester.pumpWidget(_host(GuardianMascot(
          state: state,
          size: 160,
          bodyColor: _body,
          lineColor: _line,
        )));
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(tester.takeException(), isNull);
        expect(find.byType(CustomPaint), findsWidgets);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('idle paints only the body and line colours on a transparent canvas', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(_host(RepaintBoundary(
        key: key,
        child: const GuardianMascot(
          state: GuardianMascotState.idle,
          size: 400,
          bodyColor: _body,
          lineColor: _line,
        ),
      )));
      final image = await _render(tester, key);
      final bytes = await _rgba(tester, image);
      var body = 0, line = 0, clear = 0, other = 0;
      for (var i = 0; i < bytes.length; i += 4) {
        final r = bytes[i], g = bytes[i + 1], b = bytes[i + 2], a = bytes[i + 3];
        if (a == 0) {
          clear++;
        } else if (a == 255 && r == 0x0B && g == 0x5D && b == 0x6B) {
          body++;
        } else if (a == 255 && r == 255 && g == 255 && b == 255) {
          line++;
        } else {
          other++;
        }
      }
      expect(body, greaterThan(25000), reason: 'body area');
      expect(line, greaterThan(2000), reason: 'lines and eyes');
      expect(clear, greaterThan(20000), reason: 'transparent margin');
      expect(other, lessThan(body ~/ 5), reason: 'only anti-aliased edges are blended');
      // The top-left corner and the area right of the owl are empty at rest.
      expect(bytes[3], 0);
    });

    testWidgets('writes idle and state PNGs when GUARDIAN_MASCOT_PNG_DIR is set', (tester) async {
      final dir = Platform.environment['GUARDIAN_MASCOT_PNG_DIR'];
      if (dir == null) return;
      Directory(dir).createSync(recursive: true);
      for (final entry in {
        GuardianMascotState.idle: 0.0,
        GuardianMascotState.thinking: 0.0,
        GuardianMascotState.working: 0.0,
        GuardianMascotState.success: 0.0,
        GuardianMascotState.listening: 0.0,
        GuardianMascotState.scanning: 0.0,
        GuardianMascotState.alert: 0.0,
        GuardianMascotState.stealth: 0.0,
      }.entries) {
        final key = GlobalKey();
        await tester.pumpWidget(_host(
          RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: Colors.white,
              child: GuardianMascot(
                state: entry.key,
                size: 400,
                bodyColor: const Color(0xFF00BBA6),
                lineColor: _line,
              ),
            ),
          ),
          disableAnimations: true,
        ));
        await tester.pump();
        final image = await _render(tester, key);
        final png = await tester.runAsync(() => image.toByteData(format: ui.ImageByteFormat.png));
        File('$dir/${entry.key.name}.png').writeAsBytesSync(png!.buffer.asUint8List());
      }
    });
  });

  group('animation lifecycle', () {
    testWidgets('a running state keeps animating and the controller is disposed with the widget',
        (tester) async {
      await tester.pumpWidget(_host(const GuardianMascot(state: GuardianMascotState.idle)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('no animation runs when disableAnimations is true', (tester) async {
      await tester.pumpWidget(_host(
        const GuardianMascot(state: GuardianMascotState.working),
        disableAnimations: true,
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpAndSettle();
    });

    testWidgets('turning disableAnimations on stops the clock and off restarts it', (tester) async {
      Widget build(bool reduce) =>
          _host(const GuardianMascot(state: GuardianMascotState.scanning), disableAnimations: reduce);
      await tester.pumpWidget(build(false));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(build(true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(build(false));
      await tester.pump();
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('pauses in the background and resumes in the foreground', (tester) async {
      await tester.pumpWidget(_host(const GuardianMascot(state: GuardianMascotState.listening)));
      expect(tester.hasRunningAnimations, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('pauses when tickers are disabled for the subtree', (tester) async {
      Widget build(bool enabled) => _host(TickerMode(
            enabled: enabled,
            child: const GuardianMascot(state: GuardianMascotState.thinking),
          ));
      await tester.pumpWidget(build(false));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(build(true));
      await tester.pump();
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a held alert stops the clock once its pose is reached', (tester) async {
      GuardianMascotState? ended;
      await tester.pumpWidget(_host(GuardianMascot(
        state: GuardianMascotState.alert,
        onStateEnd: (s) => ended = s,
      )));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump();
      expect(ended, GuardianMascotState.alert);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('success reports idle through onStateEnd when it finishes', (tester) async {
      final ended = <GuardianMascotState>[];
      await tester.pumpWidget(_host(GuardianMascot(
        state: GuardianMascotState.success,
        onStateEnd: ended.add,
      )));
      await tester.pump(const Duration(milliseconds: 1000));
      expect(ended, isEmpty);
      await tester.pump(const Duration(milliseconds: 2000));
      expect(ended, [GuardianMascotState.idle]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('reduced motion still returns from success after the hold', (tester) async {
      final ended = <GuardianMascotState>[];
      await tester.pumpWidget(_host(
        GuardianMascot(state: GuardianMascotState.success, onStateEnd: ended.add),
        disableAnimations: true,
      ));
      await tester.pump(const Duration(milliseconds: 1000));
      expect(ended, isEmpty);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(ended, [GuardianMascotState.idle]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('changing the state parameter switches the animation', (tester) async {
      final key = GlobalKey();
      Widget build(GuardianMascotState s) => _host(RepaintBoundary(
            key: key,
            child: GuardianMascot(state: s, size: 200, bodyColor: _body, lineColor: _line),
          ));
      await tester.pumpWidget(build(GuardianMascotState.idle), duration: const Duration(milliseconds: 50));
      final before = await _rgba(tester, await _render(tester, key));
      await tester.pumpWidget(build(GuardianMascotState.stealth));
      await tester.pump(const Duration(milliseconds: 800));
      final after = await _rgba(tester, await _render(tester, key));
      expect(after, isNot(before));
      var opaque = 0;
      for (var i = 3; i < after.length; i += 4) {
        if (after[i] > 200) opaque++;
      }
      expect(opaque, equals(0), reason: 'stealth is faint (about 0.14 opacity)');
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('colours and semantics', () {
    testWidgets('colours default to the theme colour scheme', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(_host(
        RepaintBoundary(
          key: key,
          child: const GuardianMascot(state: GuardianMascotState.idle, size: 200),
        ),
        disableAnimations: true,
      ));
      final theme = ThemeData(brightness: Brightness.light).colorScheme;
      final bytes = await _rgba(tester, await _render(tester, key));
      var hits = 0;
      final r = (theme.primary.r * 255).round();
      final g = (theme.primary.g * 255).round();
      final b = (theme.primary.b * 255).round();
      for (var i = 0; i < bytes.length; i += 4) {
        if (bytes[i + 3] == 255 && bytes[i] == r && bytes[i + 1] == g && bytes[i + 2] == b) hits++;
      }
      expect(hits, greaterThan(6000));
    });

    testWidgets('decorative by default: nothing in the semantics tree', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const GuardianMascot(state: GuardianMascotState.idle)));
      expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
      handle.dispose();
    });

    testWidgets('a label makes it a labelled image, English text never appears', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const GuardianMascot(
        state: GuardianMascotState.idle,
        semanticLabel: 'Guardian de Comportamiento',
      )));
      expect(find.bySemanticsLabel('Guardian de Comportamiento'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Owl')), findsNothing);
      handle.dispose();
    });

    testWidgets('label plus onTap is a button with a 48 dp minimum target', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(_host(GuardianMascot(
        state: GuardianMascotState.idle,
        size: 24,
        semanticLabel: 'Abrir AURA, tu asistente',
        onTap: () => taps++,
      )));
      final node = tester.getSemantics(find.bySemanticsLabel('Abrir AURA, tu asistente'));
      expect(node.flagsCollection.isButton, isTrue);
      final size = tester.getSize(find.byType(GestureDetector));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      await tester.tap(find.byType(GestureDetector));
      expect(taps, 1);
      handle.dispose();
    });
  });
}
