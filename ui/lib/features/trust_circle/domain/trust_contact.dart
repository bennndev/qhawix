/// Whether the contact paused by the person still receives anything.
enum ContactStatus {
  /// The contact can receive what the person chose to send them.
  active,

  /// The person paused this contact: nothing is prepared for them.
  paused,
}

/// What kind of person the contact is. It decides what they can receive.
enum ContactKind {
  /// Has only a phone number. Added directly, active at once, no invitation.
  /// Reached by SMS or WhatsApp that the person sends from their own phone.
  phoneOnly,

  /// Has QHAWIX installed: push, live temporary location and remote Refuge
  /// requests are possible.
  appUser,
}

/// A delivery channel. Push needs the app, so only [ContactKind.appUser]
/// contacts have it.
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

  /// For an app contact: sees the live temporary location during an SOS. For a
  /// phone-only contact: the message includes the location at the moment the
  /// person sends it.
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
  TrustContact({
    required this.id,
    required this.name,
    required this.phone,
    this.kind = ContactKind.phoneOnly,
    this.status = ContactStatus.active,
    this.permissions = const ContactPermissions(),
    AlertChannel? channel,
    this.installInvitePending = false,
  }) : channel = channel ?? AlertChannel.sms,
       assert(
         kind == ContactKind.appUser || channel != AlertChannel.push,
         'A phone-only contact has no push channel.',
       ),
       assert(
         kind == ContactKind.appUser || !permissions.mayRequestRemoteRefuge,
         'Requesting remote Refuge needs the app.',
       ),
       assert(
         kind == ContactKind.phoneOnly || !installInvitePending,
         'An app contact has nothing left to install.',
       );

  final String id;
  final String name;
  final String phone;
  final ContactKind kind;
  final ContactStatus status;
  final ContactPermissions permissions;

  /// Phone-only contact: the only channel. App contact: the fallback used
  /// after push. Never [AlertChannel.push] for a phone-only contact.
  final AlertChannel channel;

  /// The optional "Invitar a instalar QHAWIX" action was used and the person
  /// has not installed it yet. The contact stays phone-only and active.
  final bool installInvitePending;

  bool get isActive => status == ContactStatus.active;
  bool get hasApp => kind == ContactKind.appUser;

  /// Whether the contact may ask for the person's Refuge remotely.
  bool get canRequestRemoteRefuge => hasApp;

  /// Whether QHAWIX can share a live temporary location with them.
  bool get canSeeLiveLocation => hasApp;

  /// Channels that exist for this kind of contact.
  List<AlertChannel> get availableChannels => hasApp
      ? const [AlertChannel.push, AlertChannel.sms, AlertChannel.whatsapp]
      : const [AlertChannel.sms, AlertChannel.whatsapp];

  /// The reason [permissions] cannot be granted to this contact, or null.
  String? permissionViolation(ContactPermissions permissions) {
    if (permissions.mayRequestRemoteRefuge && !canRequestRemoteRefuge) {
      return 'Pedir tu Refugio necesita la app.';
    }
    return null;
  }

  /// The reason [channel] cannot be used for this contact, or null.
  String? channelViolation(AlertChannel channel) =>
      availableChannels.contains(channel)
      ? null
      : 'Sin la app no hay notificaciones push.';

  TrustContact copyWith({
    ContactKind? kind,
    ContactStatus? status,
    ContactPermissions? permissions,
    AlertChannel? channel,
    bool? installInvitePending,
  }) {
    final nextKind = kind ?? this.kind;
    return TrustContact(
      id: id,
      name: name,
      phone: phone,
      kind: nextKind,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      channel: channel ?? this.channel,
      installInvitePending: nextKind == ContactKind.appUser
          ? false
          : installInvitePending ?? this.installInvitePending,
    );
  }
}
