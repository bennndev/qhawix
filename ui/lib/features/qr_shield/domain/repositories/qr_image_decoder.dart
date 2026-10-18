import '../models/qr_image_scan_result.dart';

abstract interface class QrImageDecoder {
  Future<QrImageScanResult> decodePickedImage();
}
