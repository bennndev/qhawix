enum QrUrlSignal {
  insecureHttp,
  punycode,
  mixedScripts,
  knownShortener,
  identifiableRedirect,
  fragmentPresent,
  unusualPort,
  embeddedCredentials,
  localOrNonPublicHost,
  sensitiveQuery,
  sensitivePath,
  controlCharacters,
  unsupportedScheme,
  invalidStructure,
}

class QrUrlAssessment {
  const QrUrlAssessment({
    required this.originalValue,
    required this.parsedUri,
    required this.displayValue,
    required this.host,
    required this.unicodeHost,
    required this.asciiHost,
    required this.signals,
    required this.isEligibleForReputation,
    required this.canOpenExternally,
    required this.fragmentOmittedFromReputation,
    this.blockReasonCode,
  });

  final String originalValue;
  final Uri? parsedUri;
  final String displayValue;
  final String host;
  final String unicodeHost;
  final String asciiHost;
  final List<QrUrlSignal> signals;
  final bool isEligibleForReputation;
  final bool canOpenExternally;
  final bool fragmentOmittedFromReputation;
  final String? blockReasonCode;

  bool get hasWarnings => signals.isNotEmpty;

  Uri? get reputationUri => parsedUri?.removeFragment();

  String get historySafeValue {
    final uri = parsedUri;
    if (uri == null) return displayValue;
    final hidePath = signals.contains(QrUrlSignal.sensitivePath);
    return uri
        .replace(
          userInfo: '',
          path: hidePath ? '/[ruta oculta]' : uri.path,
          query: null,
          fragment: null,
        )
        .toString();
  }
}
