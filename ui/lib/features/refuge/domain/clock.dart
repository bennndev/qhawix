/// Source of the current time. Injected so event timestamps are testable.
///
/// Local to this module until a shared `Clock` port exists in `core/`.
abstract interface class Clock {
  DateTime now();
}

/// The device clock.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
