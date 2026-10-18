enum QrSecurityDetectionSource { localPolicy, googleWebRisk }

class QrSecurityIncident {
  const QrSecurityIncident({
    required this.timestamp,
    required this.blockedUrl,
    required this.threatCategory,
    required this.detectionSource,
  });

  final DateTime timestamp;
  final String blockedUrl;
  final String threatCategory;
  final QrSecurityDetectionSource detectionSource;
}
