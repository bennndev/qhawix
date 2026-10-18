/// What an action really did. A mock only ever reports [exampleOnly].
enum ActionOutcome {
  /// Nothing left the device: example data only.
  exampleOnly,

  /// Persisted or prepared on this phone. Never claims SMS/push delivery alone.
  saved,

  /// The action was refused (for example invalid input).
  rejected,
}

/// Result of a command, with the sentence the UI must show as is. It never
/// claims delivery unless a real implementation can prove it.
class ActionResult {
  const ActionResult(this.outcome, this.message);

  final ActionOutcome outcome;
  final String message;

  bool get isRejected => outcome == ActionOutcome.rejected;
}
