import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/trust_circle/data/mock/mock_trust_circle_repository.dart';
import 'package:qhawix/features/trust_circle/domain/action_result.dart';
import 'package:qhawix/features/trust_circle/domain/alert_preferences.dart';
import 'package:qhawix/features/trust_circle/domain/check_in.dart';
import 'package:qhawix/features/trust_circle/domain/refuge_request.dart';
import 'package:qhawix/features/trust_circle/domain/sos.dart';
import 'package:qhawix/features/trust_circle/domain/trust_circle_snapshot.dart';
import 'package:qhawix/features/trust_circle/domain/trust_contact.dart';
import 'package:qhawix/features/trust_circle/viewmodel/family_keyword_view_model.dart';
import 'package:qhawix/features/trust_circle/viewmodel/trust_circle_view_model.dart';

import 'test_support.dart';

/// Mock whose `load` waits for the test, to reorder responses.
class _GatedRepository extends MockTrustCircleRepository {
  _GatedRepository({required super.clock});

  final gates = <Completer<void>>[];

  @override
  Future<TrustCircleSnapshot> load() async {
    final snapshot = await super.load();
    if (gates.isEmpty) return snapshot;
    await gates.removeAt(0).future;
    return snapshot;
  }
}

void main() {
  late FixedClock clock;
  late MockTrustCircleRepository repo;
  late TrustCircleViewModel vm;

  setUp(() async {
    clock = FixedClock();
    repo = MockTrustCircleRepository(clock: clock);
    vm = TrustCircleViewModel(repository: repo, clock: clock);
    await vm.load();
  });

  tearDown(() => vm.dispose());

  test('loads the example circle with the three contact states', () {
    expect(vm.contacts.map((c) => c.status).toSet(), {
      ContactStatus.active,
      ContactStatus.invited,
      ContactStatus.paused,
    });
    expect(vm.pendingRequests, hasLength(1));
    expect(vm.hasKeyword, isFalse);
  });

  test('only active contacts with alerts enabled are reachable', () {
    expect(vm.reachableContacts.map((c) => c.id), ['c1', 'c2']);
  });

  test('an invitation stays invited and says nothing was sent', () async {
    final result = await vm.inviteContact(
      name: 'Eli Ejemplo',
      phone: '+51 000 000 009',
    );
    expect(result.outcome, ActionOutcome.exampleOnly);
    expect(result.message, contains('no se envió ninguna invitación'));
    expect(result.message, isNot(matches(claimsDelivery)));
    expect(vm.contacts.last.status, ContactStatus.invited);
  });

  test('an invitation with missing data is rejected and adds nobody', () async {
    final before = vm.contacts.length;
    final result = await vm.inviteContact(name: ' ', phone: '12');
    expect(result.isRejected, isTrue);
    expect(vm.contacts, hasLength(before));
  });

  test('pausing and resuming changes the contact status', () async {
    await vm.setContactPaused('c1', paused: true);
    expect(vm.contactById('c1')!.status, ContactStatus.paused);
    await vm.setContactPaused('c1', paused: false);
    expect(vm.contactById('c1')!.status, ContactStatus.active);
  });

  test('removing a contact also drops it from alerts and requests', () async {
    await vm.removeContact('c1');
    expect(vm.contactById('c1'), isNull);
    expect(vm.pendingRequests, isEmpty);
    expect(
      vm.alertPreferences.recipientsOf(AlertEventKind.paymentHold),
      isEmpty,
    );
  });

  test('push can never be the fallback channel', () async {
    final result = await vm.setContactFallback('c1', AlertChannel.push);
    expect(result.isRejected, isTrue);
    expect(vm.contactById('c1')!.fallbackChannel, AlertChannel.sms);
  });

  test(
    'SOS without recipients is rejected; with recipients it sends nothing',
    () async {
      final none = await vm.sendSos(
        contactIds: {},
        duration: SosDuration.min30,
      );
      expect(none.isRejected, isTrue);
      final some = await vm.sendSos(
        contactIds: {'c1'},
        duration: SosDuration.min30,
      );
      expect(some.outcome, ActionOutcome.exampleOnly);
      expect(some.message, contains('no se envió ningún aviso'));
      expect(some.message, isNot(matches(claimsDelivery)));
    },
  );

  test('a double tap runs the command once', () async {
    final a = vm.inviteContact(name: 'Eli Ejemplo', phone: '+51 000 000 009');
    final b = vm.inviteContact(name: 'Eli Ejemplo', phone: '+51 000 000 009');
    await Future.wait([a, b]);
    expect(vm.contacts.where((c) => c.name == 'Eli Ejemplo'), hasLength(1));
  });

  group('check-in', () {
    test(
      'waits, then turns overdue when the clock passes the window',
      () async {
        await vm.startCheckIn(CheckInWindow.hour1);
        expect(vm.checkInStatus, CheckInStatus.waiting);
        clock.time = clock.time.add(const Duration(minutes: 59));
        expect(vm.checkInStatus, CheckInStatus.waiting);
        clock.time = clock.time.add(const Duration(minutes: 1));
        expect(vm.checkInStatus, CheckInStatus.overdue);
      },
    );

    test('confirming wins over time', () async {
      await vm.startCheckIn(CheckInWindow.min30);
      await vm.confirmCheckIn();
      clock.time = clock.time.add(const Duration(hours: 5));
      expect(vm.checkInStatus, CheckInStatus.confirmed);
    });

    test('cancelling clears the window', () async {
      await vm.startCheckIn(CheckInWindow.min30);
      await vm.cancelCheckIn();
      expect(vm.checkIn, isNull);
      expect(vm.checkInStatus, isNull);
    });
  });

  group('remote Refuge requests', () {
    test('approving and denying leave the pending list', () async {
      await vm.resolveRefugeRequest('r1', approve: true);
      expect(vm.pendingRequests, isEmpty);
      expect(
        vm.snapshot!.refugeRequests.single.status,
        RefugeRequestStatus.approved,
      );
    });

    test('approving says no Refuge was activated', () async {
      final result = await vm.resolveRefugeRequest('r1', approve: true);
      expect(result.message, contains('no se activó ningún Refugio'));
    });
  });

  test('a load that answers late does not overwrite a newer one', () async {
    final gated = _GatedRepository(clock: clock);
    final model = TrustCircleViewModel(repository: gated, clock: clock);
    addTearDown(model.dispose);
    final slow = Completer<void>();
    final fast = Completer<void>();
    gated.gates.addAll([slow, fast]);
    final first = model.load();
    await Future<void>.delayed(Duration.zero);
    await gated.removeContact('c1');
    final second = model.load();
    await Future<void>.delayed(Duration.zero);
    fast.complete();
    await second;
    expect(model.contactById('c1'), isNull);
    slow.complete();
    await first;
    expect(model.contactById('c1'), isNull);
  });

  test('a disposed view model ignores late responses', () async {
    final gated = _GatedRepository(clock: clock);
    final model = TrustCircleViewModel(repository: gated, clock: clock);
    final gate = Completer<void>();
    gated.gates.add(gate);
    final pending = model.load();
    await Future<void>.delayed(Duration.zero);
    model.dispose();
    gate.complete();
    await expectLater(pending, completes);
  });

  group('family keyword', () {
    late FamilyKeywordViewModel keyword;

    setUp(() async {
      keyword = FamilyKeywordViewModel(repository: repo);
      await keyword.load();
    });

    tearDown(() => keyword.dispose());

    test('starts without a keyword and cannot reveal anything', () {
      expect(keyword.loaded, isTrue);
      expect(keyword.hasKeyword, isFalse);
      keyword.reveal();
      expect(keyword.revealed, isFalse);
    });

    test('is hidden after creating it and shown only after reveal', () async {
      final result = await keyword.save('cóndor azul');
      expect(result.isRejected, isFalse);
      expect(keyword.hasKeyword, isTrue);
      expect(keyword.revealed, isFalse);
      keyword.reveal();
      expect(keyword.revealed, isTrue);
      keyword.hide();
      expect(keyword.revealed, isFalse);
    });

    test('a short keyword is rejected and nothing changes', () async {
      final result = await keyword.save('ab');
      expect(result.isRejected, isTrue);
      expect(keyword.hasKeyword, isFalse);
    });

    test('changing the keyword hides it again', () async {
      await keyword.save('cóndor azul');
      keyword.reveal();
      await keyword.save('puma rojo');
      expect(keyword.revealed, isFalse);
      expect(keyword.keyword, 'puma rojo');
    });
  });
}
