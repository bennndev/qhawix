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

  /// Creates an invitation. The contact stays `invited` until they consent.
  Future<ActionResult> inviteContact({
    required String name,
    required String phone,
  });

  Future<ActionResult> updatePermissions(
    String contactId,
    ContactPermissions permissions,
  );

  Future<ActionResult> setContactFallback(
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
