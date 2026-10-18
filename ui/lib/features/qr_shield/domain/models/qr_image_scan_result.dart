enum QrImageScanStatus {
  cancelled,
  noQrCode,
  decoded,
  failed,
}

class QrImageScanResult {
  const QrImageScanResult._({
    required this.status,
    this.payloads = const [],
    this.reasonCode,
  });

  const QrImageScanResult.cancelled()
      : this._(status: QrImageScanStatus.cancelled);

  const QrImageScanResult.noQrCode()
      : this._(status: QrImageScanStatus.noQrCode);

  factory QrImageScanResult.decoded(List<String> payloads) {
    return QrImageScanResult._(
      status: QrImageScanStatus.decoded,
      payloads: List.unmodifiable(payloads),
    );
  }

  const QrImageScanResult.failed(String reasonCode)
      : this._(status: QrImageScanStatus.failed, reasonCode: reasonCode);

  final QrImageScanStatus status;
  final List<String> payloads;
  final String? reasonCode;
}
