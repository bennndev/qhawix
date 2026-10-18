import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/theme_extensions.dart';
import '../core/widgets/page_header.dart';
import '../core/widgets/qhawix_app_bar.dart';
import '../core/widgets/qhawix_buttons.dart';
import '../core/widgets/section_card.dart';
import '../core/widgets/status_banner.dart';
import 'module_activation_store.dart';
import 'module_catalog.dart';

/// Per-module activation: explains purpose and the permissions it will need.
///
/// Does not request system permissions yet for stub modules (honest limit).
/// Refuge keeps its own wizard. When a module's platform adapter lands, the
/// Continue action can call the real prompts from this screen.
class ModuleOnboardingScreen extends StatelessWidget {
  const ModuleOnboardingScreen({super.key, required this.entry});

  final ModuleCatalogEntry entry;

  void _finish(BuildContext context) {
    context.read<ModuleActivationStore>().markActivated(entry.id);
    // Replace the onboarding route so Back does not return to it.
    context.pushReplacement(entry.routePath);
  }

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final colors = context.qColors;
    return Scaffold(
      appBar: QhawixAppBar(title: entry.name),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: space.maxContentWidth),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: space.screenPadding,
                    children: [
                      PageHeader(
                        title: 'Activar ${entry.name}',
                        subtitle: entry.purpose,
                      ),
                      if (entry.limitNote != null) ...[
                        StatusBanner(message: entry.limitNote!),
                        SizedBox(height: space.md),
                      ],
                      Text('Permisos de este módulo', style: context.text.titleMedium),
                      SizedBox(height: space.sm),
                      Text(
                        'QHAWIX pide cada permiso aquí, no al abrir la app. '
                        'Si dices que no, el módulo ofrece una alternativa cuando exista.',
                        style: context.text.bodyMedium?.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                      SizedBox(height: space.md),
                      if (entry.permissions.isEmpty)
                        QhawixCard(
                          child: Text(
                            'Este módulo no necesita permisos del sistema por ahora.',
                            style: context.text.bodyMedium,
                          ),
                        )
                      else
                        for (final need in entry.permissions) ...[
                          QhawixCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      need.opensSystemSettings
                                          ? Icons.settings_outlined
                                          : Icons.verified_user_outlined,
                                      color: colors.accent,
                                      size: space.iconMd,
                                    ),
                                    SizedBox(width: space.md),
                                    Expanded(
                                      child: Text(
                                        need.title,
                                        style: context.text.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: space.sm),
                                Text(need.why, style: context.text.bodyMedium),
                                if (need.opensSystemSettings) ...[
                                  SizedBox(height: space.sm),
                                  Text(
                                    'Se abre en Ajustes del teléfono; la app no puede activarlo sola.',
                                    style: context.text.bodySmall?.copyWith(
                                      color: colors.onSurfaceMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: space.sm),
                        ],
                      StatusBanner(
                        message:
                            'Los diálogos del sistema se pedirán cuando la función '
                            'esté lista en este módulo. Hoy este paso deja claro qué '
                            'se pedirá y abre la pantalla del módulo.',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(space.lg),
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: 'Continuar',
                        onPressed: () => _finish(context),
                      ),
                      SizedBox(height: space.sm),
                      SecondaryButton(
                        label: 'Ahora no',
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
