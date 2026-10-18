/// Where a trusted contact stands in the mutual-consent flow.
enum ContactStatus {
  /// The person invited them; they have not accepted yet.
  invited,

  /// Both sides consented.
  active,

  /// The person paused this contact: nothing is sent to them.
  paused,
}

/// A delivery channel. Push is always tried first.
enum AlertChannel { push, sms, whatsapp }

/// What one contact may do. Each switch is the person's decision.
class ContactPermissions {
  const ContactPermissions({
    this.receiveAlerts = true,
    this.mayRequestRemoteRefuge = false,
    this.maySeeTemporaryLocation = false,
  });

  final bool receiveAlerts;
  final bool mayRequestRemoteRefuge;
  final bool maySeeTemporaryLocation;

  ContactPermissions copyWith({
    bool? receiveAlerts,
    bool? mayRequestRemoteRefuge,
    bool? maySeeTemporaryLocation,
  }) => ContactPermissions(
    receiveAlerts: receiveAlerts ?? this.receiveAlerts,
    mayRequestRemoteRefuge:
        mayRequestRemoteRefuge ?? this.mayRequestRemoteRefuge,
    maySeeTemporaryLocation:
        maySeeTemporaryLocation ?? this.maySeeTemporaryLocation,
  );
}

/// A person the user chose to trust. Typed in by hand: QHAWIX never reads the
/// phone's contacts.
class TrustContact {
  const TrustContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    this.permissions = const ContactPermissions(),
    this.fallbackChannel = AlertChannel.sms,
  });

  final String id;
  final String name;
  final String phone;
  final ContactStatus status;
  final ContactPermissions permissions;

  /// Used when push cannot be delivered. Never [AlertChannel.push].
  final AlertChannel fallbackChannel;

  bool get isActive => status == ContactStatus.active;

  TrustContact copyWith({
    ContactStatus? status,
    ContactPermissions? permissions,
    AlertChannel? fallbackChannel,
  }) => TrustContact(
    id: id,
    name: name,
    phone: phone,
    status: status ?? this.status,
    permissions: permissions ?? this.permissions,
    fallbackChannel: fallbackChannel ?? this.fallbackChannel,
  );
}
