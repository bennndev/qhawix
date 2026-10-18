import 'alert_preferences.dart';
import 'check_in.dart';
import 'refuge_request.dart';
import 'trust_contact.dart';

/// Everything the module shows, read in one piece.
class TrustCircleSnapshot {
  const TrustCircleSnapshot({
    required this.contacts,
    required this.refugeRequests,
    required this.alertPreferences,
    this.checkIn,
    this.hasKeyword = false,
  });

  final List<TrustContact> contacts;
  final List<RefugeRequest> refugeRequests;
  final AlertPreferences alertPreferences;
  final CheckIn? checkIn;
  final bool hasKeyword;

  TrustContact? contactById(String id) {
    for (final c in contacts) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<RefugeRequest> get pendingRequests => [
    for (final r in refugeRequests)
      if (r.status == RefugeRequestStatus.pending) r,
  ];
}
