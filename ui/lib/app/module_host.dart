import 'package:flutter/material.dart';

import '../core/theme/theme_extensions.dart';
import '../core/widgets/page_header.dart';
import '../core/widgets/qhawix_app_bar.dart';
import '../core/widgets/qhawix_buttons.dart';
import '../core/widgets/status_banner.dart';
import '../features/aura/view/aura_screen.dart';
import '../features/echotrap/view/echotrap_screen.dart';
import '../features/privacy/view/privacy_screen.dart';
import '../features/qr_shield/view/qr_shield_screen.dart';
import '../features/sentinel/view/sentinel_screen.dart';
import 'module_catalog.dart';

/// Resolves a catalog entry to its feature screen (stub or real).
Widget moduleScreenFor(ModuleCatalogEntry entry) {
  switch (entry.id) {
    case AppModuleId.sentinel:
      return const SentinelScreen();
    case AppModuleId.qrShield:
      return const QrShieldScreen();
    case AppModuleId.echoTrap:
      return const EchoTrapScreen();
    case AppModuleId.aura:
      return const AuraScreen();
    case AppModuleId.privacy:
      return const PrivacyScreen();
    case AppModuleId.trustCircle:
    case AppModuleId.logbook:
      return ModulePlaceholderScreen(entry: entry);
  }
}

/// Fallback when a tab-owned module is opened via `/m/...` by mistake.
class ModulePlaceholderScreen extends StatelessWidget {
  const ModulePlaceholderScreen({super.key, required this.entry});

  final ModuleCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    return Scaffold(
      appBar: QhawixAppBar(title: entry.name),
      body: SafeArea(
        child: Padding(
          padding: space.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(title: entry.name, subtitle: entry.purpose),
              const StatusBanner(
                message: 'Usa la pestaña de la barra inferior.',
              ),
              const Spacer(),
              SecondaryButton(
                label: 'Volver',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
