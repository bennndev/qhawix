import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/config/gmail_scan_policy.dart';
import '../../domain/models/gmail_email.dart';
import '../../domain/models/gmail_inbox_exception.dart';
import '../../domain/repositories/gmail_inbox_repository.dart';
import '../services/gmail_message_parser.dart';

class GoogleGmailInboxRepository implements GmailInboxRepository {
  GoogleGmailInboxRepository({
    required String serverClientId,
    GoogleSignIn? googleSignIn,
    HttpClient Function()? httpClientFactory,
    GmailMessageParser parser = const GmailMessageParser(),
  })  : _serverClientId = serverClientId.trim(),
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _httpClientFactory = httpClientFactory ?? HttpClient.new,
        _parser = parser;

  static const _scope = 'https://www.googleapis.com/auth/gmail.readonly';
  static const _gmailHost = 'gmail.googleapis.com';
  final String _serverClientId;
  final GoogleSignIn _googleSignIn;
  final HttpClient Function() _httpClientFactory;
  final GmailMessageParser _parser;
  bool _initialized = false;

  @override
  bool get isConfigured => _serverClientId.isNotEmpty;

  @override
  Future<List<GmailEmail>> fetchRecentInbox({required int limit}) async {
    if (!isConfigured) {
      throw const GmailInboxException(GmailInboxFailure.configurationMissing);
    }

    final boundedLimit = limit
        .clamp(1, GmailScanPolicy.maxMessagesPerScan)
        .toInt();
    late final String accessToken;
    try {
      if (!_initialized) {
        await _googleSignIn.initialize(serverClientId: _serverClientId);
        _initialized = true;
      }
      final account = await _googleSignIn.authenticate(
        scopeHint: const [_scope],
      );
      final authorization = await account.authorizationClient.authorizeScopes(
        const [_scope],
      );
      accessToken = authorization.accessToken;
    } catch (_) {
      throw const GmailInboxException(GmailInboxFailure.authorizationFailed);
    }

    final client = _httpClientFactory();
    try {
      final listUri = Uri.https(_gmailHost, '/gmail/v1/users/me/messages', {
        'labelIds': 'INBOX',
        'maxResults': '$boundedLimit',
      });
      final listJson = await _getText(client, listUri, accessToken);
      final ids = _parser.parseMessageIds(listJson).take(boundedLimit);
      final messages = <GmailEmail>[];

      for (final id in ids) {
        final messageUri = Uri.https(
          _gmailHost,
          '/gmail/v1/users/me/messages/${Uri.encodeComponent(id)}',
          const {'format': 'full'},
        );
        final messageJson = await _getText(client, messageUri, accessToken);
        messages.add(_parser.parseMessage(id: id, json: messageJson));
      }

      return List.unmodifiable(messages);
    } on GmailInboxException {
      rethrow;
    } on FormatException {
      throw const GmailInboxException(GmailInboxFailure.invalidResponse);
    } catch (_) {
      throw const GmailInboxException(GmailInboxFailure.networkUnavailable);
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _getText(
    HttpClient client,
    Uri uri,
    String accessToken,
  ) async {
    try {
      final request = await client
          .getUrl(uri)
          .timeout(GmailScanPolicy.requestTimeout);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request
          .close()
          .timeout(GmailScanPolicy.requestTimeout);
      final bytes = await _readBounded(response)
          .timeout(GmailScanPolicy.requestTimeout);

      if (response.statusCode == HttpStatus.unauthorized) {
        throw const GmailInboxException(GmailInboxFailure.authorizationFailed);
      }
      if (response.statusCode == HttpStatus.forbidden) {
        throw const GmailInboxException(GmailInboxFailure.permissionDenied);
      }
      if (response.statusCode == HttpStatus.tooManyRequests) {
        throw const GmailInboxException(GmailInboxFailure.rateLimited);
      }
      if (response.statusCode != HttpStatus.ok) {
        throw const GmailInboxException(GmailInboxFailure.serviceUnavailable);
      }

      return utf8.decode(bytes);
    } on GmailInboxException {
      rethrow;
    } on FormatException {
      throw const GmailInboxException(GmailInboxFailure.invalidResponse);
    } catch (_) {
      throw const GmailInboxException(GmailInboxFailure.networkUnavailable);
    }
  }

  Future<List<int>> _readBounded(HttpClientResponse response) async {
    final builder = BytesBuilder(copy: false);
    var byteCount = 0;
    await for (final chunk in response) {
      byteCount += chunk.length;
      if (byteCount > GmailScanPolicy.maxResponseBytes) {
        throw const GmailInboxException(GmailInboxFailure.responseTooLarge);
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  @override
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      throw const GmailInboxException(GmailInboxFailure.authorizationFailed);
    }
  }
}
