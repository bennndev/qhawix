import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/refuge/domain/safe_zone_config.dart';
import 'package:qhawix/features/refuge/domain/safe_zone_engine.dart';
import 'package:qhawix/features/refuge/domain/safe_zone_status.dart';

import 'test_support.dart';

void main() {
  final home = sampleConfig().home;
  // ~111 m north of home at equator-ish latitudes used in fixtures.
  final nearOutside = GeoPoint(lat: home.lat + 0.002, lng: home.lng);
  final farOutside = GeoPoint(lat: home.lat + 0.01, lng: home.lng);

  group('distanceMeters', () {
    test('zero at the same point', () {
      expect(SafeZoneEngine.distanceMeters(home, home), closeTo(0, 0.1));
    });

    test('grows with separation', () {
      final near = SafeZoneEngine.distanceMeters(home, nearOutside);
      final far = SafeZoneEngine.distanceMeters(home, farOutside);
      expect(near, greaterThan(100));
      expect(far, greaterThan(near));
    });
  });

  group('onExit', () {
    test('schedules min-away when inside the window', () {
      final config = sampleConfig().copyWith(
        mode: AlertMode.awayDuringWindow,
        minAwayMinutes: 5,
      );
      // 22:00 local — default window starts at 22:00 (1320).
      final now = DateTime(2026, 10, 17, 22, 0);
      final result = SafeZoneEngine.onExit(
        config: config,
        state: const SafeZoneRuntimeState(),
        localNow: now,
        nowMillis: now.millisecondsSinceEpoch,
      );
      expect(result.event, SafeZoneEventType.exitDetected);
      expect(result.action, SafeZoneEngineAction.scheduleMinAwayConfirm);
      expect(result.state.isAway, isTrue);
      expect(result.state.alertedThisEpisode, isFalse);
    });

    test('schedules window-open when outside the window', () {
      final config = sampleConfig().copyWith(minAwayMinutes: 5);
      final now = DateTime(2026, 10, 17, 12, 0);
      final result = SafeZoneEngine.onExit(
        config: config,
        state: const SafeZoneRuntimeState(),
        localNow: now,
        nowMillis: now.millisecondsSinceEpoch,
      );
      expect(result.action, SafeZoneEngineAction.scheduleWindowOpen);
    });

    test('awayAnytime ignores the window', () {
      final config = sampleConfig().copyWith(
        mode: AlertMode.awayAnytime,
        minAwayMinutes: 5,
      );
      final now = DateTime(2026, 10, 17, 12, 0);
      final result = SafeZoneEngine.onExit(
        config: config,
        state: const SafeZoneRuntimeState(),
        localNow: now,
        nowMillis: now.millisecondsSinceEpoch,
      );
      expect(result.action, SafeZoneEngineAction.scheduleMinAwayConfirm);
    });
  });

  group('onStillAwayConfirmed', () {
    test('starts countdown when still outside and under the daily limit', () {
      final config = sampleConfig(
        countdownSeconds: 60,
      ).copyWith(dailyLimit: 2);
      final away = SafeZoneRuntimeState(
        awaySinceMillis: 1,
        sentTodayLocalDate: SafeZoneEngine.localDateKey(
          DateTime(2026, 10, 17, 22),
        ),
      );
      final result = SafeZoneEngine.onStillAwayConfirmed(
        config: config,
        state: away,
        localNow: DateTime(2026, 10, 17, 22, 5),
        stillOutside: true,
      );
      expect(result.event, SafeZoneEventType.awayConfirmed);
      expect(result.action, SafeZoneEngineAction.startCountdown);
      expect(result.state.countdownActive, isTrue);
    });

    test('suppresses when the daily limit is reached', () {
      final config = sampleConfig(countdownSeconds: 0).copyWith(dailyLimit: 1);
      final away = SafeZoneRuntimeState(
        awaySinceMillis: 1,
        sentTodayEpisodes: 1,
        sentTodayLocalDate: '2026-10-17',
      );
      final result = SafeZoneEngine.onStillAwayConfirmed(
        config: config,
        state: away,
        localNow: DateTime(2026, 10, 17, 22, 5),
        stillOutside: true,
      );
      expect(result.event, SafeZoneEventType.suppressedDailyLimit);
      expect(result.action, SafeZoneEngineAction.none);
    });

    test('one alert per episode', () {
      final config = sampleConfig(countdownSeconds: 0).copyWith(dailyLimit: 5);
      final away = const SafeZoneRuntimeState(
        awaySinceMillis: 1,
        alertedThisEpisode: true,
        sentTodayEpisodes: 1,
        sentTodayLocalDate: '2026-10-17',
      );
      final result = SafeZoneEngine.onStillAwayConfirmed(
        config: config,
        state: away,
        localNow: DateTime(2026, 10, 17, 22, 5),
        stillOutside: true,
      );
      expect(result.event, SafeZoneEventType.suppressedAlreadyAlerted);
      expect(result.action, SafeZoneEngineAction.none);
    });
  });

  group('onEnter', () {
    test('clears away and countdown flags', () {
      const state = SafeZoneRuntimeState(
        awaySinceMillis: 99,
        alertedThisEpisode: true,
        countdownActive: true,
      );
      final result = SafeZoneEngine.onEnter(state: state);
      expect(result.event, SafeZoneEventType.enteredHome);
      expect(result.state.isAway, isFalse);
      expect(result.state.alertedThisEpisode, isFalse);
      expect(result.state.countdownActive, isFalse);
    });
  });

  group('countdown', () {
    test('cancel stops the send', () {
      const state = SafeZoneRuntimeState(
        awaySinceMillis: 1,
        countdownActive: true,
      );
      final cancelled = SafeZoneEngine.onCountdownCancelled(state: state);
      expect(cancelled.event, SafeZoneEventType.countdownCancelled);
      final ended = SafeZoneEngine.onCountdownEnded(
        config: sampleConfig(),
        state: cancelled.state,
        localNow: DateTime(2026, 10, 17, 22, 10),
      );
      expect(ended.action, SafeZoneEngineAction.none);
    });

    test('end without cancel requests SMS', () {
      const state = SafeZoneRuntimeState(
        awaySinceMillis: 1,
        countdownActive: true,
        sentTodayLocalDate: '2026-10-17',
      );
      final ended = SafeZoneEngine.onCountdownEnded(
        config: sampleConfig(countdownSeconds: 60).copyWith(dailyLimit: 2),
        state: state,
        localNow: DateTime(2026, 10, 17, 22, 10),
      );
      expect(ended.action, SafeZoneEngineAction.sendSms);
      expect(ended.state.alertedThisEpisode, isTrue);
      expect(ended.state.sentTodayEpisodes, 1);
    });
  });
}
