import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/models/sentinel_analysis.dart';
import '../viewmodel/gmail_scan_view_model.dart';

class GmailScanScreen extends StatelessWidget {
  const GmailScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GmailScanViewModel>();
    final errorMessage = viewModel.errorMessage;

    return Scaffold(
      appBar: AppBar(title: const Text('Revisar Gmail')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Revisa señales sospechosas en el correo más reciente de Recibidos. '
                  'El análisis usa las reglas locales de Sentinel; no confirma quién envió el mensaje '
                  'ni garantiza detectar todos los engaños.',
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Privacidad y alcance',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Al pulsar el botón, Google pedirá permiso de lectura de Gmail. '
                          'La app solicitará en ese momento únicamente el mensaje más reciente de Recibidos. '
                          'El permiso de Google permite lectura de correo; para estas pruebas usa una cuenta de prueba. '
                          'QHAWIX analiza el texto en este dispositivo, no lo envía a su servidor ni lo guarda en la bitácora. '
                          'No abre enlaces ni obtiene adjuntos.',
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: viewModel.consentGiven,
                          onChanged: viewModel.isBusy
                              ? null
                              : (value) => viewModel.setConsent(value ?? false),
                          title: const Text('Entiendo y autorizo esta revisión'),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!viewModel.isConfigured) ...[
                  const SizedBox(height: 8),
                  const _Notice(
                    icon: Icons.settings_outlined,
                    text: 'Falta configurar GOOGLE_SERVER_CLIENT_ID con el ID OAuth de tipo Web.',
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: viewModel.isBusy ||
                          !viewModel.consentGiven ||
                          !viewModel.isConfigured
                      ? null
                      : viewModel.scan,
                  icon: viewModel.isBusy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.manage_search),
                  label: Text(
                    viewModel.isBusy
                        ? 'Revisando…'
                        : 'Conectar y revisar el último correo',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  _Notice(icon: Icons.error_outline, text: errorMessage),
                ],
                if (viewModel.hasScanned && viewModel.results.isEmpty) ...[
                  const SizedBox(height: 16),
                  const _Notice(
                    icon: Icons.inbox_outlined,
                    text: 'No se encontraron mensajes recientes en Recibidos.',
                  ),
                ],
                if (viewModel.results.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Resultados (${viewModel.results.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  for (final result in viewModel.results)
                    _EmailResultCard(result: result),
                  const SizedBox(height: 8),
                ],
                if (viewModel.hasAttemptedConnection) ...[
                  OutlinedButton.icon(
                    onPressed: viewModel.isBusy ? null : viewModel.disconnect,
                    icon: const Icon(Icons.logout),
                    label: const Text('Desconectar Google y borrar resultados'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailResultCard extends StatelessWidget {
  const _EmailResultCard({required this.result});

  final GmailEmailScanResult result;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = switch (result.risk) {
      RequestRisk.high => 'Señales de riesgo alto',
      RequestRisk.caution => 'Señales para revisar',
      RequestRisk.abstain => 'No hay datos suficientes',
      RequestRisk.notAssessed => 'No evaluado',
      RequestRisk.noneDetected => 'No se detectaron señales locales',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  result.risk == RequestRisk.high ||
                          result.risk == RequestRisk.caution
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline,
                  color: result.risk == RequestRisk.high
                      ? colorScheme.error
                      : colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(result.subject.isEmpty ? '(Sin asunto)' : result.subject),
            if (result.sender.isNotEmpty)
              Text(
                result.sender,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (result.preview.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(result.preview, maxLines: 5, overflow: TextOverflow.ellipsis),
            ],
            if (result.ruleIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Reglas: ${result.ruleIds.join(', ')}'),
            ],
            for (final explanation in result.signalExplanations) ...[
              const SizedBox(height: 8),
              Text(explanation),
            ],
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
