import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/qr_shield/domain/models/qr_reputation_result.dart';
import 'package:qhawix/features/qr_shield/domain/models/qr_url_assessment.dart';
import 'package:qhawix/features/qr_shield/domain/services/qr_reputation_policy.dart';
import 'package:qhawix/features/qr_shield/domain/services/qr_url_inspector.dart';

void main() {
  const policy = QrReputationPolicy();
  final inspector = QrUrlInspector();
  final now = DateTime.utc(2026, 10, 17, 12);

  QrReputationResult noMatch({
    DateTime? checkedAt,
    DateTime? expiresAt,
    bool coverageComplete = true,
    List<String> checkedCategories = const ['MALWARE', 'SOCIAL_ENGINEERING'],
  }) =>
      QrReputationResult(
        status: QrReputationStatus.noKnownThreats,
        reasonCode: null,
        provider: 'Web Risk',
        checkedAt: checkedAt ?? now,
        expiresAt: expiresAt,
        coverageComplete: coverageComplete,
        categories: const [],
        checkedCategories: checkedCategories,
        providerState: QrProviderState.available,
      );

  QrReputationResult knownThreat({
    DateTime? checkedAt,
    DateTime? expiresAt,
  }) =>
      QrReputationResult(
        status: QrReputationStatus.knownThreat,
        reasonCode: null,
        provider: 'Web Risk',
        checkedAt: checkedAt ?? now,
        expiresAt: expiresAt ?? now.add(const Duration(minutes: 5)),
        coverageComplete: true,
        categories: const ['MALWARE'],
        checkedCategories: const ['MALWARE', 'SOCIAL_ENGINEERING'],
        providerState: QrProviderState.available,
      );

  QrUrlAssessment plainUrl() => inspector.inspect('https://shop.example.org/menu');

  test('accepts a fresh complete no-match without provider expiry metadata', () {
    final checkedAt = now.subtract(const Duration(seconds: 10));
    final response = noMatch(checkedAt: checkedAt);
    final assessment = plainUrl();

    final applied = policy.applyProviderResponse(
      response,
      assessment: assessment,
      now: now,
    );

    expect(applied.status, QrReputationStatus.noKnownThreats);
    expect(policy.isCurrentNegative(applied, now), isTrue);
    expect(
      policy.reviewExpiryDeadline(applied),
      checkedAt.add(QrReputationPolicy.negativeResultMaxAge),
    );
  });

  test('downgrades a no-match with local signals to unverified', () {
    final assessment = inspector.inspect('http://bit.ly/menu');

    final applied = policy.applyProviderResponse(
      noMatch(),
      assessment: assessment,
      now: now,
    );

    expect(applied.status, QrReputationStatus.suspiciousOrUnverified);
    expect(applied.reasonCode, 'local_signal');
  });

  test('does not accept stale, future-dated, incomplete, or provider-expiring negatives', () {
    final stale = policy.applyProviderResponse(
      noMatch(checkedAt: now.subtract(const Duration(seconds: 61))),
      assessment: plainUrl(),
      now: now,
    );
    final future = policy.applyProviderResponse(
      noMatch(checkedAt: now.add(const Duration(seconds: 1))),
      assessment: plainUrl(),
      now: now,
    );
    final incomplete = policy.applyProviderResponse(
      noMatch(coverageComplete: false),
      assessment: plainUrl(),
      now: now,
    );
    final hasProviderExpiry = policy.applyProviderResponse(
      noMatch(expiresAt: now.add(const Duration(minutes: 1))),
      assessment: plainUrl(),
      now: now,
    );

    expect(stale.reasonCode, 'negative_review_expired');
    expect(future.reasonCode, 'invalid_provider_response');
    expect(incomplete.reasonCode, 'coverage_incomplete');
    expect(hasProviderExpiry.reasonCode, 'invalid_provider_response');

    expect(
      policy.decideOpening(
        reviewedAssessment: plainUrl(),
        currentAssessment: plainUrl(),
        reputation: stale,
        now: now,
      ),
      QrOpenPolicyDecision.reputationExpired,
    );
  });

  test('requires an unexpired provider expiry for known threats', () {
    final current = policy.applyProviderResponse(
      knownThreat(),
      assessment: plainUrl(),
      now: now,
    );
    final expired = policy.applyProviderResponse(
      knownThreat(expiresAt: now),
      assessment: plainUrl(),
      now: now,
    );

    expect(current.status, QrReputationStatus.knownThreat);
    expect(policy.isCurrentKnownThreat(current, now), isTrue);
    expect(expired.status, QrReputationStatus.suspiciousOrUnverified);
    expect(expired.reasonCode, 'invalid_provider_response');
    expect(
      policy.decideOpening(
        reviewedAssessment: plainUrl(),
        currentAssessment: plainUrl(),
        reputation: current,
        now: now,
      ),
      QrOpenPolicyDecision.blockedByKnownThreat,
    );
  });
}
