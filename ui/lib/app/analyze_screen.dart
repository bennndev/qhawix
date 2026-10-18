import 'package:flutter/material.dart';

import '../core/theme/theme_extensions.dart';
import '../core/widgets/guardian_mascot/guardian_mascot.dart';
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
        title: 'QHAWIX',
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: space.maxContentWidth),
            child: ListView(
              padding: space.screenPadding,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: PageHeader(
                        title: 'Analizar',
                        subtitle: 'Mensajes, QR y llamadas.',
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(space.xs),
                      decoration: BoxDecoration(
                        color: context.qColors.accent,
                        borderRadius: BorderRadius.circular(space.sm),
                      ),
                      child: GuardianMascot(
                        state: GuardianMascotState.stealth,
                        size: space.iconXl,
                        bodyColor: context.scheme.onPrimary,
                        lineColor: context.scheme.onPrimary,
                        semanticLabel: 'AURA, guía disponible',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: space.md),
                for (final entry in ModuleCatalog.analyzeEntries) ...[
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
