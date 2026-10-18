import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/refuge/domain/safe_zone_config.dart';
import 'package:qhawix/features/refuge/domain/safe_zone_status.dart';

import 'test_support.dart';

void main() {
  group('AlertWindow.inWindow', () {
    test('same-day window is start inclusive, end exclusive', () {
      const w = AlertWindow(startMinute: 540, endMinute: 1020);
      expect(w.inWindow(539), isFalse);
      expect(w.inWindow(540), isTrue);
      expect(w.inWindow(1019), isTrue);
      expect(w.inWindow(1020), isFalse);
      expect(w.crossesMidnight, isFalse);
    });

    test('a window crossing midnight covers both sides', () {
      const w = AlertWindow(startMinute: 1320, endMinute: 360);
      expect(w.crossesMidnight, isTrue);
      expect(w.inWindow(1320), isTrue);
      expect(w.inWindow(1439), isTrue);
      expect(w.inWindow(0), isTrue);
      expect(w.inWindow(359), isTrue);
      expect(w.inWindow(360), isFalse);
      expect(w.inWindow(720), isFalse);
      expect(w.inWindow(1319), isFalse);
    });

    test('start == end means always', () {
      const w = AlertWindow(startMinute: 600, endMinute: 600);
      expect(w.isAlways, isTrue);
      for (final m in [0, 599, 600, 601, 1439]) {
        expect(w.inWindow(m), isTrue);
      }
    });
  });

  group('SafeZoneConfig.issues', () {
    test('a valid config has none', () {
      expect(sampleConfig().issues(hasCancelPin: true), isEmpty);
    });

    test('radius edges 100 and 5000 are valid, 99 and 5001 are not', () {
      for (final r in [100, 5000]) {
        expect(
          sampleConfig().copyWith(radiusMeters: r).issues(hasCancelPin: true),
          isEmpty,
        );
      }
      for (final r in [99, 5001]) {
        expect(
          sampleConfig().copyWith(radiusMeters: r).issues(hasCancelPin: true),
          [ConfigIssue.radius],
        );
      }
    });

    test('countdown is 0 or 15..300', () {
      for (final s in [0, 15, 300]) {
        expect(
          sampleConfig()
              .copyWith(countdownSeconds: s)
              .issues(hasCancelPin: true),
          isEmpty,
        );
      }
      for (final s in [1, 14, 301]) {
        expect(
          sampleConfig()
              .copyWith(countdownSeconds: s)
              .issues(hasCancelPin: true),
          [ConfigIssue.countdown],
        );
      }
    });

    test('a countdown needs a PIN, sending directly does not', () {
      expect(sampleConfig().issues(hasCancelPin: false), [
        ConfigIssue.pinRequired,
      ]);
      expect(
        sampleConfig(countdownSeconds: 0).issues(hasCancelPin: false),
        isEmpty,
      );
    });

    test('minAway 0..60, dailyLimit 1..10', () {
      expect(
        sampleConfig().copyWith(minAwayMinutes: 61).issues(hasCancelPin: true),
        [ConfigIssue.minAway],
      );
      expect(
        sampleConfig().copyWith(minAwayMinutes: 0).issues(hasCancelPin: true),
        isEmpty,
      );
      expect(
        sampleConfig().copyWith(dailyLimit: 0).issues(hasCancelPin: true),
        [ConfigIssue.dailyLimit],
      );
      expect(
        sampleConfig().copyWith(dailyLimit: 11).issues(hasCancelPin: true),
        [ConfigIssue.dailyLimit],
      );
    });

    test('message 1..300 after trimming and owner 1..60', () {
      expect(
        sampleConfig().copyWith(message: '   ').issues(hasCancelPin: true),
        [ConfigIssue.message],
      );
      expect(
        sampleConfig().copyWith(message: 'a' * 301).issues(hasCancelPin: true),
        [ConfigIssue.message],
      );
      expect(
        sampleConfig().copyWith(message: 'a' * 300).issues(hasCancelPin: true),
        isEmpty,
      );
      expect(
        sampleConfig().copyWith(ownerName: '').issues(hasCancelPin: true),
        [ConfigIssue.ownerName],
      );
      expect(
        sampleConfig().copyWith(ownerName: 'a' * 61).issues(hasCancelPin: true),
        [ConfigIssue.ownerName],
      );
    });

    test('recipients: none only blocks an enabled config; over 10 never', () {
      expect(
        sampleConfig().copyWith(recipients: []).issues(hasCancelPin: true),
        [ConfigIssue.recipientsMissing],
      );
      expect(
        sampleConfig(
          monitoringEnabled: false,
        ).copyWith(recipients: []).issues(hasCancelPin: true),
        isEmpty,
      );
      final eleven = [
        for (var i = 0; i < 11; i++)
          AlertRecipient(name: 'P$i', phone: '+519000000$i'),
      ];
      expect(
        sampleConfig().copyWith(recipients: eleven).issues(hasCancelPin: true),
        [ConfigIssue.recipientsTooMany],
      );
    });

    test('start == end is rejected only in awayDuringWindow mode', () {
      const always = AlertWindow(startMinute: 600, endMinute: 600);
      expect(
        sampleConfig().copyWith(window: always).issues(hasCancelPin: true),
        [ConfigIssue.windowIsAlways],
      );
      expect(
        sampleConfig()
            .copyWith(window: always, mode: AlertMode.awayAnytime)
            .issues(hasCancelPin: true),
        isEmpty,
      );
    });

    test('minutes outside 0..1439 are an invalid window', () {
      expect(
        sampleConfig()
            .copyWith(
              window: const AlertWindow(startMinute: 1440, endMinute: 10),
            )
            .issues(hasCancelPin: true),
        [ConfigIssue.window],
      );
    });

    test('a home out of range or NaN is invalid', () {
      expect(const GeoPoint(lat: 91, lng: 0).isValid, isFalse);
      expect(const GeoPoint(lat: 0, lng: -181).isValid, isFalse);
      expect(const GeoPoint(lat: double.nan, lng: 0).isValid, isFalse);
      expect(const GeoPoint(lat: -90, lng: 180).isValid, isTrue);
    });
  });

  group('mode semantics and SMS text', () {
    test('awayDuringWindow is the first (default) mode', () {
      expect(AlertMode.values.first, AlertMode.awayDuringWindow);
    });

    test('the preview shows the fixed suffix with the owner name', () {
      expect(
        sampleConfig().smsPreview,
        'Estoy fuera de casa. — Mensaje automático de QHAWIX enviado desde '
        'el celular de Luz.',
      );
    });
  });

  group('permissions', () {
    test(
      'missingRequired ignores battery, and notifications w/o countdown',
      () {
        const p = SafePermissions(
          fineLocation: true,
          backgroundLocation: true,
          sendSms: true,
          notifications: false,
          batteryOptimizationIgnored: false,
        );
        expect(p.missingRequired(hasCountdown: false), isEmpty);
        expect(p.missingRequired(hasCountdown: true), [
          PermissionKind.notifications,
        ]);
        expect(p.missingAll, [
          PermissionKind.notifications,
          PermissionKind.batteryOptimization,
        ]);
      },
    );
  });

  test('cancel PIN is 4 to 8 digits', () {
    for (final ok in ['1234', '12345678']) {
      expect(isValidCancelPin(ok), isTrue);
    }
    for (final bad in ['123', '123456789', '12a4', '', '12 34']) {
      expect(isValidCancelPin(bad), isFalse);
    }
  });
}
