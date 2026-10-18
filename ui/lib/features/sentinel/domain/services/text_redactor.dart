import '../models/redaction_result.dart';
import '../ports/text_redaction_port.dart';

class TextRedactor implements TextRedactionPort {
  const TextRedactor();

  static final List<(RegExp, String)> _patterns = [
    (
      RegExp(
        r"""((?:https?://|www\.)[^\s<>"]*[?&](?:access[_-]?token|api[_-]?key|auth|authorization|code|otp|password|passwd|pin|pwd|secret|session(?:id)?|token|key)=)[^&#\s]+""",
        caseSensitive: false,
      ),
      r'$1 [DATO DE ACCESO]',
    ),
    (
      RegExp(
        r'\b((?:c[oó]digo(?:\s+(?:otp|pin|cvv|sms|bancario|de\s+(?:seguridad|verificaci[oó]n|acceso|autenticaci[oó]n)))?|otp|pin|cvv|contrase[nñ]a|clave))\s*(?:es|:|=)?\s*[A-Z0-9_-]{3,64}\b',
        caseSensitive: false,
      ),
      r'$1 [DATO SECRETO]',
    ),
    (
      RegExp(r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b', caseSensitive: false),
      '[CORREO]',
    ),
    (
      RegExp(r'\b(?:dni|documento|c[eé])\s*(?:n[uú]mero|nro\.?|#|:)?\s*\d{7,12}\b', caseSensitive: false),
      '[DOCUMENTO]',
    ),
    (
      RegExp(r'\b(?:cuenta|cci|tarjeta)\s*(?:n[uú]mero|nro\.?|#|:)?\s*[0-9 -]{8,24}\d\b', caseSensitive: false),
      '[NÚMERO FINANCIERO]',
    ),
    (
      RegExp(r'(?<!\d)(?:\d[ -]?){13,19}(?!\d)'),
      '[TARJETA]',
    ),
    (
      RegExp(r'(?<!\w)\+?\d{1,3}[ -]?(?:\(\d{1,4}\)[ -]?)?\d(?:[ -]?\d){6,10}(?!\w)'),
      '[TELÉFONO]',
    ),
  ];

  @override
  RedactionResult redact(String input) {
    var redacted = input;
    var count = 0;
    for (final (pattern, replacement) in _patterns) {
      redacted = redacted.replaceAllMapped(pattern, (match) {
        count++;
        if (replacement.startsWith(r'$1')) {
          return '${match.group(1) ?? ''}${replacement.substring(2)}';
        }
        return replacement;
      });
    }
    return RedactionResult(text: redacted, redactionCount: count);
  }
}
