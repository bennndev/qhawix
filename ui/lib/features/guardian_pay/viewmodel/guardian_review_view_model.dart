import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../sentinel/domain/config/sentinel_policy.dart';
import '../../sentinel/domain/ports/sentinel_analysis_port.dart';
import '../../sentinel/domain/ports/text_redaction_port.dart';
import '../domain/models/guardian_assessment.dart';
import '../domain/services/guardian_engine.dart';
import '../domain/services/guardian_policy.dart';

class GuardianReviewViewModel extends ChangeNotifier {
  GuardianReviewViewModel({
    required SentinelAnalysisPort analyzer,
    required TextRedactionPort redactor,
    GuardianEngine engine = const GuardianEngine(),
  })  : _analyzer = analyzer,
        _redactor = redactor,
        _engine = engine;

  final SentinelAnalysisPort _analyzer;
  final TextRedactionPort _redactor;
  final GuardianEngine _engine;

  GuardianDecision? _decision;
  String? _redactedText;
  String? _errorMessage;

  GuardianDecision? get decision => _decision;
  String? get redactedText => _redactedText;
  String? get errorMessage => _errorMessage;

  bool analyzeRequest({
    required String text,
    required String amount,
    required bool recipientIsNew,
  }) {
    _errorMessage = null;
    _decision = null;
    _redactedText = null;
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      _errorMessage = 'Pega la solicitud de pago que quieres revisar.';
      notifyListeners();
      return false;
    }
    if (normalizedText.runes.length > SentinelPolicy.maxTextCharacters) {
      _errorMessage = 'La solicitud supera el límite permitido para el análisis.';
      notifyListeners();
      return false;
    }
    try {
      if (utf8.encode(normalizedText).length > SentinelPolicy.maxEvidenceBytes) {
        _errorMessage = 'La solicitud supera el límite permitido para el análisis.';
        notifyListeners();
        return false;
      }
    } on FormatException {
      _errorMessage = 'La solicitud tiene caracteres que no se pueden procesar.';
      notifyListeners();
      return false;
    }

    final amountCents = _parseAmount(amount);
    if (amount.trim().isNotEmpty && amountCents == null) {
      _errorMessage = 'Ingresa un monto válido en soles, con hasta dos decimales.';
      notifyListeners();
      return false;
    }

    final redaction = _redactor.redact(normalizedText);
    final analysis = _analyzer.analyze(redaction.text);
    _decision = _engine.evaluate(
      analysis: analysis,
      context: GuardianPaymentContext(
        amountCents: amountCents,
        recipientIsNew: recipientIsNew,
      ),
    );
    _redactedText = redaction.text;
    notifyListeners();
    return true;
  }

  void clear() {
    _decision = null;
    _redactedText = null;
    _errorMessage = null;
    notifyListeners();
  }

  int? _parseAmount(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    if (!RegExp(r'^\d{1,8}(?:\.\d{1,2})?$').hasMatch(normalized)) return null;
    final parts = normalized.split('.');
    final soles = int.tryParse(parts.first);
    if (soles == null) return null;
    final cents = int.tryParse((parts.length == 1 ? '' : parts[1]).padRight(2, '0')) ?? 0;
    final amountCents = soles * 100 + cents;
    return amountCents > 0 && amountCents <= GuardianPolicy.maxPaymentAmountCents
        ? amountCents
        : null;
  }
}
