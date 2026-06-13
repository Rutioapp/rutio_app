import 'dart:ui' show Locale;

import 'package:flutter/material.dart';
import 'package:rutio/models/diary_entry.dart';

const List<String> diaryV2PredefinedTags = DiaryEntry.supportedTags;

String diaryTagLabel(String tag, Locale locale) {
  final isSpanish = locale.languageCode == 'es';
  switch (tag.trim().toLowerCase()) {
    case 'gratitude':
      return isSpanish ? 'Gratitud' : 'Gratitude';
    case 'energy':
      return isSpanish ? 'Energía' : 'Energy';
    case 'focus':
      return isSpanish ? 'Foco' : 'Focus';
    case 'sleep':
      return isSpanish ? 'Sueño' : 'Sleep';
    case 'mood':
      return isSpanish ? 'Ánimo' : 'Mood';
    case 'idea':
      return 'Idea';
    default:
      return tag.trim();
  }
}

List<String> diaryTagLabels(
  List<String> tags,
  Locale locale, {
  int? maxVisible,
}) {
  final normalized = <String>[];
  for (final tag in tags) {
    final value = tag.trim().toLowerCase();
    if (value.isEmpty || !diaryV2PredefinedTags.contains(value)) continue;
    if (!normalized.contains(value)) {
      normalized.add(value);
    }
  }

  if (maxVisible == null || normalized.length <= maxVisible) {
    return normalized
        .map((tag) => diaryTagLabel(tag, locale))
        .toList(growable: false);
  }

  final visible = normalized.take(maxVisible).map((tag) => diaryTagLabel(tag, locale));
  final remaining = normalized.length - maxVisible;
  return <String>[
    ...visible,
    '+$remaining',
  ];
}
