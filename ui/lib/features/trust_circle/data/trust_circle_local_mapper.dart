import '../domain/alert_preferences.dart';
import '../domain/check_in.dart';
import '../domain/trust_contact.dart';

/// JSON map helpers for on-device Trust Circle persistence.
abstract final class TrustCircleLocalMapper {
  static const schemaVersion = 1;

  static Map<String, Object?> contactToJson(TrustContact c) => {
        'id': c.id,
        'name': c.name,
        'phone': c.phone,
        'kind': c.kind.name,
        'status': c.status.name,
        'channel': c.channel.name,
        'installInvitePending': c.installInvitePending,
        'permissions': {
          'receiveAlerts': c.permissions.receiveAlerts,
          'mayRequestRemoteRefuge': c.permissions.mayRequestRemoteRefuge,
          'maySeeTemporaryLocation': c.permissions.maySeeTemporaryLocation,
        },
      };

  static TrustContact contactFromJson(Map<String, Object?> m) {
    final p = (m['permissions'] as Map?)?.cast<String, Object?>() ?? const {};
    return TrustContact(
      id: m['id'] as String,
      name: m['name'] as String? ?? '',
      phone: m['phone'] as String? ?? '',
      kind: ContactKind.values.byName(m['kind'] as String? ?? 'phoneOnly'),
      status: ContactStatus.values.byName(m['status'] as String? ?? 'active'),
      channel: AlertChannel.values.byName(m['channel'] as String? ?? 'sms'),
      installInvitePending: m['installInvitePending'] as bool? ?? false,
      permissions: ContactPermissions(
        receiveAlerts: p['receiveAlerts'] as bool? ?? true,
        mayRequestRemoteRefuge: p['mayRequestRemoteRefuge'] as bool? ?? false,
        maySeeTemporaryLocation: p['maySeeTemporaryLocation'] as bool? ?? false,
      ),
    );
  }

  static Map<String, Object?> prefsToJson(AlertPreferences prefs) => {
        'fallbackChannel': prefs.fallbackChannel.name,
        'recipients': {
          for (final e in prefs.recipients.entries)
            e.key.name: e.value.toList(),
        },
      };

  static AlertPreferences prefsFromJson(Map<String, Object?>? m) {
    if (m == null) return const AlertPreferences();
    final raw = (m['recipients'] as Map?)?.cast<String, Object?>() ?? const {};
    return AlertPreferences(
      fallbackChannel: AlertChannelChoice.values.byName(
        m['fallbackChannel'] as String? ?? 'sms',
      ),
      recipients: {
        for (final e in raw.entries)
          AlertEventKind.values.byName(e.key): {
            for (final id in (e.value as List<Object?>? ?? const []))
              id as String,
          },
      },
    );
  }

  static Map<String, Object?>? checkInToJson(CheckIn? c) {
    if (c == null) return null;
    return {
      'startedAtMillis': c.startedAt.millisecondsSinceEpoch,
      'dueAtMillis': c.dueAt.millisecondsSinceEpoch,
      'confirmedAtMillis': c.confirmedAt?.millisecondsSinceEpoch,
    };
  }

  static CheckIn? checkInFromJson(Map<String, Object?>? m) {
    if (m == null) return null;
    final confirmed = m['confirmedAtMillis'] as int?;
    return CheckIn(
      startedAt: DateTime.fromMillisecondsSinceEpoch(m['startedAtMillis'] as int),
      dueAt: DateTime.fromMillisecondsSinceEpoch(m['dueAtMillis'] as int),
      confirmedAt: confirmed == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(confirmed),
    );
  }
}
