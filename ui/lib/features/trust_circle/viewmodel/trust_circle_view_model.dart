import 'package:flutter/foundation.dart';

import '../domain/action_result.dart';
import '../domain/alert_preferences.dart';
import '../domain/check_in.dart';
import '../domain/clock.dart';
import '../domain/refuge_request.dart';
import '../domain/sos.dart';
import '../domain/trust_circle_repository.dart';
import '../domain/trust_circle_snapshot.dart';
import '../domain/trust_contact.dart';

/// State and commands of the circle: contacts, preferences, SOS, check-in and
/// remote Refuge requests. The View reads immutable snapshots from here.
///
/// A response that arrives after a newer load has started is discarded, and a
/// command that is already running is not started twice (double tap).
class TrustCircleViewModel extends ChangeNotifier {
  TrustCircleViewModel({
    required TrustCircleRepository repository,
    required Clock clock,
  }) : _repository = repository,
       _clock = clock;

  final TrustCircleRepository _repository;
  final Clock _clock;

  TrustCircleSnapshot? _snapshot;
  bool _loading = false;
  bool _failed = false;
  bool _disposed = false;
  int _loadToken = 0;
  final Map<String, Future<ActionResult>> _running = {};

  TrustCircleSnapshot? get snapshot => _snapshot;
  bool get loading => _loading;
  bool get failed => _failed;

  List<TrustContact> get contacts => _snapshot?.contacts ?? const [];
  List<RefugeRequest> get pendingRequests =>
      _snapshot?.pendingRequests ?? const [];
  AlertPreferences get alertPreferences =>
      _snapshot?.alertPreferences ?? const AlertPreferences();
  CheckIn? get checkIn => _snapshot?.checkIn;
  bool get hasKeyword => _snapshot?.hasKeyword ?? false;

  /// Contacts that can receive something right now.
  List<TrustContact> get reachableContacts => [
    for (final c in contacts)
      if (c.isActive && c.permissions.receiveAlerts) c,
  ];

  CheckInStatus? get checkInStatus => checkIn?.statusAt(_clock);

  TrustContact? contactById(String id) => _snapshot?.contactById(id);

  Future<void> load() => _refresh(showLoading: true);

  Future<void> _refresh({bool showLoading = false}) async {
    final token = ++_loadToken;
    if (showLoading) {
      _loading = true;
      _failed = false;
      _notify();
    }
    try {
      final snapshot = await _repository.load();
      if (token != _loadToken) return;
      _snapshot = snapshot;
      _failed = false;
    } on Object {
      if (token != _loadToken) return;
      _failed = true;
    }
    _loading = false;
    _notify();
  }

  Future<ActionResult> _command(
    String key,
    Future<ActionResult> Function() run,
  ) {
    final existing = _running[key];
    if (existing != null) return existing;
    final future = () async {
      try {
        final result = await run();
        await _refresh();
        return result;
      } finally {
        _running.remove(key);
      }
    }();
    _running[key] = future;
    return future;
  }

  Future<ActionResult> inviteContact({
    required String name,
    required String phone,
  }) => _command(
    'invite',
    () => _repository.inviteContact(name: name, phone: phone),
  );

  Future<ActionResult> updatePermissions(
    String contactId,
    ContactPermissions permissions,
  ) => _command(
    'permissions:$contactId',
    () => _repository.updatePermissions(contactId, permissions),
  );

  Future<ActionResult> setContactFallback(
    String contactId,
    AlertChannel channel,
  ) => _command(
    'fallback:$contactId',
    () => _repository.setContactFallback(contactId, channel),
  );

  Future<ActionResult> setContactPaused(
    String contactId, {
    required bool paused,
  }) => _command(
    'pause:$contactId',
    () => _repository.setContactPaused(contactId, paused: paused),
  );

  Future<ActionResult> removeContact(String contactId) =>
      _command('remove:$contactId', () => _repository.removeContact(contactId));

  Future<ActionResult> setAlertRecipients(
    AlertEventKind kind,
    Set<String> contactIds,
  ) => _command(
    'alerts:${kind.name}',
    () => _repository.setAlertRecipients(kind, contactIds),
  );

  Future<ActionResult> setAlertFallback(AlertChannelChoice choice) =>
      _command('alert-fallback', () => _repository.setAlertFallback(choice));

  Future<ActionResult> sendSos({
    required Set<String> contactIds,
    required SosDuration duration,
  }) => _command(
    'sos',
    () => _repository.sendSos(contactIds: contactIds, duration: duration),
  );

  Future<ActionResult> startCheckIn(CheckInWindow window) =>
      _command('checkin-start', () => _repository.startCheckIn(window));

  Future<ActionResult> confirmCheckIn() =>
      _command('checkin-confirm', _repository.confirmCheckIn);

  Future<ActionResult> cancelCheckIn() =>
      _command('checkin-cancel', _repository.cancelCheckIn);

  Future<ActionResult> resolveRefugeRequest(
    String requestId, {
    required bool approve,
  }) => _command(
    'refuge:$requestId',
    () => _repository.resolveRefugeRequest(requestId, approve: approve),
  );

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
