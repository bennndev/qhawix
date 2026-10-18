enum QrReputationStatus { knownThreat, noKnownThreats, suspiciousOrUnverified }

enum QrProviderState {
  notConfigured,
  notRequested,
  available,
  offline,
  timeout,
  quotaExceeded,
  failed,
  invalidResponse,
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
    List<String> checkedCategories = const [],
    this.providerState = QrProviderState.notRequested,
    this.isSimulation = false,
  }) : categories = List.unmodifiable(categories),
       checkedCategories = List.unmodifiable(checkedCategories) {
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
  final List<String> checkedCategories;
  final QrProviderState providerState;
  final bool isSimulation;

  factory QrReputationResult.suspiciousOrUnverified(
    String reasonCode, {
    QrProviderState providerState = QrProviderState.notRequested,
    String? provider,
    DateTime? checkedAt,
    DateTime? expiresAt,
    bool coverageComplete = false,
    List<String> categories = const [],
    List<String> checkedCategories = const [],
    bool isSimulation = false,
  }) {
    return QrReputationResult(
      status: QrReputationStatus.suspiciousOrUnverified,
      reasonCode: reasonCode,
      provider: provider,
      checkedAt: checkedAt,
      expiresAt: expiresAt,
      coverageComplete: coverageComplete,
      categories: List.unmodifiable(categories),
      checkedCategories: checkedCategories,
      providerState: providerState,
      isSimulation: isSimulation,
    );
  }
}
