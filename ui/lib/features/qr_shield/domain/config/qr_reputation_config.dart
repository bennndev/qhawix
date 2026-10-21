/// Versioned limits shared by the reputation command and its gateway adapter.
abstract final class QrReputationConfig {
  static const int version = 2;
  static const Duration gatewayTimeout = Duration(seconds: 55);
  static const Duration commandTimeout = Duration(seconds: 60);
  static const Duration negativeResultMaxAge = Duration(seconds: 60);
  static const Duration matchReviewMaxAge = Duration(minutes: 5);
}
