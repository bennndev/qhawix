import 'package:flutter/foundation.dart';

/// App-state flag for the discreet appearance (a presentation mode, not a
/// third theme). Feed it to `AppTheme.light(discreet: ...)` and
/// `AppTheme.dark(discreet: ...)`; switching is instant and silent.
class DiscreetAppearance extends ChangeNotifier {
  DiscreetAppearance({bool enabled = false}) : _enabled = enabled;

  bool _enabled;

  bool get enabled => _enabled;

  set enabled(bool value) {
    if (value == _enabled) return;
    _enabled = value;
    notifyListeners();
  }
}
