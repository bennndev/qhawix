import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/trust_circle/trust_circle_providers.dart';
import 'app_router.dart';
import 'module_activation_store.dart';

/// Root widget: theme, providers and the shell router.
class QhawixApp extends StatefulWidget {
  const QhawixApp({
    super.key,
    this.router,
    this.forceDisableAnimations = false,
  });

  /// Injected in tests; production builds its own [GoRouter].
  final GoRouter? router;

  /// Widget tests set this so the mascot loop does not block pumps.
  final bool forceDisableAnimations;

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
      ],
      child: MaterialApp.router(
        title: 'QHAWIX',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: _router,
        builder: (context, child) {
          final content = child ?? const SizedBox.shrink();
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
