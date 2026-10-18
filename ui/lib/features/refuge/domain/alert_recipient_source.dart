import 'safe_zone_config.dart';

/// Where the people who may receive the SMS come from. The Trust Circle
/// implements it; this module never imports that module's data or view.
abstract interface class AlertRecipientSource {
  /// Active contacts that may receive alerts, in display order.
  Future<List<AlertRecipient>> activeRecipients();
}
