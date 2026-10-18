import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/trust_circle/data/local_trust_circle_repository.dart';
import 'package:qhawix/features/trust_circle/domain/action_result.dart';
import 'package:qhawix/features/trust_circle/domain/clock.dart';
import 'package:qhawix/features/trust_circle/domain/sos.dart';

class _FixedClock implements Clock {
  _FixedClock(this.time);
  DateTime time;
  @override
  DateTime now() => time;
}

void main() {
  late Directory dir;
  late LocalTrustCircleRepository repo;
  final launched = <Uri>[];

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('trust_circle_test_');
    launched.clear();
    repo = LocalTrustCircleRepository(
      clock: _FixedClock(DateTime.utc(2026, 10, 17, 15)),
      supportDirectory: () async => dir,
      launchUri: (uri) async {
        launched.add(uri);
        return true;
      },
    );
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('starts empty without example data and without setup', () async {
    final snap = await repo.load();
    expect(repo.usesExampleData, isFalse);
    expect(snap.setupComplete, isFalse);
    expect(snap.contacts, isEmpty);
  });

  test('completeSetup persists and survives a new repository instance', () async {
    await repo.completeSetup();
    expect((await repo.load()).setupComplete, isTrue);

    final again = LocalTrustCircleRepository(
      clock: _FixedClock(DateTime.utc(2026, 10, 17, 15)),
      supportDirectory: () async => dir,
      launchUri: (_) async => true,
    );
    expect((await again.load()).setupComplete, isTrue);
  });

  test('addContact persists a phone-only contact', () async {
    final result = await repo.addContact(
      name: 'Ana',
      phone: '+51 999 111 222',
    );
    expect(result.outcome, ActionOutcome.saved);
    expect(result.message, contains('No se envió ningún mensaje'));
    final snap = await repo.load();
    expect(snap.contacts, hasLength(1));
    expect(snap.contacts.single.name, 'Ana');
    expect(snap.contacts.single.phone, '+51 999 111 222');
  });

  test('sendSos opens a message URI and does not claim delivery', () async {
    await repo.addContact(name: 'Ana', phone: '+51999111222');
    final id = (await repo.load()).contacts.single.id;
    final result = await repo.sendSos(
      contactIds: {id},
      duration: SosDuration.min15,
    );
    expect(result.outcome, ActionOutcome.saved);
    expect(result.message.toLowerCase(), isNot(contains('enviada')));
    expect(launched, hasLength(1));
    expect(launched.single.scheme, 'sms');
  });
}
