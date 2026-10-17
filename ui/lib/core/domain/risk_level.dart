/// Request-risk values shared across modules (master spec §12.2).
///
/// These four-plus-one states stay distinct: "not assessed", "abstain" and
/// "none detected" must never be collapsed into "safe".
enum RiskLevel { notAssessed, noneDetected, caution, high, abstain }
