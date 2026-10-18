import 'package:flutter/material.dart';
import '../core/theme/theme_extensions.dart';
import '../core/widgets/guardian_mascot/guardian_mascot.dart';
import '../core/widgets/module_card.dart';
import '../core/widgets/page_header.dart';
import '../core/widgets/qhawix_app_bar.dart';
import '../core/widgets/status_banner.dart';
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
      appBar: QhawixAppBar(title: 'QHAWIX', automaticallyImplyLeading: false),
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
                    Expanded(
                      child: PageHeader(
                        title: 'Tu vigía',
                        subtitle:
                            'Elige un módulo. Cada uno pide sus permisos solo '
                            'cuando lo activas, no al abrir la app.',
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
                const StatusBanner(
                  message:
                      'Los módulos en construcción abren una pantalla de '
                      'activación que lista los permisos. Refugio ya tiene su '
                      'propio asistente de configuración.',
                ),
                SizedBox(height: space.lg),
                Text('Módulos', style: context.text.titleMedium),
                SizedBox(height: space.md),
                for (final entry in ModuleCatalog.homeEntries) ...[
                  ModuleCard(
                    icon: entry.icon,
                    name: entry.name,
                    purpose: entry.purpose,
                    limitNote: entry.limitNote,
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
