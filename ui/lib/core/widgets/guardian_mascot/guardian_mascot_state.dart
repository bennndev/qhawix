/// The eight states of the Guardian mascot. `name` is the key used in the animation spec.
enum GuardianMascotState {
  /// Slow breathing and the occasional blink. Default.
  idle,

  /// Head tilt with three pulsing dots: a response is being composed.
  thinking,

  /// Gears turning and a quick bounce: a bounded analysis is running.
  working,

  /// One-shot hop with a check mark and sparks, then back to [idle].
  success,

  /// Attentive, with soft rings: the voice detector is listening.
  listening,

  /// Eyes sweeping and a turning halo: a QR, link or message is being checked.
  scanning,

  /// One-shot: squash, small head shake, then a held pose with a "!" mark. Never red.
  alert,

  /// Faint, almost still silhouette for discreet use.
  stealth,
}
