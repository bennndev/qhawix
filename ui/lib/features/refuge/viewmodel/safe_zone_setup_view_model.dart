import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/alert_recipient_source.dart';
import '../domain/safe_zone_config.dart';
import '../domain/safe_zone_error.dart';
import '../domain/safe_zone_platform.dart';
import '../domain/safe_zone_status.dart';
import 'command_note.dart';

/// Steps of the setup wizard, in order. The same wizard edits an existing
/// configuration: the hub opens it at the step to change.
enum SetupStep {
  intro,
  recipients,
  home,
  parameters,
  sending,
  permissions,
  autoStart,
  review,
}

/// A command the wizard can be running. At most one at a time.
enum SetupCommand { locate, permission, pin, autoStart, sendTest, finish }

/// Draft of the configuration plus the commands to complete it. Used by the
/// onboarding and by the settings edit. Real platform calls, nothing mocked.
class SafeZoneSetupViewModel extends ChangeNotifier {
  SafeZoneSetupViewModel({
    required SafeZonePlatform platform,
    required AlertRecipientSource recipientSource,
    SetupStep initialStep = SetupStep.intro,
  }) : _platform = platform,
       _recipientSource = recipientSource,
       _step = initialStep;

  final SafeZonePlatform _platform;
  final AlertRecipientSource _recipientSource;
  int _revision = 0;
  bool _disposed = false;

  SetupStep _step;
  bool _loading = true;
  bool _unavailable = false;
  SafeZoneStatus? _status;
  bool _pinSet = false;
  bool _autoStartConfirmed = false;
  List<AlertRecipient> _available = const [];
  final Set<String> _selectedPhones = {};

  String _ownerName = '';
  GeoPoint? _home;
  double? _homeAccuracy;
  int _radiusMeters = SafeZoneLimits.defaultRadiusMeters;
  int _windowStart = SafeZoneLimits.defaultWindowStartMinute;
  int _windowEnd = SafeZoneLimits.defaultWindowEndMinute;
  AlertMode _mode = AlertMode.awayDuringWindow;
  int _minAway = SafeZoneLimits.defaultMinAwayMinutes;
  int _countdown = SafeZoneLimits.defaultCountdownSeconds;
  int _dailyLimit = SafeZoneLimits.defaultDailyLimit;
  String _message = SafeZoneLimits.defaultMessage;

  SetupCommand? _running;
  CommandNote? _note;
  List<TestSendResult> _testResults = const [];
  bool _finished = false;

  // -- reads ---------------------------------------------------------------

  SetupStep get step => _step;
  bool get loading => _loading;
  bool get unavailable => _unavailable;
  SafeZoneStatus? get status => _status;
  SafePermissions get permissions =>
      _status?.permissions ?? const SafePermissions.none();
  bool get monitoringNow => _status?.monitoring ?? false;
  bool get pinSet => _pinSet;
  bool get autoStartConfirmed => _autoStartConfirmed;
  List<AlertRecipient> get availableRecipients => _available;
  Set<String> get selectedPhones => Set.unmodifiable(_selectedPhones);
  String get ownerName => _ownerName;
  GeoPoint? get home => _home;
  double? get homeAccuracyMeters => _homeAccuracy;
  int get radiusMeters => _radiusMeters;
  AlertWindow get window =>
      AlertWindow(startMinute: _windowStart, endMinute: _windowEnd);
  AlertMode get mode => _mode;
  int get minAwayMinutes => _minAway;
  int get countdownSeconds => _countdown;
  int get dailyLimit => _dailyLimit;
  String get message => _message;
  SetupCommand? get running => _running;
  bool get busy => _running != null;
  CommandNote? get note => _note;
  List<TestSendResult> get testResults => _testResults;

  /// True once the config was saved and monitoring runs (or the edit saved).
  bool get finished => _finished;

  List<AlertRecipient> get selectedRecipients => [
    for (final r in _available)
      if (_selectedPhones.contains(r.phone)) r,
  ];

  /// The draft as a config. Home may be missing: it then reports
  /// [ConfigIssue.home] instead of being invented.
  SafeZoneConfig draftConfig({bool monitoringEnabled = true}) => SafeZoneConfig(
    monitoringEnabled: monitoringEnabled,
    ownerName: _ownerName,
    home: _home ?? const GeoPoint(lat: double.nan, lng: double.nan),
    radiusMeters: _radiusMeters,
    window: window,
    mode: _mode,
    minAwayMinutes: _minAway,
    countdownSeconds: _countdown,
    dailyLimit: _dailyLimit,
    message: _message,
    recipients: selectedRecipients,
  );

  List<ConfigIssue> get allIssues =>
      draftConfig().issues(hasCancelPin: _pinSet);

  /// The issues that block leaving [step].
  List<ConfigIssue> issuesFor(SetupStep step) {
    final relevant = switch (step) {
      SetupStep.recipients => const {
        ConfigIssue.ownerName,
        ConfigIssue.recipientsMissing,
        ConfigIssue.recipientsTooMany,
      },
      SetupStep.home => const {ConfigIssue.home},
      SetupStep.parameters => const {
        ConfigIssue.radius,
        ConfigIssue.window,
        ConfigIssue.windowIsAlways,
        ConfigIssue.minAway,
      },
      SetupStep.sending => const {
        ConfigIssue.countdown,
        ConfigIssue.dailyLimit,
        ConfigIssue.message,
        ConfigIssue.pinRequired,
      },
      SetupStep.intro ||
      SetupStep.permissions ||
      SetupStep.autoStart ||
      SetupStep.review => const <ConfigIssue>{},
    };
    return [
      for (final issue in allIssues)
        if (relevant.contains(issue)) issue,
    ];
  }

  bool get canAdvance => issuesFor(_step).isEmpty;

  /// Permissions monitoring cannot start without, given the draft countdown.
  List<PermissionKind> get missingRequired =>
      permissions.missingRequired(hasCountdown: _countdown > 0);

  /// Whether "Iniciar monitoreo" may run.
  bool get canStart =>
      allIssues.isEmpty && missingRequired.isEmpty && _autoStartConfirmed;

  // -- navigation ----------------------------------------------------------

  void next() {
    if (!canAdvance || _step == SetupStep.review) return;
    _step = SetupStep.values[_step.index + 1];
    _notify();
  }

  void back() {
    if (_step == SetupStep.intro) return;
    _step = SetupStep.values[_step.index - 1];
    _notify();
  }

  void goTo(SetupStep step) {
    _step = step;
    _notify();
  }

  // -- draft edits ---------------------------------------------------------

  void setOwnerName(String value) => _edit(() => _ownerName = value);

  void toggleRecipient(String phone) => _edit(() {
    if (!_selectedPhones.remove(phone)) _selectedPhones.add(phone);
  });

  void setRadius(int meters) => _edit(() => _radiusMeters = meters);

  void setWindowStart(int minute) => _edit(() => _windowStart = minute);

  void setWindowEnd(int minute) => _edit(() => _windowEnd = minute);

  void setMode(AlertMode mode) => _edit(() => _mode = mode);

  void setMinAway(int minutes) => _edit(() => _minAway = minutes);

  void setCountdown(int seconds) => _edit(() => _countdown = seconds);

  void setDailyLimit(int limit) => _edit(() => _dailyLimit = limit);

  void setMessage(String value) => _edit(() => _message = value);

  /// Manual alternative to the GPS. False when the coordinates are invalid.
  bool setHomeManually(double lat, double lng) {
    final point = GeoPoint(lat: lat, lng: lng);
    if (!point.isValid) return false;
    _edit(() {
      _home = point;
      _homeAccuracy = null;
    });
    return true;
  }

  void dismissNote() {
    if (_note == null) return;
    _note = null;
    _notify();
  }

  // -- reads from the platform ---------------------------------------------

  /// Loads the stored config (to edit it), the PIN flag, the status and the
  /// recipient candidates.
  Future<void> load() async {
    final revision = ++_revision;
    try {
      final status = await _platform.getStatus();
      final stored = await _platform.loadConfig();
      final pinSet = await _platform.hasCancelPin();
      final autoStart = await _platform.isAutoStartConfirmed();
      final candidates = await _recipientSource.activeRecipients();
      if (_stale(revision)) return;
      _status = status;
      _pinSet = pinSet;
      _autoStartConfirmed = autoStart;
      _available = candidates;
      if (stored != null) _prefill(stored);
    } on UnavailableError {
      if (_stale(revision)) return;
      _unavailable = true;
    } on SafeZoneError {
      if (_stale(revision)) return;
      _note = const CommandNote.problem(
        'No se pudo leer la configuración. Inténtalo otra vez.',
      );
    }
    _loading = false;
    _notify();
  }

  /// Re-reads the status only. Called when the app resumes, because the
  /// settings page of background location returns without a result.
  Future<void> refreshStatus() async {
    final revision = ++_revision;
    try {
      final status = await _platform.getStatus();
      if (_stale(revision)) return;
      _status = status;
      _notify();
    } on SafeZoneError {
      // Keep what is shown; the next resume tries again.
    }
  }

  void _prefill(SafeZoneConfig c) {
    _ownerName = c.ownerName;
    _home = c.home;
    _radiusMeters = c.radiusMeters;
    _windowStart = c.window.startMinute;
    _windowEnd = c.window.endMinute;
    _mode = c.mode;
    _minAway = c.minAwayMinutes;
    _countdown = c.countdownSeconds;
    _dailyLimit = c.dailyLimit;
    _message = c.message;
    // Stored recipients that are no longer Trust Circle candidates stay
    // visible and selected, so editing never drops them silently.
    final known = {for (final r in _available) r.phone};
    _available = [
      ..._available,
      for (final r in c.recipients)
        if (!known.contains(r.phone)) r,
    ];
    _selectedPhones
      ..clear()
      ..addAll(c.recipients.map((r) => r.phone));
  }

  // -- commands ------------------------------------------------------------

  Future<void> useCurrentLocation() => _command(SetupCommand.locate, () async {
    final location = await _platform.currentLocation();
    _home = GeoPoint(lat: location.lat, lng: location.lng);
    _homeAccuracy = location.accuracyMeters;
    return null;
  });

  Future<void> confirmAutoStart() => _command(SetupCommand.autoStart, () async {
    await _platform.confirmAutoStart();
    _autoStartConfirmed = true;
    return const CommandNote.ok(
      'Quedó registrado que activaste el inicio automático en este teléfono.',
    );
  });

  Future<void> requestPermission(PermissionKind kind) =>
      _command(SetupCommand.permission, () async {
        final result = await _platform.requestPermission(kind);
        try {
          _status = await _platform.getStatus();
        } on SafeZoneError {
          // Keep the previous status; resume re-reads it.
        }
        return switch (result) {
          PermissionResult.granted => null,
          PermissionResult.denied => const CommandNote.problem(
            'El permiso no se concedió. Puedes seguir y concederlo después, '
            'pero el monitoreo no empezará sin él.',
          ),
          PermissionResult.openedSettings => const CommandNote.ok(
            'Elige la opción en los ajustes del sistema y vuelve a QHAWIX.',
          ),
        };
      });

  /// Saves the cancel PIN. Native keeps only a salted hash.
  Future<void> savePin(String pin, String confirmation) =>
      _command(SetupCommand.pin, () async {
        if (!isValidCancelPin(pin)) {
          return const CommandNote.problem(
            'El PIN debe tener entre 4 y 8 dígitos.',
          );
        }
        if (pin != confirmation) {
          return const CommandNote.problem('Los dos PIN no coinciden.');
        }
        await _platform.setCancelPin(pin);
        _pinSet = true;
        return const CommandNote.ok('PIN guardado en este teléfono.');
      });

  /// Stores the draft (without changing whether monitoring runs) and sends a
  /// real SMS test. The caller confirms with the person first.
  Future<void> sendTestMessage() => _command(SetupCommand.sendTest, () async {
    if (allIssues.any((i) => i != ConfigIssue.pinRequired) ||
        selectedRecipients.isEmpty) {
      return const CommandNote.problem(
        'Completa los pasos anteriores antes de enviar una prueba.',
      );
    }
    await _platform.saveConfig(draftConfig(monitoringEnabled: monitoringNow));
    _testResults = await _platform.sendTestMessage();
    return null;
  });

  /// Saves the config and makes sure monitoring runs.
  Future<void> finish() => _command(SetupCommand.finish, () async {
    if (!canStart) {
      return const CommandNote.problem(
        'Faltan datos o permisos obligatorios para iniciar el monitoreo.',
      );
    }
    if (monitoringNow) {
      await _platform.saveConfig(draftConfig());
    } else {
      await _platform.saveConfig(draftConfig(monitoringEnabled: false));
      await _platform.startMonitoring();
      await _platform.saveConfig(draftConfig());
    }
    _finished = true;
    return null;
  });

  /// Runs one command at a time; a second tap while one runs does nothing.
  Future<void> _command(
    SetupCommand command,
    Future<CommandNote?> Function() body,
  ) async {
    if (_running != null) return;
    _running = command;
    _note = null;
    _notify();
    CommandNote? note;
    try {
      note = await body();
    } on PermissionMissingError catch (e) {
      note = CommandNote.problem(
        e.message == 'auto_start'
            ? 'Confirma el inicio automático en el paso anterior antes de activar.'
            : 'Falta un permiso. Concédelo e inténtalo otra vez.',
      );
    } on InvalidConfigError {
      note = const CommandNote.problem(
        'Android rechazó la configuración. Revisa los datos.',
      );
    } on UnavailableError {
      note = const CommandNote.problem(
        'Esta función no está disponible en este dispositivo.',
      );
    } on SafeZoneError {
      note = const CommandNote.problem(
        'No se pudo completar la acción. Inténtalo otra vez.',
      );
    }
    _running = null;
    _note = note;
    _notify();
  }

  void _edit(VoidCallback change) {
    change();
    _notify();
  }

  bool _stale(int revision) => _disposed || revision != _revision;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
