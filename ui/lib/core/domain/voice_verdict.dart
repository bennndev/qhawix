/// Verdict of the EchoTrap voice detector.
///
/// The score always accompanies the verdict because the threshold is
/// calibrated, not certain. Mapping to colors lives in the view layer.
enum VoiceVerdict { human, doubtful, cloned, inconclusive }
