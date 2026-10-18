import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/echotrap/domain/voice_origin_level.dart';

void main() {
  group('classifyVoiceOrigin', () {
    test('under 10% is normal', () {
      expect(classifyVoiceOrigin(0), VoiceOriginLevel.normal);
      expect(classifyVoiceOrigin(0.099), VoiceOriginLevel.normal);
    });

    test('10% up to 30% is doubtful', () {
      expect(classifyVoiceOrigin(0.10), VoiceOriginLevel.doubtful);
      expect(classifyVoiceOrigin(0.2999), VoiceOriginLevel.doubtful);
    });

    test('30% or more is synthetic', () {
      expect(classifyVoiceOrigin(0.30), VoiceOriginLevel.synthetic);
      expect(classifyVoiceOrigin(1), VoiceOriginLevel.synthetic);
    });
  });

  test('percent is rounded and clamped', () {
    expect(voiceOriginPercent(0.296), 30);
    expect(voiceOriginPercent(1.4), 100);
    expect(voiceOriginPercent(-0.2), 0);
  });
}
