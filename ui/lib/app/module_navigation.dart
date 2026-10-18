import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'module_activation_store.dart';
import 'module_catalog.dart';

/// Opens a module: own onboarding / tab, activation gate, or destination.
void openModule(BuildContext context, ModuleCatalogEntry entry) {
  final store = context.read<ModuleActivationStore>();
  if (entry.skipActivationGate || entry.usesOwnOnboarding) {
    context.go(entry.routePath);
    return;
  }
  if (!store.isActivated(entry.id)) {
    context.push('/m/${ModuleCatalog.slugFor(entry.id)}/onboarding');
    return;
  }
  context.push(entry.routePath);
}
