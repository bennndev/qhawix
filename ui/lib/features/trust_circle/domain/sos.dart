/// How long the temporary location is shared after an SOS.
enum SosDuration {
  min15(15),
  min30(30),
  hour1(60),
  hour2(120);

  const SosDuration(this.minutes);

  final int minutes;

  Duration get duration => Duration(minutes: minutes);
}
