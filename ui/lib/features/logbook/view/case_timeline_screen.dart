import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../domain/models/logbook_case.dart';
import '../viewmodel/logbook_view_model.dart';
import '../../sentinel/domain/models/sentinel_analysis.dart';
import 'logbook_screen.dart' show formatSessionDateTime;

class CaseTimelineScreen extends StatelessWidget {
  const CaseTimelineScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context) {
    final item = context.watch<LogbookViewModel>().caseById(caseId);
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Línea de tiempo')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/logbook'),
            child: const Text('Volver a mi sesión'),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Línea de tiempo'),
        actions: [
          IconButton(
            tooltip: 'Ver caso',
            onPressed: () => context.go('/cases/$caseId'),
            icon: const Icon(Icons.description_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'La línea de tiempo permanece en esta sesión. Los resúmenes no incluyen texto original, números completos, enlaces ni montos.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final event in item.events.reversed)
            Card(
              child: ListTile(
                leading: Icon(_eventIcon(event.type)),
                title: Text(_eventLabel(event.type)),
                subtitle: Text(
                  '${formatSessionDateTime(event.at)} · Persona o política\n'
                  '${event.ruleIds.isEmpty ? 'Sin reglas asociadas' : 'Reglas: ${event.ruleIds.join(', ')}'}',
                ),
                isThreeLine: true,
              ),
            ),
          if (item.evidence.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Evidencia redactada', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final evidence in item.evidence.reversed)
              _EvidenceTile(evidence: evidence),
          ],
        ],
      ),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({required this.evidence});

  final EvidenceRecord evidence;

  @override
  Widget build(BuildContext context) => Card(
        child: ExpansionTile(
          leading: const Icon(Icons.text_snippet_outlined),
          title: Text('Comunicación · ${_riskLabel(evidence.analysis.risk)}'),
          subtitle: Text('${formatSessionDateTime(evidence.createdAt)} · ${_channelLabel(evidence.channel)}'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(evidence.redactedText),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Versión de reglas: ${evidence.analysis.ruleSetVersion}'),
            ),
          ],
        ),
      );
}

String _eventLabel(String type) => switch (type) {
      'case_created' => 'Caso iniciado',
      'evidence_analyzed' => 'Comunicación analizada',
      'false_alarm_reported' => 'Posible falsa alarma registrada',
      _ => 'Actividad de sesión',
    };

String _riskLabel(RequestRisk value) => switch (value) {
      RequestRisk.notAssessed => 'no evaluado',
      RequestRisk.noneDetected => 'sin señales detectadas',
      RequestRisk.caution => 'precaución',
      RequestRisk.high => 'alto',
      RequestRisk.abstain => 'abstención',
    };

String _channelLabel(String channel) => switch (channel) {
      'phone_call' => 'llamada telefónica',
      'sms' => 'SMS',
      'messaging_app' => 'aplicación de mensajería',
      'email' => 'correo electrónico',
      'in_person' => 'en persona',
      _ => 'desconocido',
    };

IconData _eventIcon(String type) => switch (type) {
      'evidence_analyzed' => Icons.text_snippet_outlined,
      'false_alarm_reported' => Icons.feedback_outlined,
      _ => Icons.history,
    };
