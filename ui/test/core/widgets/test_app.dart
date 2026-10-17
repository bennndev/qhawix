import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/core/theme/app_theme.dart';

/// Wraps [child] in a themed app with an optional text scale.
Widget qhawixApp(
  Widget child, {
  ThemeData? theme,
  double textScale = 1,
  bool disableAnimations = false,
  bool scaffold = true,
}) => MaterialApp(
  theme: theme ?? AppTheme.light(),
  builder: (context, home) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: disableAnimations,
    ),
    child: home!,
  ),
  home: scaffold ? Scaffold(body: Center(child: child)) : child,
);

/// Sets a phone-sized logical surface for the test and restores it afterwards.
void usePhoneSurface(
  WidgetTester tester, {
  Size size = const Size(360, 800),
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
