import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../sentinel/domain/config/sentinel_policy.dart';
import '../domain/models/guardian_assessment.dart';
import '../viewmodel/guardian_review_view_model.dart';
import '../../sentinel/domain/models/sentinel_analysis.dart';

class GuardianReviewScreen extends StatefulWidget {
  const GuardianReviewScreen({super.key});

  @override
  State<GuardianReviewScreen> createState() => _GuardianReviewScreenState();
}

class _GuardianReviewScreenState extends State<GuardianReviewScreen> {
  final TextEditingController _requestController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _recipientIsNew = false;
  bool _privacyAcknowledged = false;

  @override
  void dispose() {
    _requestController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _analyze() {
    context.read<GuardianReviewViewModel>().analyzeRequest(
          text: _requestController.text,
          amount: _amountController.text,
          recipientIsNew: _recipientIsNew,
        );
  }

  void _clear() {
    _requestController.clear();
    _amountController.clear();
    setState(() {
      _recipientIsNew = false;
      _privacyAcknowledged = false;
    });
    context.read<GuardianReviewViewModel>().clear();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GuardianReviewViewModel>();
    final decision = viewModel.decision;

    return Scaffold(
      appBar: AppBar(title: const Text('Guardian Pago')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Analiza una solicitud de pago real antes de actuar. El texto se procesa en este dispositivo y no se guarda al salir de esta pantalla. La redacción automática puede pasar por alto datos sensibles.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('guardian-request-input'),
                  controller: _requestController,
                  minLines: 6,
                  maxLines: 12,
                  maxLength: SentinelPolicy.maxTextCharacters,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Solicitud recibida',
                    hintText: 'Pega aquí el mensaje relacionado con el pago',
                    helperText: 'No incluyas claves, PIN, códigos ni datos completos de cuenta.',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto mencionado (opcional)',
                    prefixText: 'S/ ',
                    hintText: '100.00',
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _recipientIsNew,
                  onChanged: (value) => setState(() => _recipientIsNew = value ?? false),
                  title: const Text('El destinatario es nuevo o no habitual'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _privacyAcknowledged,
                  onChanged: (value) => setState(() => _privacyAcknowledged = value ?? false),
                  title: const Text('Entiendo cómo se procesa la solicitud'),
                  subtitle: const Text(
                    'Se analiza localmente y solo se muestra el texto redactado en el resultado.',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                FilledButton.icon(
                  key: const Key('guardian-analyze-request'),
                  onPressed: _privacyAcknowledged ? _analyze : null,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Analizar solicitud'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
                if (viewModel.errorMessage case final error?) ...[
                  const SizedBox(height: 8),
                  Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                if (decision != null) ...[
                  const SizedBox(height: 16),
                  _DecisionCard(decision: decision),
                  const SizedBox(height: 12),
                  _TrustDimensionsCard(decision: decision),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Texto redactado', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          SelectableText(viewModel.redactedText ?? ''),
                        ],
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Analizar otra solicitud'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Guardian no bloquea pagos dentro de otras aplicaciones, no mueve dinero y no confirma la identidad de una institución. Para verificar, usa la aplicación oficial o un contacto obtenido de una fuente independiente.',
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

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.decision});

  final GuardianDecision decision;

  @override
  Widget build(BuildContext context) {
    final (title, description, icon) = switch (decision.action) {
      GuardianAction.allow => (
          'Sin señales conocidas',
          'El análisis no encontró indicadores conocidos. Esto no confirma que la solicitud sea legítima ni autoriza un pago.',
          Icons.info_outline,
        ),
      GuardianAction.warn => (
          'Precaución',
          'Revisa la solicitud por un canal independiente antes de actuar.',
          Icons.warning_amber_outlined,
        ),
      GuardianAction.holdForReview => (
          'Pausa recomendada',
          'No continúes hasta verificar por otra fuente. QHAWIX no puede bloquear el pago en la aplicación financiera.',
          Icons.pause_circle_outline,
        ),
    };

    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 12),
            for (final reason in decision.reasons)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(reason)),
                  ],
                ),
              ),
            if (decision.ruleIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Reglas: ${decision.ruleIds.join(', ')}'),
            ],
            const SizedBox(height: 8),
            Text('Versión: ${decision.policyVersion}'),
          ],
        ),
      ),
    );
  }
}

class _TrustDimensionsCard extends StatelessWidget {
  const _TrustDimensionsCard({required this.decision});

  final GuardianDecision decision;

  @override
  Widget build(BuildContext context) {
    final dimensions = decision.dimensions;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dimensiones independientes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Procedencia del número: ${_numberProvenanceLabel(dimensions.numberProvenance)}'),
            Text('Confirmación institucional: ${_institutionLabel(dimensions.institutionConfirmation)}'),
            Text('Riesgo de la solicitud: ${_riskLabel(dimensions.requestRisk)}'),
            Text('Desviación conductual: ${_behaviorLabel(dimensions.behavioralDeviation)}'),
          ],
        ),
      ),
    );
  }
}

String _numberProvenanceLabel(NumberProvenance value) => switch (value) {
      NumberProvenance.unknown => 'desconocida',
      NumberProvenance.directoryMatchUnverified => 'coincidencia de directorio no verificada',
      NumberProvenance.notApplicable => 'no aplica',
    };

String _institutionLabel(InstitutionConfirmation value) => switch (value) {
      InstitutionConfirmation.notAttempted => 'no intentada',
      InstitutionConfirmation.pending => 'pendiente, autodeclarada',
      InstitutionConfirmation.userReportedConfirmed => 'confirmada por declaración de la persona',
      InstitutionConfirmation.userReportedNotConfirmed => 'no confirmada por declaración de la persona',
      InstitutionConfirmation.unreachable => 'sin respuesta por declaración de la persona',
      InstitutionConfirmation.abandoned => 'abandonada por la persona',
    };

String _riskLabel(RequestRisk value) => switch (value) {
      RequestRisk.notAssessed => 'no evaluado',
      RequestRisk.noneDetected => 'sin señales detectadas',
      RequestRisk.caution => 'precaución',
      RequestRisk.high => 'alto',
      RequestRisk.abstain => 'abstención por evidencia insuficiente',
    };

String _behaviorLabel(BehavioralDeviation value) => switch (value) {
      BehavioralDeviation.notEnrolled => 'sin referencia inscrita',
      BehavioralDeviation.insufficientData => 'datos insuficientes',
      BehavioralDeviation.withinRange => 'dentro del rango aprendido',
      BehavioralDeviation.deviation => 'desviación observada',
      BehavioralDeviation.disabled => 'desactivada',
    };
