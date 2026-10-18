import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/qr_security_incident.dart';
import '../../domain/repositories/qr_security_history_repository.dart';

class AndroidQrSecurityHistoryRepository
    implements QrSecurityHistoryRepository {
  static const MethodChannel _channel = MethodChannel(
    'pe.qhawix.qhawix/qr_security_history',
  );
  static const int _maxUrlBytes = 8 * 1024;

  @override
  Future<void> recordBlockedIncident(QrSecurityIncident incident) async {
    final url = incident.blockedUrl;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return;
    if (utf8.encode(url).length > _maxUrlBytes) return;

    await _channel.invokeMethod<void>('recordBlockedIncident', {
      'timestamp': incident.timestamp.toUtc().toIso8601String(),
      'url_bloqueada': url,
      'categoria_amenaza': incident.threatCategory,
      'detection_source': incident.detectionSource.name,
    });
  }
}
