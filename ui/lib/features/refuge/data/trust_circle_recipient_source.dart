import '../../trust_circle/domain/trust_circle_repository.dart';
import '../domain/alert_recipient_source.dart';
import '../domain/safe_zone_config.dart';

/// Recipients are the Trust Circle contacts that are active and may receive
/// alerts. Reads only the Trust Circle `domain/` port.
class TrustCircleRecipientSource implements AlertRecipientSource {
  const TrustCircleRecipientSource(this._repository);

  final TrustCircleRepository _repository;

  @override
  Future<List<AlertRecipient>> activeRecipients() async {
    final snapshot = await _repository.load();
    return [
      for (final c in snapshot.contacts)
        if (c.isActive && c.permissions.receiveAlerts)
          AlertRecipient(name: c.name, phone: c.phone),
    ];
  }
}
