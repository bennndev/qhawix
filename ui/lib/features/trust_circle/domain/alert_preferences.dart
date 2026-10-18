/// Events that can notify the circle.
enum AlertEventKind { voiceCloneDetected, paymentHold, refugeActivated }

/// Fallback used after push: SMS or WhatsApp.
enum AlertChannelChoice { sms, whatsapp }

/// Which contacts hear about which event, and the shared fallback channel.
class AlertPreferences {
  const AlertPreferences({
    this.recipients = const {},
    this.fallbackChannel = AlertChannelChoice.sms,
  });

  final Map<AlertEventKind, Set<String>> recipients;
  final AlertChannelChoice fallbackChannel;

  Set<String> recipientsOf(AlertEventKind kind) => recipients[kind] ?? const {};

  AlertPreferences withRecipients(AlertEventKind kind, Set<String> ids) =>
      AlertPreferences(
        recipients: {...recipients, kind: Set.unmodifiable(ids)},
        fallbackChannel: fallbackChannel,
      );

  AlertPreferences withFallback(AlertChannelChoice choice) =>
      AlertPreferences(recipients: recipients, fallbackChannel: choice);

  /// Drops [contactId] from every event.
  AlertPreferences without(String contactId) => AlertPreferences(
    recipients: {
      for (final e in recipients.entries)
        e.key: Set.unmodifiable(e.value.difference({contactId})),
    },
    fallbackChannel: fallbackChannel,
  );
}
