import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/models/qr_image_scan_result.dart';
import '../../domain/repositories/qr_image_decoder.dart';

class AndroidQrImageDecoder implements QrImageDecoder {
  static const MethodChannel _channel = MethodChannel(
    'pe.qhawix.qhawix/qr_image_picker',
  );

  @override
  Future<QrImageScanResult> decodePickedImage() async {
    String? path;
    try {
      path = await _channel.invokeMethod<String>('pickQrImage');
    } on PlatformException catch (error) {
      return QrImageScanResult.failed(error.code);
    }
    if (path == null) return const QrImageScanResult.cancelled();

    final controller = MobileScannerController(autoStart: false);
    try {
      final capture = await controller.analyzeImage(
        path,
        formats: const [BarcodeFormat.qrCode],
      );
      final values = <String>{};
      for (final barcode in capture?.barcodes ?? const <Barcode>[]) {
        final value = barcode.rawValue;
        if (barcode.format == BarcodeFormat.qrCode && value != null) {
          values.add(value);
        }
      }
      if (values.isEmpty) return const QrImageScanResult.noQrCode();
      return QrImageScanResult.decoded(values.toList(growable: false));
    } on UnsupportedError {
      return const QrImageScanResult.failed('image_scan_unsupported');
    } catch (_) {
      return const QrImageScanResult.failed('image_decode_failed');
    } finally {
      try {
        await controller.dispose();
      } catch (_) {
        // The image cleanup still runs if scanner disposal fails.
      }
      try {
        await _channel.invokeMethod<void>('deleteQrImage', {'path': path});
      } catch (_) {
        // The native layer clears stale temporary images on the next launch.
      }
    }
  }
}
