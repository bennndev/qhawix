import 'dart:convert';

import '../config/qr_shield_policy.dart';

enum QrPayloadKind {
  url,
  text,
  vCard,
  calendar,
  wifi,
  phone,
  sms,
  email,
  payment,
  coordinates,
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
    int byteLength;
    try {
      byteLength = utf8.encode(rawValue).length;
    } on FormatException {
      return QrScanPayload._(
        rawValue: rawValue,
        byteLength: rawValue.length,
        kind: QrPayloadKind.unsupported,
        errorCode: 'invalid_text_encoding',
      );
    }
    if (byteLength > QrShieldPolicy.maxPayloadBytes) {
      return QrScanPayload._(
        rawValue: '',
        byteLength: byteLength,
        kind: QrPayloadKind.unsupported,
        errorCode: 'payload_too_large',
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

  String get safeDisplayValue => escapeControlCharacters(rawValue);
}

QrPayloadKind classifyQrPayload(String rawValue) {
  final value = rawValue.trimLeft();
  final upper = value.toUpperCase();

  if (upper.startsWith('BEGIN:VCARD') || upper.startsWith('MECARD:')) {
    return QrPayloadKind.vCard;
  }
  if (upper.startsWith('BEGIN:VCALENDAR') || upper.startsWith('BEGIN:VEVENT')) {
    return QrPayloadKind.calendar;
  }
  if (upper.startsWith('WIFI:')) return QrPayloadKind.wifi;
  if (upper.startsWith('GEO:')) return QrPayloadKind.coordinates;

  final uri = Uri.tryParse(value);
  final scheme = uri?.scheme.toLowerCase();
  if (scheme == 'http' || scheme == 'https') return QrPayloadKind.url;
  if (scheme == 'tel') return QrPayloadKind.phone;
  if (scheme == 'sms' || scheme == 'smsto') return QrPayloadKind.sms;
  if (scheme == 'mailto') return QrPayloadKind.email;
  if (const {'upi', 'bitcoin', 'ethereum', 'payto', 'web+pay'}.contains(scheme)) {
    return QrPayloadKind.payment;
  }
  if (scheme != null && scheme.isNotEmpty) return QrPayloadKind.unsupported;
  return QrPayloadKind.text;
}

String escapeControlCharacters(String value) {
  final output = StringBuffer();
  for (final rune in value.runes) {
    if (_isDisplayControl(rune)) {
      output
        ..write('\\u')
        ..write(rune.toRadixString(16).padLeft(4, '0'));
    } else {
      output.writeCharCode(rune);
    }
  }
  return output.toString();
}

bool _isDisplayControl(int rune) =>
    rune < 0x20 ||
    (rune >= 0x7f && rune <= 0x9f) ||
    rune == 0x00ad ||
    rune == 0x061c ||
    rune == 0x200b ||
    rune == 0x200e ||
    rune == 0x200f ||
    rune == 0x2028 ||
    rune == 0x2029 ||
    (rune >= 0x202a && rune <= 0x202e) ||
    rune == 0x2060 ||
    (rune >= 0x2066 && rune <= 0x2069) ||
    rune == 0xfeff;
