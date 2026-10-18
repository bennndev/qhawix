import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../sentinel/domain/models/sentinel_analysis.dart';
import '../domain/models/logbook_case.dart';
import '../viewmodel/logbook_view_model.dart';

class CaseOverviewScreen extends StatelessWidget {
  const CaseOverviewScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context) {
    final item = context.watch<LogbookViewModel>().caseById(caseId);
    if (item == null) return _missingCase(context);
    final latest = item.evidence.isEmpty ? null : item.evidence.last;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado Sentinel'),
        actions: [
          IconButton(
            tooltip: 'Ver timeline del caso',
            onPressed: () => context.push('/cases/$caseId/timeline'),
            icon: const Icon(Icons.timeline),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (latest == null)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Este caso aún no tiene una comunicación analizada.'),
                    ),
                  )
                else ...[
                  _RiskCard(analysis: latest.analysis),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Contenido redactado', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          SelectableText(latest.redactedText),
                          const SizedBox(height: 8),
                          Text('Canal declarado: ${_channelLabel(latest.channel)}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (latest.analysis.signals.isEmpty)
                    const Text('No se encontraron señales en el texto analizado; eso no confirma legitimidad.')
                  else
                    for (final signal in latest.analysis.signals)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: Text('${signal.ruleId} · ${signal.kind}'),
                          subtitle: Text('${signal.explanation}\nFragmento redactado: ${_excerpt(latest, signal.start, signal.end)}'),
                          isThreeLine: true,
                        ),
                      ),
                ],
                const SizedBox(height: 12),
                _TrustDimensionsCard(risk: latest?.analysis.risk),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.push('/guardian'),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('Analizar solicitud de pago con Guardian'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/evidence/new?caseId=$caseId'),
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir otra evidencia'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
                TextButton.icon(
                  onPressed: () => context.read<LogbookViewModel>().recordFalseAlarm(caseId),
                  icon: const Icon(Icons.feedback_outlined),
                  label: const Text('Registrar posible falsa alarma'),
                  style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _missingCase(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Caso no disponible')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Volver al inicio'),
          ),
        ),
      );
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.analysis});

  final SentinelAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final label = switch (analysis.risk) {
      RequestRisk.notAssessed => 'No evaluado',
      RequestRisk.noneDetected => 'No se detectaron señales',
      RequestRisk.caution => 'Precaución',
      RequestRisk.high => 'Riesgo alto',
      RequestRisk.abstain => 'Análisis insuficiente',
    };
    final description = switch (analysis.risk) {
      RequestRisk.notAssessed => 'No hay evidencia para evaluar.',
      RequestRisk.noneDetected => 'No se encontraron señales en este texto; no significa que sea legítimo.',
      RequestRisk.caution => 'Verifica la solicitud por un canal independiente.',
      RequestRisk.high => 'Pausa cualquier acción y verifica por un canal independiente.',
      RequestRisk.abstain => 'El texto es corto o el idioma no está cubierto; no se interpreta como seguro.',
    };
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 8),
            Text('Reglas: ${analysis.ruleSetVersion}'),
          ],
        ),
      ),
    );
  }
}

class _TrustDimensionsCard extends StatelessWidget {
  const _TrustDimensionsCard({required this.risk});

  final RequestRisk? risk;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dimensiones independientes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text('Procedencia del número: desconocida (sin directorio)'),
              const Text('Confirmación institucional: no intentada'),
              Text('Riesgo de la solicitud: ${_riskLabel(risk)}'),
              const Text('Desviación conductual: desactivada en esta versión'),
            ],
          ),
        ),
      );
}

String _riskLabel(RequestRisk? value) => switch (value) {
      RequestRisk.notAssessed || null => 'no evaluado',
      RequestRisk.noneDetected => 'sin señales detectadas',
      RequestRisk.caution => 'precaución',
      RequestRisk.high => 'alto',
      RequestRisk.abstain => 'abstención',
    };

String _excerpt(EvidenceRecord evidence, int start, int end) {
  final text = evidence.redactedText;
  if (start < 0 || end > text.length || start >= end) return 'No hay cita disponible.';
  return text.substring(start, end);
}

String _channelLabel(String channel) => switch (channel) {
      'phone_call' => 'llamada telefónica',
      'sms' => 'SMS',
      'messaging_app' => 'aplicación de mensajería',
      'email' => 'correo electrónico',
      'in_person' => 'en persona',
      _ => 'desconocido',
    };
