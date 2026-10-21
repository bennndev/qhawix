/// A short note the person wrote about a destination they reviewed.
///
/// It is personal context only: it never changes the reputation result, the
/// opening policy or any other safety decision of Escudo QR.
class QrSiteNote {
  const QrSiteNote({required this.id, required this.text, this.savedAt});

  final String id;

  /// Text as stored, after server-side redaction.
  final String text;
  final DateTime? savedAt;
}

enum QrSiteNoteOutcome { found, none, saved, deleted, failed }

enum QrSiteNoteFailure {
  /// Notes are not enabled in this installation (no provider credentials).
  notConfigured,
  unauthorized,
  rateLimited,
  timeout,
  unavailable,
  invalidInput,

  /// The provider answered but did not confirm a stored note.
  saveUnconfirmed,

  /// A correction could not replace the previous note; the previous note is
  /// kept unchanged.
  correctionNotApplied,
}

class QrSiteNoteResult {
  const QrSiteNoteResult._(this.outcome, {this.note, this.failure});

  const QrSiteNoteResult.found(QrSiteNote note)
    : this._(QrSiteNoteOutcome.found, note: note);
  const QrSiteNoteResult.none() : this._(QrSiteNoteOutcome.none);
  const QrSiteNoteResult.saved(QrSiteNote note)
    : this._(QrSiteNoteOutcome.saved, note: note);
  const QrSiteNoteResult.deleted() : this._(QrSiteNoteOutcome.deleted);
  const QrSiteNoteResult.failed(QrSiteNoteFailure failure)
    : this._(QrSiteNoteOutcome.failed, failure: failure);

  final QrSiteNoteOutcome outcome;
  final QrSiteNote? note;
  final QrSiteNoteFailure? failure;
}

/// Maximum note length accepted by the gateway.
const int qrSiteNoteMaxLength = 280;

final RegExp _hostPattern = RegExp(
  r'^(?=.{1,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z](?:[a-z0-9-]{0,61}[a-z0-9])?$',
);

/// Exact key for notes: the lowercase ASCII (Punycode) host, so a look-alike
/// Unicode domain never receives the note of the real one. Null when the host
/// cannot carry a note (IP literal, local name, invalid).
String? qrSiteNoteHostKey(String asciiHost) {
  var host = asciiHost.trim().toLowerCase();
  if (host.endsWith('.')) host = host.substring(0, host.length - 1);
  return _hostPattern.hasMatch(host) ? host : null;
}
