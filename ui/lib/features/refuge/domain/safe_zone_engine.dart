import 'dart:math' as math;

import 'safe_zone_config.dart';
import 'safe_zone_status.dart';

/// On-device episode counters and away flags (file-backed by the data layer).
class SafeZoneRuntimeState {
  const SafeZoneRuntimeState({
    this.awaySinceMillis,
    this.alertedThisEpisode = false,
    this.sentTodayEpisodes = 0,
    this.sentTodayLocalDate = '',
    this.countdownActive = false,
    this.countdownCancelled = false,
    this.autoStartConfirmed = false,
  });

  final int? awaySinceMillis;
  final bool alertedThisEpisode;
  final int sentTodayEpisodes;

  /// Local calendar day `yyyy-MM-dd` for [sentTodayEpisodes].
  final String sentTodayLocalDate;
  final bool countdownActive;
  final bool countdownCancelled;

  /// Person confirmed OEM auto-start settings (cannot be read from the OS).
  final bool autoStartConfirmed;

  bool get isAway => awaySinceMillis != null;

  SafeZoneRuntimeState copyWith({
    int? awaySinceMillis,
    bool clearAway = false,
    bool? alertedThisEpisode,
    int? sentTodayEpisodes,
    String? sentTodayLocalDate,
    bool? countdownActive,
    bool? countdownCancelled,
    bool? autoStartConfirmed,
  }) => SafeZoneRuntimeState(
    awaySinceMillis: clearAway
        ? null
        : (awaySinceMillis ?? this.awaySinceMillis),
    alertedThisEpisode: alertedThisEpisode ?? this.alertedThisEpisode,
    sentTodayEpisodes: sentTodayEpisodes ?? this.sentTodayEpisodes,
    sentTodayLocalDate: sentTodayLocalDate ?? this.sentTodayLocalDate,
    countdownActive: countdownActive ?? this.countdownActive,
    countdownCancelled: countdownCancelled ?? this.countdownCancelled,
    autoStartConfirmed: autoStartConfirmed ?? this.autoStartConfirmed,
  );
}

/// What the data layer should do after a pure-engine evaluation.
enum SafeZoneEngineAction {
  none,
  scheduleMinAwayConfirm,
  scheduleWindowOpen,
  startCountdown,
  sendSms,
}

/// One evaluation result: next state, optional event, and one action.
class SafeZoneEngineResult {
  const SafeZoneEngineResult({
    required this.state,
    this.event,
    this.action = SafeZoneEngineAction.none,
    this.detail,
  });

  final SafeZoneRuntimeState state;
  final SafeZoneEventType? event;
  final SafeZoneEngineAction action;
  final String? detail;
}

/// Pure rules for away episodes. Time and location are injected by the caller.
abstract final class SafeZoneEngine {
  /// Great-circle distance in meters (Haversine).
  static double distanceMeters(GeoPoint a, GeoPoint b) {
    const earth = 6371000.0;
    final dLat = _rad(b.lat - a.lat);
    final dLng = _rad(b.lng - a.lng);
    final lat1 = _rad(a.lat);
    final lat2 = _rad(b.lat);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earth * math.asin(math.min(1, math.sqrt(h)));
  }

  static double _rad(double deg) => deg * math.pi / 180;

  static bool isOutsideHome(
    GeoPoint position,
    SafeZoneConfig config,
  ) =>
      distanceMeters(position, config.home) > config.radiusMeters;

  static int minuteOfDay(DateTime local) => local.hour * 60 + local.minute;

  static String localDateKey(DateTime local) {
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static SafeZoneRuntimeState rollDailyLimit(
    SafeZoneRuntimeState state,
    DateTime localNow,
  ) {
    final key = localDateKey(localNow);
    if (state.sentTodayLocalDate == key) return state;
    return state.copyWith(sentTodayEpisodes: 0, sentTodayLocalDate: key);
  }

  /// Geofence EXIT: start an away episode and decide the next wait.
  static SafeZoneEngineResult onExit({
    required SafeZoneConfig config,
    required SafeZoneRuntimeState state,
    required DateTime localNow,
    required int nowMillis,
  }) {
    var next = rollDailyLimit(state, localNow).copyWith(
      awaySinceMillis: nowMillis,
      alertedThisEpisode: false,
      countdownActive: false,
      countdownCancelled: false,
    );
    final inWin = config.mode == AlertMode.awayAnytime ||
        config.window.inWindow(minuteOfDay(localNow));
    if (!inWin) {
      return SafeZoneEngineResult(
        state: next,
        event: SafeZoneEventType.exitDetected,
        action: SafeZoneEngineAction.scheduleWindowOpen,
        detail: 'outside_window',
      );
    }
    if (config.minAwayMinutes > 0) {
      return SafeZoneEngineResult(
        state: next,
        event: SafeZoneEventType.exitDetected,
        action: SafeZoneEngineAction.scheduleMinAwayConfirm,
      );
    }
    return _tryAlert(
      config: config,
      state: next,
      localNow: localNow,
      exitAlreadyEmitted: true,
    );
  }

  /// Geofence ENTER: end the episode.
  static SafeZoneEngineResult onEnter({
    required SafeZoneRuntimeState state,
  }) =>
      SafeZoneEngineResult(
        state: state.copyWith(
          clearAway: true,
          alertedThisEpisode: false,
          countdownActive: false,
          countdownCancelled: false,
        ),
        event: SafeZoneEventType.enteredHome,
      );

  /// Window-open alarm while still away, or min-away confirmation after a
  /// fresh location proved the person is still outside.
  static SafeZoneEngineResult onStillAwayConfirmed({
    required SafeZoneConfig config,
    required SafeZoneRuntimeState state,
    required DateTime localNow,
    required bool stillOutside,
  }) {
    var next = rollDailyLimit(state, localNow);
    if (!next.isAway) {
      return SafeZoneEngineResult(state: next);
    }
    if (!stillOutside) {
      return onEnter(state: next);
    }
    final inWin = config.mode == AlertMode.awayAnytime ||
        config.window.inWindow(minuteOfDay(localNow));
    if (!inWin) {
      return SafeZoneEngineResult(
        state: next,
        event: SafeZoneEventType.suppressedOutsideWindow,
        action: SafeZoneEngineAction.scheduleWindowOpen,
      );
    }
    return _tryAlert(
      config: config,
      state: next,
      localNow: localNow,
      exitAlreadyEmitted: false,
    );
  }

  /// Countdown finished without a correct PIN cancel.
  static SafeZoneEngineResult onCountdownEnded({
    required SafeZoneConfig config,
    required SafeZoneRuntimeState state,
    required DateTime localNow,
  }) {
    var next = rollDailyLimit(state, localNow);
    if (next.countdownCancelled || !next.countdownActive) {
      return SafeZoneEngineResult(
        state: next.copyWith(countdownActive: false),
        event: SafeZoneEventType.countdownCancelled,
      );
    }
    return _commitSend(config: config, state: next, localNow: localNow);
  }

  /// Person cancelled via PIN during countdown.
  static SafeZoneEngineResult onCountdownCancelled({
    required SafeZoneRuntimeState state,
  }) =>
      SafeZoneEngineResult(
        state: state.copyWith(
          countdownActive: false,
          countdownCancelled: true,
        ),
        event: SafeZoneEventType.countdownCancelled,
      );

  static SafeZoneEngineResult _tryAlert({
    required SafeZoneConfig config,
    required SafeZoneRuntimeState state,
    required DateTime localNow,
    required bool exitAlreadyEmitted,
  }) {
    if (state.alertedThisEpisode) {
      return SafeZoneEngineResult(
        state: state,
        event: exitAlreadyEmitted
            ? SafeZoneEventType.exitDetected
            : SafeZoneEventType.suppressedAlreadyAlerted,
      );
    }
    if (state.sentTodayEpisodes >= config.dailyLimit) {
      return SafeZoneEngineResult(
        state: state,
        event: exitAlreadyEmitted
            ? SafeZoneEventType.exitDetected
            : SafeZoneEventType.suppressedDailyLimit,
      );
    }
    if (config.hasCountdown) {
      return SafeZoneEngineResult(
        state: state.copyWith(
          countdownActive: true,
          countdownCancelled: false,
        ),
        event: exitAlreadyEmitted
            ? SafeZoneEventType.exitDetected
            : SafeZoneEventType.awayConfirmed,
        action: SafeZoneEngineAction.startCountdown,
      );
    }
    return _commitSend(
      config: config,
      state: state,
      localNow: localNow,
      confirmEvent: exitAlreadyEmitted
          ? SafeZoneEventType.exitDetected
          : SafeZoneEventType.awayConfirmed,
    );
  }

  static SafeZoneEngineResult _commitSend({
    required SafeZoneConfig config,
    required SafeZoneRuntimeState state,
    required DateTime localNow,
    SafeZoneEventType confirmEvent = SafeZoneEventType.awayConfirmed,
  }) {
    if (state.alertedThisEpisode) {
      return SafeZoneEngineResult(
        state: state.copyWith(countdownActive: false),
        event: SafeZoneEventType.suppressedAlreadyAlerted,
      );
    }
    if (state.sentTodayEpisodes >= config.dailyLimit) {
      return SafeZoneEngineResult(
        state: state.copyWith(countdownActive: false),
        event: SafeZoneEventType.suppressedDailyLimit,
      );
    }
    final key = localDateKey(localNow);
    return SafeZoneEngineResult(
      state: state.copyWith(
        alertedThisEpisode: true,
        sentTodayEpisodes: state.sentTodayEpisodes + 1,
        sentTodayLocalDate: key,
        countdownActive: false,
        countdownCancelled: false,
      ),
      event: confirmEvent,
      action: SafeZoneEngineAction.sendSms,
    );
  }
}
