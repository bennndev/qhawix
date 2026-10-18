import '../models/qr_reputation_result.dart';

abstract interface class QrReputationRepository {
  bool get isConfigured;
  String? get providerName;
  String? get privacyDisclosure;

  Future<QrReputationResult> checkUrl({
    required Uri url,
    required bool userConsented,
    required int inputRevision,
  });
}
