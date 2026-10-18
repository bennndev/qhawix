import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/qr_shield/qr_shield_providers.dart';
import '../features/refuge/refuge_providers.dart';
import '../features/trust_circle/trust_circle_providers.dart';
import 'authentication_gate.dart';
import 'app_router.dart';
import 'module_activation_store.dart';

/// Root widget: theme, providers and the shell router.
class QhawixApp extends StatefulWidget {
  const QhawixApp({
    super.key,
    this.router,
    this.forceDisableAnimations = false,
    this.requireAuthentication = true,
  });

  /// Injected in tests; production builds its own [GoRouter].
  final GoRouter? router;

  /// Widget tests set this so the mascot loop does not block pumps.
  final bool forceDisableAnimations;

  /// Tests and explicitly labeled preview builds can bypass the login screen.
  final bool requireAuthentication;

  @override
  State<QhawixApp> createState() => _QhawixAppState();
}

class _QhawixAppState extends State<QhawixApp> {
  late final GoRouter _router = widget.router ?? createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ModuleActivationStore()),
        ...trustCircleProviders(),
        ...refugeProviders(),
        ...qrShieldProviders(),
      ],
      child: MaterialApp.router(
        title: 'QHAWIX',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: _router,
        builder: (context, child) {
          Widget content = child ?? const SizedBox.shrink();
          if (widget.requireAuthentication) {
            content = AuthenticationGate(child: content);
          }
          if (!widget.forceDisableAnimations) return content;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: content,
          );
        },
      ),
    );
  }
}
