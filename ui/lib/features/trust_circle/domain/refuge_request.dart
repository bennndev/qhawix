enum RefugeRequestStatus { pending, approved, denied }

/// A trusted contact asks the person to activate Refuge. Only the person,
/// after verifying, can approve.
class RefugeRequest {
  const RefugeRequest({
    required this.id,
    required this.contactId,
    required this.requestedAt,
    this.status = RefugeRequestStatus.pending,
  });

  final String id;
  final String contactId;
  final DateTime requestedAt;
  final RefugeRequestStatus status;

  RefugeRequest copyWith({RefugeRequestStatus? status}) => RefugeRequest(
    id: id,
    contactId: contactId,
    requestedAt: requestedAt,
    status: status ?? this.status,
  );
}
