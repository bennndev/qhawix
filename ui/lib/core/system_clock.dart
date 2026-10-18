import 'clock.dart';

class SystemClock implements Clock {
  const SystemClock();

  static final Stopwatch _stopwatch = Stopwatch()..start();
  static final DateTime _wallAnchor = DateTime.now().toUtc();
  static DateTime? _lastEffectiveTime;
  static Duration _lastElapsed = Duration.zero;

  @override
  DateTime now() {
    final elapsed = _stopwatch.elapsed;
    final observed = DateTime.now().toUtc();
    final previous = _lastEffectiveTime;
    final monotonicCandidate = _wallAnchor.add(elapsed);
    final effective = previous == null
        ? (observed.isAfter(_wallAnchor) ? observed : monotonicCandidate)
        : observed.isAfter(previous)
            ? observed
            : monotonicCandidate.isAfter(previous)
                ? monotonicCandidate
                : previous.add(elapsed - _lastElapsed);
    _lastEffectiveTime = effective;
    _lastElapsed = elapsed;
    return effective;
  }

  @override
  Duration monotonicNow() => _stopwatch.elapsed;
}
