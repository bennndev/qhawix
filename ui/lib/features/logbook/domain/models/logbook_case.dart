import '../../../sentinel/domain/models/sentinel_analysis.dart';

class EvidenceRecord {
  const EvidenceRecord({
    required this.id,
    required this.channel,
    required this.redactedText,
    required this.analysis,
    required this.createdAt,
  });

  final String id;
  final String channel;
  final String redactedText;
  final SentinelAnalysis analysis;
  final DateTime createdAt;
}

class TimelineEvent {
  TimelineEvent({
    required this.id,
    required this.sequence,
    required this.type,
    required this.actor,
    required this.at,
    List<String> ruleIds = const [],
  }) : ruleIds = List.unmodifiable(ruleIds);

  final String id;
  final int sequence;
  final String type;
  final String actor;
  final DateTime at;
  final List<String> ruleIds;
}

class QhawixCase {
  QhawixCase({
    required this.id,
    required this.createdAt,
    required this.expiresAt,
    List<EvidenceRecord> evidence = const [],
    List<TimelineEvent> events = const [],
    this.evidenceRevision = 0,
  })  : evidence = List.unmodifiable(evidence),
        events = List.unmodifiable(events);

  final String id;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<EvidenceRecord> evidence;
  final List<TimelineEvent> events;
  final int evidenceRevision;

  QhawixCase addEvidence(EvidenceRecord record, TimelineEvent event) => QhawixCase(
        id: id,
        createdAt: createdAt,
        expiresAt: expiresAt,
        evidence: [...evidence, record],
        events: [...events, event],
        evidenceRevision: evidenceRevision + 1,
      );

  QhawixCase addEvent(TimelineEvent event) => QhawixCase(
        id: id,
        createdAt: createdAt,
        expiresAt: expiresAt,
        evidence: evidence,
        events: [...events, event],
        evidenceRevision: evidenceRevision,
      );
}
