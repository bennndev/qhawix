import '../models/qr_site_note.dart';

/// Personal notes per reviewed host, owned by the signed-in account.
abstract interface class QrSiteNoteRepository {
  /// False when there is no signed-in session or no backend configured; the
  /// review screen then shows nothing about notes.
  bool get isAvailable;

  Future<QrSiteNoteResult> find(String host);
  Future<QrSiteNoteResult> save(String host, String note);
  Future<QrSiteNoteResult> delete(String host);
}
