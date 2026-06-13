import 'package:flutter/foundation.dart';

@immutable
class DiaryEntry {
  final String id;
  final int createdAt; // epoch ms
  final String text;
  final String? title;
  final String? body;
  final String? remoteId;

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
    this.title,
    this.body,
    this.remoteId,
    this.habitId,
    this.familyId,
    this.mood,
    this.isPinned = false,
  });

  String? get normalizedTitle => _normalizedNullableText(title);
  String? get normalizedBody => _normalizedNullableText(body);

  DiaryEntryTextParts get textParts {
    final resolvedTitle = normalizedTitle;
    final resolvedBody = normalizedBody;
    if (resolvedTitle != null || resolvedBody != null) {
      return DiaryEntryTextParts(
        title: resolvedTitle ?? '',
        body: resolvedBody ?? '',
      );
    }
    return DiaryEntryTextParts.fromLegacyText(text);
  }

  String get legacyText => composeLegacyDiaryText(
        title: title,
        body: body,
        fallbackText: text,
      );

  DiaryEntry copyWith({
    String? id,
    int? createdAt,
    String? text,
    String? title,
    String? body,
    String? remoteId,
    String? habitId,
    String? familyId,
    int? mood,
    bool? isPinned,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      text: text ?? this.text,
      title: title ?? this.title,
      body: body ?? this.body,
      remoteId: remoteId ?? this.remoteId,
      habitId: habitId ?? this.habitId,
      familyId: familyId ?? this.familyId,
      mood: mood ?? this.mood,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt,
        'text': legacyText,
        'title': normalizedTitle,
        'body': normalizedBody,
        'remoteId': remoteId,
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
        text: composeLegacyDiaryText(
          title: json['title'],
          body: json['body'],
          fallbackText: (json['text'] ?? '').toString(),
        ),
        title: _resolveJsonTitle(json),
        body: _resolveJsonBody(json),
        remoteId: (json['remoteId'] as Object?)?.toString(),
        habitId: (json['habitId'] as Object?)?.toString(),
        familyId: (json['familyId'] as Object?)?.toString(),
        mood: (json['mood'] is int) ? json['mood'] as int : int.tryParse((json['mood'] ?? '').toString()),
        isPinned: (json['isPinned'] as bool?) ?? false,
      );
}

@immutable
class DiaryEntryTextParts {
  const DiaryEntryTextParts({
    required this.title,
    required this.body,
  });

  factory DiaryEntryTextParts.fromLegacyText(String text) {
    final normalizedLines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    if (normalizedLines.isEmpty) {
      return const DiaryEntryTextParts(title: '', body: '');
    }
    if (normalizedLines.length == 1) {
      return DiaryEntryTextParts(title: normalizedLines.first, body: '');
    }
    return DiaryEntryTextParts(
      title: normalizedLines.first,
      body: normalizedLines.skip(1).join('\n'),
    );
  }

  final String title;
  final String body;
}

String composeLegacyDiaryText({
  String? title,
  String? body,
  String? fallbackText,
}) {
  final normalizedTitle = _normalizedNullableText(title);
  final normalizedBody = _normalizedNullableText(body);

  if (normalizedTitle == null && normalizedBody == null) {
    return (fallbackText ?? '').trim();
  }

  return [
    if (normalizedTitle != null) normalizedTitle,
    if (normalizedBody != null) normalizedBody,
  ].join('\n\n').trim();
}

String? _resolveJsonTitle(Map<String, dynamic> json) {
  final directTitle = _normalizedNullableText(json['title']);
  if (directTitle != null) return directTitle;
  final title =
      DiaryEntryTextParts.fromLegacyText((json['text'] ?? '').toString()).title;
  return title.trim().isEmpty ? null : title;
}

String? _resolveJsonBody(Map<String, dynamic> json) {
  final directBody = _normalizedNullableText(json['body']);
  if (directBody != null) return directBody;
  final body =
      DiaryEntryTextParts.fromLegacyText((json['text'] ?? '').toString()).body;
  return body.trim().isEmpty ? null : body;
}

String? _normalizedNullableText(Object? value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
}
