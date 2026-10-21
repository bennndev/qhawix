enum QrSecurityDetectionSource { localPolicy, urlscan, legacyReputation }

class QrSecurityIncident {
  const QrSecurityIncident({
    this.id,
    required this.timestamp,
    required this.blockedUrl,
    required this.threatCategory,
    required this.detectionSource,
    this.isAllowed = false,
    this.hasAllowlistFingerprint = false,
  });

  final int? id;
  final DateTime timestamp;
  final String blockedUrl;
  final String threatCategory;
  final QrSecurityDetectionSource detectionSource;
  final bool isAllowed;
  final bool hasAllowlistFingerprint;

  bool get canBeAllowed =>
      id != null &&
      detectionSource != QrSecurityDetectionSource.localPolicy &&
      hasAllowlistFingerprint &&
      !isAllowed;
}
