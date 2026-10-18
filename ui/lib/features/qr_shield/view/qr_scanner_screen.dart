import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../domain/models/qr_scan_payload.dart';
import '../viewmodel/qr_shield_view_model.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _cameraActivated = false;
  bool _handlingCode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      autoStart: false,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraActivated || !_controller.value.hasCameraPermission) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_startScanner());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_stopScanner());
    }
  }

  Future<void> _startScanner() async {
    try {
      await _controller.start();
    } on MobileScannerException {
      // The scanner widget presents the permission or camera failure state.
    }
  }

  Future<void> _stopScanner() async {
    try {
      await _controller.stop();
    } on MobileScannerException {
      // A camera that never started needs no further cleanup.
    }
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_handlingCode || !mounted) return;
    final candidates = <String>{};
    for (final barcode in capture.barcodes) {
      if (barcode.format == BarcodeFormat.qrCode && barcode.rawValue != null) {
        candidates.add(barcode.rawValue!);
      }
    }
    if (candidates.isEmpty) return;

    _handlingCode = true;
    String? rawValue;
    if (candidates.length == 1) {
      rawValue = candidates.first;
    } else {
      rawValue = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Se detectaron varios códigos'),
          content: SizedBox(
            width: 520,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final candidate in candidates)
                  ListTile(
                    leading: const Icon(Icons.qr_code_2),
                    title: Text(_safePreview(candidate)),
                    subtitle: Text('${candidate.runes.length} caracteres'),
                    onTap: () => Navigator.of(dialogContext).pop(candidate),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );
    }
    if (!mounted) return;
    if (rawValue == null) {
      _handlingCode = false;
      return;
    }
    final viewModel = context.read<QrShieldViewModel>()..inspect(rawValue);
    context.go('/qr/result/${viewModel.review!.revision}');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/qr'),
        ),
      ),
      body: SafeArea(
        child: _cameraActivated ? _buildCamera() : _buildCameraExplanation(),
      ),
    );
  }

  Widget _buildCameraExplanation() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 52),
              const SizedBox(height: 16),
              Text(
                'La cámara se usa solo para leer el QR que tienes enfrente. '
                'El contenido se revisa en el dispositivo y no se abre solo.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('activate-camera'),
                onPressed: () {
                  setState(() => _cameraActivated = true);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) unawaited(_startScanner());
                  });
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Activar cámara'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => context.go('/qr'),
                icon: const Icon(Icons.content_paste),
                label: const Text('Pegar el contenido en su lugar'),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCamera() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: _handleDetection,
                errorBuilder: (context, error) => _CameraError(
                  error: error,
                  onPaste: () => context.go('/qr'),
                ),
              ),
              IgnorePointer(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextButton.icon(
            onPressed: () => context.go('/qr'),
            icon: const Icon(Icons.content_paste),
            label: const Text('Usar entrada manual'),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ],
    );
  }
}

String _safePreview(String value) {
  final visible = escapeControlCharacters(value);
  final prefix = visible.runes.take(120).map(String.fromCharCode).join();
  return visible.runes.length > 120 ? '$prefix…' : prefix;
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error, required this.onPaste});

  final MobileScannerException error;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(denied ? Icons.no_photography_outlined : Icons.error_outline),
              const SizedBox(height: 12),
              Text(
                denied
                    ? 'No se concedió permiso para usar la cámara.'
                    : 'No se pudo iniciar el escáner en este dispositivo.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text('Puedes pegar el contenido del QR como alternativa.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onPaste,
                icon: const Icon(Icons.content_paste),
                label: const Text('Pegar contenido'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
