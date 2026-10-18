/// How the synthetic-voice estimate is read. These cut-offs are product
/// configuration, kept in one place so they can be recalibrated with real
/// call audio without touching any widget.
class VoiceOriginThresholds {
  const VoiceOriginThresholds._();

  /// Below this score the voice reads as normal.
  static const double normalBelow = 0.10;

  /// From this score up the voice is flagged as probably synthetic.
  static const double syntheticFrom = 0.30;
}

enum VoiceOriginLevel {
  /// Under 10%: nothing unusual.
  normal,

  /// 10% up to (not including) 30%: doubtful, keep watching.
  doubtful,

  /// 30% or more: probably synthetic or cloned.
  synthetic,
}

/// Classifies a provider score in the 0..1 range.
VoiceOriginLevel classifyVoiceOrigin(double score) {
  if (score >= VoiceOriginThresholds.syntheticFrom) {
    return VoiceOriginLevel.synthetic;
  }
  if (score >= VoiceOriginThresholds.normalBelow) {
    return VoiceOriginLevel.doubtful;
  }
  return VoiceOriginLevel.normal;
}

/// Rounds a 0..1 score to a whole percent for display.
int voiceOriginPercent(double score) => (score.clamp(0.0, 1.0) * 100).round();
