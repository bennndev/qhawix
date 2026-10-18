import '../../domain/repositories/qr_clock.dart';

class SystemQrClock implements QrClock {
  const SystemQrClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}
