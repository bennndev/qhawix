import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/refuge/data/method_channel_safe_zone_platform.dart';
import 'package:qhawix/features/refuge/domain/safe_zone_config.dart';
import 'package:qhawix/features/refuge/domain/safe_zone_error.dart';
import 'package:qhawix/features/refuge/domain/safe_zone_status.dart';

import 'test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('qhawix/safe_zone');
  const eventChannel = EventChannel('qhawix/safe_zone/events');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;
  late Object? Function(MethodCall call) answer;

  late MethodChannelSafeZonePlatform platform;

  setUp(() {
    calls = [];
    answer = (_) => null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return answer(call);
    });
    platform = MethodChannelSafeZonePlatform(isAndroid: true);
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockStreamHandler(eventChannel, null);
  });

  test('channel names are the contract names', () {
    expect(MethodChannelSafeZonePlatform.channelName, 'qhawix/safe_zone');
    expect(
      MethodChannelSafeZonePlatform.eventChannelName,
      'qhawix/safe_zone/events',
    );
  });

  test('saveConfig sends the exact config payload', () async {
    answer = (_) => {'ok': true};
    await platform.saveConfig(sampleConfig());
    expect(calls.single.method, 'saveConfig');
    expect(calls.single.arguments, {
      'monitoringEnabled': true,
      'ownerName': 'Luz',
      'home': {'lat': -12.0464, 'lng': -77.0428},
      'radiusMeters': 300,
      'windowStartMinute': 1320,
      'windowEndMinute': 360,
      'mode': 'awayDuringWindow',
      'minAwayMinutes': 5,
      'countdownSeconds': 60,
      'dailyLimit': 2,
      'message': 'Estoy fuera de casa.',
      'recipients': [
        {'name': 'Ana', 'phone': '+51900000001'},
      ],
    });
  });

  test('awayAnytime travels as its contract string', () async {
    answer = (_) => {'ok': true};
    await platform.saveConfig(
      sampleConfig().copyWith(mode: AlertMode.awayAnytime),
    );
    expect((calls.single.arguments as Map)['mode'], 'awayAnytime');
  });

  test('loadConfig maps a config and null', () async {
    answer = (_) => null;
    expect(await platform.loadConfig(), isNull);

    answer = (_) => {
      'monitoringEnabled': false,
      'ownerName': 'Luz',
      'home': {'lat': -12.0, 'lng': -77.0},
      'radiusMeters': 500,
      'windowStartMinute': 60,
      'windowEndMinute': 120,
      'mode': 'awayAnytime',
      'minAwayMinutes': 10,
      'countdownSeconds': 0,
      'dailyLimit': 3,
      'message': 'Hola',
      'recipients': [
        {'name': 'Ana', 'phone': '1'},
      ],
    };
    final config = await platform.loadConfig();
    expect(calls.map((c) => c.method), ['loadConfig', 'loadConfig']);
    expect(config!.mode, AlertMode.awayAnytime);
    expect(config.radiusMeters, 500);
    expect(config.window, const AlertWindow(startMinute: 60, endMinute: 120));
    expect(config.recipients.single.name, 'Ana');
  });

  test('getStatus maps permissions, away time and last event', () async {
    answer = (_) => {
      'monitoring': true,
      'playServicesAvailable': true,
      'permissions': {
        'fineLocation': true,
        'backgroundLocation': false,
        'sendSms': true,
        'notifications': true,
        'batteryOptimizationIgnored': false,
      },
      'awaySinceMillis': 1000,
      'sentTodayEpisodes': 1,
      'lastEvent': {
        'type': 'sms_sent',
        'atMillis': 2000,
        'test': true,
        'detail': 'ok',
      },
    };
    final status = await platform.getStatus();
    expect(calls.single.method, 'getStatus');
    expect(calls.single.arguments, isNull);
    expect(status.monitoring, isTrue);
    expect(status.permissions.backgroundLocation, isFalse);
    expect(status.awaySinceMillis, 1000);
    expect(status.lastEvent!.type, SafeZoneEventType.smsSent);
    expect(status.lastEvent!.test, isTrue);
  });

  test('requestPermission sends the kind and maps the three results', () async {
    for (final (wire, expected) in [
      ('granted', PermissionResult.granted),
      ('denied', PermissionResult.denied),
      ('opened_settings', PermissionResult.openedSettings),
    ]) {
      answer = (_) => {'result': wire};
      expect(
        await platform.requestPermission(PermissionKind.backgroundLocation),
        expected,
      );
    }
    expect(calls.first.method, 'requestPermission');
    expect(calls.first.arguments, {'kind': 'backgroundLocation'});
  });

  test('every permission kind uses its contract wire name', () async {
    answer = (_) => {'result': 'granted'};
    for (final kind in PermissionKind.values) {
      await platform.requestPermission(kind);
    }
    expect(
      [for (final c in calls) (c.arguments as Map)['kind']],
      [
        'fineLocation',
        'backgroundLocation',
        'sendSms',
        'notifications',
        'batteryOptimization',
      ],
    );
  });

  test('setCancelPin and hasCancelPin payloads', () async {
    answer = (call) =>
        call.method == 'hasCancelPin' ? {'set': true} : {'ok': true};
    await platform.setCancelPin('1234');
    expect(await platform.hasCancelPin(), isTrue);
    expect(calls[0].method, 'setCancelPin');
    expect(calls[0].arguments, {'pin': '1234'});
    expect(calls[1].method, 'hasCancelPin');
  });

  test('currentLocation and pickContact', () async {
    answer = (call) => call.method == 'currentLocation'
        ? {'lat': -12.5, 'lng': -77.5, 'accuracyMeters': 12.5}
        : null;
    final location = await platform.currentLocation();
    expect(location.lat, -12.5);
    expect(location.accuracyMeters, 12.5);
    expect(await platform.pickContact(), isNull);
    expect(calls.map((c) => c.method), ['currentLocation', 'pickContact']);
  });

  test('sendTestMessage sends the prefix and maps outcomes', () async {
    answer = (_) => {
      'results': [
        {'phone': '1', 'outcome': 'sent', 'detail': ''},
        {'phone': '2', 'outcome': 'permission_denied'},
        {'phone': '3', 'outcome': 'failed', 'detail': 'radio off'},
      ],
    };
    final results = await platform.sendTestMessage();
    expect(calls.single.method, 'sendTestMessage');
    expect(calls.single.arguments, {'prefix': 'Prueba'});
    expect(
      [for (final r in results) r.outcome],
      [SendOutcome.sent, SendOutcome.permissionDenied, SendOutcome.failed],
    );
    expect(results.last.detail, 'radio off');
  });

  test('argument-less methods send no arguments', () async {
    answer = (call) =>
        call.method == 'cancelCountdown' ? {'ok': true} : {'ok': true};
    await platform.startMonitoring();
    await platform.stopMonitoring();
    await platform.runEndToEndTest();
    expect(await platform.cancelCountdown(), isTrue);
    expect(calls.map((c) => c.method), [
      'startMonitoring',
      'stopMonitoring',
      'runEndToEndTest',
      'cancelCountdown',
    ]);
    expect(calls.every((c) => c.arguments == null), isTrue);
  });

  test('PlatformException codes map to typed errors', () async {
    for (final (code, matcher) in <(String, Matcher)>[
      ('invalid_config', isA<InvalidConfigError>()),
      ('permission_missing', isA<PermissionMissingError>()),
      ('unavailable', isA<UnavailableError>()),
      ('invalid_argument', isA<InvalidArgumentError>()),
      ('failed', isA<FailedError>()),
      ('something_new', isA<FailedError>()),
    ]) {
      answer = (_) => throw PlatformException(code: code, message: 'why');
      await expectLater(platform.startMonitoring(), throwsA(matcher));
    }
  });

  test('the error keeps the native reason', () async {
    answer = (_) =>
        throw PlatformException(code: 'invalid_config', message: 'radius');
    await expectLater(
      platform.saveConfig(sampleConfig()),
      throwsA(
        isA<InvalidConfigError>().having((e) => e.message, 'message', 'radius'),
      ),
    );
  });

  test('a missing Android side reads as unavailable', () async {
    messenger.setMockMethodCallHandler(channel, null);
    await expectLater(platform.getStatus(), throwsA(isA<UnavailableError>()));
  });

  test(
    'off Android every call is unavailable and no channel is touched',
    () async {
      final off = MethodChannelSafeZonePlatform(isAndroid: false);
      await expectLater(off.getStatus(), throwsA(isA<UnavailableError>()));
      await expectLater(
        off.startMonitoring(),
        throwsA(isA<UnavailableError>()),
      );
      expect(calls, isEmpty);
      expect(await off.events.toList(), isEmpty);
    },
  );

  test(
    'the placeholder event stream stays empty (package adapter owns events)',
    () async {
      expect(await platform.events.toList(), isEmpty);
    },
  );

  test('confirmAutoStart and isAutoStartConfirmed go through the channel', () async {
    answer = (call) => switch (call.method) {
      'isAutoStartConfirmed' => {'confirmed': true},
      _ => {'ok': true},
    };
    await platform.confirmAutoStart();
    expect(await platform.isAutoStartConfirmed(), isTrue);
    expect(calls.map((c) => c.method), [
      'confirmAutoStart',
      'isAutoStartConfirmed',
    ]);
  });
}
