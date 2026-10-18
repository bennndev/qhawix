class LogbookPolicy {
  const LogbookPolicy._();

  static const version = 'logbook-p0-1.0.0';
  static const maxCasesInMemory = 20;
  static const maxEventsPerCase = 200;
  static const caseLifetime = Duration(hours: 24);
}
