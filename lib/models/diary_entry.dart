import 'package:flutter/foundation.dart';

@immutable
class DiaryEntry {
  final String id;
  final int createdAt; // epoch ms
  final String text;

  /// If null => personal entry
  final String? habitId;

  /// Optional cache for quick filtering (should match habit.familyId when habitId != null)
  final String? familyId;

  /// Optional mood value: -2..+2
  final int? mood;

  final bool isPinned;

  const DiaryEntry({
    required this.id,
    required this.createdAt,
    required this.text,
    this.habitId,
    this.familyId,
    this.mood,
    this.isPinned = false,
  });

  DiaryEntry copyWith({
    String? id,
    int? createdAt,
    String? text,
    String? habitId,
    String? familyId,
    int? mood,
    bool? isPinned,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      text: text ?? this.text,
      habitId: habitId ?? this.habitId,
      familyId: familyId ?? this.familyId,
      mood: mood ?? this.mood,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt,
        'text': text,
        'habitId': habitId,
        'familyId': familyId,
        'mood': mood,
        'isPinned': isPinned,
      };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
        id: (json['id'] ?? '').toString(),
        createdAt: (json['createdAt'] is int)
            ? json['createdAt'] as int
            : int.tryParse((json['createdAt'] ?? '0').toString()) ?? 0,
        text: (json['text'] ?? '').toString(),
        habitId: (json['habitId'] as Object?)?.toString(),
        familyId: (json['familyId'] as Object?)?.toString(),
        mood: (json['mood'] is int) ? json['mood'] as int : int.tryParse((json['mood'] ?? '').toString()),
        isPinned: (json['isPinned'] as bool?) ?? false,
      );
}
