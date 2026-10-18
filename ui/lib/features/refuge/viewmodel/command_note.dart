/// What a screen shows after a command, in plain words. A problem is never
/// worded as success, and `sent` never means delivered.
class CommandNote {
  const CommandNote.ok(this.message) : isProblem = false;
  const CommandNote.problem(this.message) : isProblem = true;

  final String message;
  final bool isProblem;
}
