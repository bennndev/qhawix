import 'dart:async';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_geofence/native_geofence.dart';

import '../domain/safe_zone_config.dart';
import '../domain/safe_zone_engine.dart';
import '../domain/safe_zone_status.dart';
import 'refuge_sms.dart';
import 'safe_zone_file_store.dart';

/// Top-level background entry points for Refuge safe-zone monitoring.
///
/// Must stay top-level with `@pragma('vm:entry-point')` so alarm and geofence
/// isolates can find them after the UI process is dead.

final _store = SafeZoneFileStore();
final _notifications = FlutterLocalNotificationsPlugin();

Future<void> _emit(
  SafeZoneEventType type, {
  bool test = false,
  String? detail,
}) async {
  await _store.appendEvent(
    SafeZoneEvent(
      type: type,
      atMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
      test: test,
      detail: detail,
    ),
  );
}

Future<DeviceLocation?> _oneShotLocation() async {
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
  } on Object {
    return null;
  }
}

Future<void> _sendAlertSms(
  SafeZoneConfig config, {
  required bool test,
  String prefix = '',
}) async {
  final body = '$prefix${config.smsPreview}';
  var anySent = false;
  for (final r in config.recipients) {
    try {
      await sendRefugeSms(to: r.phone, message: body, background: true);
      anySent = true;
    } on Object catch (e) {
      await _emit(
        SafeZoneEventType.smsFailed,
        test: test,
        detail: e.toString(),
      );
    }
  }
  if (anySent) {
    await _emit(SafeZoneEventType.smsSent, test: test);
  }
  await Future<void>.delayed(
    Duration(seconds: SafeZoneLimits.smsStatusWaitSeconds),
  );
}

Future<void> _applyResult(
  SafeZoneEngineResult result, {
  required SafeZoneConfig config,
  bool test = false,
}) async {
  await _store.saveRuntime(result.state);
  if (result.event != null) {
    await _emit(result.event!, test: test, detail: result.detail);
  }
  switch (result.action) {
    case SafeZoneEngineAction.none:
      break;
    case SafeZoneEngineAction.scheduleMinAwayConfirm:
      final delay = Duration(minutes: config.minAwayMinutes);
      await AndroidAlarmManager.oneShot(
        delay,
        SafeZoneLimits.alarmMinAwayId,
        safeZoneAlarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
        params: const {'kind': 'min_away'},
      );
    case SafeZoneEngineAction.scheduleWindowOpen:
      final now = DateTime.now();
      final start = config.window.startMinute;
      var next = DateTime(
        now.year,
        now.month,
        now.day,
        start ~/ 60,
        start % 60,
      );
      if (!next.isAfter(now)) {
        next = next.add(Duration(minutes: SafeZoneLimits.minutesPerDay));
      }
      await AndroidAlarmManager.oneShotAt(
        next,
        SafeZoneLimits.alarmWindowOpenId,
        safeZoneAlarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
        params: const {'kind': 'window_open'},
      );
    case SafeZoneEngineAction.startCountdown:
      await _startCountdown(config, test: test);
    case SafeZoneEngineAction.sendSms:
      await _sendAlertSms(config, test: test);
  }
}

Future<void> _startCountdown(SafeZoneConfig config, {bool test = false}) async {
  await _emit(SafeZoneEventType.countdownStarted, test: test);
  await _notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  const android = AndroidNotificationDetails(
    'safe_zone_countdown',
    'QHAWIX',
    channelDescription: 'Acciones pendientes de QHAWIX',
    importance: Importance.high,
    priority: Priority.high,
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction(
        SafeZoneLimits.countdownCancelActionId,
        'Cancelar',
        showsUserInterface: true,
        cancelNotification: false,
      ),
    ],
  );
  await _notifications.show(
    id: SafeZoneLimits.countdownNotificationId,
    title: SafeZoneLimits.countdownNotificationTitle,
    body: SafeZoneLimits.countdownNotificationBody,
    notificationDetails: const NotificationDetails(android: android),
    payload: 'safe_zone_cancel',
  );
  await AndroidAlarmManager.oneShot(
    Duration(seconds: config.countdownSeconds),
    SafeZoneLimits.alarmCountdownId,
    safeZoneAlarmCallback,
    exact: true,
    wakeup: true,
    allowWhileIdle: true,
    rescheduleOnReboot: true,
    params: {'kind': 'countdown', 'test': test},
  );
}

Future<void> _confirmStillAway({bool test = false}) async {
  final config = await _store.loadConfig();
  if (config == null || !config.monitoringEnabled) return;
  final runtime = await _store.loadRuntime();
  final loc = await _oneShotLocation();
  final stillOutside = loc == null
      ? true
      : SafeZoneEngine.isOutsideHome(
          GeoPoint(lat: loc.lat, lng: loc.lng),
          config,
        );
  final result = SafeZoneEngine.onStillAwayConfirmed(
    config: config,
    state: runtime,
    localNow: DateTime.now(),
    stillOutside: stillOutside,
  );
  await _applyResult(result, config: config, test: test);
}

/// Alarm manager entry point (own isolate).
@pragma('vm:entry-point')
Future<void> safeZoneAlarmCallback(int id, Map<String, dynamic> params) async {
  DartPluginRegistrant.ensureInitialized();
  await AndroidAlarmManager.initialize();
  final kind = params['kind'] as String? ?? '';
  final test = params['test'] == true;
  final config = await _store.loadConfig();
  if (config == null) return;
  final runtime = await _store.loadRuntime();
  switch (kind) {
    case 'min_away':
      await _confirmStillAway(test: test);
    case 'window_open':
      await _emit(SafeZoneEventType.windowOpenedWhileAway, test: test);
      await _confirmStillAway(test: test);
    case 'countdown':
      final result = SafeZoneEngine.onCountdownEnded(
        config: config,
        state: runtime,
        localNow: DateTime.now(),
      );
      await _notifications.cancel(id: SafeZoneLimits.countdownNotificationId);
      await _applyResult(result, config: config, test: test);
  }
}

/// native_geofence entry point (fresh isolate; app may be dead).
@pragma('vm:entry-point')
Future<void> safeZoneGeofenceCallback(GeofenceCallbackParams params) async {
  DartPluginRegistrant.ensureInitialized();
  await AndroidAlarmManager.initialize();
  final config = await _store.loadConfig();
  if (config == null || !config.monitoringEnabled) return;
  final runtime = await _store.loadRuntime();
  final now = DateTime.now();
  if (params.event == GeofenceEvent.exit) {
    final result = SafeZoneEngine.onExit(
      config: config,
      state: runtime,
      localNow: now,
      nowMillis: now.toUtc().millisecondsSinceEpoch,
    );
    await _applyResult(result, config: config);
  } else if (params.event == GeofenceEvent.enter) {
    await AndroidAlarmManager.cancel(SafeZoneLimits.alarmMinAwayId);
    await AndroidAlarmManager.cancel(SafeZoneLimits.alarmWindowOpenId);
    await AndroidAlarmManager.cancel(SafeZoneLimits.alarmCountdownId);
    await _notifications.cancel(id: SafeZoneLimits.countdownNotificationId);
    final result = SafeZoneEngine.onEnter(state: runtime);
    await _applyResult(result, config: config);
  }
}

/// Registers or replaces the home geofence from the stored config.
Future<void> registerHomeGeofence(SafeZoneConfig config) async {
  await NativeGeofenceManager.instance.initialize();
  try {
    await NativeGeofenceManager.instance.removeGeofenceById(
      SafeZoneLimits.homeGeofenceId,
    );
  } on Object {
    // Nothing registered yet.
  }
  await NativeGeofenceManager.instance.createGeofence(
    Geofence(
      id: SafeZoneLimits.homeGeofenceId,
      location: Location(
        latitude: config.home.lat,
        longitude: config.home.lng,
      ),
      radiusMeters: config.radiusMeters.toDouble(),
      triggers: {GeofenceEvent.enter, GeofenceEvent.exit},
      iosSettings: const IosGeofenceSettings(initialTrigger: false),
      androidSettings: const AndroidGeofenceSettings(
        initialTriggers: {GeofenceEvent.enter},
      ),
    ),
    safeZoneGeofenceCallback,
  );
}

Future<void> removeHomeGeofence() async {
  try {
    await NativeGeofenceManager.instance.initialize();
    await NativeGeofenceManager.instance.removeGeofenceById(
      SafeZoneLimits.homeGeofenceId,
    );
  } on Object {
    // Ignore.
  }
  await AndroidAlarmManager.cancel(SafeZoneLimits.alarmMinAwayId);
  await AndroidAlarmManager.cancel(SafeZoneLimits.alarmWindowOpenId);
  await AndroidAlarmManager.cancel(SafeZoneLimits.alarmCountdownId);
}
