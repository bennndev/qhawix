/// Read models the native side reports. Pure data, no platform types.
library;

/// A permission or system setting the feature depends on. The names are the
/// wire values of `requestPermission`.
enum PermissionKind {
  fineLocation,
  backgroundLocation,
  sendSms,
  notifications,
  batteryOptimization,
}

/// What `requestPermission` answered.
enum PermissionResult {
  granted,
  denied,

  /// Android sent the person to a system settings page. Re-read the status
  /// when the app resumes; there is no result.
  openedSettings,
}

/// Live state of every permission.
class SafePermissions {
  const SafePermissions({
    required this.fineLocation,
    required this.backgroundLocation,
    required this.sendSms,
    required this.notifications,
    required this.batteryOptimizationIgnored,
  });

  const SafePermissions.none()
    : fineLocation = false,
      backgroundLocation = false,
      sendSms = false,
      notifications = false,
      batteryOptimizationIgnored = false;

  final bool fineLocation;
  final bool backgroundLocation;
  final bool sendSms;
  final bool notifications;
  final bool batteryOptimizationIgnored;

  bool isGranted(PermissionKind kind) => switch (kind) {
    PermissionKind.fineLocation => fineLocation,
    PermissionKind.backgroundLocation => backgroundLocation,
    PermissionKind.sendSms => sendSms,
    PermissionKind.notifications => notifications,
    PermissionKind.batteryOptimization => batteryOptimizationIgnored,
  };

  /// What monitoring cannot start without. Notifications count only when a
  /// countdown exists, because the cancel action lives in its notification;
  /// battery optimization is advice, never a requirement.
  List<PermissionKind> missingRequired({required bool hasCountdown}) => [
    if (!fineLocation) PermissionKind.fineLocation,
    if (!backgroundLocation) PermissionKind.backgroundLocation,
    if (!sendSms) PermissionKind.sendSms,
    if (hasCountdown && !notifications) PermissionKind.notifications,
  ];

  /// Every item that is not granted, required or not.
  List<PermissionKind> get missingAll => [
    for (final kind in PermissionKind.values)
      if (!isGranted(kind)) kind,
  ];
}

/// Kinds of events native reports. Unknown wire values map to [unknown].
enum SafeZoneEventType {
  monitoringStarted,
  monitoringStopped,
  exitDetected,
  enteredHome,
  windowOpenedWhileAway,
  awayConfirmed,
  suppressedOutsideWindow,
  suppressedDailyLimit,
  suppressedAlreadyAlerted,
  countdownStarted,
  countdownCancelled,
  smsSent,
  smsFailed,
  permissionLost,
  unknown,
}

/// One entry of the on-device event log.
class SafeZoneEvent {
  const SafeZoneEvent({
    required this.type,
    required this.atMillis,
    required this.test,
    this.detail,
  });

  final SafeZoneEventType type;

  /// Milliseconds since epoch, UTC.
  final int atMillis;

  /// True when it came from "Probar el proceso completo".
  final bool test;
  final String? detail;

  DateTime get at =>
      DateTime.fromMillisecondsSinceEpoch(atMillis, isUtc: true).toLocal();

  @override
  bool operator ==(Object other) =>
      other is SafeZoneEvent &&
      other.type == type &&
      other.atMillis == atMillis &&
      other.test == test &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(type, atMillis, test, detail);
}

/// Answer of `getStatus`.
class SafeZoneStatus {
  const SafeZoneStatus({
    required this.monitoring,
    required this.playServicesAvailable,
    required this.permissions,
    required this.sentTodayEpisodes,
    this.awaySinceMillis,
    this.lastEvent,
  });

  final bool monitoring;
  final bool playServicesAvailable;
  final SafePermissions permissions;
  final int sentTodayEpisodes;
  final int? awaySinceMillis;
  final SafeZoneEvent? lastEvent;

  DateTime? get awaySince => awaySinceMillis == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(
          awaySinceMillis!,
          isUtc: true,
        ).toLocal();
}

/// Answer of `currentLocation`.
class DeviceLocation {
  const DeviceLocation({
    required this.lat,
    required this.lng,
    required this.accuracyMeters,
  });

  final double lat;
  final double lng;
  final double accuracyMeters;
}

/// A contact chosen in the system picker.
class PickedContact {
  const PickedContact({required this.name, required this.phone});

  final String name;
  final String phone;
}

/// Outcome of one SMS in a test. `sent` means handed to the radio of the
/// operator network, never delivered.
enum SendOutcome { sent, permissionDenied, failed }

class TestSendResult {
  const TestSendResult({
    required this.phone,
    required this.outcome,
    this.detail,
  });

  final String phone;
  final SendOutcome outcome;
  final String? detail;
}
