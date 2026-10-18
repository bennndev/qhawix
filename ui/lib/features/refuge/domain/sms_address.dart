/// Digits (and optional leading `+`) for Android SmsManager.
///
/// Contact pickers often return spaces, dashes or parentheses; those break
/// direct sends even when the permission is granted.
String normalizeSmsAddress(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final out = StringBuffer();
  if (trimmed.startsWith('+')) out.write('+');
  for (final unit in trimmed.codeUnits) {
    if (unit >= 0x30 && unit <= 0x39) out.writeCharCode(unit);
  }
  final result = out.toString();
  if (result == '+') return '';
  return result;
}
