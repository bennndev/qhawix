import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/refuge/domain/safe_zone_config.dart';
import 'package:qhawix/features/refuge/domain/safe_zone_error.dart';
import 'package:qhawix/features/refuge/domain/safe_zone_status.dart';
import 'package:qhawix/features/refuge/viewmodel/safe_zone_setup_view_model.dart';
import 'package:qhawix/features/refuge/viewmodel/safe_zone_status_view_model.dart';

import 'test_support.dart';

SafeZoneSetupViewModel _setup(FakeSafeZonePlatform platform) =>
    SafeZoneSetupViewModel(
      platform: platform,
      recipientSource: FakeRecipients(),
    );

/// A setup draft that satisfies every step except permissions.
Future<SafeZoneSetupViewModel> _completeDraft(
  FakeSafeZonePlatform platform, {
  int countdown = 0,
}) async {
  final vm = _setup(platform);
  await vm.load();
  vm
    ..setOwnerName('Luz')
    ..toggleRecipient('+51900000001')
    ..setHomeManually(-12.0464, -77.0428)
    ..setCountdown(countdown);
  return vm;
}

void main() {
  group('SafeZoneStatusViewModel', () {
    test('load reads status and config and starts unconfigured', () async {
      final platform = FakeSafeZonePlatform();
      final vm = SafeZoneStatusViewModel(platform: platform);
      expect(vm.loading, isTrue);
      await vm.load();
      expect(vm.loading, isFalse);
      expect(vm.configured, isFalse);
      expect(vm.status, isNotNull);
      vm.dispose();
    });

    test('an unavailable platform is reported as unavailable', () async {
      final platform = FakeSafeZonePlatform()
        ..failWith = const UnavailableError();
      final vm = SafeZoneStatusViewModel(platform: platform);
      await vm.load();
      expect(vm.unavailable, isTrue);
      expect(vm.error, isNull);
      vm.dispose();
    });

    test('another failure is an error, not unavailable', () async {
      final platform = FakeSafeZonePlatform()..failWith = const FailedError();
      final vm = SafeZoneStatusViewModel(platform: platform);
      await vm.load();
      expect(vm.unavailable, isFalse);
      expect(vm.error, isA<FailedError>());
      expect(vm.loading, isFalse);
      vm.dispose();
    });

    test(
      'events arrive newest first, deduplicated against lastEvent',
      () async {
        const last = SafeZoneEvent(
          type: SafeZoneEventType.monitoringStarted,
          atMillis: 100,
          test: false,
        );
        final platform = FakeSafeZonePlatform(
          status: statusWith(lastEvent: last),
          config: sampleConfig(),
        );
        final vm = SafeZoneStatusViewModel(platform: platform);
        await vm.load();
        platform
          ..emit(last)
          ..emit(
            const SafeZoneEvent(
              type: SafeZoneEventType.exitDetected,
              atMillis: 200,
              test: false,
            ),
          );
        await Future<void>.delayed(Duration.zero);
        expect(vm.events.map((e) => e.atMillis), [200, 100]);
        vm.dispose();
      },
    );

    test('a stale load result is discarded', () async {
      final gate = Completer<void>();
      final platform = _SlowFirstStatusPlatform(gate);
      final vm = SafeZoneStatusViewModel(platform: platform);
      final first = vm.load();
      final second = vm.load();
      await second;
      expect(vm.status!.sentTodayEpisodes, 2);
      gate.complete();
      await first;
      expect(vm.status!.sentTodayEpisodes, 2, reason: 'older answer ignored');
      vm.dispose();
    });

    test('a double tap on stop runs the command once', () async {
      final platform = FakeSafeZonePlatform(
        status: statusWith(monitoring: true, permissions: allGranted),
        config: sampleConfig(),
      );
      final vm = SafeZoneStatusViewModel(platform: platform);
      await vm.load();
      final a = vm.stopMonitoring();
      final b = vm.stopMonitoring();
      await Future.wait([a, b]);
      await Future<void>.delayed(Duration.zero);
      expect(platform.calls.where((c) => c == 'stopMonitoring'), hasLength(1));
      expect(
        vm.monitoring,
        isFalse,
        reason: 'status re-read after the command',
      );
      vm.dispose();
    });

    test('a failed command becomes a problem note, never success', () async {
      final platform = FakeSafeZonePlatform(
        status: statusWith(monitoring: false, permissions: allGranted),
        config: sampleConfig(),
      );
      final vm = SafeZoneStatusViewModel(platform: platform);
      await vm.load();
      platform.failWith = const PermissionMissingError('sendSms');
      await vm.resumeMonitoring();
      expect(vm.note!.isProblem, isTrue);
      expect(vm.running, isNull);
      vm.dispose();
    });

    test('the SMS test keeps the per-recipient outcomes', () async {
      final platform =
          FakeSafeZonePlatform(
              status: statusWith(permissions: allGranted),
              config: sampleConfig(),
            )
            ..testResults = const [
              TestSendResult(phone: '+51900000001', outcome: SendOutcome.sent),
            ];
      final vm = SafeZoneStatusViewModel(platform: platform);
      await vm.load();
      await vm.sendTestMessage();
      expect(vm.testResults.single.outcome, SendOutcome.sent);
      expect(platform.calls, contains('sendTestMessage'));
      vm.dispose();
    });

    test('resume re-reads the status', () async {
      final platform = FakeSafeZonePlatform(config: sampleConfig());
      final vm = SafeZoneStatusViewModel(platform: platform);
      await vm.load();
      expect(vm.status!.permissions.backgroundLocation, isFalse);
      platform.status = statusWith(permissions: allGranted);
      await vm.refresh();
      expect(vm.status!.permissions.backgroundLocation, isTrue);
      vm.dispose();
    });
  });

  group('SafeZoneSetupViewModel', () {
    test('defaults are the contract defaults', () async {
      final vm = _setup(FakeSafeZonePlatform());
      await vm.load();
      expect(vm.mode, AlertMode.awayDuringWindow);
      expect(vm.minAwayMinutes, 5);
      expect(vm.countdownSeconds, 60);
      expect(vm.dailyLimit, 2);
      expect(vm.radiusMeters, 300);
    });

    test('each step blocks until its own rules hold', () async {
      final vm = _setup(FakeSafeZonePlatform());
      await vm.load();
      expect(vm.canAdvance, isTrue, reason: 'intro');
      vm.next();
      expect(vm.step, SetupStep.recipients);
      expect(vm.canAdvance, isFalse);
      vm.next();
      expect(vm.step, SetupStep.recipients, reason: 'cannot skip');
      vm.setOwnerName('Luz');
      expect(vm.canAdvance, isFalse, reason: 'needs a recipient');
      vm.toggleRecipient('+51900000001');
      expect(vm.canAdvance, isTrue);
      vm.next();
      expect(vm.step, SetupStep.home);
      expect(vm.canAdvance, isFalse);
      expect(vm.setHomeManually(200, 0), isFalse);
      expect(vm.setHomeManually(-12.0, -77.0), isTrue);
      expect(vm.canAdvance, isTrue);
    });

    test(
      'start == end blocks the parameters step in window mode only',
      () async {
        final vm = _setup(FakeSafeZonePlatform())..goTo(SetupStep.parameters);
        await vm.load();
        vm
          ..setWindowStart(600)
          ..setWindowEnd(600);
        expect(vm.issuesFor(SetupStep.parameters), [
          ConfigIssue.windowIsAlways,
        ]);
        expect(vm.canAdvance, isFalse);
        vm.setMode(AlertMode.awayAnytime);
        expect(vm.canAdvance, isTrue);
      },
    );

    test('a countdown needs the PIN before the sending step passes', () async {
      final platform = FakeSafeZonePlatform();
      final vm = _setup(platform)..goTo(SetupStep.sending);
      await vm.load();
      expect(vm.canAdvance, isFalse);
      await vm.savePin('12', '12');
      expect(vm.pinSet, isFalse);
      expect(vm.note!.isProblem, isTrue);
      await vm.savePin('1234', '4321');
      expect(vm.pinSet, isFalse);
      expect(platform.calls, isNot(contains('setCancelPin')));
      await vm.savePin('1234', '1234');
      expect(vm.pinSet, isTrue);
      expect(vm.canAdvance, isTrue);
      vm.setCountdown(0);
      expect(vm.canAdvance, isTrue);
    });

    test('useCurrentLocation stores the point and the accuracy', () async {
      final platform = FakeSafeZonePlatform();
      final vm = _setup(platform);
      await vm.load();
      await vm.useCurrentLocation();
      expect(vm.home, const GeoPoint(lat: -12.0464, lng: -77.0428));
      expect(vm.homeAccuracyMeters, 18);
    });

    test('a missing location permission is a note, not a crash', () async {
      final platform = FakeSafeZonePlatform();
      final vm = _setup(platform);
      await vm.load();
      platform.failWith = const PermissionMissingError();
      await vm.useCurrentLocation();
      expect(vm.home, isNull);
      expect(vm.note!.isProblem, isTrue);
    });

    test('monitoring cannot start without the required permissions', () async {
      final platform = FakeSafeZonePlatform(
        status: statusWith(
          permissions: const SafePermissions(
            fineLocation: true,
            backgroundLocation: false,
            sendSms: true,
            notifications: true,
            batteryOptimizationIgnored: false,
          ),
        ),
      );
      final vm = await _completeDraft(platform);
      expect(vm.missingRequired, [PermissionKind.backgroundLocation]);
      expect(vm.canStart, isFalse);
      await vm.finish();
      expect(vm.finished, isFalse);
      expect(platform.calls, isNot(contains('startMonitoring')));
      expect(platform.saved, isEmpty);
    });

    test('notifications are required only with a countdown', () async {
      final platform = FakeSafeZonePlatform(
        status: statusWith(
          permissions: const SafePermissions(
            fineLocation: true,
            backgroundLocation: true,
            sendSms: true,
            notifications: false,
            batteryOptimizationIgnored: false,
          ),
        ),
        pinSet: true,
      );
      final vm = await _completeDraft(platform);
      expect(vm.canStart, isTrue, reason: 'direct send');
      vm.setCountdown(60);
      expect(vm.missingRequired, [PermissionKind.notifications]);
      expect(vm.canStart, isFalse);
    });

    test('finish saves, starts and enables monitoring in that order', () async {
      final platform = FakeSafeZonePlatform(
        status: statusWith(permissions: allGranted),
      );
      final vm = await _completeDraft(platform);
      await vm.finish();
      expect(vm.finished, isTrue);
      expect(
        platform.calls.where(
          (c) => c.startsWith('save') || c.startsWith('start'),
        ),
        ['saveConfig', 'startMonitoring', 'saveConfig'],
      );
      expect(platform.saved.first.monitoringEnabled, isFalse);
      expect(platform.saved.last.monitoringEnabled, isTrue);
      expect(platform.saved.last.recipients.single.name, 'Ana');
    });

    test('a double tap on finish saves once', () async {
      final gate = Completer<void>();
      final platform = FakeSafeZonePlatform(
        status: statusWith(permissions: allGranted),
      )..holdSaveConfig = gate;
      final vm = await _completeDraft(platform);
      final a = vm.finish();
      final b = vm.finish();
      gate.complete();
      await Future.wait([a, b]);
      expect(platform.calls.where((c) => c == 'startMonitoring'), hasLength(1));
    });

    test('editing a running config saves it without restarting', () async {
      final platform = FakeSafeZonePlatform(
        status: statusWith(monitoring: true, permissions: allGranted),
        config: sampleConfig(),
        pinSet: true,
      );
      final vm = _setup(platform);
      await vm.load();
      expect(vm.ownerName, 'Luz');
      expect(vm.selectedPhones, {'+51900000001'});
      vm.setRadius(500);
      await vm.finish();
      expect(platform.calls, isNot(contains('startMonitoring')));
      expect(platform.saved.single.radiusMeters, 500);
      expect(platform.saved.single.monitoringEnabled, isTrue);
    });

    test(
      'the test SMS stores the draft first and keeps monitoring as is',
      () async {
        final platform =
            FakeSafeZonePlatform(status: statusWith(permissions: allGranted))
              ..testResults = const [
                TestSendResult(
                  phone: '+51900000001',
                  outcome: SendOutcome.failed,
                ),
              ];
        final vm = await _completeDraft(platform);
        await vm.sendTestMessage();
        expect(
          platform.calls,
          containsAllInOrder(['saveConfig', 'sendTestMessage']),
        );
        expect(platform.saved.single.monitoringEnabled, isFalse);
        expect(vm.testResults.single.outcome, SendOutcome.failed);
      },
    );

    test('the test SMS is refused while the draft is incomplete', () async {
      final platform = FakeSafeZonePlatform();
      final vm = _setup(platform);
      await vm.load();
      await vm.sendTestMessage();
      expect(platform.calls, isNot(contains('sendTestMessage')));
      expect(vm.note!.isProblem, isTrue);
    });

    test('a stale status read after dispose does not notify', () async {
      final platform = FakeSafeZonePlatform();
      final vm = _setup(platform);
      final pending = vm.load();
      vm.dispose();
      await pending;
    });
  });
}

/// The first `getStatus` waits on [gate]; the second answers at once.
class _SlowFirstStatusPlatform extends FakeSafeZonePlatform {
  _SlowFirstStatusPlatform(this.gate);

  final Completer<void> gate;
  int _reads = 0;

  @override
  Future<SafeZoneStatus> getStatus() async {
    final read = ++_reads;
    if (read == 1) await gate.future;
    return statusWith(sentToday: read);
  }
}
