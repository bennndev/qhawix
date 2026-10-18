import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/qr_shield/domain/models/qr_url_assessment.dart';
import 'package:qhawix/features/qr_shield/domain/services/qr_url_inspector.dart';

void main() {
  late QrUrlInspector inspector;

  setUp(() => inspector = QrUrlInspector());

  test(
    'keeps an ordinary HTTPS URL eligible and omits its fragment remotely',
    () {
      final assessment = inspector.inspect(
        'https://shop.example.org/menu#mesa-12',
      );

      expect(assessment.isEligibleForReputation, isTrue);
      expect(assessment.canOpenExternally, isTrue);
      expect(assessment.fragmentOmittedFromReputation, isTrue);
      expect(
        assessment.reputationUri.toString(),
        'https://shop.example.org/menu',
      );
      expect(assessment.signals, contains(QrUrlSignal.fragmentPresent));
    },
  );

  test(
    'treats HTTP and known shorteners as warnings, not proof of malware',
    () {
      final http = inspector.inspect('http://shop.example.org/menu');
      final shortener = inspector.inspect('https://bit.ly/menu');

      expect(http.signals, contains(QrUrlSignal.insecureHttp));
      expect(http.canOpenExternally, isTrue);
      expect(shortener.signals, contains(QrUrlSignal.knownShortener));
      expect(shortener.canOpenExternally, isTrue);
      expect(shortener.isEligibleForReputation, isTrue);
    },
  );

  test('blocks credentials, private/local destinations, and unusual ports', () {
    final credentialed = inspector.inspect(
      'https://user:secret@shop.example.org/',
    );
    final privateIp = inspector.inspect('https://192.168.1.1/');
    final localhost = inspector.inspect('https://printer.local/');
    final unusualPort = inspector.inspect('https://shop.example.org:8443/');

    for (final assessment in [
      credentialed,
      privateIp,
      localhost,
      unusualPort,
    ]) {
      expect(assessment.isEligibleForReputation, isFalse);
      expect(assessment.canOpenExternally, isFalse);
    }
    expect(credentialed.displayValue, isNot(contains('secret')));
    expect(privateIp.signals, contains(QrUrlSignal.localOrNonPublicHost));
    expect(unusualPort.signals, contains(QrUrlSignal.unusualPort));
  });

  test('marks recognizable secrets ineligible and redacts their display', () {
    final query = inspector.inspect(
      'https://shop.example.org/account?access_token=private-value',
    );
    final path = inspector.inspect(
      'https://shop.example.org/password-reset/abcdefghijklmnop1234',
    );

    expect(query.isEligibleForReputation, isFalse);
    expect(query.canOpenExternally, isFalse);
    expect(query.displayValue, isNot(contains('private-value')));
    expect(path.isEligibleForReputation, isFalse);
    expect(path.canOpenExternally, isFalse);
    expect(path.displayValue, isNot(contains('abcdefghijklmnop1234')));
  });

  test('flags IDN/punycode and rejects malformed punycode hosts', () {
    final validPunycode = inspector.inspect('https://xn--bcher-kva.de/');
    final malformedPunycode = inspector.inspect('https://xn--a.com/');

    expect(validPunycode.signals, contains(QrUrlSignal.punycode));
    expect(validPunycode.asciiHost, 'xn--bcher-kva.de');
    expect(malformedPunycode.canOpenExternally, isFalse);
    expect(malformedPunycode.blockReasonCode, 'invalid_idn');
  });

  test('rejects unsupported schemes, controls, and malformed URLs', () {
    final unsupported = inspector.inspect('intent://scan/#Intent;scheme=x;end');
    final controls = inspector.inspect(
      'https://shop.example.org/\u202eaccount',
    );
    final malformed = inspector.inspect('https://shop.example.org/%xy');

    for (final assessment in [unsupported, controls, malformed]) {
      expect(assessment.isEligibleForReputation, isFalse);
      expect(assessment.canOpenExternally, isFalse);
    }
    expect(unsupported.signals, contains(QrUrlSignal.unsupportedScheme));
    expect(controls.signals, contains(QrUrlSignal.controlCharacters));
  });
}
