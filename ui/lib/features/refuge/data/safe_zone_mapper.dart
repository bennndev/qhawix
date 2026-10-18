import '../domain/safe_zone_config.dart';
import '../domain/safe_zone_status.dart';

/// Wire format of `contracts/safe-zone-channel.md`. The only place that knows
/// the JSON keys; DTO maps never reach the view.
abstract final class SafeZoneMapper {
  static Map<String, Object?> configToWire(SafeZoneConfig c) => {
    'monitoringEnabled': c.monitoringEnabled,
    'ownerName': c.ownerName.trim(),
    'home': {'lat': c.home.lat, 'lng': c.home.lng},
    'radiusMeters': c.radiusMeters,
    'windowStartMinute': c.window.startMinute,
    'windowEndMinute': c.window.endMinute,
    'mode': switch (c.mode) {
      AlertMode.awayDuringWindow => 'awayDuringWindow',
      AlertMode.awayAnytime => 'awayAnytime',
    },
    'minAwayMinutes': c.minAwayMinutes,
    'countdownSeconds': c.countdownSeconds,
    'dailyLimit': c.dailyLimit,
    'message': c.message.trim(),
    'recipients': [
      for (final r in c.recipients) {'name': r.name, 'phone': r.phone},
    ],
  };

  static SafeZoneConfig configFromWire(Map<String, Object?> m) {
    final home = asMap(m['home']);
    return SafeZoneConfig(
      monitoringEnabled: m['monitoringEnabled'] as bool? ?? false,
      ownerName: m['ownerName'] as String? ?? '',
      home: GeoPoint(
        lat: (home['lat'] as num).toDouble(),
        lng: (home['lng'] as num).toDouble(),
      ),
      radiusMeters: (m['radiusMeters'] as num).toInt(),
      window: AlertWindow(
        startMinute: (m['windowStartMinute'] as num).toInt(),
        endMinute: (m['windowEndMinute'] as num).toInt(),
      ),
      mode: m['mode'] == 'awayAnytime'
          ? AlertMode.awayAnytime
          : AlertMode.awayDuringWindow,
      minAwayMinutes:
          (m['minAwayMinutes'] as num?)?.toInt() ??
          SafeZoneLimits.defaultMinAwayMinutes,
      countdownSeconds:
          (m['countdownSeconds'] as num?)?.toInt() ??
          SafeZoneLimits.defaultCountdownSeconds,
      dailyLimit:
          (m['dailyLimit'] as num?)?.toInt() ??
          SafeZoneLimits.defaultDailyLimit,
      message: m['message'] as String? ?? '',
      recipients: [
        for (final r in (m['recipients'] as List<Object?>? ?? const []))
          AlertRecipient(
            name: asMap(r)['name'] as String? ?? '',
            phone: asMap(r)['phone'] as String? ?? '',
          ),
      ],
    );
  }

  static SafeZoneStatus statusFromWire(Map<String, Object?> m) {
    final p = asMap(m['permissions']);
    final last = m['lastEvent'];
    return SafeZoneStatus(
      monitoring: m['monitoring'] as bool? ?? false,
      playServicesAvailable: m['playServicesAvailable'] as bool? ?? false,
      permissions: SafePermissions(
        fineLocation: p['fineLocation'] as bool? ?? false,
        backgroundLocation: p['backgroundLocation'] as bool? ?? false,
        sendSms: p['sendSms'] as bool? ?? false,
        notifications: p['notifications'] as bool? ?? false,
        batteryOptimizationIgnored:
            p['batteryOptimizationIgnored'] as bool? ?? false,
      ),
      awaySinceMillis: (m['awaySinceMillis'] as num?)?.toInt(),
      sentTodayEpisodes: (m['sentTodayEpisodes'] as num?)?.toInt() ?? 0,
      lastEvent: last == null ? null : eventFromWire(asMap(last)),
    );
  }

  static SafeZoneEvent eventFromWire(Map<String, Object?> m) => SafeZoneEvent(
    type: _eventTypes[m['type']] ?? SafeZoneEventType.unknown,
    atMillis: (m['atMillis'] as num?)?.toInt() ?? 0,
    test: m['test'] as bool? ?? false,
    detail: m['detail'] as String?,
  );

  static const _eventTypes = <String, SafeZoneEventType>{
    'monitoring_started': SafeZoneEventType.monitoringStarted,
    'monitoring_stopped': SafeZoneEventType.monitoringStopped,
    'exit_detected': SafeZoneEventType.exitDetected,
    'entered_home': SafeZoneEventType.enteredHome,
    'window_opened_while_away': SafeZoneEventType.windowOpenedWhileAway,
    'away_confirmed': SafeZoneEventType.awayConfirmed,
    'suppressed_outside_window': SafeZoneEventType.suppressedOutsideWindow,
    'suppressed_daily_limit': SafeZoneEventType.suppressedDailyLimit,
    'suppressed_already_alerted': SafeZoneEventType.suppressedAlreadyAlerted,
    'countdown_started': SafeZoneEventType.countdownStarted,
    'countdown_cancelled': SafeZoneEventType.countdownCancelled,
    'sms_sent': SafeZoneEventType.smsSent,
    'sms_failed': SafeZoneEventType.smsFailed,
    'permission_lost': SafeZoneEventType.permissionLost,
  };

  static PermissionResult permissionResultFromWire(Object? value) =>
      switch (value) {
        'granted' => PermissionResult.granted,
        'opened_settings' => PermissionResult.openedSettings,
        _ => PermissionResult.denied,
      };

  static TestSendResult testResultFromWire(Map<String, Object?> m) =>
      TestSendResult(
        phone: m['phone'] as String? ?? '',
        outcome: switch (m['outcome']) {
          'sent' => SendOutcome.sent,
          'permission_denied' => SendOutcome.permissionDenied,
          _ => SendOutcome.failed,
        },
        detail: m['detail'] as String?,
      );

  /// Platform channels return `Map<Object?, Object?>`; this normalizes it.
  static Map<String, Object?> asMap(Object? value) => {
    for (final e in (value as Map<Object?, Object?>).entries)
      e.key as String: e.value,
  };
}
