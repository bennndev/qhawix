/// Shared bounds for calls to external providers and local result caching.
abstract final class AppTimeouts {
  static const Duration qrWebRiskConnection = Duration(seconds: 5);
  static const Duration qrReputationRequest = Duration(seconds: 7);
  static const Duration qrProviderDecision = Duration(seconds: 8);
  static const Duration qrNegativeResultMaxAge = Duration(seconds: 60);

  /// Whole round trip for a personal site note (gateway plus Atomic Memory).
  static const Duration qrSiteNoteRequest = Duration(seconds: 8);

  /// Longest EchoTrap waits for the SMS to trusted contacts before warning the
  /// caller anyway.
  static const Duration echoTrapContactAlert = Duration(seconds: 8);
}
