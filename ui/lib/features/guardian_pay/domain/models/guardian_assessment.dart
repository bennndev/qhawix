import '../../../sentinel/domain/models/sentinel_analysis.dart';

enum GuardianAction { allow, warn, holdForReview }

class GuardianPaymentContext {
  const GuardianPaymentContext({
    this.amountCents,
    this.recipientIsNew = false,
  });

  final int? amountCents;
  final bool recipientIsNew;
}

class GuardianDecision {
  GuardianDecision({
    required this.action,
    required this.dimensions,
    required List<String> ruleIds,
    required List<String> reasons,
    required this.policyVersion,
  })  : ruleIds = List.unmodifiable(ruleIds.toSet().toList()..sort()),
        reasons = List.unmodifiable(reasons);

  final GuardianAction action;
  final TrustDimensions dimensions;
  final List<String> ruleIds;
  final List<String> reasons;
  final String policyVersion;
}
