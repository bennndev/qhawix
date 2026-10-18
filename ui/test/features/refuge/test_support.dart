import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qhawix/core/theme/app_theme.dart';
import 'package:qhawix/features/refuge/domain/alert_recipient_source.dart';
import 'package:qhawix/features/refuge/domain/clock.dart';
import 'package:qhawix/features/refuge/domain/safe_zone_config.dart';
import 'package:qhawix/features/refuge/domain/safe_zone_error.dart';
import 'package:qhawix/features/refuge/domain/safe_zone_platform.dart';
import 'package:qhawix/features/refuge/domain/safe_zone_status.dart';
import 'package:qhawix/features/refuge/refuge_providers.dart';

/// Fake of the platform port. Used only in tests: the app never ships it.
class FakeSafeZonePlatform implements SafeZonePlatform {
  FakeSafeZonePlatform({
    this.status = const SafeZoneStatus(
      monitoring: false,
      playServicesAvailable: true,
      permissions: SafePermissions.none(),
      sentTodayEpisodes: 0,
    ),
    this.config,
    this.pinSet = false,
  });

  SafeZoneStatus status;
  SafeZoneConfig? config;
  bool pinSet;
  SafeZoneError? failWith;
  DeviceLocation location = const DeviceLocation(
    lat: -12.0464,
    lng: -77.0428,
    accuracyMeters: 18,
  );
  PermissionResult permissionAnswer = PermissionResult.granted;
  List<TestSendResult> testResults = const [];
  Completer<void>? holdSaveConfig;
  final calls = <String>[];
  final saved = <SafeZoneConfig>[];
  final _events = StreamController<SafeZoneEvent>.broadcast();

  void emit(SafeZoneEvent event) => _events.add(event);

  SafeZoneStatus _withPermission(PermissionKind kind) {
    final p = status.permissions;
    return SafeZoneStatus(
      monitoring: status.monitoring,
      playServicesAvailable: status.playServicesAvailable,
      permissions: SafePermissions(
        fineLocation: kind == PermissionKind.fineLocation || p.fineLocation,
        backgroundLocation:
            kind == PermissionKind.backgroundLocation || p.backgroundLocation,
        sendSms: kind == PermissionKind.sendSms || p.sendSms,
        notifications: kind == PermissionKind.notifications || p.notifications,
        batteryOptimizationIgnored:
            kind == PermissionKind.batteryOptimization ||
            p.batteryOptimizationIgnored,
      ),
      sentTodayEpisodes: status.sentTodayEpisodes,
      awaySinceMillis: status.awaySinceMillis,
      lastEvent: status.lastEvent,
    );
  }

  SafeZoneStatus _withMonitoring(bool on) => SafeZoneStatus(
    monitoring: on,
    playServicesAvailable: status.playServicesAvailable,
    permissions: status.permissions,
    sentTodayEpisodes: status.sentTodayEpisodes,
    awaySinceMillis: status.awaySinceMillis,
    lastEvent: status.lastEvent,
  );

  void _check(String call) {
    calls.add(call);
    final error = failWith;
    if (error != null) throw error;
  }

  @override
  Future<SafeZoneStatus> getStatus() async {
    _check('getStatus');
    return status;
  }

  @override
  Future<void> saveConfig(SafeZoneConfig config) async {
    _check('saveConfig');
    await holdSaveConfig?.future;
    saved.add(config);
    this.config = config;
  }

  @override
  Future<SafeZoneConfig?> loadConfig() async {
    _check('loadConfig');
    return config;
  }

  @override
  Future<void> startMonitoring() async {
    _check('startMonitoring');
    status = _withMonitoring(true);
  }

  @override
  Future<void> stopMonitoring() async {
    _check('stopMonitoring');
    status = _withMonitoring(false);
  }

  @override
  Future<PermissionResult> requestPermission(PermissionKind kind) async {
    _check('requestPermission:${kind.name}');
    if (permissionAnswer == PermissionResult.granted) {
      status = _withPermission(kind);
    }
    return permissionAnswer;
  }

  @override
  Future<void> setCancelPin(String pin) async {
    _check('setCancelPin');
    pinSet = true;
  }

  @override
  Future<bool> hasCancelPin() async {
    _check('hasCancelPin');
    return pinSet;
  }

  @override
  Future<DeviceLocation> currentLocation() async {
    _check('currentLocation');
    return location;
  }

  @override
  Future<PickedContact?> pickContact() async {
    _check('pickContact');
    return null;
  }

  @override
  Future<List<TestSendResult>> sendTestMessage() async {
    _check('sendTestMessage');
    return testResults;
  }

  @override
  Future<void> runEndToEndTest() async {
    _check('runEndToEndTest');
  }

  @override
  Future<bool> cancelCountdown() async {
    _check('cancelCountdown');
    return true;
  }

  @override
  Stream<SafeZoneEvent> get events => _events.stream;
}

class FakeRecipients implements AlertRecipientSource {
  FakeRecipients([
    this.recipients = const [
      AlertRecipient(name: 'Ana', phone: '+51900000001'),
      AlertRecipient(name: 'Beto', phone: '+51900000002'),
    ],
  ]);

  final List<AlertRecipient> recipients;

  @override
  Future<List<AlertRecipient>> activeRecipients() async => recipients;
}

class FixedClock implements Clock {
  FixedClock([DateTime? start]) : time = start ?? DateTime(2026, 10, 17, 15);

  DateTime time;

  @override
  DateTime now() => time;
}

SafeZoneConfig sampleConfig({
  bool monitoringEnabled = true,
  int countdownSeconds = 60,
}) => SafeZoneConfig(
  monitoringEnabled: monitoringEnabled,
  ownerName: 'Luz',
  home: const GeoPoint(lat: -12.0464, lng: -77.0428),
  radiusMeters: 300,
  window: const AlertWindow(startMinute: 1320, endMinute: 360),
  mode: AlertMode.awayDuringWindow,
  minAwayMinutes: 5,
  countdownSeconds: countdownSeconds,
  dailyLimit: 2,
  message: 'Estoy fuera de casa.',
  recipients: const [AlertRecipient(name: 'Ana', phone: '+51900000001')],
);

const allGranted = SafePermissions(
  fineLocation: true,
  backgroundLocation: true,
  sendSms: true,
  notifications: true,
  batteryOptimizationIgnored: true,
);

SafeZoneStatus statusWith({
  bool monitoring = false,
  SafePermissions permissions = const SafePermissions.none(),
  bool playServices = true,
  int sentToday = 0,
  int? awaySinceMillis,
  SafeZoneEvent? lastEvent,
}) => SafeZoneStatus(
  monitoring: monitoring,
  playServicesAvailable: playServices,
  permissions: permissions,
  sentTodayEpisodes: sentToday,
  awaySinceMillis: awaySinceMillis,
  lastEvent: lastEvent,
);

/// Pumps [screen] inside the Refuge providers (with fakes) and the project
/// theme at a phone-sized surface and an optional text scale.
Future<void> pumpRefuge(
  WidgetTester tester,
  Widget screen, {
  required FakeSafeZonePlatform platform,
  AlertRecipientSource? recipients,
  FixedClock? clock,
  double textScale = 1,
  Size size = const Size(360, 800),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MultiProvider(
      providers: refugeProviders(
        platform: platform,
        recipientSource: recipients ?? FakeRecipients(),
        clock: clock ?? FixedClock(),
      ),
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, home) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: home!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
