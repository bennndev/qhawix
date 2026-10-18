import 'package:flutter/foundation.dart';

import '../domain/action_result.dart';
import '../domain/trust_circle_repository.dart';

/// The shared family keyword. It is hidden by default and only shown after an
/// explicit [reveal]; leaving the screen should call [hide].
class FamilyKeywordViewModel extends ChangeNotifier {
  FamilyKeywordViewModel({required TrustCircleRepository repository})
    : _repository = repository;

  final TrustCircleRepository _repository;

  String? _keyword;
  bool _loaded = false;
  bool _revealed = false;
  bool _disposed = false;
  int _token = 0;

  /// Null until loaded or when no keyword exists yet.
  String? get keyword => _keyword;
  bool get loaded => _loaded;
  bool get hasKeyword => _keyword != null;
  bool get revealed => _revealed;

  Future<void> load() async {
    final token = ++_token;
    final value = await _repository.readKeyword();
    if (token != _token) return;
    _keyword = value;
    _loaded = true;
    _notify();
  }

  void reveal() {
    if (!hasKeyword || _revealed) return;
    _revealed = true;
    _notify();
  }

  void hide() {
    if (!_revealed) return;
    _revealed = false;
    _notify();
  }

  /// Creates or changes the keyword; it goes back to hidden afterwards.
  Future<ActionResult> save(String keyword) async {
    final token = ++_token;
    final result = await _repository.saveKeyword(keyword);
    if (token != _token || result.isRejected) return result;
    _keyword = keyword.trim();
    _revealed = false;
    _notify();
    return result;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
