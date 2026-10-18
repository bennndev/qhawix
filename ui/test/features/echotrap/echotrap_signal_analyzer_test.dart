import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/echotrap/domain/echotrap_signal_analyzer.dart';

void main() {
  group('assessEchoTrapText', () {
    test('flags a direct request for a bank security code as high risk', () {
      final result = assessEchoTrapText(
        'Le llamo del BCP, comparta su código de seguridad ahora.',
      );

      expect(result.risk, EchoTrapTextRisk.highRisk);
    });

    test('flags a request to install remote access software', () {
      final result = assessEchoTrapText(
        'Instala AnyDesk para revisar tu cuenta.',
      );

      expect(result.risk, EchoTrapTextRisk.highRisk);
    });

    test('a bank name alone only asks the person to be cautious', () {
      final result = assessEchoTrapText('Te llamo del BCP para saludarte.');

      expect(result.risk, EchoTrapTextRisk.caution);
      expect(result.message, contains('no prueban identidad'));
    });

    test('does not call an ordinary greeting safe or suspicious', () {
      final result = assessEchoTrapText('Buenos días, ¿cómo estás?');

      expect(result.risk, EchoTrapTextRisk.noSignal);
      expect(
        result.message,
        contains('no significa que la llamada sea segura'),
      );
    });
  });
}
