enum GmailInboxFailure {
  configurationMissing,
  authorizationFailed,
  permissionDenied,
  networkUnavailable,
  serviceUnavailable,
  rateLimited,
  invalidResponse,
  responseTooLarge,
}

class GmailInboxException implements Exception {
  const GmailInboxException(this.failure);

  final GmailInboxFailure failure;
}
