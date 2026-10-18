import '../models/qr_security_incident.dart';

abstract interface class QrSecurityHistoryQueryRepository {
  Future<bool> isUrlAllowed(Uri url);

  Future<List<QrSecurityIncident>> loadIncidents();

  Future<bool> allowIncident(int id);
}
