import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/qr_shield/domain/models/qr_scan_payload.dart';
import 'package:qhawix/features/qr_shield/domain/use_cases/inspect_qr_payload.dart';
import 'package:qhawix/features/qr_shield/domain/services/qr_url_inspector.dart';

void main() {
  group('QrScanPayload', () {
    test('enforces the 8 KiB limit using UTF-8 bytes', () {
      final exactLimit = QrScanPayload.create(
        List.filled(maxQrPayloadBytes, 'a').join(),
      );
      final overCharacterLimit = QrScanPayload.create(
        List.filled(maxQrPayloadBytes + 1, 'a').join(),
      );
      final overUtf8Limit = QrScanPayload.create(
        List.filled(2049, '😀').join(),
      );

      expect(exactLimit.isAccepted, isTrue);
      expect(exactLimit.byteLength, maxQrPayloadBytes);
      expect(overCharacterLimit.errorCode, 'payload_too_large');
      expect(overUtf8Limit.errorCode, 'payload_too_large');
      expect(overUtf8Limit.byteLength, greaterThan(maxQrPayloadBytes));
    });

    test('rejects empty and malformed Unicode input recoverably', () {
      final empty = QrScanPayload.create(' \n\u200b');
      final malformed = QrScanPayload.create(String.fromCharCode(0xd800));

      expect(empty.errorCode, 'empty_payload');
      expect(malformed.errorCode, 'invalid_encoding');
    });

    test('escapes invisible formatting controls for static display', () {
      final payload = QrScanPayload.create('inicio\u061cfin');

      expect(payload.safeDisplayValue, r'inicio\u{61c}fin');
      expect(payload.mayContainSensitiveContent, isFalse);
    });

    test('classifies non-URL QR formats as static sensitive previews', () {
      final fixtures = <String, QrPayloadKind>{
        'BEGIN:VCARD\nFN:Ana\nEND:VCARD': QrPayloadKind.vCard,
        'WIFI:T:WPA;S:casa;P:secreto;;': QrPayloadKind.wifi,
        'sms:+51999999999': QrPayloadKind.sms,
        'bitcoin:address': QrPayloadKind.payment,
        'tel:+51999999999': QrPayloadKind.phone,
      };

      for (final entry in fixtures.entries) {
        final payload = QrScanPayload.create(entry.key);
        expect(payload.kind, entry.value, reason: entry.key);
        expect(payload.mayContainSensitiveContent, isTrue, reason: entry.key);
      }
    });

    test(
      'does not create a URL assessment for executable or static content',
      () {
        final inspector = InspectQrPayload(urlInspector: QrUrlInspector());

        for (final value in [
          'javascript:alert(1)',
          'WIFI:T:WPA;S:casa;P:x;;',
        ]) {
          final result = inspector.inspect(value);
          expect(result.urlAssessment, isNull, reason: value);
        }
      },
    );
  });
}
