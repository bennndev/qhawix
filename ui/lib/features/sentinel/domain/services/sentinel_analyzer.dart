import '../models/sentinel_analysis.dart';
import '../ports/sentinel_analysis_port.dart';

class SentinelAnalyzer implements SentinelAnalysisPort {
  const SentinelAnalyzer();

  static const ruleSetVersion = 'guardian-rules-0.2.0';

  static final _payment = RegExp(
    r'\b(?:pago|pagar|paga|transfier\w*|transferencia|dep[oó]sito|depositar|yape\w*|plin\w*|dinero|monto|soles?)\b|S/\s*\d[\d,.]*',
    caseSensitive: false,
  );
  static final _request = RegExp(
    r'\b(?:dame|dime|indica|env[ií]\w*|p[aá]s\w*|mand\w*|deposit\w*|transf\w*|pag\w*|yap\w*|plin\w*|haz\w*|hac\w*|realiz\w*|compr\w*|instal\w*|descarg\w*|abr\w*|compart\w*|dict\w*|ingres\w*|confirm\w*|actualiz\w*|cambi\w*|us\w*|llam\w*|solicit\w*|ped\w*|pid\w*|muev\w*|mov\w*)\b',
    caseSensitive: false,
  );
  static final _code = RegExp(
    r'\b(?:c[oó]digo|otp|pin|cvv|clave|contrase[nñ]a|token)\b',
    caseSensitive: false,
  );
  static final _institution = RegExp(
    r'\b(?:banco|bcp|interbank|scotiabank|bbva|yape|plin|polic[ií]a|fiscal[ií]a|sbs|sunat)\b',
    caseSensitive: false,
  );
  static final _pressure = RegExp(
    r'\b(?:urgente|ahora mismo|inmediatamente|hoy|te van a detener|secuestro|amenaz\w*|no le digas a nadie|en secreto|cambia de canal|no cuelgues)\b',
    caseSensitive: false,
  );
  static final _spanishEvidence = RegExp(
    r'\b(?:el|la|los|las|de|del|que|por|para|con|una|un|me|mi|tu|su|hola|buenos|buenas|gracias|necesito|puedes|favor|pago|transferencia)\b',
    caseSensitive: false,
  );

  @override
  SentinelAnalysis analyze(String redactedText) {
    final signals = <SentinelSignal>[];
    final codeRequest = _hasRequestAndTarget(
      redactedText,
      _request,
      _code,
    );
    if (codeRequest != null) {
      signals.add(_signal(
        ruleId: 'R-01',
        kind: 'credential_request',
        explanation: 'El texto pide un código o secreto de acceso.',
        strength: SignalStrength.strong,
        start: codeRequest.start,
        end: codeRequest.end,
      ));
    }

    final suppliedChannel = _hasRequestAndTarget(
      redactedText,
      RegExp(r'\b(?:llam\w*|comunic\w*|escrib\w*|contact\w*|usa|abre|entra|escanea)\b', caseSensitive: false),
      RegExp(
        r'\b(?:a\s+(?:este|mi)\s+n[uú]mero|(?:mi|este|siguiente)\s+(?:n[uú]mero|tel[eé]fono|whatsapp)|(?:este|el)\s+(?:enlace|qr|c[oó]digo)|mi\s+n[uú]mero\s+es\s+el\s+de\s+verificaci[oó]n)\b|\[(?:TEL[EÉ]FONO|CORREO)\]',
        caseSensitive: false,
      ),
    );
    if (suppliedChannel != null) {
      signals.add(_signal(
        ruleId: 'R-02',
        kind: 'requester_supplied_verification',
        explanation: 'El solicitante ofrece su propio canal como verificación.',
        strength: SignalStrength.moderate,
        start: suppliedChannel.start,
        end: suppliedChannel.end,
      ));
    }

    final pressureMatch = _pressure.firstMatch(redactedText);
    final paymentRequest = _hasRequestAndTarget(redactedText, _request, _payment);
    if (paymentRequest != null && pressureMatch != null) {
      final match = _cover(paymentRequest, pressureMatch);
      signals.add(_signal(
        ruleId: 'R-03',
        kind: 'payment_with_pressure',
        explanation: 'El pago aparece junto con presión, amenaza o secreto.',
        strength: SignalStrength.strong,
        start: match.start,
        end: match.end,
      ));
    }

    final safeAccount = _hasRequestAndTarget(
      redactedText,
      _request,
      RegExp(r'\b(?:cuenta|billetera)\s+(?:segura|protegida|de\s+resguardo)\b|\bcuenta\s+(?:de\s+)?seguridad\b', caseSensitive: false),
    );
    if (safeAccount != null) {
      signals.add(_signal(
        ruleId: 'R-04',
        kind: 'safe_account_instruction',
        explanation: 'El mensaje indica mover dinero a una supuesta cuenta segura.',
        strength: SignalStrength.strong,
        start: safeAccount.start,
        end: safeAccount.end,
      ));
    }

    final remoteAccess = _firstMatch(redactedText, [
      RegExp(r'\b(?:instal\w*|descarg\w*|abr\w*)\b.{0,45}\b(?:anydesk|teamviewer|rustdesk|acceso\s+remoto|control\s+remoto)\b', caseSensitive: false),
      RegExp(r'\b(?:compart\w*|activ\w*|permit\w*|habilit\w*)\b.{0,35}\b(?:pantalla|control\s+remoto|acceso\s+remoto)\b', caseSensitive: false),
    ]);
    if (remoteAccess != null && !_isNegated(redactedText, remoteAccess.start)) {
      signals.add(_signal(
        ruleId: 'R-05',
        kind: 'remote_access_request',
        explanation: 'Se solicita instalar o habilitar acceso remoto.',
        strength: SignalStrength.strong,
        start: remoteAccess.start,
        end: remoteAccess.end,
      ));
    }

    if (paymentRequest != null && signals.every((signal) => signal.ruleId != 'R-03')) {
      signals.add(_signal(
        ruleId: 'R-06',
        kind: 'payment_request',
        explanation: 'El texto contiene una solicitud de pago; verifica por otro canal.',
        strength: SignalStrength.weak,
        start: paymentRequest.start,
        end: paymentRequest.end,
      ));
    }

    final recipientChange = _hasRequestAndTarget(
      redactedText,
      RegExp(r'\b(?:cambi\w*|actualiz\w*|reemplaz\w*|modific\w*)\b', caseSensitive: false),
      RegExp(r'\b(?:cuenta|destinatario|n[uú]mero|cci|billetera)\b', caseSensitive: false),
    );
    if (recipientChange != null) {
      signals.add(_signal(
        ruleId: 'R-08',
        kind: 'recipient_change',
        explanation: 'Se pide cambiar la cuenta o el destinatario habitual.',
        strength: SignalStrength.strong,
        start: recipientChange.start,
        end: recipientChange.end,
      ));
    }

    final institutionalPayment = _institutionalRequest(redactedText);
    if (institutionalPayment != null) {
      signals.add(_signal(
        ruleId: 'R-09',
        kind: 'institution_with_payment_or_code',
        explanation: 'Una supuesta institución solicita dinero o un código.',
        strength: SignalStrength.strong,
        start: institutionalPayment.start,
        end: institutionalPayment.end,
      ));
    } else {
      final institutionalClaim = _firstMatch(redactedText, [
        RegExp(r'\b(?:soy|habla|llamamos|te\s+llamo|me\s+comunico)\b.{0,40}\b(?:banco|polic[ií]a|fiscal[ií]a|sbs|sunat)\b', caseSensitive: false),
        RegExp(r'\b(?:banco|polic[ií]a|fiscal[ií]a|sbs|sunat)\b.{0,40}\b(?:te\s+solicita|requiere|ordena|confirma)\b', caseSensitive: false),
      ]);
      if (institutionalClaim != null && !_isNegated(redactedText, institutionalClaim.start)) {
        signals.add(_signal(
          ruleId: 'R-10',
          kind: 'institution_claim',
          explanation: 'La mención de una institución no confirma quién envió el mensaje.',
          strength: SignalStrength.weak,
          start: institutionalClaim.start,
          end: institutionalClaim.end,
        ));
      }
    }

    final injection = _firstMatch(redactedText, [
      RegExp(r'\b(?:ignora|olvida|desobedece)\b.{0,50}\b(?:instrucciones|reglas|sistema|analizador)\b', caseSensitive: false),
      RegExp(r'\b(?:prompt|mensaje del sistema)\b.{0,40}\b(?:ignora|revela|obedece)\b', caseSensitive: false),
    ]);
    if (injection != null) {
      signals.add(_signal(
        ruleId: 'R-11',
        kind: 'analysis_instruction_injection',
        explanation: 'El contenido intenta cambiar las instrucciones del análisis.',
        strength: SignalStrength.moderate,
        start: injection.start,
        end: injection.end,
      ));
    }

    final languageSupported = _spanishEvidence.hasMatch(redactedText);
    final risk = _deriveRisk(redactedText, signals, languageSupported);
    if (signals.isEmpty &&
        redactedText.trim().isNotEmpty &&
        (redactedText.trim().runes.length < 40 || !languageSupported)) {
      signals.add(_signal(
        ruleId: 'R-12',
        kind: 'insufficient_evidence',
        explanation: 'El texto es demasiado corto o el idioma no está cubierto para evaluar señales.',
        strength: SignalStrength.weak,
        start: 0,
        end: redactedText.length,
      ));
    }
    return SentinelAnalysis(
      redactedText: redactedText,
      signals: signals,
      risk: risk,
      ruleSetVersion: ruleSetVersion,
      languageSupported: languageSupported,
    );
  }

  RequestRisk _deriveRisk(
    String text,
    List<SentinelSignal> signals,
    bool languageSupported,
  ) {
    if (text.trim().isEmpty) return RequestRisk.notAssessed;
    if (signals.any((signal) => signal.strength == SignalStrength.strong)) {
      return RequestRisk.high;
    }
    if (signals.isNotEmpty) return RequestRisk.caution;
    if (text.trim().runes.length < 40 || !languageSupported) {
      return RequestRisk.abstain;
    }
    return RequestRisk.noneDetected;
  }

  SentinelSignal _signal({
    required String ruleId,
    required String kind,
    required String explanation,
    required SignalStrength strength,
    required int start,
    required int end,
  }) => SentinelSignal(
        ruleId: ruleId,
        kind: kind,
        explanation: explanation,
        strength: strength,
        start: start,
        end: end,
      );

  RegExpMatch? _firstMatch(String text, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) return match;
    }
    return null;
  }

  _Span? _hasRequestAndTarget(String text, RegExp request, RegExp target) {
    for (final requestMatch in request.allMatches(text)) {
      final beforeRequest = text.substring(0, requestMatch.start);
      final previousBoundary = beforeRequest.lastIndexOf(RegExp(r'[.!?;\n]'));
      final sentenceStart = previousBoundary < 0 ? 0 : previousBoundary + 1;
      if (_isNegated(text, requestMatch.start)) continue;
      final sentenceSuffix = text.substring(requestMatch.end);
      final nextBoundary = RegExp(r'[.!?;\n]').firstMatch(sentenceSuffix);
      final sentenceEnd = nextBoundary == null
          ? text.length
          : requestMatch.end + nextBoundary.start;
      final start = (requestMatch.start - 70).clamp(sentenceStart, text.length).toInt();
      final end = (requestMatch.end + 70).clamp(0, sentenceEnd).toInt();
      if (start >= end) continue;
      final window = text.substring(start, end);
      final targetMatch = target.firstMatch(window);
      if (targetMatch != null) {
        return _Span(start + targetMatch.start, start + targetMatch.end);
      }
    }
    return null;
  }

  bool _isNegated(String text, int index) {
    final beforeMatch = text.substring(0, index);
    final previousBoundary = beforeMatch.lastIndexOf(RegExp(r'[.!?;\n]'));
    final sentenceStart = previousBoundary < 0 ? 0 : previousBoundary + 1;
    final sentencePrefix = text.substring(sentenceStart, index);
    return RegExp(
      r'\b(?:no|nunca|jam[aá]s)\b(?:\s+\w+){0,4}\s*$',
      caseSensitive: false,
    ).hasMatch(sentencePrefix);
  }

  _Span? _institutionalRequest(String text) {
    for (final institution in _institution.allMatches(text)) {
      final windowStart = (institution.start - 20).clamp(0, text.length).toInt();
      final windowEnd = (institution.end + 100).clamp(0, text.length).toInt();
      final window = text.substring(windowStart, windowEnd);
      if (_hasRequestAndTarget(window, _request, _code) != null ||
          _hasRequestAndTarget(window, _request, _payment) != null) {
        return _Span(windowStart, windowEnd);
      }
    }
    return null;
  }

  _Span _cover(_Span first, RegExpMatch second) {
    return _Span(
      first.start < second.start ? first.start : second.start,
      first.end > second.end ? first.end : second.end,
    );
  }
}

class _Span {
  const _Span(this.start, this.end);

  final int start;
  final int end;
}
