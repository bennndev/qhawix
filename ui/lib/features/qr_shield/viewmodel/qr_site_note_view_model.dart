import 'package:flutter/foundation.dart';

import '../domain/models/qr_site_note.dart';
import '../domain/repositories/qr_site_note_repository.dart';

enum QrSiteNoteStatus {
  /// Nothing was asked yet for this host; no request has left the device.
  idle,
  loading,
  saving,
  deleting,
  found,
  none,
  failed,
}

/// Personal notes for the host under review.
///
/// Kept apart from [QrShieldViewModel] on purpose: a note is context the
/// person wrote, and it never feeds the reputation verdict or the opening
/// policy. Every request starts from an explicit tap.
class QrSiteNoteViewModel extends ChangeNotifier {
  QrSiteNoteViewModel({required QrSiteNoteRepository repository})
    : _repository = repository;

  final QrSiteNoteRepository _repository;

  String? _host;
  QrSiteNoteStatus _status = QrSiteNoteStatus.idle;
  QrSiteNote? _note;
  QrSiteNoteFailure? _failure;
  int _activeRequest = 0;
  bool _isDisposed = false;

  bool get isAvailable => _repository.isAvailable;
  String? get host => _host;
  QrSiteNoteStatus get status => _status;
  QrSiteNote? get note => _note;
  QrSiteNoteFailure? get failure => _failure;
  bool get isBusy =>
      _status == QrSiteNoteStatus.loading ||
      _status == QrSiteNoteStatus.saving ||
      _status == QrSiteNoteStatus.deleting;

  /// Points the card at [host] (an exact ASCII host key, or null when the
  /// review has none). Resets state without any network request.
  void focusHost(String? host) {
    if (_isDisposed || host == _host) return;
    _activeRequest++;
    _host = host;
    _status = QrSiteNoteStatus.idle;
    _note = null;
    _failure = null;
    _notify();
  }

  Future<void> load() =>
      _run(QrSiteNoteStatus.loading, (host) => _repository.find(host));

  Future<void> save(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > qrSiteNoteMaxLength) {
      return Future.value();
    }
    return _run(
      QrSiteNoteStatus.saving,
      (host) => _repository.save(host, trimmed),
    );
  }

  Future<void> delete() =>
      _run(QrSiteNoteStatus.deleting, (host) => _repository.delete(host));

  Future<void> _run(
    QrSiteNoteStatus pending,
    Future<QrSiteNoteResult> Function(String host) request,
  ) async {
    final host = _host;
    if (_isDisposed || host == null || isBusy || !isAvailable) return;
    final requestId = ++_activeRequest;
    final previousStatus = _status;
    final previousNote = _note;
    _status = pending;
    _failure = null;
    _notify();

    QrSiteNoteResult result;
    try {
      result = await request(host);
    } catch (_) {
      result = const QrSiteNoteResult.failed(QrSiteNoteFailure.unavailable);
    }
    if (_isDisposed || requestId != _activeRequest || host != _host) return;

    switch (result.outcome) {
      case QrSiteNoteOutcome.found:
      case QrSiteNoteOutcome.saved:
        _status = QrSiteNoteStatus.found;
        _note = result.note;
      case QrSiteNoteOutcome.none:
      case QrSiteNoteOutcome.deleted:
        _status = QrSiteNoteStatus.none;
        _note = null;
      case QrSiteNoteOutcome.failed:
        // Keep what was already confirmed; a failed save or delete never
        // changes the note shown.
        _status = previousNote != null
            ? QrSiteNoteStatus.found
            : previousStatus == QrSiteNoteStatus.none
            ? QrSiteNoteStatus.none
            : QrSiteNoteStatus.failed;
        _failure = result.failure;
    }
    _notify();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
