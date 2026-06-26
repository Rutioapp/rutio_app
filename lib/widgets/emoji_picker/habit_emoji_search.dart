import 'habit_emoji_catalog.dart';

String normalizeEmojiSearchText(String value) {
  const Map<String, String> replacements = <String, String>{
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
    'ç': 'c',
  };

  final lower = value.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(replacements[char] ?? char);
  }
  return buffer.toString();
}

List<EmojiOption> resolveEmojiPickerOptions({
  required String query,
  required String selectedCategory,
  List<String> recentEmojis = const <String>[],
}) {
  final normalizedQuery = normalizeEmojiSearchText(query);

  if (selectedCategory == HabitEmojiCategories.recent) {
    final recents = <EmojiOption>[];
    for (final emoji in recentEmojis) {
      final option = kHabitEmojiOptions
          .where((item) => item.emoji == emoji)
          .firstOrNull;
      if (option != null) {
        recents.add(option);
      }
    }
    if (normalizedQuery.isEmpty) {
      return recents;
    }
  }

  final options = kHabitEmojiOptions.where((option) {
    if (selectedCategory != HabitEmojiCategories.recent &&
        selectedCategory != option.category) {
      return false;
    }
    if (normalizedQuery.isEmpty) {
      return true;
    }
    final haystacks = <String>[
      option.emoji,
      option.label,
      option.category,
      ...option.keywords,
    ].map(normalizeEmojiSearchText);
    return haystacks.any((candidate) => candidate.contains(normalizedQuery));
  }).toList(growable: false);

  if (normalizedQuery.isEmpty) {
    return options;
  }

  final ranked = options.toList()
    ..sort((a, b) => _scoreEmojiOption(b, normalizedQuery).compareTo(
          _scoreEmojiOption(a, normalizedQuery),
        ));
  return ranked;
}

int _scoreEmojiOption(EmojiOption option, String normalizedQuery) {
  var score = 0;
  final label = normalizeEmojiSearchText(option.label);
  if (label == normalizedQuery) {
    score += 120;
  } else if (label.startsWith(normalizedQuery)) {
    score += 80;
  } else if (label.contains(normalizedQuery)) {
    score += 40;
  }

  for (final keyword in option.keywords) {
    final normalizedKeyword = normalizeEmojiSearchText(keyword);
    if (normalizedKeyword == normalizedQuery) {
      score += 100;
    } else if (normalizedKeyword.startsWith(normalizedQuery)) {
      score += 60;
    } else if (normalizedKeyword.contains(normalizedQuery)) {
      score += 24;
    }
  }

  if (option.emoji == normalizedQuery) {
    score += 20;
  }

  return score;
}

final class HabitEmojiRecentsStore {
  static final List<String> _recentEmojis = <String>[];

  static List<String> get values => List<String>.unmodifiable(_recentEmojis);

  static void register(String emoji) {
    final trimmed = emoji.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _recentEmojis.remove(trimmed);
    _recentEmojis.insert(0, trimmed);
    if (_recentEmojis.length > 12) {
      _recentEmojis.removeRange(12, _recentEmojis.length);
    }
  }
}
