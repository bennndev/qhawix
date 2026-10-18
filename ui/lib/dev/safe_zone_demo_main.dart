// Developer-only entry point for the safe-zone alerts (Refugio). It talks to the
// REAL Android channel, so tests and alerts send real SMS. The recipients come
// from the Trust Circle's in-memory mock repository for now. Run from ui/:
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
      providers: [...trustCircleProviders(), ...refugeProviders()],
      child: MaterialApp(
        title: 'Refugio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const RefugeScreen(),
      ),
    );
  }
}
