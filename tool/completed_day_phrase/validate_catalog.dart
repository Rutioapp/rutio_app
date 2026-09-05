import 'dart:convert';
import 'dart:io';

const _allowedCategories = <String>{'personal', 'consistency', 'motivation'};
const _allowedTones = <String>{'gentle', 'balanced', 'energetic'};
const _allowedSourceTypes = <String>{'original', 'quote', 'proverb'};
const _allowedTokens = <String>{'name', 'streak_label', 'progress'};
final _tokenPattern = RegExp(r'\{([a-z_]+)\}');

void main(List<String> args) {
  final path = args.isEmpty
      ? 'supabase/catalog/completed_day_phrase/es-ES.v1.json'
      : args.single;
  final raw = jsonDecode(File(path).readAsStringSync());
  if (raw is! Map) _fail('catalog root must be an object');
  final catalog = Map<String, dynamic>.from(raw.cast<String, dynamic>());
  _expect(catalog['schemaVersion'] == 1, 'schemaVersion must be 1');
  final locale = _string(catalog, 'locale');
  _expect(locale == locale.trim(), 'locale must not have surrounding spaces');
  _expect(catalog['catalogVersion'] == '1', 'catalogVersion must be "1"');
  _expect(catalog['releaseVersion'] == 1, 'releaseVersion must be 1');

  final rawPhrases = catalog['phrases'];
  _expect(rawPhrases is List, 'phrases must be an array');
  final phrases = rawPhrases.cast<Object?>().map((entry) {
    _expect(entry is Map, 'each phrase must be an object');
    return Map<String, dynamic>.from(entry!.cast<String, dynamic>());
  }).toList(growable: false);
  _expect(phrases.length == 300, 'expected 300 phrases, got ${phrases.length}');

  final seenIds = <String>{};
  final categoryCounts = <String, int>{};
  final toneCounts = <String, int>{};
  final exactTexts = <String, List<String>>{};
  final over110 = <String>[];
  var maxLength = 0;

  for (final phrase in phrases) {
    final id = _string(phrase, 'id');
    _expect(seenIds.add(id), 'duplicate ID: $id');
    final expectedCategory = _categoryForId(id);
    final category = _string(phrase, 'category');
    _expect(_allowedCategories.contains(category), 'invalid category: $id');
    _expect(category == expectedCategory, 'category mismatch: $id');
    categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

    final tone = _string(phrase, 'tone');
    _expect(_allowedTones.contains(tone), 'invalid tone: $id');
    toneCounts[tone] = (toneCounts[tone] ?? 0) + 1;

    final sourceType = _string(phrase, 'sourceType');
    _expect(
        _allowedSourceTypes.contains(sourceType), 'invalid sourceType: $id');
    final author = phrase['author'];
    if (sourceType == 'original') {
      _expect(author == null, 'original phrase must have null author: $id');
    } else {
      _expect(author is String && author.trim().isNotEmpty,
          'attributed phrase needs author: $id');
    }

    final template = _string(phrase, 'template');
    _expect(template.trim().isNotEmpty, 'empty template: $id');
    final actualTokens = <String>[];
    for (final match in _tokenPattern.allMatches(template)) {
      final token = match.group(1)!;
      _expect(_allowedTokens.contains(token), 'unknown token $token: $id');
      if (!actualTokens.contains(token)) actualTokens.add(token);
    }
    final declaredRaw = phrase['requiredTokens'];
    _expect(declaredRaw is List, 'requiredTokens must be an array: $id');
    final declared = <String>[
      ...declaredRaw.cast<Object?>().map((value) {
        _expect(value is String, 'requiredTokens must contain strings: $id');
        return value as String;
      })
    ];
    _expect(declared.toSet().length == declared.length,
        'requiredTokens contains duplicates: $id');
    _expect(setEquals(actualTokens, declared),
        'requiredTokens does not match template: $id');

    final weight = phrase['weight'];
    _expect(weight is num && weight > 0, 'invalid weight: $id');
    _expect(phrase['enabled'] is bool, 'invalid enabled: $id');
    final contentVersion = phrase['contentVersion'];
    _expect(contentVersion is int && contentVersion > 0,
        'invalid contentVersion: $id');

    final length = template.length;
    maxLength = length > maxLength ? length : maxLength;
    exactTexts.putIfAbsent(template, () => <String>[]).add(id);
    if (length > 110) over110.add('$id=$length');
  }

  for (final prefix in <String>['personal', 'consistency', 'motivation']) {
    final expected = prefix == 'personal'
        ? 50
        : prefix == 'consistency'
            ? 100
            : 150;
    _expect(
        categoryCounts[prefix] == expected, '$prefix count must be $expected');
    for (var index = 1; index <= expected; index++) {
      final id = '${prefix}_${index.toString().padLeft(3, '0')}';
      _expect(seenIds.contains(id), 'missing ID: $id');
    }
  }

  final duplicates = exactTexts.entries
      .where((entry) => entry.value.length > 1)
      .map((entry) => '${entry.value.join(',')} (${entry.key})')
      .toList(growable: false);
  stdout.writeln('VALID catalog=$path locale=$locale');
  stdout.writeln('COUNT total=${phrases.length} categories=$categoryCounts');
  stdout.writeln('TONES $toneCounts');
  stdout.writeln('IDS sequential=true duplicates=${duplicates.length}');
  stdout.writeln('TOKENS exact=true');
  stdout.writeln(
      'LENGTH max=$maxLength over110=${over110.isEmpty ? 'none' : over110.join(',')}');
  stdout.writeln(
      'DUPLICATE_TEXTS ${duplicates.isEmpty ? 'none' : duplicates.join('; ')}');
}

bool setEquals(Iterable<String> left, Iterable<String> right) {
  final a = left.toSet();
  final b = right.toSet();
  return a.length == b.length && a.containsAll(b);
}

String _categoryForId(String id) {
  final match =
      RegExp(r'^(personal|consistency|motivation)_(\d{3})$').firstMatch(id);
  _expect(match != null, 'invalid ID: $id');
  final prefix = match!.group(1)!;
  final number = int.parse(match.group(2)!);
  final max = prefix == 'personal'
      ? 50
      : prefix == 'consistency'
          ? 100
          : 150;
  _expect(number >= 1 && number <= max, 'ID out of range: $id');
  return prefix;
}

String _string(Map<String, dynamic> value, String key) {
  final result = value[key];
  _expect(result is String && result.trim().isNotEmpty, 'invalid $key field');
  return result as String;
}

void _expect(bool condition, String message) {
  if (!condition) _fail(message);
}

Never _fail(String message) {
  stderr.writeln('INVALID $message');
  exitCode = 1;
  throw StateError(message);
}
