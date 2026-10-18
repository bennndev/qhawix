/// Pure rules of the safe-zone feature. They mirror
/// `contracts/safe-zone-channel.md`; the native side validates the same ranges.
library;

/// Ranges and defaults of the config, in one place (config, not constants in
/// widgets). Durations are plain integers on purpose.
abstract final class SafeZoneLimits {
  static const ownerNameMax = 60;
  static const minRadiusMeters = 100;
  static const maxRadiusMeters = 5000;
  static const defaultRadiusMeters = 300;
  static const minutesPerDay = 1440;
  static const maxMinAwayMinutes = 60;
  static const defaultMinAwayMinutes = 5;
  static const minCountdownSeconds = 15;
  static const maxCountdownSeconds = 300;
  static const defaultCountdownSeconds = 60;
  static const minDailyLimit = 1;
  static const maxDailyLimit = 10;
  static const defaultDailyLimit = 2;
  static const messageMax = 300;
  static const maxRecipients = 10;
  static const pinMinDigits = 4;
  static const pinMaxDigits = 8;
  static const defaultWindowStartMinute = 1320;
  static const defaultWindowEndMinute = 360;
  static const defaultMessage =
      'Estoy fuera de casa a una hora inusual. Por favor, intenta '
      'comunicarte conmigo.';
}

/// A point on the map. It never leaves the device.
class GeoPoint {
  const GeoPoint({required this.lat, required this.lng});

  final double lat;
  final double lng;

  bool get isValid =>
      lat.isFinite &&
      lng.isFinite &&
      lat >= -90 &&
      lat <= 90 &&
      lng >= -180 &&
      lng <= 180;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}

/// When an alert may start.
enum AlertMode {
  /// Away from home and inside the alert window (default).
  awayDuringWindow,

  /// Away from home at any hour.
  awayAnytime,
}

/// Alert window as minutes of the day in the device's local time.
class AlertWindow {
  const AlertWindow({required this.startMinute, required this.endMinute});

  final int startMinute;
  final int endMinute;

  /// `start == end` means "always"; the UI must not offer it for
  /// [AlertMode.awayDuringWindow].
  bool get isAlways => startMinute == endMinute;

  bool get crossesMidnight => startMinute > endMinute;

  bool get isValid => _isMinute(startMinute) && _isMinute(endMinute);

  /// Contract helper: `start <= m < end` when `start < end`;
  /// `m >= start || m < end` when `start > end`; always true when equal.
  bool inWindow(int minuteOfDay) {
    if (startMinute == endMinute) return true;
    if (startMinute < endMinute) {
      return minuteOfDay >= startMinute && minuteOfDay < endMinute;
    }
    return minuteOfDay >= startMinute || minuteOfDay < endMinute;
  }

  static bool _isMinute(int m) => m >= 0 && m < SafeZoneLimits.minutesPerDay;

  @override
  bool operator ==(Object other) =>
      other is AlertWindow &&
      other.startMinute == startMinute &&
      other.endMinute == endMinute;

  @override
  int get hashCode => Object.hash(startMinute, endMinute);
}

/// Someone who receives the SMS. Identified by the phone number.
class AlertRecipient {
  const AlertRecipient({required this.name, required this.phone});

  final String name;
  final String phone;

  @override
  bool operator ==(Object other) =>
      other is AlertRecipient && other.phone == phone && other.name == name;

  @override
  int get hashCode => Object.hash(name, phone);
}

/// What is wrong with a config. The view maps each to Spanish copy.
enum ConfigIssue {
  ownerName,
  home,
  radius,
  window,
  windowIsAlways,
  minAway,
  countdown,
  dailyLimit,
  message,
  recipientsMissing,
  recipientsTooMany,
  pinRequired,
}

/// The stored configuration of the safe-zone alerts.
class SafeZoneConfig {
  const SafeZoneConfig({
    required this.monitoringEnabled,
    required this.ownerName,
    required this.home,
    required this.radiusMeters,
    required this.window,
    required this.mode,
    required this.minAwayMinutes,
    required this.countdownSeconds,
    required this.dailyLimit,
    required this.message,
    required this.recipients,
  });

  final bool monitoringEnabled;
  final String ownerName;
  final GeoPoint home;
  final int radiusMeters;
  final AlertWindow window;
  final AlertMode mode;
  final int minAwayMinutes;

  /// 0 sends immediately; otherwise a cancellable countdown of this length.
  final int countdownSeconds;
  final int dailyLimit;
  final String message;
  final List<AlertRecipient> recipients;

  bool get hasCountdown => countdownSeconds > 0;

  /// The fixed, non-removable suffix native appends to every alert.
  static String autoSuffix(String ownerName) =>
      ' — Mensaje automático de QHAWIX enviado desde el celular de '
      '${ownerName.trim()}.';

  /// Exactly what the recipients read.
  String get smsPreview => '${message.trim()}${autoSuffix(ownerName)}';

  /// Everything wrong with the config, in contract order. Empty means the
  /// native side accepts it. [hasCancelPin] is whether a PIN is already set.
  List<ConfigIssue> issues({required bool hasCancelPin}) {
    final owner = ownerName.trim();
    final text = message.trim();
    return [
      if (owner.isEmpty || owner.length > SafeZoneLimits.ownerNameMax)
        ConfigIssue.ownerName,
      if (!home.isValid) ConfigIssue.home,
      if (radiusMeters < SafeZoneLimits.minRadiusMeters ||
          radiusMeters > SafeZoneLimits.maxRadiusMeters)
        ConfigIssue.radius,
      if (!window.isValid) ConfigIssue.window,
      if (mode == AlertMode.awayDuringWindow &&
          window.isValid &&
          window.isAlways)
        ConfigIssue.windowIsAlways,
      if (minAwayMinutes < 0 ||
          minAwayMinutes > SafeZoneLimits.maxMinAwayMinutes)
        ConfigIssue.minAway,
      if (countdownSeconds != 0 &&
          (countdownSeconds < SafeZoneLimits.minCountdownSeconds ||
              countdownSeconds > SafeZoneLimits.maxCountdownSeconds))
        ConfigIssue.countdown,
      if (dailyLimit < SafeZoneLimits.minDailyLimit ||
          dailyLimit > SafeZoneLimits.maxDailyLimit)
        ConfigIssue.dailyLimit,
      if (text.isEmpty || text.length > SafeZoneLimits.messageMax)
        ConfigIssue.message,
      if (monitoringEnabled && recipients.isEmpty)
        ConfigIssue.recipientsMissing,
      if (recipients.length > SafeZoneLimits.maxRecipients)
        ConfigIssue.recipientsTooMany,
      if (countdownSeconds > 0 && !hasCancelPin) ConfigIssue.pinRequired,
    ];
  }

  SafeZoneConfig copyWith({
    bool? monitoringEnabled,
    String? ownerName,
    GeoPoint? home,
    int? radiusMeters,
    AlertWindow? window,
    AlertMode? mode,
    int? minAwayMinutes,
    int? countdownSeconds,
    int? dailyLimit,
    String? message,
    List<AlertRecipient>? recipients,
  }) => SafeZoneConfig(
    monitoringEnabled: monitoringEnabled ?? this.monitoringEnabled,
    ownerName: ownerName ?? this.ownerName,
    home: home ?? this.home,
    radiusMeters: radiusMeters ?? this.radiusMeters,
    window: window ?? this.window,
    mode: mode ?? this.mode,
    minAwayMinutes: minAwayMinutes ?? this.minAwayMinutes,
    countdownSeconds: countdownSeconds ?? this.countdownSeconds,
    dailyLimit: dailyLimit ?? this.dailyLimit,
    message: message ?? this.message,
    recipients: recipients ?? this.recipients,
  );
}

/// Whether [pin] is 4 to 8 digits, the contract's rule for `setCancelPin`.
bool isValidCancelPin(String pin) => RegExp(
  '^[0-9]{${SafeZoneLimits.pinMinDigits},${SafeZoneLimits.pinMaxDigits}}\$',
).hasMatch(pin);
