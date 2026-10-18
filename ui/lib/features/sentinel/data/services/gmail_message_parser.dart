import 'dart:convert';

import '../../domain/config/gmail_scan_policy.dart';
import '../../domain/models/gmail_email.dart';

class GmailMessageParser {
  const GmailMessageParser();

  List<String> parseMessageIds(String json) {
    final root = _decodeObject(json);
    final messages = root['messages'];
    if (messages == null) return const [];
    if (messages is! List<Object?>) throw const FormatException();

    return List.unmodifiable(
      messages
          .whereType<Map<String, dynamic>>()
          .map((message) => message['id'])
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .take(GmailScanPolicy.maxMessagesPerScan),
    );
  }

  GmailEmail parseMessage({required String id, required String json}) {
    final root = _decodeObject(json);
    final payload = _asObject(root['payload']) ?? const <String, dynamic>{};
    final headers = payload['headers'];
    final parts = _collectText(payload);
    final body = parts.plainText.isNotEmpty
        ? parts.plainText
        : _htmlToText(parts.html);
    final snippet = root['snippet'] is String ? root['snippet'] as String : '';

    return GmailEmail(
      id: id,
      sender: _cleanHeader(_headerValue(headers, 'from')),
      subject: _cleanHeader(_headerValue(headers, 'subject')),
      body: _truncateRunes(
        body.isEmpty ? snippet : body,
        GmailScanPolicy.maxBodyRunes,
      ),
    );
  }

  Map<String, dynamic> _decodeObject(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      throw const FormatException('Invalid Gmail response.');
    }
    final object = _asObject(decoded);
    if (object == null) throw const FormatException('Invalid Gmail response.');
    return object;
  }

  Map<String, dynamic>? _asObject(Object? value) =>
      value is Map<String, dynamic> ? value : null;

  String _headerValue(Object? rawHeaders, String target) {
    if (rawHeaders is! List<Object?>) return '';
    for (final rawHeader in rawHeaders) {
      final header = _asObject(rawHeader);
      if (header == null) continue;
      final name = header['name'];
      if (name is String && name.toLowerCase() == target) {
        return header['value'] is String ? header['value'] as String : '';
      }
    }
    return '';
  }

  _MessageText _collectText(Map<String, dynamic> part) {
    final plain = <String>[];
    final html = <String>[];

    void visit(Map<String, dynamic> current) {
      final mimeType = current['mimeType'];
      final body = _asObject(current['body']);
      final data = body?['data'];
      if (mimeType is String && data is String && data.isNotEmpty) {
        final decoded = _decodeBody(data);
        if (mimeType.toLowerCase() == 'text/plain') {
          plain.add(decoded);
        } else if (mimeType.toLowerCase() == 'text/html') {
          html.add(decoded);
        }
      }

      final children = current['parts'];
      if (children is List<Object?>) {
        for (final child in children) {
          final childMap = _asObject(child);
          if (childMap != null) visit(childMap);
        }
      }
    }

    visit(part);
    return _MessageText(plain.join('\n'), html.join('\n'));
  }

  String _decodeBody(String data) {
    try {
      return utf8.decode(
        base64Url.decode(base64Url.normalize(data)),
        allowMalformed: true,
      );
    } on FormatException {
      return '';
    }
  }

  String _htmlToText(String html) => html
      .replaceAll(
        RegExp(r'<br\s*/?>|</p\s*>|</div\s*>', caseSensitive: false),
        '\n',
      )
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .trim();

  String _cleanHeader(String value) => _truncateRunes(
        value.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ').trim(),
        GmailScanPolicy.maxHeaderRunes,
      );

  String _truncateRunes(String value, int maxRunes) {
    final runes = value.runes;
    if (runes.length <= maxRunes) return value;
    return String.fromCharCodes(runes.take(maxRunes));
  }
}

class _MessageText {
  const _MessageText(this.plainText, this.html);

  final String plainText;
  final String html;
}
