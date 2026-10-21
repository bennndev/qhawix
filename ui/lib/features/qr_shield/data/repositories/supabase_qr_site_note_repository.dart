import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/timeouts.dart';
import '../../domain/models/qr_site_note.dart';
import '../../domain/repositories/qr_site_note_repository.dart';
import '../mappers/qr_site_note_mapper.dart';

/// Sends one request to the `qr-site-notes` Edge Function and returns the
/// HTTP status with the decoded JSON body.
typedef QrSiteNoteInvoker =
    Future<({int status, Object? body})> Function(Map<String, Object?> body);

/// Notes through the `qr-site-notes` Edge Function. The app only sends the
/// signed-in session; Atomic Memory credentials stay on the server.
class SupabaseQrSiteNoteRepository implements QrSiteNoteRepository {
  SupabaseQrSiteNoteRepository({
    QrSiteNoteInvoker? invoker,
    bool Function()? hasSession,
    bool enabled = _enabledByBuild,
  }) : _invoker = invoker ?? _invokeSupabase,
       _hasSession = hasSession ?? _hasSupabaseSession,
       _enabled = enabled;

  /// Off unless the build opts in with `--dart-define=QR_SITE_NOTES_ENABLED=true`.
  static const bool _enabledByBuild = bool.fromEnvironment(
    'QR_SITE_NOTES_ENABLED',
  );
  static const String _functionName = 'qr-site-notes';

  final QrSiteNoteInvoker _invoker;
  final bool Function() _hasSession;
  final bool _enabled;

  @override
  bool get isAvailable => _enabled && _hasSession();

  @override
  Future<QrSiteNoteResult> find(String host) =>
      _send({'action': 'get', 'host': host});

  @override
  Future<QrSiteNoteResult> save(String host, String note) =>
      _send({'action': 'save', 'host': host, 'note': note});

  @override
  Future<QrSiteNoteResult> delete(String host) =>
      _send({'action': 'delete', 'host': host});

  Future<QrSiteNoteResult> _send(Map<String, Object?> body) async {
    if (!isAvailable) {
      return const QrSiteNoteResult.failed(QrSiteNoteFailure.notConfigured);
    }
    final host = body['host'];
    if (host is! String || qrSiteNoteHostKey(host) != host) {
      return const QrSiteNoteResult.failed(QrSiteNoteFailure.invalidInput);
    }
    try {
      final response = await _invoker({
        'schemaVersion': QrSiteNoteMapper.schemaVersion,
        ...body,
      }).timeout(AppTimeouts.qrSiteNoteRequest);
      return QrSiteNoteMapper.fromResponse(response.status, response.body);
    } on TimeoutException {
      return const QrSiteNoteResult.failed(QrSiteNoteFailure.timeout);
    } catch (_) {
      return const QrSiteNoteResult.failed(QrSiteNoteFailure.unavailable);
    }
  }

  /// False in previews and tests, where Supabase is not initialized.
  static bool _hasSupabaseSession() {
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  static Future<({int status, Object? body})> _invokeSupabase(
    Map<String, Object?> body,
  ) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        _functionName,
        body: body,
      );
      return (status: response.status, body: response.data);
    } on FunctionException catch (error) {
      return (status: error.status, body: error.details);
    }
  }
}
