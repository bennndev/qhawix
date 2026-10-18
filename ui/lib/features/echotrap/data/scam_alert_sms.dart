import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

/// Sends the automatic scam warning as a real SMS from the person's phone.
/// It needs the SMS permission (asked just in time, only when a call turns
/// red); without it nothing is sent and the caller is told so.
class ScamAlertSms {
  const ScamAlertSms();

  Future<bool> ensurePermission() async {
    final status = await Permission.sms.status;
    if (status.isGranted) return true;
    return (await Permission.sms.request()).isGranted;
  }

  /// Returns how many messages the phone accepted for sending.
  Future<int> sendAll(Iterable<String> phones, String message) async {
    var sent = 0;
    for (final phone in phones.toSet()) {
      final address = phone.replaceAll(RegExp(r'[^0-9+]'), '');
      if (address.isEmpty) continue;
      try {
        await Telephony.instance.sendSms(
          to: address,
          message: message,
          isMultipart: true,
        );
        sent++;
      } catch (_) {
        // One failed number must not stop the rest of the circle.
      }
    }
    return sent;
  }
}
