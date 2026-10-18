import 'action_result.dart';
import 'alert_preferences.dart';
import 'check_in.dart';
import 'sos.dart';
import 'trust_circle_snapshot.dart';
import 'trust_contact.dart';

/// Port of the Trust Circle data. A real implementation talks to Supabase; the
/// mock under `data/mock/` keeps everything in memory and sends nothing.
abstract interface class TrustCircleRepository {
  Future<TrustCircleSnapshot> load();

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
