import '../models/sentinel_analysis.dart';

abstract interface class SentinelAnalysisPort {
  SentinelAnalysis analyze(String redactedText);
}
