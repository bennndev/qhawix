import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/echotrap/domain/scam_response.dart';

void main() {
  test('a notice survives a round trip', () {
    final parsed = ScamNotice.tryParse(
      const ScamNotice(reported: true).encode(),
    );
    expect(parsed?.reported, isTrue);
    expect(
      ScamNotice.tryParse(const ScamNotice(reported: false).encode())?.reported,
      isFalse,
    );
  });

  test('anything that is not a valid notice is ignored', () {
    expect(ScamNotice.tryParse(const []), isNull);
    expect(ScamNotice.tryParse(utf8.encode('not json')), isNull);
    expect(
      ScamNotice.tryParse(
        utf8.encode('{"type":"other","v":1,"reported":true}'),
      ),
      isNull,
    );
    expect(
      ScamNotice.tryParse(
        utf8.encode('{"type":"qhawix.scam_notice","v":2,"reported":true}'),
      ),
      isNull,
    );
    expect(
      ScamNotice.tryParse(
        utf8.encode('{"type":"qhawix.scam_notice","v":1,"reported":"yes"}'),
      ),
      isNull,
    );
    expect(ScamNotice.tryParse(List.filled(600, 65)), isNull);
  });

  test('the spoken text only says contacts were warned when they were', () {
    expect(
      const ScamNotice(reported: true).spokenText,
      contains('contactos de confianza'),
    );
    expect(
      const ScamNotice(reported: false).spokenText,
      isNot(contains('contactos')),
    );
  });
}
