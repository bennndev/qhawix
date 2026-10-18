import '../../domain/models/qr_reputation_result.dart';
import '../../domain/repositories/qr_reputation_repository.dart';

class UnconfiguredQrReputationRepository implements QrReputationRepository {
  const UnconfiguredQrReputationRepository();

  @override
  bool get isConfigured => false;

  @override
  String? get providerName => null;

  @override
  String? get privacyDisclosure => null;

  @override
  Future<QrReputationResult> checkUrl({
    required Uri url,
    required bool userConsented,
    required int inputRevision,
  }) async {
    if (!userConsented) {
      return QrReputationResult.unverifiable('consent_not_granted');
    }
    return QrReputationResult.unverifiable('provider_not_configured');
  }
}
