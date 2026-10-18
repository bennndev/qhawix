import 'dart:convert';

const int maxQrPayloadBytes = 8 * 1024;

enum QrPayloadKind {
  url,
  text,
  vCard,
  calendar,
  geocoordinates,
  wifi,
  phone,
  sms,
  email,
  payment,
  unsupported,
}

class QrScanPayload {
  const QrScanPayload._({
    required this.rawValue,
    required this.byteLength,
    required this.kind,
    this.errorCode,
  });

  factory QrScanPayload.create(String rawValue) {
    if (rawValue.length > maxQrPayloadBytes) {
      return QrScanPayload._(
        rawValue: '',
        byteLength: maxQrPayloadBytes + 1,
        kind: QrPayloadKind.unsupported,
        errorCode: 'payload_too_large',
      );
    }

    if (_containsUnpairedSurrogate(rawValue)) {
      return QrScanPayload._(
        rawValue: '',
        byteLength: 0,
        kind: QrPayloadKind.unsupported,
        errorCode: 'invalid_encoding',
      );
    }
    final byteLength = utf8.encode(rawValue).length;
    if (byteLength > maxQrPayloadBytes) {
      return QrScanPayload._(
        rawValue: '',
        byteLength: byteLength,
        kind: QrPayloadKind.unsupported,
        errorCode: 'payload_too_large',
      );
    }

    final visibleContent = String.fromCharCodes(
      rawValue.runes.where((rune) => !_isControlOrFormattingRune(rune)),
    );
    if (visibleContent.trim().isEmpty) {
      return QrScanPayload._(
        rawValue: '',
        byteLength: byteLength,
        kind: QrPayloadKind.unsupported,
        errorCode: 'empty_payload',
      );
    }

    return QrScanPayload._(
      rawValue: rawValue,
      byteLength: byteLength,
      kind: classifyQrPayload(rawValue),
    );
  }

  final String rawValue;
  final int byteLength;
  final QrPayloadKind kind;
  final String? errorCode;

  bool get isAccepted => errorCode == null;

  bool get mayContainSensitiveContent =>
      kind == QrPayloadKind.unsupported ||
      const {
        QrPayloadKind.vCard,
        QrPayloadKind.calendar,
        QrPayloadKind.geocoordinates,
        QrPayloadKind.wifi,
        QrPayloadKind.phone,
        QrPayloadKind.sms,
        QrPayloadKind.email,
        QrPayloadKind.payment,
      }.contains(kind) ||
      _containsPotentialSecrets(rawValue);

  String get safeDisplayValue => escapeControlCharacters(rawValue);
}

bool _containsUnpairedSurrogate(String value) {
  for (var index = 0; index < value.length; index++) {
    final codeUnit = value.codeUnitAt(index);
    if (codeUnit >= 0xd800 && codeUnit <= 0xdbff) {
      if (index + 1 >= value.length) return true;
      final nextCodeUnit = value.codeUnitAt(index + 1);
      if (nextCodeUnit < 0xdc00 || nextCodeUnit > 0xdfff) return true;
      index++;
    } else if (codeUnit >= 0xdc00 && codeUnit <= 0xdfff) {
      return true;
    }
  }
  return false;
}

bool _containsPotentialSecrets(String value) => RegExp(
  r'(?:access[_-]?token|api[_-]?key|authorization|password|passwd|pin|secret|session|token|otp)\s*[:=]',
  caseSensitive: false,
).hasMatch(value);

QrPayloadKind classifyQrPayload(String rawValue) {
  final value = String.fromCharCodes(
    rawValue.runes.where((rune) => !_isControlOrFormattingRune(rune)),
  ).trimLeft();
  final upper = value.toUpperCase();

  if (upper.startsWith('BEGIN:VCARD') || upper.startsWith('MECARD:')) {
    return QrPayloadKind.vCard;
  }
  if (upper.startsWith('BEGIN:VCALENDAR') || upper.startsWith('BEGIN:VEVENT')) {
    return QrPayloadKind.calendar;
  }
  if (value.toLowerCase().startsWith('geo:') || _isCoordinatePair(value)) {
    return QrPayloadKind.geocoordinates;
  }
  if (upper.startsWith('WIFI:')) return QrPayloadKind.wifi;

  final uri = Uri.tryParse(value);
  final scheme = uri?.scheme.toLowerCase();
  if (scheme == 'http' || scheme == 'https') return QrPayloadKind.url;
  if (scheme == 'tel') return QrPayloadKind.phone;
  if (scheme == 'sms' || scheme == 'smsto') return QrPayloadKind.sms;
  if (scheme == 'mailto') return QrPayloadKind.email;
  if (const {
    'upi',
    'bitcoin',
    'ethereum',
    'payto',
    'web+pay',
  }.contains(scheme)) {
    return QrPayloadKind.payment;
  }
  if (scheme != null && scheme.isNotEmpty) return QrPayloadKind.unsupported;
  return QrPayloadKind.text;
}

bool _isCoordinatePair(String value) {
  final match = RegExp(
    r'^([+-]?\d{1,3}(?:\.\d+)?)\s*,\s*([+-]?\d{1,3}(?:\.\d+)?)$',
  ).firstMatch(value.trim());
  if (match == null) return false;
  final latitude = double.tryParse(match.group(1)!);
  final longitude = double.tryParse(match.group(2)!);
  return latitude != null &&
      longitude != null &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

bool hasControlOrFormattingCharacters(String value) =>
    value.runes.any(_isControlOrFormattingRune);

bool _isControlOrFormattingRune(int rune) =>
    rune < 0x20 ||
    (rune >= 0x7f && rune <= 0x9f) ||
    rune == 0x00ad ||
    (rune >= 0x0600 && rune <= 0x0605) ||
    rune == 0x061c ||
    rune == 0x06dd ||
    rune == 0x070f ||
    (rune >= 0x0890 && rune <= 0x0891) ||
    rune == 0x08e2 ||
    rune == 0x180e ||
    (rune >= 0x200b && rune <= 0x200f) ||
    (rune >= 0x202a && rune <= 0x202e) ||
    (rune >= 0x2060 && rune <= 0x206f) ||
    rune == 0xfeff ||
    (rune >= 0xfff9 && rune <= 0xfffb) ||
    rune == 0x110bd ||
    rune == 0x110cd ||
    (rune >= 0x13430 && rune <= 0x1343f) ||
    (rune >= 0x1bca0 && rune <= 0x1bca3) ||
    (rune >= 0x1d173 && rune <= 0x1d17a) ||
    rune == 0xe0001 ||
    (rune >= 0xe0020 && rune <= 0xe007f);

String escapeControlCharacters(String value) {
  final output = StringBuffer();
  for (final rune in value.runes) {
    if (_isControlOrFormattingRune(rune)) {
      output
        ..write('\\u')
        ..write('{')
        ..write(rune.toRadixString(16))
        ..write('}');
    } else {
      output.writeCharCode(rune);
    }
  }
  return output.toString();
}
