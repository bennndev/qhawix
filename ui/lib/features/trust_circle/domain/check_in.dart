import 'clock.dart';

enum CheckInStatus { waiting, confirmed, overdue }

/// A safe-arrival window: the person promises to confirm before [dueAt].
class CheckIn {
  const CheckIn({
    required this.startedAt,
    required this.dueAt,
    this.confirmedAt,
  });

  final DateTime startedAt;
  final DateTime dueAt;
  final DateTime? confirmedAt;

  /// Status derived from [clock]; a confirmed check-in stays confirmed.
  CheckInStatus statusAt(Clock clock) {
    if (confirmedAt != null) return CheckInStatus.confirmed;
    return clock.now().isBefore(dueAt)
        ? CheckInStatus.waiting
        : CheckInStatus.overdue;
  }

  CheckIn confirm(DateTime at) =>
      CheckIn(startedAt: startedAt, dueAt: dueAt, confirmedAt: at);
}

/// Windows the person can pick.
enum CheckInWindow {
  min30(30),
  hour1(60),
  hour2(120),
  hour4(240);

  const CheckInWindow(this.minutes);

  final int minutes;

  Duration get duration => Duration(minutes: minutes);
}
