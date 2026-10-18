enum QrUrlSignal {
  insecureHttp,
  punycode,
  mixedScripts,
  knownShortener,
  unusualPort,
  embeddedCredentials,
  localOrNonPublicHost,
  sensitiveQuery,
  controlCharacters,
  unsupportedScheme,
  invalidStructure,
}

class QrUrlAssessment {
  QrUrlAssessment({
    required this.originalValue,
    required this.displayValue,
    required this.fullDisplayValue,
    required this.host,
    required this.unicodeHost,
    required this.asciiHost,
    required List<QrUrlSignal> signals,
    required this.isEligibleForReputation,
    required this.canOpenExternally,
    required this.fragmentOmittedFromReputation,
    this.blockReasonCode,
  }) : signals = List.unmodifiable(signals);

  final String originalValue;
  final String displayValue;
  final String fullDisplayValue;
  final String host;
  final String unicodeHost;
  final String asciiHost;
  final List<QrUrlSignal> signals;
  final bool isEligibleForReputation;
  final bool canOpenExternally;
  final bool fragmentOmittedFromReputation;
  final String? blockReasonCode;

  bool get hasWarnings => signals.isNotEmpty;
}
