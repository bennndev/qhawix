import 'package:flutter/material.dart';
import '../core/theme/theme_extensions.dart';
import '../core/widgets/guardian_mascot/guardian_mascot.dart';
import '../core/widgets/module_card.dart';
import '../core/widgets/page_header.dart';
import '../core/widgets/qhawix_app_bar.dart';
import 'authentication_gate.dart';
import 'module_catalog.dart';
import 'module_navigation.dart';

/// Inicio: brand + Guardian mascot + module menu (DESIGN.md Operate mode).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final colors = context.qColors;
    return Scaffold(
      appBar: QhawixAppBar(
        title: 'QHAWIX',
        automaticallyImplyLeading: false,
        actions: [
          if (hasQhawixSession)
            QhawixAction(
              icon: Icons.logout,
              tooltip: 'Cerrar sesión',
              onPressed: signOutOfQhawix,
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: space.maxContentWidth),
            child: ListView(
              padding: space.screenPadding,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: PageHeader(
                        title: 'Tu vigía',
                        subtitle: 'Elige qué quieres cuidar hoy.',
                      ),
                    ),
                    GuardianMascot(
                      state: GuardianMascotState.idle,
                      size: space.moduleCardHeight,
                      bodyColor: colors.accent,
                      lineColor: context.scheme.onPrimary,
                      semanticLabel: 'Abrir AURA, tu asistente',
                      onTap: () => openModule(
                        context,
                        ModuleCatalog.byId(AppModuleId.aura),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: space.lg),
                for (final entry in ModuleCatalog.homeEntries) ...[
                  ModuleCard(
                    icon: entry.icon,
                    name: entry.name,
                    purpose: entry.purpose,
                    onTap: () => openModule(context, entry),
                  ),
                  SizedBox(height: space.sm),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
