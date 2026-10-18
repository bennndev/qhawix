enum RequestRisk { notAssessed, noneDetected, caution, high, abstain }

enum SignalStrength { weak, moderate, strong }

enum NumberProvenance {
  unknown,
  directoryMatchUnverified,
  notApplicable,
}

enum InstitutionConfirmation {
  notAttempted,
  pending,
  userReportedConfirmed,
  userReportedNotConfirmed,
  unreachable,
  abandoned,
}

enum BehavioralDeviation {
  notEnrolled,
  insufficientData,
  withinRange,
  deviation,
  disabled,
}

class TrustDimensions {
  const TrustDimensions({
    this.numberProvenance = NumberProvenance.unknown,
    this.institutionConfirmation = InstitutionConfirmation.notAttempted,
    this.requestRisk = RequestRisk.notAssessed,
    this.behavioralDeviation = BehavioralDeviation.disabled,
  });

  final NumberProvenance numberProvenance;
  final InstitutionConfirmation institutionConfirmation;
  final RequestRisk requestRisk;
  final BehavioralDeviation behavioralDeviation;
}

class SentinelSignal {
  const SentinelSignal({
    required this.ruleId,
    required this.kind,
    required this.explanation,
    required this.strength,
    required this.start,
    required this.end,
  });

  final String ruleId;
  final String kind;
  final String explanation;
  final SignalStrength strength;
  final int start;
  final int end;
}

class SentinelAnalysis {
  SentinelAnalysis({
    required this.redactedText,
    required List<SentinelSignal> signals,
    required this.risk,
    required this.ruleSetVersion,
    required this.languageSupported,
  }) : signals = List.unmodifiable(signals);

  final String redactedText;
  final List<SentinelSignal> signals;
  final RequestRisk risk;
  final String ruleSetVersion;
  final bool languageSupported;

  List<String> get ruleIds =>
      List.unmodifiable(signals.map((signal) => signal.ruleId).toSet());
}
