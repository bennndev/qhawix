import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/bottom_nav.dart';

/// Persistent chrome: bottom navigation for the main tabs.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = <QhawixTab>[
    QhawixTab.inicio,
    QhawixTab.analizar,
    QhawixTab.red,
    QhawixTab.bitacora,
  ];

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex.clamp(0, _tabs.length - 1);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: QhawixBottomNav(
        selected: _tabs[index],
        onSelected: (tab) {
          final i = _tabs.indexOf(tab);
          if (i >= 0) navigationShell.goBranch(i);
        },
      ),
    );
  }
}
