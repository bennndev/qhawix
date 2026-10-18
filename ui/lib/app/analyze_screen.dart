import 'package:flutter/material.dart';

import '../core/theme/theme_extensions.dart';
import '../core/widgets/module_card.dart';
import '../core/widgets/page_header.dart';
import '../core/widgets/qhawix_app_bar.dart';
import 'module_catalog.dart';
import 'module_navigation.dart';

/// Analizar tab: Sentinel, Escudo QR and EchoTrap entry cards.
class AnalyzeScreen extends StatelessWidget {
  const AnalyzeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Scaffold(
      appBar: QhawixAppBar(
        title: 'Analizar',
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: space.maxContentWidth),
            child: ListView(
              padding: space.screenPadding,
              children: [
                const PageHeader(
                  title: 'Analizar',
                  subtitle:
                      'Mensajes, QR y llamadas. Cada módulo pide solo el '
                      'permiso que necesita cuando lo abres.',
                ),
                for (final entry in ModuleCatalog.analyzeEntries) ...[
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
