import '../config/qr_reputation_config.dart';
import '../models/qr_reputation_result.dart';
import '../models/qr_url_assessment.dart';

enum QrOpenPolicyDecision {
  allowAfterConfirmation,
  blockedByLocalPolicy,
  blockedByKnownThreat,
  blockedByUnverified,
  reputationExpired,
}

class QrReputationPolicy {
  const QrReputationPolicy();

  static const Duration negativeResultMaxAge =
      QrReputationConfig.negativeResultMaxAge;

  QrReputationResult applyProviderResponse(
    QrReputationResult result, {
    required QrUrlAssessment assessment,
    required DateTime now,
  }) {
    if (result.status == QrReputationStatus.suspiciousOrUnverified) {
      return result;
    }

    if (!assessment.isEligibleForReputation) {
      return _unverified(
        'url_not_eligible',
        providerState: QrProviderState.invalidResponse,
        result: result,
      );
    }

    final checkedAt = result.checkedAt;
    final expiresAt = result.expiresAt;
    final hasCurrentMetadata =
        result.provider?.trim().isNotEmpty == true &&
        result.providerState == QrProviderState.available &&
        checkedAt != null &&
        !checkedAt.isAfter(now);
    if (!hasCurrentMetadata) {
      return _unverified(
        'invalid_provider_response',
        providerState: QrProviderState.invalidResponse,
        result: result,
      );
    }

    if (result.status == QrReputationStatus.noKnownThreats &&
        (result.categories.isNotEmpty || expiresAt != null)) {
      return _unverified(
        'invalid_provider_response',
        providerState: QrProviderState.invalidResponse,
        result: result,
      );
    }

    if (result.checkedCategories.any((category) => category.trim().isEmpty) ||
        result.categories.any((category) => category.trim().isEmpty)) {
      return _unverified(
        'invalid_provider_response',
        providerState: QrProviderState.invalidResponse,
        result: result,
      );
    }

    if (result.status == QrReputationStatus.noKnownThreats &&
        !result.coverageComplete) {
      return _unverified(
        'coverage_incomplete',
        providerState: result.providerState,
        result: result,
      );
    }

    if (result.status == QrReputationStatus.noKnownThreats &&
        result.checkedCategories.isEmpty) {
      return _unverified(
        'scope_missing',
        providerState: QrProviderState.invalidResponse,
        result: result,
      );
    }

    if (result.status == QrReputationStatus.noKnownThreats &&
        now.difference(checkedAt) > negativeResultMaxAge) {
      return _unverified(
        'negative_review_expired',
        providerState: result.providerState,
        result: result,
      );
    }

    if (result.status == QrReputationStatus.noKnownThreats &&
        assessment.hasWarnings) {
      return _unverified(
        'local_signal',
        providerState: result.providerState,
        result: result,
      );
    }

    if (result.status == QrReputationStatus.knownThreat &&
        (expiresAt == null || !expiresAt.isAfter(now))) {
      return _unverified(
        'invalid_provider_response',
        providerState: QrProviderState.invalidResponse,
        result: result,
      );
    }

    return result;
  }

  QrOpenPolicyDecision decideOpening({
    required QrUrlAssessment reviewedAssessment,
    required QrUrlAssessment? currentAssessment,
    required QrReputationResult? reputation,
    required DateTime now,
  }) {
    if (currentAssessment == null ||
        !reviewedAssessment.canOpenExternally ||
        !currentAssessment.canOpenExternally ||
        reviewedAssessment.originalValue != currentAssessment.originalValue) {
      return QrOpenPolicyDecision.blockedByLocalPolicy;
    }

    if (reputation?.status == QrReputationStatus.knownThreat) {
      return isCurrentKnownThreat(reputation!, now)
          ? QrOpenPolicyDecision.blockedByKnownThreat
          : QrOpenPolicyDecision.reputationExpired;
    }

    if (reputation?.reasonCode == 'negative_review_expired') {
      return QrOpenPolicyDecision.reputationExpired;
    }

    if (reputation?.status == QrReputationStatus.noKnownThreats) {
      if (reviewedAssessment.hasWarnings ||
          currentAssessment.hasWarnings ||
          !isCurrentNegative(reputation!, now)) {
        return QrOpenPolicyDecision.reputationExpired;
      }
      return QrOpenPolicyDecision.allowAfterConfirmation;
    }

    return QrOpenPolicyDecision.blockedByUnverified;
  }

  bool isCurrentKnownThreat(QrReputationResult result, DateTime now) =>
      result.status == QrReputationStatus.knownThreat &&
      result.providerState == QrProviderState.available &&
      result.provider?.trim().isNotEmpty == true &&
      result.checkedAt != null &&
      !result.checkedAt!.isAfter(now) &&
      result.expiresAt?.isAfter(now) == true &&
      result.categories.isNotEmpty &&
      result.categories.every((category) => category.trim().isNotEmpty);

  bool isCurrentNegative(QrReputationResult result, DateTime now) {
    final checkedAt = result.checkedAt;
    if (result.status != QrReputationStatus.noKnownThreats ||
        result.providerState != QrProviderState.available ||
        result.provider?.trim().isNotEmpty != true ||
        checkedAt == null ||
        checkedAt.isAfter(now) ||
        result.expiresAt != null ||
        !result.coverageComplete ||
        result.checkedCategories.isEmpty ||
        result.checkedCategories.any((category) => category.trim().isEmpty) ||
        result.categories.isNotEmpty) {
      return false;
    }

    final age = now.difference(checkedAt);
    return !age.isNegative && age <= negativeResultMaxAge;
  }

  DateTime? reviewExpiryDeadline(QrReputationResult result) {
    if (result.status == QrReputationStatus.suspiciousOrUnverified) return null;

    if (result.status != QrReputationStatus.noKnownThreats) {
      return result.expiresAt;
    }

    final checkedAt = result.checkedAt;
    if (checkedAt == null) return null;
    final localFreshnessLimit = checkedAt.add(negativeResultMaxAge);
    final providerExpiry = result.expiresAt;
    if (providerExpiry == null ||
        localFreshnessLimit.isBefore(providerExpiry)) {
      return localFreshnessLimit;
    }
    return providerExpiry;
  }

  QrReputationResult expired(QrReputationResult previous) => _unverified(
    previous.status == QrReputationStatus.noKnownThreats ||
            previous.reasonCode == 'negative_review_expired'
        ? 'negative_review_expired'
        : 'reputation_expired',
    providerState: previous.providerState,
    result: previous,
  );

  QrReputationResult _unverified(
    String reasonCode, {
    required QrProviderState providerState,
    required QrReputationResult result,
  }) => QrReputationResult.suspiciousOrUnverified(
    reasonCode,
    providerState: providerState,
    provider: result.provider,
    checkedAt: result.checkedAt,
    expiresAt: result.expiresAt,
    coverageComplete: result.coverageComplete,
    categories: result.categories,
    checkedCategories: result.checkedCategories,
  );
}
