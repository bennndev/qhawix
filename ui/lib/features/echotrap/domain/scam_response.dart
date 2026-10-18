import 'dart:convert';

/// What EchoTrap does on its own once a call turns red: it tells the caller
/// (spoken, on the caller's own phone) and warns the person's trusted
/// contacts. The notice travels over the call's data channel; it carries no
/// audio and no personal data.
class ScamNotice {
  const ScamNotice({required this.reported});

  /// LiveKit data topic for the notice.
  static const String topic = 'qhawix.scam';

  static const String _type = 'qhawix.scam_notice';
  static const int _version = 1;

  /// True only when at least one trusted contact was actually warned.
  final bool reported;

  List<int> encode() => utf8.encode(
    jsonEncode({'type': _type, 'v': _version, 'reported': reported}),
  );

  /// Returns null for anything that is not a valid notice.
  static ScamNotice? tryParse(List<int> bytes) {
    if (bytes.isEmpty || bytes.length > 512) return null;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map ||
          decoded['type'] != _type ||
          decoded['v'] != _version ||
          decoded['reported'] is! bool) {
        return null;
      }
      return ScamNotice(reported: decoded['reported'] as bool);
    } on FormatException {
      return null;
    }
  }

  /// Short sentence spoken to the caller. "Reportada" is only said when a
  /// trusted contact really was warned.
  String get spokenText => reported
      ? 'Atención. Esta llamada está siendo analizada por Qhawix, fue marcada '
            'como posible estafa y ya se avisó a contactos de confianza.'
      : 'Atención. Esta llamada está siendo analizada por Qhawix y fue '
            'marcada como posible estafa.';
}

/// SMS sent to a trusted contact when a call turns red.
const String scamAlertSmsText =
    'QHAWIX: una llamada que recibí fue marcada como posible estafa. '
    'Estoy atento(a). Si me ves actuar raro, llámame. Mensaje automático.';
