import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/identity/user_namespace.dart';
import '../../domain/motivational_phrase.dart';
import '../../domain/phrase_catalog_locale_resolver.dart';
import '../../domain/phrase_date_key.dart';

class SharedPreferencesCompletedDayPhraseStore implements PhraseHistoryStore {
  SharedPreferencesCompletedDayPhraseStore({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  }) : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance;

  static const int schemaVersion = 1;
  static const String rootPrefix = 'completed_day_phrase_v1';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;

  static String historyKey(String userId) =>
      '$rootPrefix/${safeUserNamespace(userId)}/history';

  static String dailySelectionKey(
    String userId,
    DateTime localDate, {
    String? locale,
  }) =>
      '$rootPrefix/${safeUserNamespace(userId)}/daily_phrase/'
      '${PhraseCatalogLocaleResolver.selectionLocale(locale ?? 'es')}/'
      '${PhraseDateKey.format(localDate)}';

  static String _legacyDailySelectionKey(
    String userId,
    DateTime localDate, {
    String? locale,
  }) =>
      '$rootPrefix/${safeUserNamespace(userId)}/daily_phrase/'
      '${PhraseLocale.canonicalize(locale ?? 'es')}/'
      '${PhraseDateKey.format(localDate)}';

  @override
  Future<PhraseHistory> loadHistory(String userId) async {
    final prefs = await _sharedPreferencesProvider();
    final raw = prefs.getString(historyKey(userId));
    if (raw == null || raw.trim().isEmpty) return const PhraseHistory();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const PhraseHistory();
      final map = Map<String, dynamic>.from(decoded.cast<String, dynamic>());
      if (map['schemaVersion'] != schemaVersion ||
          map['userNamespace'] != safeUserNamespace(userId)) {
        return const PhraseHistory();
      }
      final rawIds = map['phraseIds'];
      if (rawIds is! List) return const PhraseHistory();
      final ids =
          rawIds.whereType<String>().where((id) => id.trim().isNotEmpty);
      var history = const PhraseHistory();
      for (final id in ids) {
        history = history.append(id);
      }
      return history;
    } catch (_) {
      return const PhraseHistory();
    }
  }

  @override
  Future<void> saveHistory(String userId, PhraseHistory history) async {
    final prefs = await _sharedPreferencesProvider();
    var normalized = const PhraseHistory();
    for (final id in history.phraseIds) {
      if (id.trim().isNotEmpty) normalized = normalized.append(id);
    }
    await prefs.setString(
      historyKey(userId),
      jsonEncode(<String, Object?>{
        'schemaVersion': schemaVersion,
        'userNamespace': safeUserNamespace(userId),
        'phraseIds': normalized.phraseIds,
      }),
    );
  }

  @override
  Future<PhraseDailySelection?> loadDailySelection(
    String userId,
    DateTime localDate, {
    String? locale,
  }) async {
    final prefs = await _sharedPreferencesProvider();
    final raw = prefs.getString(
          dailySelectionKey(userId, localDate, locale: locale),
        ) ??
        prefs.getString(
          _legacyDailySelectionKey(userId, localDate, locale: locale),
        );
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded.cast<String, dynamic>());
      if (map['schemaVersion'] != schemaVersion ||
          map['userNamespace'] != safeUserNamespace(userId) ||
          map['localDate'] is! String ||
          map['phraseId'] is! String ||
          map['locale'] is! String ||
          map['catalogVersion'] is! String) {
        return null;
      }
      final dateKey = map['localDate'] as String;
      if (dateKey != PhraseDateKey.format(localDate)) {
        return null;
      }
      final phraseId = (map['phraseId'] as String).trim();
      final locale = (map['locale'] as String).trim();
      final catalogVersion = (map['catalogVersion'] as String).trim();
      if (phraseId.isEmpty || locale.isEmpty || catalogVersion.isEmpty) {
        return null;
      }
      return PhraseDailySelection(
        phraseId: phraseId,
        localDate: PhraseDateKey.parse(dateKey),
        locale: locale,
        catalogVersion: catalogVersion,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDailySelection(
    String userId,
    DateTime localDate,
    PhraseDailySelection selection,
  ) async {
    final prefs = await _sharedPreferencesProvider();
    final dateKey = PhraseDateKey.format(localDate);
    if (PhraseDateKey.format(selection.localDate) != dateKey) {
      throw ArgumentError('Daily selection date does not match its key.');
    }
    await prefs.setString(
      dailySelectionKey(userId, localDate, locale: selection.locale),
      jsonEncode(<String, Object?>{
        'schemaVersion': schemaVersion,
        'userNamespace': safeUserNamespace(userId),
        'localDate': dateKey,
        'phraseId': selection.phraseId,
        'locale': selection.locale,
        'catalogVersion': selection.catalogVersion,
      }),
    );
  }
}
