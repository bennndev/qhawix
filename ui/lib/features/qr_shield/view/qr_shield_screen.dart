import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/qhawix_app_bar.dart';
import '../../../core/widgets/qhawix_buttons.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/status_banner.dart';
import '../viewmodel/qr_shield_view_model.dart';

/// Escudo QR module hosted by the existing QHAWIX shell.
class QrShieldScreen extends StatefulWidget {
  const QrShieldScreen({super.key});

  @override
  State<QrShieldScreen> createState() => _QrShieldScreenState();
}

class _QrShieldScreenState extends State<QrShieldScreen> {
  final TextEditingController _payloadController = TextEditingController();
  String? _inputMessage;

  @override
  void dispose() {
    _payloadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final space = context.space;
    final viewModel = context.watch<QrShieldViewModel>();

    return Scaffold(
      appBar: QhawixAppBar(title: 'Escudo QR'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: space.maxContentWidth),
            child: ListView(
              padding: space.screenPadding,
              children: [
                const PageHeader(
                  title: 'Comprueba antes de abrir',
                  subtitle:
                      'Revisa el destino de un código QR o enlace antes de '
                      'decidir qué hacer.',
                ),
                SizedBox(height: space.md),
                const StatusBanner(
                  message:
                      'Los enlaces no se abren automáticamente. Si no se '
                      'puede verificar un destino, se mostrará como no verificable.',
                ),
                SizedBox(height: space.md),
                SectionCard(
                  title: 'Escanear un código QR',
                  children: [
                    Text(
                      'La cámara se activa solo cuando inicias el escaneo. '
                      'El contenido se revisa antes de abrir cualquier enlace.',
                      style: context.text.bodyMedium,
                    ),
                    SizedBox(height: space.md),
                    PrimaryButton(
                      key: const Key('open-scanner'),
                      label: 'Escanear código QR',
                      icon: Icons.qr_code_scanner,
                      onPressed: () => context.push('/m/qr-shield/scanner'),
                    ),
                    SizedBox(height: space.sm),
                    SecondaryButton(
                      label: 'Elegir una imagen',
                      icon: Icons.image_search_outlined,
                      onPressed: viewModel.isSelectingImage ? null : _pickImage,
                    ),
                    if (viewModel.isSelectingImage) ...[
                      SizedBox(height: space.sm),
                      const Center(child: CircularProgressIndicator()),
                    ],
                    if (viewModel.imageScanMessage case final message?) ...[
                      SizedBox(height: space.sm),
                      StatusBanner(
                        message: message,
                        kind: StatusBannerKind.caution,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: space.md),
                SectionCard(
                  title: 'Revisar contenido manualmente',
                  children: [
                    TextField(
                      key: const Key('qr-payload-input'),
                      controller: _payloadController,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Pega aquí el enlace o contenido del QR',
                        alignLabelWithHint: true,
                      ),
                      onChanged: (_) {
                        if (_inputMessage != null) {
                          setState(() => _inputMessage = null);
                        }
                      },
                    ),
                    if (_inputMessage case final message?) ...[
                      SizedBox(height: space.sm),
                      StatusBanner(
                        message: message,
                        kind: StatusBannerKind.caution,
                      ),
                    ],
                    SizedBox(height: space.md),
                    PrimaryButton(
                      key: const Key('inspect-pasted-content'),
                      label: 'Revisar contenido',
                      icon: Icons.fact_check_outlined,
                      onPressed: _inspectManualContent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _inspectManualContent() {
    final payload = _payloadController.text.trim();
    if (payload.isEmpty) {
      setState(() => _inputMessage = 'Pega el contenido que quieres revisar.');
      return;
    }

    context.read<QrShieldViewModel>().inspect(payload);
    context.push('/m/qr-shield/review');
  }

  Future<void> _pickImage() async {
    final action = await context
        .read<QrShieldViewModel>()
        .inspectPickedImage();
    if (!mounted) return;

    switch (action) {
      case QrImageScanAction.review:
        context.push('/m/qr-shield/review');
      case QrImageScanAction.chooseCandidate:
        context.push('/m/qr-shield/candidates');
      case QrImageScanAction.cancelled:
        break;
    }
  }
}
