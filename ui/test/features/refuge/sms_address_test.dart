import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/refuge/domain/sms_address.dart';

void main() {
  test('normalizeSmsAddress keeps digits and a leading plus', () {
    expect(normalizeSmsAddress('+51 999 888 777'), '+51999888777');
    expect(normalizeSmsAddress('(999) 888-777'), '999888777');
    expect(normalizeSmsAddress('  '), '');
    expect(normalizeSmsAddress('+'), '');
  });
}
