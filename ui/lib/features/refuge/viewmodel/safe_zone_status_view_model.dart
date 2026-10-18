import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/safe_zone_config.dart';
import '../domain/safe_zone_error.dart';
import '../domain/safe_zone_platform.dart';
import '../domain/safe_zone_status.dart';
import 'command_note.dart';

/// What the hub is doing right now. At most one command runs at a time.
enum StatusCommand { stop, resume, sendTest, endToEnd, requestPermission }

/// State of the safe-zone hub: monitoring, permission health, configuration
/// and the event history. Real data from the platform port, never mocked.
class SafeZoneStatusViewModel extends ChangeNotifier {
  SafeZoneStatusViewModel({required SafeZonePlatform platform})
    : _platform = platform;

  /// History cap, the same as the 50 events native persists.
  static const maxEvents = 50;

  final SafeZonePlatform _platform;
  StreamSubscription<SafeZoneEvent>? _subscription;
  int _revision = 0;
  bool _disposed = false;

  bool _loading = true;
  bool _unavailable = false;
  SafeZoneError? _error;
  SafeZoneConfig? _config;
  SafeZoneStatus? _status;
  final List<SafeZoneEvent> _events = [];
  StatusCommand? _running;
  CommandNote? _note;
  List<TestSendResult> _testResults = const [];

  bool get loading => _loading;

  /// This device cannot run the feature (not Android, or native said so).
  bool get unavailable => _unavailable;

  /// A failure other than "unavailable" while reading.
  SafeZoneError? get error => _error;

  /// Null while nothing is configured: the entry is the onboarding.
  SafeZoneConfig? get config => _config;
  SafeZoneStatus? get status => _status;
  bool get configured => _config != null;
  bool get monitoring => _status?.monitoring ?? false;
  StatusCommand? get running => _running;
  bool get busy => _running != null;
  CommandNote? get note => _note;
  List<TestSendResult> get testResults => _testResults;

  /// Newest first. Only events seen while the app was alive plus the last one
  /// native stored: the contract has no history call in v1.
  List<SafeZoneEvent> get events => List.unmodifiable(_events);

  /// Reads status and config, and (once) starts listening to events. Called on
  /// start and every time the app resumes, because the system settings page of
  /// background location returns without a result.
  Future<void> load() async {
    final revision = ++_revision;
    _subscription ??= _platform.events.listen(_onEvent, onError: (_) {});
    try {
      final status = await _platform.getStatus();
      final config = await _platform.loadConfig();
      if (_stale(revision)) return;
      _status = status;
      _config = config;
      _error = null;
      _unavailable = false;
      final last = status.lastEvent;
      if (last != null) _addEvent(last);
    } on UnavailableError {
      if (_stale(revision)) return;
      _unavailable = true;
    } on SafeZoneError catch (e) {
      if (_stale(revision)) return;
      _error = e;
    }
    _loading = false;
    _notify();
  }

  /// Same as [load] but keeps the screen content while it runs.
  Future<void> refresh() => load();

  Future<void> requestPermission(PermissionKind kind) =>
      _command(StatusCommand.requestPermission, () async {
        final result = await _platform.requestPermission(kind);
        return switch (result) {
          PermissionResult.granted => null,
          PermissionResult.denied => const CommandNote.problem(
            'El permiso no se concedió. Puedes intentarlo otra vez.',
          ),
          PermissionResult.openedSettings => const CommandNote.ok(
            'Elige la opción en los ajustes del sistema y vuelve a QHAWIX.',
          ),
        };
      });

  Future<void> stopMonitoring() => _command(StatusCommand.stop, () async {
    await _platform.stopMonitoring();
    return const CommandNote.ok('Monitoreo detenido.');
  });

  Future<void> resumeMonitoring() => _command(StatusCommand.resume, () async {
    await _platform.startMonitoring();
    return const CommandNote.ok('Monitoreo iniciado.');
  });

  /// Sends a real SMS to every stored recipient. The caller confirms first.
  Future<void> sendTestMessage() => _command(StatusCommand.sendTest, () async {
    _testResults = await _platform.sendTestMessage();
    return null;
  });

  /// Runs the full pipeline with a real SMS. The caller confirms first.
  Future<void> runEndToEndTest() => _command(StatusCommand.endToEnd, () async {
    await _platform.runEndToEndTest();
    return const CommandNote.ok(
      'Proceso de prueba iniciado. Si tienes cuenta regresiva, aparecerá una '
      'notificación; el SMS es real.',
    );
  });

  void dismissNote() {
    if (_note == null) return;
    _note = null;
    _notify();
  }

  /// Runs one command at a time; a second tap while one runs does nothing.
  Future<void> _command(
    StatusCommand command,
    Future<CommandNote?> Function() body,
  ) async {
    if (_running != null) return;
    _running = command;
    _note = null;
    _notify();
    CommandNote? note;
    try {
      note = await body();
    } on SafeZoneError catch (e) {
      note = CommandNote.problem(_describe(e));
    }
    _running = null;
    _note = note;
    _notify();
    // The result of any command can change monitoring or permissions.
    unawaited(load());
  }

  static String _describe(SafeZoneError e) => switch (e) {
    UnavailableError() =>
      'Esta función no está disponible en este dispositivo.',
    PermissionMissingError() =>
      'Faltan permisos. Revisa la lista de permisos y concédelos.',
    InvalidConfigError() =>
      'La configuración no es válida. Edítala y vuelve a intentarlo.',
    InvalidArgumentError() ||
    FailedError() => 'No se pudo completar la acción. Inténtalo otra vez.',
  };

  void _onEvent(SafeZoneEvent event) {
    _addEvent(event);
    _notify();
    // An event can mean monitoring or permissions changed.
    unawaited(load());
  }

  void _addEvent(SafeZoneEvent event) {
    if (_events.contains(event)) return;
    _events.add(event);
    _events.sort((a, b) => b.atMillis.compareTo(a.atMillis));
    if (_events.length > maxEvents) {
      _events.removeRange(maxEvents, _events.length);
    }
  }

  bool _stale(int revision) => _disposed || revision != _revision;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
