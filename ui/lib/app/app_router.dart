import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/logbook/view/logbook_screen.dart';
import '../features/qr_shield/view/qr_candidate_selection_screen.dart';
import '../features/qr_shield/view/qr_review_screen.dart';
import '../features/qr_shield/view/qr_scanner_screen.dart';
import '../features/trust_circle/view/trust_circle_screen.dart';
import 'analyze_screen.dart';
import 'app_shell.dart';
import 'home_screen.dart';
import 'module_catalog.dart';
import 'module_host.dart';
import 'module_onboarding_screen.dart';

/// Root [GoRouter] for the QHAWIX shell (four tabs + module routes).
GoRouter createAppRouter({GlobalKey<NavigatorState>? navigatorKey}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/inicio',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inicio',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analizar',
                builder: (context, state) => const AnalyzeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/red',
                builder: (context, state) => const TrustCircleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bitacora',
                builder: (context, state) => const LogbookScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/m/:slug/onboarding',
        builder: (context, state) {
          final entry =
              ModuleCatalog.byPathSegment(state.pathParameters['slug']!);
          if (entry == null) {
            return const _UnknownModuleScreen();
          }
          return ModuleOnboardingScreen(entry: entry);
        },
      ),
      GoRoute(
        path: '/m/qr-shield/scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/m/qr-shield/review',
        builder: (context, state) => const QrReviewScreen(),
      ),
      GoRoute(
        path: '/m/qr-shield/candidates',
        builder: (context, state) => const QrCandidateSelectionScreen(),
      ),
      GoRoute(
        path: '/m/:slug',
        builder: (context, state) {
          final entry =
              ModuleCatalog.byPathSegment(state.pathParameters['slug']!);
          if (entry == null) {
            return const _UnknownModuleScreen();
          }
          return moduleScreenFor(entry);
        },
      ),
    ],
  );
}

class _UnknownModuleScreen extends StatelessWidget {
  const _UnknownModuleScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Módulo')),
      body: const Center(child: Text('No se encontró este módulo.')),
    );
  }
}
