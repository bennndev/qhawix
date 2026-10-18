import 'action_result.dart';
import 'alert_preferences.dart';
import 'check_in.dart';
import 'sos.dart';
import 'trust_circle_snapshot.dart';
import 'trust_contact.dart';

/// Port of the Trust Circle data. Production uses on-device storage; the mock
/// under `data/mock/` is for tests only and must never be the default in the app.
abstract interface class TrustCircleRepository {
  /// When true the UI shows the example-data banner (tests / demos only).
  bool get usesExampleData;

  Future<TrustCircleSnapshot> load();

  /// Marks the module onboarding (permissions) as finished on this device.
  Future<ActionResult> completeSetup();

  /// Adds a phone-only contact, active at once. Nothing is sent: no
  /// invitation and no message.
  Future<ActionResult> addContact({
    required String name,
    required String phone,
  });

  /// Optional: invites a phone-only contact to install QHAWIX. Adding a
  /// contact never calls this.
  Future<ActionResult> inviteToInstall(String contactId);

  Future<ActionResult> updatePermissions(
    String contactId,
    ContactPermissions permissions,
  );

  /// Sets the contact's channel (phone-only) or its fallback after push.
  Future<ActionResult> setContactChannel(
    String contactId,
    AlertChannel channel,
  );

  Future<ActionResult> setContactPaused(
    String contactId, {
    required bool paused,
  });

  Future<ActionResult> removeContact(String contactId);

  Future<ActionResult> setAlertRecipients(
    AlertEventKind kind,
    Set<String> contactIds,
  );

  Future<ActionResult> setAlertFallback(AlertChannelChoice choice);

  Future<ActionResult> sendSos({
    required Set<String> contactIds,
    required SosDuration duration,
  });

  Future<ActionResult> startCheckIn(CheckInWindow window);

  Future<ActionResult> confirmCheckIn();

  Future<ActionResult> cancelCheckIn();

  Future<ActionResult> resolveRefugeRequest(
    String requestId, {
    required bool approve,
  });

  Future<String?> readKeyword();

  Future<ActionResult> saveKeyword(String keyword);
}
