enum QrReputationStatus {
  knownThreat,
  noKnownThreats,
  unverifiable,
}

class QrReputationResult {
  QrReputationResult({
    required this.status,
    required this.reasonCode,
    required this.provider,
    required this.checkedAt,
    required this.expiresAt,
    required this.coverageComplete,
    required List<String> categories,
  }) : categories = List.unmodifiable(categories) {
    if (status == QrReputationStatus.noKnownThreats && !coverageComplete) {
      throw ArgumentError('A negative result requires complete coverage.');
    }
    if (status == QrReputationStatus.knownThreat && categories.isEmpty) {
      throw ArgumentError('A known threat requires at least one category.');
    }
  }

  final QrReputationStatus status;
  final String? reasonCode;
  final String? provider;
  final DateTime? checkedAt;
  final DateTime? expiresAt;
  final bool coverageComplete;
  final List<String> categories;

  factory QrReputationResult.unverifiable(String reasonCode) {
    return QrReputationResult(
      status: QrReputationStatus.unverifiable,
      reasonCode: reasonCode,
      provider: null,
      checkedAt: null,
      expiresAt: null,
      coverageComplete: false,
      categories: const [],
    );
  }
}
