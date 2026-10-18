// Developer-only entry for isolated Refugio package work. Product navigation
// lives in the main QHAWIX app (lib/main.dart → tabs + Inicio modules).
// Run from ui/:
//   flutter run -t lib/dev/safe_zone_demo_main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/refuge/refuge_providers.dart';
import '../features/refuge/view/refuge_screen.dart';
import '../features/trust_circle/trust_circle_providers.dart';

void main() => runApp(const SafeZoneDemoApp());

class SafeZoneDemoApp extends StatelessWidget {
  const SafeZoneDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ...trustCircleProviders(),
        ...refugeProviders(),
      ],
      child: MaterialApp(
        title: 'Refugio (dev)',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const RefugeScreen(),
      ),
    );
  }
}
