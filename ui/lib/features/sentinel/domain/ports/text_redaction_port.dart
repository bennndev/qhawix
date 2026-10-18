import '../models/redaction_result.dart';

abstract interface class TextRedactionPort {
  RedactionResult redact(String input);
}
