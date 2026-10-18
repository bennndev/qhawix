import '../models/qr_scan_payload.dart';
import '../models/qr_url_assessment.dart';
import '../services/qr_url_inspector.dart';

class InspectQrPayload {
  const InspectQrPayload({required QrUrlInspector urlInspector})
      : _urlInspector = urlInspector;

  final QrUrlInspector _urlInspector;

  QrInspection inspect(String rawValue) {
    final payload = QrScanPayload.create(rawValue);
    final urlAssessment = payload.isAccepted && payload.kind == QrPayloadKind.url
        ? _urlInspector.inspect(payload.rawValue)
        : null;
    return QrInspection(payload: payload, urlAssessment: urlAssessment);
  }
}

class QrInspection {
  const QrInspection({required this.payload, required this.urlAssessment});

  final QrScanPayload payload;
  final QrUrlAssessment? urlAssessment;
}
