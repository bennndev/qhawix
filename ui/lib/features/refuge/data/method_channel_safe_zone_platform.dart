import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/safe_zone_config.dart';
import '../domain/safe_zone_error.dart';
import '../domain/safe_zone_platform.dart';
import '../domain/safe_zone_status.dart';
import 'safe_zone_mapper.dart';

/// `SafeZonePlatform` over the channels of `contracts/safe-zone-channel.md`.
///
/// Off Android every call fails with [UnavailableError] and [events] is empty,
/// so the UI can say the feature is not available on this device.
class MethodChannelSafeZonePlatform implements SafeZonePlatform {
  MethodChannelSafeZonePlatform({
    MethodChannel? channel,
    EventChannel? eventChannel,
    bool? isAndroid,
  }) : _channel = channel ?? const MethodChannel(channelName),
       _events = eventChannel ?? const EventChannel(eventChannelName),
       _isAndroid =
           isAndroid ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  static const channelName = 'qhawix/safe_zone';
  static const eventChannelName = 'qhawix/safe_zone/events';

  /// Text prefix the contract fixes for `sendTestMessage`.
  static const testPrefix = 'Prueba';

  final MethodChannel _channel;
  // Retained for API compatibility; not subscribed while this is a placeholder.
  // ignore: unused_field
  final EventChannel _events;
  final bool _isAndroid;

  Future<Object?> _call(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    if (!_isAndroid) {
      throw const UnavailableError('Not running on Android.');
    }
    try {
      return await _channel.invokeMethod<Object?>(method, arguments);
    } on PlatformException catch (e) {
      throw _mapError(e);
    } on MissingPluginException {
      throw const UnavailableError('The Android side is not installed.');
    }
  }

  static SafeZoneError _mapError(PlatformException e) => switch (e.code) {
    'invalid_config' => InvalidConfigError(e.message),
    'permission_missing' => PermissionMissingError(e.message),
    'unavailable' => UnavailableError(e.message),
    'invalid_argument' => InvalidArgumentError(e.message),
    _ => FailedError(e.message),
  };

  @override
  Future<SafeZoneStatus> getStatus() async => SafeZoneMapper.statusFromWire(
    SafeZoneMapper.asMap(await _call('getStatus')),
  );

  @override
  Future<void> saveConfig(SafeZoneConfig config) async {
    await _call('saveConfig', SafeZoneMapper.configToWire(config));
  }

  @override
  Future<SafeZoneConfig?> loadConfig() async {
    final raw = await _call('loadConfig');
    return raw == null
        ? null
        : SafeZoneMapper.configFromWire(SafeZoneMapper.asMap(raw));
  }

  @override
  Future<void> startMonitoring() async {
    await _call('startMonitoring');
  }

  @override
  Future<void> stopMonitoring() async {
    await _call('stopMonitoring');
  }

  @override
  Future<PermissionResult> requestPermission(PermissionKind kind) async {
    final raw = await _call('requestPermission', {'kind': kind.name});
    return SafeZoneMapper.permissionResultFromWire(
      SafeZoneMapper.asMap(raw)['result'],
    );
  }

  @override
  Future<void> setCancelPin(String pin) async {
    await _call('setCancelPin', {'pin': pin});
  }

  @override
  Future<bool> hasCancelPin() async =>
      SafeZoneMapper.asMap(await _call('hasCancelPin'))['set'] == true;

  @override
  Future<DeviceLocation> currentLocation() async {
    final m = SafeZoneMapper.asMap(await _call('currentLocation'));
    return DeviceLocation(
      lat: (m['lat'] as num).toDouble(),
      lng: (m['lng'] as num).toDouble(),
      accuracyMeters: (m['accuracyMeters'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Future<PickedContact?> pickContact() async {
    final raw = await _call('pickContact');
    if (raw == null) return null;
    final m = SafeZoneMapper.asMap(raw);
    return PickedContact(
      name: m['name'] as String? ?? '',
      phone: m['phone'] as String? ?? '',
    );
  }

  @override
  Future<List<TestSendResult>> sendTestMessage() async {
    final m = SafeZoneMapper.asMap(
      await _call('sendTestMessage', {'prefix': testPrefix}),
    );
    return [
      for (final r in (m['results'] as List<Object?>? ?? const []))
        SafeZoneMapper.testResultFromWire(SafeZoneMapper.asMap(r)),
    ];
  }

  @override
  Future<void> runEndToEndTest() async {
    await _call('runEndToEndTest');
  }

  @override
  Future<bool> cancelCountdown() async =>
      SafeZoneMapper.asMap(await _call('cancelCountdown'))['ok'] == true;

  @override
  Future<void> confirmAutoStart() async {
    await _call('confirmAutoStart');
  }

  @override
  Future<bool> isAutoStartConfirmed() async =>
      SafeZoneMapper.asMap(await _call('isAutoStartConfirmed'))['confirmed'] ==
      true;

  @override
  Stream<SafeZoneEvent> get events {
    // Do not attach to the EventChannel while this placeholder has no native
    // peer (MissingPluginException on listen). The package-based adapter will
    // own events. Method calls still go through [_call] and map to unavailable.
    if (!_isAndroid) return const Stream.empty();
    return const Stream.empty();
  }
}
