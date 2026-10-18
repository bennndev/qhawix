// Developer-only entry point for the Red de Confianza screens with the real
// on-device repository (empty until the person adds contacts). Run from ui/:
//   flutter run -t lib/dev/trust_circle_demo_main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/trust_circle/trust_circle_providers.dart';
import '../features/trust_circle/view/trust_circle_screen.dart';

void main() => runApp(const TrustCircleDemoApp());

class TrustCircleDemoApp extends StatelessWidget {
  const TrustCircleDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: trustCircleProviders(),
      child: MaterialApp(
        title: 'Red de Confianza',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const TrustCircleScreen(),
      ),
    );
  }
}
