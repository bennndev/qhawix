import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/config/qr_shield_policy.dart';
import '../viewmodel/qr_shield_view_model.dart';

class QrShieldHomeScreen extends StatefulWidget {
  const QrShieldHomeScreen({super.key});

  @override
  State<QrShieldHomeScreen> createState() => _QrShieldHomeScreenState();
}

class _QrShieldHomeScreenState extends State<QrShieldHomeScreen> {
  final TextEditingController _payloadController = TextEditingController();

  @override
  void dispose() {
    _payloadController.dispose();
    super.dispose();
  }

  void _inspectPastedContent() {
    final value = _payloadController.text;
    if (value.trim().isEmpty) return;
    context.read<QrShieldViewModel>().inspect(value);
    final revision = context.read<QrShieldViewModel>().review?.revision;
    if (revision != null) context.go('/qr/result/$revision');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escudo QR')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _IntroCard(),
                const SizedBox(height: 12),
                const _ProviderNotice(),
                const SizedBox(height: 8),
                const Text(
                  'En este estado del módulo, el contenido se procesa en el '
                  'dispositivo y no se guarda en un historial.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('open-scanner'),
                  onPressed: () => context.push('/qr/scan'),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear un código QR'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  key: const Key('qr-payload-input'),
                  controller: _payloadController,
                  minLines: 2,
                  maxLines: 5,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Pegar enlace o contenido del QR',
                    hintText: 'https://ejemplo.com',
                    helperText:
                        'El contenido se limita a ${QrShieldPolicy.maxPayloadBytes ~/ 1024} KiB.',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('inspect-pasted-content'),
                  onPressed: _inspectPastedContent,
                  icon: const Icon(Icons.search),
                  label: const Text('Revisar antes de abrir'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Escudo QR muestra el destino y señales locales. No garantiza '
                  'que un enlace sea seguro ni confirma quién colocó el código.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, size: 36, color: colors.onPrimaryContainer),
            const SizedBox(height: 12),
            Text(
              'Revisa el destino antes de continuar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escanea un QR o pega su contenido. QHAWIX no abrirá enlaces '
              'ni ejecutará acciones automáticamente.',
              style: TextStyle(color: colors.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderNotice extends StatelessWidget {
  const _ProviderNotice();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<QrShieldViewModel>();
    final message = viewModel.canRequestReputation
        ? 'Proveedor configurado: ${viewModel.reputationProviderName}. Antes de cada consulta se mostrará qué URL se transmite.'
        : 'La consulta de reputación en línea no está habilitada. Los enlaces aparecerán como no verificables; eso no significa que sean seguros.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
