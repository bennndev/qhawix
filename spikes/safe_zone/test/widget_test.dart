import 'package:flutter_test/flutter_test.dart';

import 'package:safe_zone_spike/background.dart';

void main() {
  test('background entry points use distinct alarm ids', () {
    final ids = {alarmSmsId, alarmLocationId, alarmCountdownId, alarmRebootId};
    expect(ids.length, 4);
  });
}
