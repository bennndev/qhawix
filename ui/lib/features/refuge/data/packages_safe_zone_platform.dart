import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/safe_zone_config.dart';
import '../domain/safe_zone_engine.dart';
import '../domain/safe_zone_error.dart';
import '../domain/safe_zone_platform.dart';
import '../domain/safe_zone_status.dart';
import 'refuge_sms.dart';
import 'safe_zone_background.dart';
import 'safe_zone_file_store.dart';

/// `SafeZonePlatform` over pub.dev packages (no custom Kotlin).
///
/// Proven on Honor via `spikes/safe_zone` with OEM auto-launch required.
class PackagesSafeZonePlatform implements SafeZonePlatform {
  PackagesSafeZonePlatform({
    SafeZoneFileStore? store,
    FlutterSecureStorage? secureStorage,
    bool? isAndroid,
  }) : _store = store ?? SafeZoneFileStore(),
       _secure = secureStorage ?? const FlutterSecureStorage(),
       _isAndroid =
           isAndroid ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  final SafeZoneFileStore _store;
  final FlutterSecureStorage _secure;
  final bool _isAndroid;
  final _events = StreamController<SafeZoneEvent>.broadcast();
  final _notifications = FlutterLocalNotificationsPlugin();
  final _picker = FlutterNativeContactPicker();
  var _initialized = false;

  static const _pinKey = 'safe_zone_cancel_pin';
  static const _pinSaltKey = 'safe_zone_cancel_pin_salt';
  static const testPrefix = 'Prueba: ';

  void _ensureAndroid() {
    if (!_isAndroid) {
      throw const UnavailableError('Not running on Android.');
    }
  }

  Future<void> ensureInitialized() async {
    if (_initialized || !_isAndroid) return;
    await AndroidAlarmManager.initialize();
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        // PIN cancel is handled by opening the cancel route from the app shell.
        if (response.actionId == SafeZoneLimits.countdownCancelActionId ||
            response.payload == 'safe_zone_cancel') {
          _events.add(
            SafeZoneEvent(
              type: SafeZoneEventType.countdownCancelled,
              atMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
              test: false,
              detail: 'notification_action',
            ),
          );
        }
      },
    );
    _initialized = true;
  }

  Future<void> _record(SafeZoneEvent event) async {
    await _store.appendEvent(event);
    if (!_events.isClosed) _events.add(event);
  }

  Future<SafePermissions> _readPermissions() async {
    final fine = await Permission.location.status;
    final always = await Permission.locationAlways.status;
    final sms = await Permission.sms.status;
    final notif = await Permission.notification.status;
    final battery = await Permission.ignoreBatteryOptimizations.status;
    return SafePermissions(
      fineLocation: fine.isGranted,
      backgroundLocation: always.isGranted,
      sendSms: sms.isGranted,
      notifications: notif.isGranted,
      batteryOptimizationIgnored: battery.isGranted,
    );
  }

  @override
  Future<SafeZoneStatus> getStatus() async {
    _ensureAndroid();
    await ensureInitialized();
    final runtime = await _store.loadRuntime();
    final rolled = SafeZoneEngine.rollDailyLimit(runtime, DateTime.now());
    if (rolled.sentTodayEpisodes != runtime.sentTodayEpisodes ||
        rolled.sentTodayLocalDate != runtime.sentTodayLocalDate) {
      await _store.saveRuntime(rolled);
    }
    return SafeZoneStatus(
      monitoring: (await _store.loadConfig())?.monitoringEnabled ?? false,
      playServicesAvailable: true,
      permissions: await _readPermissions(),
      sentTodayEpisodes: rolled.sentTodayEpisodes,
      awaySinceMillis: rolled.awaySinceMillis,
      lastEvent: await _store.lastEvent(),
    );
  }

  @override
  Future<void> saveConfig(SafeZoneConfig config) async {
    _ensureAndroid();
    await ensureInitialized();
    final pinSet = await hasCancelPin();
    final issues = config.issues(hasCancelPin: pinSet);
    if (issues.isNotEmpty) {
      throw InvalidConfigError(issues.map((e) => e.name).join(','));
    }
    await _store.saveConfig(config);
    if (config.monitoringEnabled) {
      // Same checks as startMonitoring (OEM auto-start + permissions).
      final runtime = await _store.loadRuntime();
      if (!runtime.autoStartConfirmed) {
        throw const PermissionMissingError('auto_start');
      }
      final missing = (await _readPermissions()).missingRequired(
        hasCountdown: config.hasCountdown,
      );
      if (missing.isNotEmpty) {
        throw PermissionMissingError(missing.map((e) => e.name).join(','));
      }
      await registerHomeGeofence(config);
    } else {
      await removeHomeGeofence();
    }
  }

  @override
  Future<SafeZoneConfig?> loadConfig() async {
    _ensureAndroid();
    return _store.loadConfig();
  }

  @override
  Future<void> startMonitoring() async {
    _ensureAndroid();
    await ensureInitialized();
    final config = await _store.loadConfig();
    if (config == null) {
      throw const InvalidConfigError('missing_config');
    }
    final runtime = await _store.loadRuntime();
    if (!runtime.autoStartConfirmed) {
      throw const PermissionMissingError('auto_start');
    }
    final status = await getStatus();
    final missing = status.permissions.missingRequired(
      hasCountdown: config.hasCountdown,
    );
    if (missing.isNotEmpty) {
      throw PermissionMissingError(missing.map((e) => e.name).join(','));
    }
    final enabled = config.copyWith(monitoringEnabled: true);
    await _store.saveConfig(enabled);
    await registerHomeGeofence(enabled);
    await _record(
      SafeZoneEvent(
        type: SafeZoneEventType.monitoringStarted,
        atMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
        test: false,
      ),
    );
  }

  @override
  Future<void> stopMonitoring() async {
    _ensureAndroid();
    await ensureInitialized();
    final config = await _store.loadConfig();
    if (config != null) {
      await _store.saveConfig(config.copyWith(monitoringEnabled: false));
    }
    await removeHomeGeofence();
    await _record(
      SafeZoneEvent(
        type: SafeZoneEventType.monitoringStopped,
        atMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
        test: false,
      ),
    );
  }

  @override
  Future<PermissionResult> requestPermission(PermissionKind kind) async {
    _ensureAndroid();
    final permission = switch (kind) {
      PermissionKind.fineLocation => Permission.location,
      PermissionKind.backgroundLocation => Permission.locationAlways,
      PermissionKind.sendSms => Permission.sms,
      PermissionKind.notifications => Permission.notification,
      PermissionKind.batteryOptimization =>
        Permission.ignoreBatteryOptimizations,
    };
    if (kind == PermissionKind.backgroundLocation) {
      final fine = await Permission.location.status;
      if (!fine.isGranted) {
        final first = await Permission.location.request();
        if (!first.isGranted) return PermissionResult.denied;
      }
      final after = await Permission.locationAlways.request();
      if (after.isGranted) return PermissionResult.granted;
      // Android 11+: usually needs the system settings page.
      await openAppSettings();
      return PermissionResult.openedSettings;
    }
    if (kind == PermissionKind.batteryOptimization) {
      final after = await permission.request();
      if (after.isGranted) return PermissionResult.granted;
      await openAppSettings();
      return PermissionResult.openedSettings;
    }
    final after = await permission.request();
    return after.isGranted ? PermissionResult.granted : PermissionResult.denied;
  }

  @override
  Future<void> setCancelPin(String pin) async {
    _ensureAndroid();
    if (!isValidCancelPin(pin)) {
      throw const InvalidArgumentError('pin');
    }
    final algo = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final secret = await algo.deriveKeyFromPassword(
      password: pin,
      nonce: salt,
    );
    final bytes = await secret.extractBytes();
    await _secure.write(key: _pinSaltKey, value: base64Encode(salt));
    await _secure.write(key: _pinKey, value: base64Encode(bytes));
  }

  /// Verifies the cancel PIN (UI cancel screen).
  Future<bool> verifyCancelPin(String pin) async {
    final saltB64 = await _secure.read(key: _pinSaltKey);
    final hashB64 = await _secure.read(key: _pinKey);
    if (saltB64 == null || hashB64 == null) return false;
    final algo = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    final secret = await algo.deriveKeyFromPassword(
      password: pin,
      nonce: base64Decode(saltB64),
    );
    final bytes = await secret.extractBytes();
    return base64Encode(bytes) == hashB64;
  }

  @override
  Future<bool> hasCancelPin() async {
    _ensureAndroid();
    final hash = await _secure.read(key: _pinKey);
    return hash != null && hash.isNotEmpty;
  }

  @override
  Future<DeviceLocation> currentLocation() async {
    _ensureAndroid();
    final perm = await Permission.location.status;
    if (!perm.isGranted) {
      throw const PermissionMissingError('fineLocation');
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: SafeZoneLimits.locationTimeoutSeconds),
        ),
      );
      return DeviceLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        accuracyMeters: pos.accuracy,
      );
    } on Object catch (e) {
      throw FailedError(e.toString());
    }
  }

  @override
  Future<PickedContact?> pickContact() async {
    _ensureAndroid();
    final picked = await _picker.selectPhoneNumber();
    if (picked == null) return null;
    final phone = picked.selectedPhoneNumber?.trim() ?? '';
    if (phone.isEmpty) return null;
    final name = picked.fullName?.trim() ?? '';
    return PickedContact(name: name.isEmpty ? phone : name, phone: phone);
  }

  @override
  Future<List<TestSendResult>> sendTestMessage() async {
    _ensureAndroid();
    final config = await _store.loadConfig();
    if (config == null || config.recipients.isEmpty) {
      throw const InvalidConfigError('recipients');
    }
    final sms = await Permission.sms.status;
    if (!sms.isGranted) {
      return [
        for (final r in config.recipients)
          TestSendResult(
            phone: r.phone,
            outcome: SendOutcome.permissionDenied,
          ),
      ];
    }
    final results = <TestSendResult>[];
    final body = '$testPrefix${config.smsPreview}';
    for (final r in config.recipients) {
      try {
        await sendRefugeSms(to: r.phone, message: body);
        results.add(TestSendResult(phone: r.phone, outcome: SendOutcome.sent));
      } on Object catch (e) {
        results.add(
          TestSendResult(
            phone: r.phone,
            outcome: SendOutcome.failed,
            detail: e.toString(),
          ),
        );
      }
    }
    await _record(
      SafeZoneEvent(
        type: results.any((r) => r.outcome == SendOutcome.sent)
            ? SafeZoneEventType.smsSent
            : SafeZoneEventType.smsFailed,
        atMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
        test: true,
      ),
    );
    return results;
  }

  @override
  Future<void> runEndToEndTest() async {
    _ensureAndroid();
    await ensureInitialized();
    final config = await _store.loadConfig();
    if (config == null) throw const InvalidConfigError('missing_config');
    final runtime = await _store.loadRuntime();
    final now = DateTime.now();
    // Bypass zone/window: treat as a confirmed away episode for the test path.
    final forced = runtime.copyWith(
      awaySinceMillis: now.toUtc().millisecondsSinceEpoch,
      alertedThisEpisode: false,
      countdownActive: false,
      countdownCancelled: false,
    );
    await _store.saveRuntime(forced);
    final result = SafeZoneEngine.onStillAwayConfirmed(
      config: config.copyWith(mode: AlertMode.awayAnytime, minAwayMinutes: 0),
      state: forced,
      localNow: now,
      stillOutside: true,
    );
    // Reuse background apply by scheduling the same actions here.
    if (result.event != null) {
      await _record(
        SafeZoneEvent(
          type: result.event!,
          atMillis: now.toUtc().millisecondsSinceEpoch,
          test: true,
          detail: result.detail,
        ),
      );
    }
    await _store.saveRuntime(result.state);
    switch (result.action) {
      case SafeZoneEngineAction.startCountdown:
        await AndroidAlarmManager.oneShot(
          Duration(seconds: config.countdownSeconds),
          SafeZoneLimits.alarmCountdownId,
          safeZoneAlarmCallback,
          exact: true,
          wakeup: true,
          allowWhileIdle: true,
          rescheduleOnReboot: true,
          params: const {'kind': 'countdown', 'test': true},
        );
        await _record(
          SafeZoneEvent(
            type: SafeZoneEventType.countdownStarted,
            atMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
            test: true,
          ),
        );
      case SafeZoneEngineAction.sendSms:
        await sendTestMessage();
      case SafeZoneEngineAction.none:
      case SafeZoneEngineAction.scheduleMinAwayConfirm:
      case SafeZoneEngineAction.scheduleWindowOpen:
        break;
    }
  }

  @override
  Future<bool> cancelCountdown() async {
    _ensureAndroid();
    await ensureInitialized();
    final runtime = await _store.loadRuntime();
    final next = SafeZoneEngine.onCountdownCancelled(state: runtime);
    await _store.saveRuntime(next.state);
    await AndroidAlarmManager.cancel(SafeZoneLimits.alarmCountdownId);
    await _notifications.cancel(id: SafeZoneLimits.countdownNotificationId);
    if (next.event != null) {
      await _record(
        SafeZoneEvent(
          type: next.event!,
          atMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
          test: false,
        ),
      );
    }
    return true;
  }

  /// Marks that the person confirmed OEM auto-start settings.
  @override
  Future<void> confirmAutoStart() async {
    _ensureAndroid();
    final runtime = await _store.loadRuntime();
    await _store.saveRuntime(runtime.copyWith(autoStartConfirmed: true));
  }

  @override
  Future<bool> isAutoStartConfirmed() async {
    _ensureAndroid();
    return (await _store.loadRuntime()).autoStartConfirmed;
  }

  @override
  Stream<SafeZoneEvent> get events => _events.stream;
}
