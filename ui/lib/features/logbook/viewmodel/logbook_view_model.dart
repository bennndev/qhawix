import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/clock.dart';
import '../../sentinel/domain/config/sentinel_policy.dart';
import '../../sentinel/domain/ports/sentinel_analysis_port.dart';
import '../../sentinel/domain/ports/text_redaction_port.dart';
import '../domain/models/logbook_case.dart';
import '../domain/services/logbook_policy.dart';

class LogbookViewModel extends ChangeNotifier {
  LogbookViewModel({
    required Clock clock,
    required SentinelAnalysisPort analyzer,
    required TextRedactionPort redactor,
  })  : _clock = clock,
        _analyzer = analyzer,
        _redactor = redactor {
    _expiryTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_purgeExpired()) notifyListeners();
    });
  }

  final Clock _clock;
  final SentinelAnalysisPort _analyzer;
  final TextRedactionPort _redactor;
  final Random _random = Random.secure();
  final Map<String, QhawixCase> _cases = {};
  late final Timer _expiryTimer;
  String? errorMessage;

  @override
  void dispose() {
    _expiryTimer.cancel();
    super.dispose();
  }

  List<QhawixCase> get cases {
    _purgeExpired();
    final items = _cases.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(items);
  }

  QhawixCase? caseById(String id) {
    _purgeExpired();
    return _cases[id];
  }

  String? createEmptyCase() {
    errorMessage = null;
    _purgeExpired();
    if (_cases.length >= LogbookPolicy.maxCasesInMemory) {
      errorMessage = 'La sesión alcanzó el límite de casos. Borra uno para continuar.';
      return null;
    }
    final now = _clock.now();
    final item = QhawixCase(
      id: _newId(),
      createdAt: now,
      expiresAt: now.add(LogbookPolicy.caseLifetime),
    );
    _cases[item.id] = item.addEvent(_event(item, 'case_created', const []));
    notifyListeners();
    return item.id;
  }

  String? analyzeEvidence({required String text, required String channel}) {
    errorMessage = null;
    final normalized = _validateText(text);
    if (normalized == null) return null;
    _purgeExpired();
    if (_cases.length >= LogbookPolicy.maxCasesInMemory) {
      errorMessage = 'La sesión alcanzó el límite de casos. Borra uno para continuar.';
      return null;
    }

    final now = _clock.now();
    final id = _newId();
    final analysis = _analyzer.analyze(_redactor.redact(normalized).text);
    final item = QhawixCase(
      id: id,
      createdAt: now,
      expiresAt: now.add(LogbookPolicy.caseLifetime),
    );
    final evidence = EvidenceRecord(
      id: _newId(),
      channel: channel,
      redactedText: analysis.redactedText,
      analysis: analysis,
      createdAt: now,
    );
    final withCaseEvent = item.addEvent(_event(item, 'case_created', const []));
    _cases[id] = withCaseEvent.addEvidence(
      evidence,
      _event(withCaseEvent, 'evidence_analyzed', analysis.ruleIds),
    );
    notifyListeners();
    return id;
  }

  bool addEvidenceToCase({
    required String caseId,
    required String text,
    required String channel,
  }) {
    errorMessage = null;
    final item = caseById(caseId);
    if (item == null) {
      errorMessage = 'El caso ya no está disponible en esta sesión.';
      return false;
    }
    if (item.events.length >= LogbookPolicy.maxEventsPerCase) {
      errorMessage = 'El caso alcanzó el límite de eventos. Borra el caso para continuar.';
      return false;
    }
    final normalized = _validateText(text);
    if (normalized == null) return false;

    final analysis = _analyzer.analyze(_redactor.redact(normalized).text);
    _cases[caseId] = item.addEvidence(
      EvidenceRecord(
        id: _newId(),
        channel: channel,
        redactedText: analysis.redactedText,
        analysis: analysis,
        createdAt: _clock.now(),
      ),
      _event(item, 'evidence_analyzed', analysis.ruleIds),
    );
    notifyListeners();
    return true;
  }

  bool deleteCase(String caseId) {
    if (_cases.remove(caseId) == null) return false;
    notifyListeners();
    return true;
  }

  bool recordFalseAlarm(String caseId) {
    final item = caseById(caseId);
    if (item == null) return false;
    if (item.events.length >= LogbookPolicy.maxEventsPerCase) {
      errorMessage = 'La línea de tiempo alcanzó su límite.';
      return false;
    }
    _cases[caseId] = item.addEvent(_event(item, 'false_alarm_reported', const []));
    notifyListeners();
    return true;
  }

  String? _validateText(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      errorMessage = 'Escribe o pega el contenido que quieres revisar.';
      return null;
    }
    if (normalized.runes.length > SentinelPolicy.maxTextCharacters) {
      errorMessage = 'El contenido supera el límite permitido para esta sesión.';
      return null;
    }
    try {
      if (utf8.encode(normalized).length > SentinelPolicy.maxEvidenceBytes) {
        errorMessage = 'El contenido supera el límite permitido para esta sesión.';
        return null;
      }
    } on FormatException {
      errorMessage = 'El contenido tiene caracteres que no se pueden procesar.';
      return null;
    }
    return normalized;
  }

  bool _purgeExpired() {
    final now = _clock.now();
    final expiredIds = _cases.values
        .where((item) => !item.expiresAt.isAfter(now))
        .map((item) => item.id)
        .toList();
    if (expiredIds.isEmpty) return false;
    for (final id in expiredIds) {
      _cases.remove(id);
    }
    return true;
  }

  TimelineEvent _event(QhawixCase item, String type, List<String> ruleIds) =>
      TimelineEvent(
        id: _newId(),
        sequence: item.events.length + 1,
        type: type,
        actor: 'user_or_policy',
        at: _clock.now(),
        ruleIds: ruleIds,
      );

  String _newId() => List<int>.generate(16, (_) => _random.nextInt(256))
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}
