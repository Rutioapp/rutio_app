import 'package:flutter/foundation.dart';

enum PhraseCategory { personal, consistency, motivation }

enum PhraseTone { gentle, balanced, energetic }

enum PhraseSourceType { original, quote, proverb }

extension PhraseCategoryWireName on PhraseCategory {
  String get wireName => name;

  static PhraseCategory parse(String value) {
    return PhraseCategory.values.firstWhere(
      (candidate) => candidate.name == value.trim(),
      orElse: () => throw ArgumentError.value(value, 'category'),
    );
  }
}

extension PhraseToneWireName on PhraseTone {
  String get wireName => name;

  static PhraseTone parse(String value) {
    return PhraseTone.values.firstWhere(
      (candidate) => candidate.name == value.trim(),
      orElse: () => throw ArgumentError.value(value, 'tone'),
    );
  }
}

extension PhraseSourceTypeWireName on PhraseSourceType {
  String get wireName => name;

  static PhraseSourceType parse(String value) {
    return PhraseSourceType.values.firstWhere(
      (candidate) => candidate.name == value.trim(),
      orElse: () => throw ArgumentError.value(value, 'sourceType'),
    );
  }
}

@immutable
class MotivationalPhrase {
  const MotivationalPhrase({
    required this.id,
    required this.category,
    required this.tone,
    required this.sourceType,
    required this.author,
    required this.template,
    required this.requiredTokens,
    required this.weight,
    required this.enabled,
    required this.contentVersion,
  });

  final String id;
  final PhraseCategory category;
  final PhraseTone tone;
  final PhraseSourceType sourceType;
  final String? author;
  final String template;
  final List<String> requiredTokens;
  final double weight;
  final bool enabled;
  final int contentVersion;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MotivationalPhrase &&
            other.id == id &&
            other.category == category &&
            other.tone == tone &&
            other.sourceType == sourceType &&
            other.author == author &&
            other.template == template &&
            listEquals(other.requiredTokens, requiredTokens) &&
            other.weight == weight &&
            other.enabled == enabled &&
            other.contentVersion == contentVersion;
  }

  @override
  int get hashCode => Object.hash(
        id,
        category,
        tone,
        sourceType,
        author,
        template,
        Object.hashAll(requiredTokens),
        weight,
        enabled,
        contentVersion,
      );
}

@immutable
class PhraseContext {
  const PhraseContext({
    required this.userId,
    required this.localDate,
    required this.locale,
    required this.name,
    required this.streak,
    required this.streakLabel,
    required this.progressLabel,
  });

  final String userId;
  final DateTime localDate;
  final String locale;
  final String? name;
  final int streak;
  final String? streakLabel;
  final String progressLabel;

  String? get normalizedName {
    final value = name?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}

@immutable
class PhraseCatalog {
  const PhraseCatalog({
    required this.schemaVersion,
    required this.catalogVersion,
    required this.locale,
    required this.phrases,
  });

  final int schemaVersion;
  final String catalogVersion;
  final String locale;
  final List<MotivationalPhrase> phrases;
}

@immutable
class RenderedMotivationalPhrase {
  const RenderedMotivationalPhrase({
    required this.phrase,
    required this.text,
    required this.localDate,
    required this.fromDailySelection,
  });

  final MotivationalPhrase phrase;
  final String text;
  final DateTime localDate;
  final bool fromDailySelection;
}

abstract interface class PhraseCatalogSource {
  Future<PhraseCatalog> load(String locale);
}

abstract interface class PhraseHistoryStore {
  Future<PhraseHistory> loadHistory(String userId);

  Future<void> saveHistory(String userId, PhraseHistory history);

  Future<PhraseDailySelection?> loadDailySelection(
    String userId,
    DateTime localDate,
  );

  Future<void> saveDailySelection(
    String userId,
    DateTime localDate,
    PhraseDailySelection selection,
  );
}

@immutable
class PhraseHistory {
  const PhraseHistory({this.phraseIds = const <String>[]});

  static const int maxLength = 30;

  final List<String> phraseIds;

  PhraseHistory append(String phraseId) {
    final next = <String>[...phraseIds]..remove(phraseId);
    next.add(phraseId);
    final start = next.length > maxLength ? next.length - maxLength : 0;
    return PhraseHistory(
      phraseIds: List<String>.unmodifiable(next.sublist(start)),
    );
  }
}

@immutable
class PhraseDailySelection {
  const PhraseDailySelection({
    required this.phraseId,
    required this.localDate,
    required this.locale,
    required this.catalogVersion,
  });

  final String phraseId;
  final DateTime localDate;
  final String locale;
  final String catalogVersion;
}
