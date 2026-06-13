import 'package:flutter/material.dart';

class DiaryMoodVisuals {
  static const List<int> values = [-2, -1, 0, 1, 2];

  static const Map<int, _DiaryMoodVisual> _visuals = {
    -2: _DiaryMoodVisual(
      emoji: '☁️',
      englishLabel: 'Very low',
      spanishLabel: 'Muy bajo',
      fillColor: Color(0xFFF8E4DE),
      borderColor: Color(0xFF8F5146),
    ),
    -1: _DiaryMoodVisual(
      emoji: '🌙',
      englishLabel: 'Low',
      spanishLabel: 'Bajo',
      fillColor: Color(0xFFF8E8D7),
      borderColor: Color(0xFF976739),
    ),
    0: _DiaryMoodVisual(
      emoji: '○',
      englishLabel: 'Neutral',
      spanishLabel: 'Neutral',
      fillColor: Color(0xFFF5E7D2),
      borderColor: Color(0xFF8C6339),
    ),
    1: _DiaryMoodVisual(
      emoji: '☀️',
      englishLabel: 'Good',
      spanishLabel: 'Bien',
      fillColor: Color(0xFFEAF2E3),
      borderColor: Color(0xFF667B4D),
    ),
    2: _DiaryMoodVisual(
      emoji: '♥️',
      englishLabel: 'Very good',
      spanishLabel: 'Muy bien',
      fillColor: Color(0xFFE2EED9),
      borderColor: Color(0xFF4F6B38),
    ),
  };

  static String emojiFor(int mood) => _visualFor(mood).emoji;

  static String labelForLocale(int mood, Locale locale) =>
      labelForLocaleTag(mood, locale.toLanguageTag());

  static String labelForLocaleTag(int mood, String localeTag) {
    final visual = _visualFor(mood);
    return localeTag.startsWith('es')
        ? visual.spanishLabel
        : visual.englishLabel;
  }

  static String semanticLabelForLocale(int mood, Locale locale) {
    return '${labelForLocale(mood, locale)} mood';
  }

  static Color fillColorFor(int mood) => _visualFor(mood).fillColor;

  static Color borderColorFor(int mood) => _visualFor(mood).borderColor;

  static _DiaryMoodVisual _visualFor(int mood) => _visuals[mood] ?? _visuals[0]!;
}

class _DiaryMoodVisual {
  const _DiaryMoodVisual({
    required this.emoji,
    required this.englishLabel,
    required this.spanishLabel,
    required this.fillColor,
    required this.borderColor,
  });

  final String emoji;
  final String englishLabel;
  final String spanishLabel;
  final Color fillColor;
  final Color borderColor;
}
