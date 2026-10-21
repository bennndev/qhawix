import '../../domain/models/qr_site_note.dart';

/// Maps the `qr-site-notes` gateway JSON (schemaVersion 1) to domain results.
///
/// The body is untrusted: anything unexpected becomes a failure, never a
/// found or saved note.
abstract final class QrSiteNoteMapper {
  static const int schemaVersion = 1;

  static QrSiteNoteResult fromResponse(int status, Object? body) {
    if (status != 200) return QrSiteNoteResult.failed(failureFor(status, body));
    if (body is! Map || body['schemaVersion'] != schemaVersion) {
      return const QrSiteNoteResult.failed(QrSiteNoteFailure.unavailable);
    }
    switch (body['status']) {
      case 'found':
        final note = _note(body['note']);
        return note == null
            ? const QrSiteNoteResult.failed(QrSiteNoteFailure.unavailable)
            : QrSiteNoteResult.found(note);
      case 'none':
        return const QrSiteNoteResult.none();
      case 'saved':
        final note = _note(body['note']);
        return note == null
            ? const QrSiteNoteResult.failed(QrSiteNoteFailure.saveUnconfirmed)
            : QrSiteNoteResult.saved(note);
      case 'deleted':
        return const QrSiteNoteResult.deleted();
      default:
        return const QrSiteNoteResult.failed(QrSiteNoteFailure.unavailable);
    }
  }

  static QrSiteNoteFailure failureFor(int status, Object? body) {
    final code = body is Map ? body['code'] : null;
    return switch (code) {
      'not_configured' => QrSiteNoteFailure.notConfigured,
      'unauthorized' => QrSiteNoteFailure.unauthorized,
      'rate_limited' => QrSiteNoteFailure.rateLimited,
      'provider_timeout' => QrSiteNoteFailure.timeout,
      'invalid_input' || 'payload_too_large' => QrSiteNoteFailure.invalidInput,
      'save_unconfirmed' => QrSiteNoteFailure.saveUnconfirmed,
      'correction_not_applied' => QrSiteNoteFailure.correctionNotApplied,
      _ => switch (status) {
        401 || 403 => QrSiteNoteFailure.unauthorized,
        429 => QrSiteNoteFailure.rateLimited,
        504 => QrSiteNoteFailure.timeout,
        _ => QrSiteNoteFailure.unavailable,
      },
    };
  }

  static QrSiteNote? _note(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final text = value['text'];
    final savedAt = value['savedAt'];
    if (id is! String || id.isEmpty || text is! String || text.isEmpty) {
      return null;
    }
    return QrSiteNote(
      id: id,
      text: text.length > qrSiteNoteMaxLength * 2
          ? text.substring(0, qrSiteNoteMaxLength * 2)
          : text,
      savedAt: savedAt is String ? DateTime.tryParse(savedAt) : null,
    );
  }
}
