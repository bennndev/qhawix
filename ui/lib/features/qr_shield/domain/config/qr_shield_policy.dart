class QrShieldPolicy {
  const QrShieldPolicy._();

  static const version = 'qr-shield-p0-1.0.0';
  static const maxPayloadBytes = 8 * 1024;
  static const maxNegativeReputationAge = Duration(seconds: 60);
}
