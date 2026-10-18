import 'package:flutter/foundation.dart';

import '../domain/config/gmail_scan_policy.dart';
import '../domain/models/gmail_email.dart';
import '../domain/models/gmail_inbox_exception.dart';
import '../domain/models/sentinel_analysis.dart';
import '../domain/ports/sentinel_analysis_port.dart';
import '../domain/ports/text_redaction_port.dart';
import '../domain/repositories/gmail_inbox_repository.dart';

class GmailEmailScanResult {
  GmailEmailScanResult({
    required this.sender,
    required this.subject,
    required this.preview,
    required this.risk,
    required List<String> ruleIds,
    required List<String> signalExplanations,
  })  : ruleIds = List.unmodifiable(ruleIds),
        signalExplanations = List.unmodifiable(signalExplanations);

  final String sender;
  final String subject;
  final String preview;
  final RequestRisk risk;
  final List<String> ruleIds;
  final List<String> signalExplanations;
}

class GmailScanViewModel extends ChangeNotifier {
  GmailScanViewModel({
    required GmailInboxRepository repository,
    required SentinelAnalysisPort analyzer,
    required TextRedactionPort redactor,
  })  : _repository = repository,
        _analyzer = analyzer,
        _redactor = redactor;

  final GmailInboxRepository _repository;
  final SentinelAnalysisPort _analyzer;
  final TextRedactionPort _redactor;

  List<GmailEmailScanResult> _results = const [];
  bool _consentGiven = false;
  bool _isBusy = false;
  bool _hasScanned = false;
  bool _hasAttemptedConnection = false;
  bool _disposed = false;
  int _revision = 0;
  String? _errorMessage;

  bool get isConfigured => _repository.isConfigured;
  bool get consentGiven => _consentGiven;
  bool get isBusy => _isBusy;
  bool get hasScanned => _hasScanned;
  bool get hasAttemptedConnection => _hasAttemptedConnection;
  String? get errorMessage => _errorMessage;
  List<GmailEmailScanResult> get results => List.unmodifiable(_results);

  void setConsent(bool value) {
    _consentGiven = value;
    _errorMessage = null;
    if (!value) {
      _revision++;
      _results = const [];
      _hasScanned = false;
      _isBusy = false;
    }
    _notify();
  }

  Future<void> scan() async {
    if (_isBusy) return;
    if (!_consentGiven) {
      _errorMessage = 'Confirma el consentimiento antes de conectar Gmail.';
      _notify();
      return;
    }
    if (!isConfigured) {
      _errorMessage = 'Falta configurar el ID de cliente OAuth de tipo Web.';
      _notify();
      return;
    }

    final revision = ++_revision;
    _isBusy = true;
    _hasScanned = false;
    _hasAttemptedConnection = true;
    _results = const [];
    _errorMessage = null;
    _notify();

    try {
      final emails = await _repository.fetchRecentInbox(
        limit: GmailScanPolicy.maxMessagesPerScan,
      );
      if (!_isCurrent(revision)) return;
      _results = List.unmodifiable(
        emails.take(GmailScanPolicy.maxMessagesPerScan).map(_analyzeEmail),
      );
      _hasScanned = true;
    } on GmailInboxException catch (error) {
      if (_isCurrent(revision)) {
        _errorMessage = _messageFor(error.failure);
      }
    } catch (_) {
      if (_isCurrent(revision)) {
        _errorMessage = 'No se pudo revisar Gmail. Inténtalo de nuevo.';
      }
    } finally {
      if (_isCurrent(revision)) {
        _isBusy = false;
        _notify();
      }
    }
  }

  Future<void> disconnect() async {
    if (_isBusy) return;
    final revision = ++_revision;
    _isBusy = true;
    _errorMessage = null;
    _results = const [];
    _hasScanned = false;
    _notify();

    try {
      await _repository.disconnect();
      if (_isCurrent(revision)) _hasAttemptedConnection = false;
    } on GmailInboxException catch (error) {
      if (_isCurrent(revision)) _errorMessage = _messageFor(error.failure);
    } catch (_) {
      if (_isCurrent(revision)) {
        _errorMessage = 'No se pudo desconectar la cuenta de Google.';
      }
    } finally {
      if (_isCurrent(revision)) {
        _isBusy = false;
        _notify();
      }
    }
  }

  GmailEmailScanResult _analyzeEmail(GmailEmail email) {
    final sender = _redactor.redact(email.sender).text;
    final subject = _redactor.redact(email.subject).text;
    final body = _redactor.redact(email.body).text;
    final analysis = _analyzer.analyze('Asunto: $subject\n$body');

    return GmailEmailScanResult(
      sender: sender,
      subject: subject,
      preview: _truncateRunes(body, 240),
      risk: analysis.risk,
      ruleIds: analysis.ruleIds,
      signalExplanations: analysis.signals
          .map((signal) => signal.explanation)
          .toList(growable: false),
    );
  }

  String _messageFor(GmailInboxFailure failure) => switch (failure) {
        GmailInboxFailure.configurationMissing =>
          'Falta configurar el ID de cliente OAuth de tipo Web.',
        GmailInboxFailure.authorizationFailed =>
          'No se completó la autorización de Google. Revisa la configuración y vuelve a intentarlo.',
        GmailInboxFailure.permissionDenied =>
          'Google no concedió acceso de lectura. Revisa el permiso de Gmail y que la API esté habilitada.',
        GmailInboxFailure.networkUnavailable =>
          'No se pudo conectar con Gmail. Revisa la conexión e inténtalo otra vez.',
        GmailInboxFailure.serviceUnavailable =>
          'Gmail no pudo completar la solicitud. Inténtalo de nuevo más tarde.',
        GmailInboxFailure.rateLimited =>
          'Gmail limitó temporalmente las solicitudes. Espera un momento e inténtalo de nuevo.',
        GmailInboxFailure.invalidResponse =>
          'Gmail devolvió una respuesta que no se pudo procesar.',
        GmailInboxFailure.responseTooLarge =>
          'Un mensaje supera el tamaño admitido para esta revisión.',
      };

  String _truncateRunes(String value, int maxRunes) {
    final runes = value.runes;
    if (runes.length <= maxRunes) return value;
    return '${String.fromCharCodes(runes.take(maxRunes))}…';
  }

  bool _isCurrent(int revision) => !_disposed && revision == _revision;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    _results = const [];
    super.dispose();
  }
}
