import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/qr_shield/domain/models/qr_site_note.dart';
import 'package:qhawix/features/qr_shield/domain/repositories/qr_site_note_repository.dart';
import 'package:qhawix/features/qr_shield/viewmodel/qr_site_note_view_model.dart';

void main() {
  late _FakeSiteNoteRepository repository;
  late QrSiteNoteViewModel viewModel;

  setUp(() {
    repository = _FakeSiteNoteRepository();
    viewModel = QrSiteNoteViewModel(repository: repository);
  });

  tearDown(() => viewModel.dispose());

  test('focusing a host sends nothing until the person asks', () {
    viewModel.focusHost('mitienda.pe');
    expect(viewModel.status, QrSiteNoteStatus.idle);
    expect(repository.calls, isEmpty);
  });

  test('loads, saves, corrects and deletes a note', () async {
    viewModel.focusHost('mitienda.pe');
    await viewModel.load();
    expect(viewModel.status, QrSiteNoteStatus.none);

    await viewModel.save('  Primera  ');
    expect(viewModel.status, QrSiteNoteStatus.found);
    expect(viewModel.note!.text, 'Primera');

    await viewModel.save('Corregida');
    expect(viewModel.note!.text, 'Corregida');

    await viewModel.delete();
    expect(viewModel.status, QrSiteNoteStatus.none);
    expect(viewModel.note, isNull);
    expect(repository.calls, ['get', 'save', 'save', 'delete']);
  });

  test('a failed delete keeps showing the confirmed note', () async {
    viewModel.focusHost('mitienda.pe');
    await viewModel.save('Mi nota');
    repository.failNext = QrSiteNoteFailure.unavailable;
    await viewModel.delete();
    expect(viewModel.status, QrSiteNoteStatus.found);
    expect(viewModel.note!.text, 'Mi nota');
    expect(viewModel.failure, QrSiteNoteFailure.unavailable);
  });

  test('a correction that was not applied keeps the previous note', () async {
    viewModel.focusHost('mitienda.pe');
    await viewModel.save('Primera');
    repository.failNext = QrSiteNoteFailure.correctionNotApplied;
    await viewModel.save('Segunda');
    expect(viewModel.status, QrSiteNoteStatus.found);
    expect(viewModel.note!.text, 'Primera');
    expect(viewModel.failure, QrSiteNoteFailure.correctionNotApplied);
  });

  test('a failed save is not shown as saved', () async {
    viewModel.focusHost('mitienda.pe');
    await viewModel.load();
    repository.failNext = QrSiteNoteFailure.saveUnconfirmed;
    await viewModel.save('Mi nota');
    expect(viewModel.status, QrSiteNoteStatus.none);
    expect(viewModel.note, isNull);
    expect(viewModel.failure, QrSiteNoteFailure.saveUnconfirmed);
  });

  test('discards a response that arrives after the host changed', () async {
    repository.notes['first.pe'] = 'Nota de first';
    final gate = Completer<void>();
    repository.gate = gate;
    viewModel.focusHost('first.pe');
    final pending = viewModel.load();
    viewModel.focusHost('second.pe');
    gate.complete();
    await pending;
    expect(viewModel.host, 'second.pe');
    expect(viewModel.status, QrSiteNoteStatus.idle);
    expect(viewModel.note, isNull);
  });

  test('rejects empty and over-long notes without a request', () async {
    viewModel.focusHost('mitienda.pe');
    await viewModel.save('   ');
    await viewModel.save('a' * (qrSiteNoteMaxLength + 1));
    expect(repository.calls, isEmpty);
  });

  test('does nothing when notes are unavailable', () async {
    repository.isAvailable = false;
    viewModel.focusHost('mitienda.pe');
    await viewModel.load();
    expect(repository.calls, isEmpty);
    expect(viewModel.status, QrSiteNoteStatus.idle);
  });
}

class _FakeSiteNoteRepository implements QrSiteNoteRepository {
  final calls = <String>[];
  final notes = <String, String>{};
  QrSiteNoteFailure? failNext;
  Completer<void>? gate;

  @override
  bool isAvailable = true;

  Future<QrSiteNoteResult?> _start(String action) async {
    calls.add(action);
    final pending = gate;
    if (pending != null) {
      gate = null;
      await pending.future;
    }
    final failure = failNext;
    failNext = null;
    return failure == null ? null : QrSiteNoteResult.failed(failure);
  }

  @override
  Future<QrSiteNoteResult> find(String host) async {
    final failed = await _start('get');
    if (failed != null) return failed;
    final text = notes[host];
    return text == null
        ? const QrSiteNoteResult.none()
        : QrSiteNoteResult.found(QrSiteNote(id: host, text: text));
  }

  @override
  Future<QrSiteNoteResult> save(String host, String note) async {
    final failed = await _start('save');
    if (failed != null) return failed;
    notes[host] = note;
    return QrSiteNoteResult.saved(QrSiteNote(id: host, text: note));
  }

  @override
  Future<QrSiteNoteResult> delete(String host) async {
    final failed = await _start('delete');
    if (failed != null) return failed;
    notes.remove(host);
    return const QrSiteNoteResult.deleted();
  }
}
