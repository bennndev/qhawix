import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/qr_security_incident.dart';
import '../../domain/repositories/qr_security_history_repository.dart';
import '../../domain/repositories/qr_security_history_query_repository.dart';

class AndroidQrSecurityHistoryRepository
    implements QrSecurityHistoryRepository, QrSecurityHistoryQueryRepository {
  static const MethodChannel _channel = MethodChannel(
    'pe.qhawix.qhawix/qr_security_history',
  );
  static const int _maxUrlBytes = 8 * 1024;

  @override
  Future<void> recordBlockedIncident(
    QrSecurityIncident incident, {
    required Uri lookupUri,
  }) async {
    final url = incident.blockedUrl;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return;
    if (utf8.encode(url).length > _maxUrlBytes ||
        !_isEligibleLookupUri(lookupUri)) {
      return;
    }

    await _channel.invokeMethod<void>('recordBlockedIncident', {
      'timestamp': incident.timestamp.toUtc().toIso8601String(),
      'url_bloqueada': url,
      'lookup_url': lookupUri.toString(),
      'categoria_amenaza': incident.threatCategory,
      'detection_source': incident.detectionSource.name,
    });
  }

  @override
  Future<bool> isUrlAllowed(Uri url) async {
    if (!_isEligibleLookupUri(url)) return false;
    return await _channel.invokeMethod<bool>('isUrlAllowed', {
          'lookup_url': url.toString(),
        }) ??
        false;
  }

  @override
  Future<List<QrSecurityIncident>> loadIncidents() async {
    final rows = await _channel.invokeListMethod<Object?>(
      'getIncidents',
    );
    if (rows == null) return const [];

    final incidents = <QrSecurityIncident>[];
    for (final value in rows) {
      if (value is! Map) continue;
      final row = Map<Object?, Object?>.from(value);
      final id = row['id'];
      final timestamp = DateTime.tryParse(row['timestamp'] as String? ?? '');
      final blockedUrl = row['url_bloqueada'];
      final category = row['categoria_amenaza'];
      final source = QrSecurityDetectionSource.values.where(
        (candidate) => candidate.name == row['detection_source'],
      );
      if (id is! num ||
          timestamp == null ||
          blockedUrl is! String ||
          category is! String ||
          source.isEmpty) {
        continue;
      }
      incidents.add(
        QrSecurityIncident(
          id: id.toInt(),
          timestamp: timestamp.toUtc(),
          blockedUrl: blockedUrl,
          threatCategory: category,
          detectionSource: source.first,
          isAllowed: row['permitido'] == true,
          hasAllowlistFingerprint: row['puede_permitirse'] == true,
        ),
      );
    }
    return List.unmodifiable(incidents);
  }

  @override
  Future<bool> allowIncident(int id) async {
    if (id <= 0) return false;
    return await _channel.invokeMethod<bool>('allowIncident', {
          'id': id,
        }) ??
        false;
  }

  bool _isEligibleLookupUri(Uri uri) =>
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      uri.hasAuthority &&
      utf8.encode(uri.toString()).length <= _maxUrlBytes &&
      !RegExp(r'[\u0000-\u001f\u007f]').hasMatch(uri.toString());
}
