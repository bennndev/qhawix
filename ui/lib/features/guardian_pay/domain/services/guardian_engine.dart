import '../../../sentinel/domain/models/sentinel_analysis.dart';
import '../models/guardian_assessment.dart';
import 'guardian_policy.dart';

class GuardianEngine {
  const GuardianEngine();

  GuardianDecision evaluate({
    required SentinelAnalysis analysis,
    required GuardianPaymentContext context,
    TrustDimensions dimensions = const TrustDimensions(),
  }) {
    final ruleIds = analysis.ruleIds.toSet();
    final reasons = <String>[];
    const hardHoldRules = {
      'R-01',
      'R-03',
      'R-04',
      'R-05',
      'R-08',
      'R-09',
    };

    var action = switch (analysis.risk) {
      RequestRisk.high => GuardianAction.holdForReview,
      RequestRisk.caution || RequestRisk.abstain || RequestRisk.notAssessed =>
        GuardianAction.warn,
      RequestRisk.noneDetected => GuardianAction.allow,
    };

    if (ruleIds.any(hardHoldRules.contains)) {
      action = GuardianAction.holdForReview;
      reasons.add('Hay una señal que requiere pausar y verificar por otra fuente.');
    } else if (analysis.risk == RequestRisk.high) {
      reasons.add('El análisis encontró señales de riesgo alto.');
    } else if (analysis.risk == RequestRisk.caution) {
      reasons.add('El análisis encontró señales que requieren cautela.');
    } else if (analysis.risk == RequestRisk.abstain) {
      reasons.add('La evidencia es insuficiente para evaluar esta solicitud.');
    } else if (analysis.risk == RequestRisk.notAssessed) {
      reasons.add('No se evaluó una comunicación; esto no confirma legitimidad.');
    } else {
      reasons.add('No se detectaron señales conocidas; esto no confirma legitimidad.');
    }

    if (ruleIds.contains('R-02')) {
      if (action == GuardianAction.allow) action = GuardianAction.warn;
      reasons.add('No uses el canal de verificación que aportó quien solicita el pago.');
    }
    if (ruleIds.contains('R-06')) {
      if (action == GuardianAction.allow) action = GuardianAction.warn;
      reasons.add('Verifica la solicitud por un canal independiente.');
    }
    if (ruleIds.contains('R-10')) {
      reasons.add('La mención de una institución no confirma quién hizo la solicitud.');
    }
    if (ruleIds.contains('R-11')) {
      reasons.add('Se descartó una instrucción dirigida a cambiar el análisis.');
    }
    if (context.recipientIsNew &&
        context.amountCents != null &&
        context.amountCents! >= GuardianPolicy.newRecipientWarningCents) {
      ruleIds.add('R-07');
      final hasReliableSignal = analysis.signals.any(
        (signal) => signal.strength != SignalStrength.weak,
      );
      if (hasReliableSignal) {
        action = GuardianAction.holdForReview;
        reasons.add('El destinatario es nuevo y el monto alcanza el umbral de revisión.');
      } else {
        if (action == GuardianAction.allow) action = GuardianAction.warn;
        reasons.add('Confirma por otro canal el destinatario nuevo y el monto.');
      }
    }

    return GuardianDecision(
      action: action,
      dimensions: TrustDimensions(
        numberProvenance: dimensions.numberProvenance,
        institutionConfirmation: dimensions.institutionConfirmation,
        requestRisk: analysis.risk,
        behavioralDeviation: dimensions.behavioralDeviation,
      ),
      ruleIds: ruleIds.toList(),
      reasons: reasons,
      policyVersion: GuardianPolicy.version,
    );
  }
}
