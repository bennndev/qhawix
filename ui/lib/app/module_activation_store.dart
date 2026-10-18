import 'package:flutter/foundation.dart';

import 'module_catalog.dart';

/// Remembers which modules finished the generic activation onboarding.
///
/// In-memory only for this shell slice: a process restart asks again. Refuge
/// and Red use their own persistence and skip this gate.
class ModuleActivationStore extends ChangeNotifier {
  final Set<AppModuleId> _activated = {};

  bool isActivated(AppModuleId id) => _activated.contains(id);

  void markActivated(AppModuleId id) {
    if (_activated.add(id)) notifyListeners();
  }

  @visibleForTesting
  void resetForTest() {
    _activated.clear();
    notifyListeners();
  }
}
