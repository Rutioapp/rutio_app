import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/diary_v2/diary_v2_mood_visuals.dart';

void main() {
  group('DiaryMoodVisuals', () {
    test('maps every mood to the standardized emoji set', () {
      expect(DiaryMoodVisuals.emojiFor(-2), '☁️');
      expect(DiaryMoodVisuals.emojiFor(-1), '🌙');
      expect(DiaryMoodVisuals.emojiFor(0), '○');
      expect(DiaryMoodVisuals.emojiFor(1), '☀️');
      expect(DiaryMoodVisuals.emojiFor(2), '♥️');
    });

    test('returns consistent localized labels', () {
      expect(DiaryMoodVisuals.labelForLocale(-2, const Locale('es')), 'Muy bajo');
      expect(DiaryMoodVisuals.labelForLocale(-1, const Locale('en')), 'Low');
      expect(DiaryMoodVisuals.labelForLocale(0, const Locale('es')), 'Neutral');
      expect(DiaryMoodVisuals.labelForLocale(1, const Locale('en')), 'Good');
      expect(DiaryMoodVisuals.labelForLocale(2, const Locale('es')), 'Muy bien');
    });
  });
}
