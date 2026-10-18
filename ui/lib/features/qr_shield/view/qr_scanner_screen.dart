import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../viewmodel/qr_shield_view_model.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  bool _cameraActivated = false;
  bool _handlingCode = false;
  bool _isStartingScanner = false;
  bool _isStoppingScanner = false;
  bool _pauseRequested = false;
  late AppLifecycleState _lifecycleState;
  late final MobileScannerController _scannerController;

  @override
  void initState() {
    super.initState();
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      autoStart: false,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (!_cameraActivated || !_scannerController.value.hasCameraPermission) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _pauseRequested = false;
      unawaited(_startScanner());
    } else {
      unawaited(_stopScanner());
    }
  }

  Future<void> _startScanner() async {
    if (!mounted ||
        !_cameraActivated ||
        _handlingCode ||
        _pauseRequested ||
        _lifecycleState != AppLifecycleState.resumed ||
        _isStartingScanner ||
        _isStoppingScanner) {
      return;
    }

    _isStartingScanner = true;
    try {
      await _scannerController.start();
    } catch (_) {
      // The scanner's errorBuilder presents camera or device failures.
    } finally {
      _isStartingScanner = false;
      if (_pauseRequested || _lifecycleState != AppLifecycleState.resumed) {
        await _stopScanner();
      }
    }
  }

  Future<void> _stopScanner() async {
    _pauseRequested = true;
    if (_isStartingScanner || _isStoppingScanner) return;

    _isStoppingScanner = true;
    try {
      await _scannerController.stop();
    } catch (_) {
      // The route may already be disposing the controller.
    } finally {
      _isStoppingScanner = false;
      if (mounted &&
          _cameraActivated &&
          !_pauseRequested &&
          _lifecycleState == AppLifecycleState.resumed) {
        unawaited(_startScanner());
      }
    }
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_handlingCode) return;
    final candidates = <String>{};
    for (final barcode in capture.barcodes) {
      if (barcode.format == BarcodeFormat.qrCode && barcode.rawValue != null) {
        candidates.add(barcode.rawValue!);
      }
    }
    if (candidates.isEmpty) return;

    _handlingCode = true;
    await _stopScanner();
    if (!mounted) return;
    if (candidates.length == 1) {
      context.read<QrShieldViewModel>().inspect(candidates.single);
      context.go('/m/qr-shield/review');
    } else {
      context.read<QrShieldViewModel>().setCandidates(candidates.toList());
      context.go('/m/qr-shield/candidates');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraActivated = false;
    _pauseRequested = true;
    unawaited(_disposeScannerController());
    super.dispose();
  }

  Future<void> _disposeScannerController() async {
    try {
      await _scannerController.dispose();
    } catch (_) {
      // The route is already closing; no further camera action is needed.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/m/qr-shield'),
        ),
      ),
      body: SafeArea(
        child: _cameraActivated ? _buildCamera() : _buildCameraExplanation(),
      ),
    );
  }

  Widget _buildCameraExplanation() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
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
                      'La cámara lee el QR para revisar su contenido. Las amenazas '
                      'conocidas se bloquean; los enlaces verificados sin coincidencias '
                      'y los que permitiste desde el historial se abren en el navegador.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const Key('activate-camera'),
                      onPressed: _activateCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Activar cámara'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => context.go('/m/qr-shield'),
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
                controller: _scannerController,
                onDetect: _handleDetection,
                errorBuilder: (context, error) => _CameraError(
                  error: error,
                  onPaste: () => context.go('/m/qr-shield'),
                ),
              ),
              Semantics(
                container: true,
                label: 'Área de escaneo de códigos QR',
                hint: 'Alinea el código QR dentro del recuadro.',
                child: IgnorePointer(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextButton.icon(
            onPressed: () => context.go('/m/qr-shield'),
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

  void _activateCamera() {
    if (_cameraActivated) return;
    setState(() => _cameraActivated = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_startScanner());
    });
  }
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
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
          ),
        ),
      ),
    );
  }
}
