import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/sentinel/data/services/gmail_message_parser.dart';

void main() {
  const parser = GmailMessageParser();

  test('parses message IDs and limits the result to the latest one', () {
    final ids = List.generate(7, (index) => {'id': 'message-$index'});

    expect(
      parser.parseMessageIds(jsonEncode({'messages': ids})),
      ['message-0'],
    );
  });

  test('decodes the plain-text body and extracts safe headers', () {
    final body = base64Url.encode(utf8.encode('Hola, verifica tu cuenta.'));
    final message = parser.parseMessage(
      id: 'message-1',
      json: jsonEncode({
        'snippet': 'Fallback snippet',
        'payload': {
          'mimeType': 'text/plain',
          'headers': [
            {'name': 'From', 'value': 'Avisos <alerts@example.com>'},
            {'name': 'Subject', 'value': 'Aviso importante'},
          ],
          'body': {'data': body},
        },
      }),
    );

    expect(message.id, 'message-1');
    expect(message.sender, 'Avisos <alerts@example.com>');
    expect(message.subject, 'Aviso importante');
    expect(message.body, 'Hola, verifica tu cuenta.');
  });

  test('uses snippet when the message has no decodable body', () {
    final message = parser.parseMessage(
      id: 'message-2',
      json: jsonEncode({
        'snippet': 'Vista previa del correo',
        'payload': {'mimeType': 'multipart/alternative', 'parts': []},
      }),
    );

    expect(message.body, 'Vista previa del correo');
  });
}
