import '../models/qr_security_incident.dart';

abstract interface class QrSecurityHistoryRepository {
  Future<void> recordBlockedIncident(
    QrSecurityIncident incident, {
    required Uri lookupUri,
  });
}
