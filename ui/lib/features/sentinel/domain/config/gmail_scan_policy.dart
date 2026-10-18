class GmailScanPolicy {
  const GmailScanPolicy._();

  static const version = 'gmail-scan-0.2.0';
  static const maxMessagesPerScan = 1;
  static const maxHeaderRunes = 500;
  static const maxBodyRunes = 20000;
  static const maxResponseBytes = 2 * 1024 * 1024;
  static const requestTimeout = Duration(seconds: 20);
}
