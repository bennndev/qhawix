import 'package:another_telephony/telephony.dart';

import '../domain/sms_address.dart';

/// Sends one Refuge alert/test SMS. Always multipart: the automatic suffix
/// plus the person's text exceeds a single GSM segment (spike used short
/// bodies and did not hit this).
Future<void> sendRefugeSms({
  required String to,
  required String message,
  bool background = false,
}) async {
  final address = normalizeSmsAddress(to);
  if (address.isEmpty) {
    throw StateError('empty_sms_address');
  }
  final telephony =
      background ? Telephony.backgroundInstance : Telephony.instance;
  await telephony.sendSms(
    to: address,
    message: message,
    isMultipart: true,
  );
}
