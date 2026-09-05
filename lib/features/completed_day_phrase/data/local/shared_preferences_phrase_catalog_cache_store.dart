import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/motivational_phrase.dart';
import '../../domain/phrase_catalog_locale_resolver.dart';
import '../../domain/phrase_catalog_validator.dart';
import '../remote/phrase_catalog_dto.dart';

class PhraseCatalogCacheEntry {
  const PhraseCatalogCacheEntry({
    required this.releaseId,
    required this.releaseVersion,
    required this.locale,
    required this.downloadedAt,
    required this.catalog,
  });

  final String releaseId;
  final String releaseVersion;
  final String locale;
  final DateTime downloadedAt;
  final PhraseCatalog catalog;
}

abstract interface class PhraseCatalogCacheStore {
  Future<PhraseCatalogCacheEntry?> load(String locale);

  Future<void> save(PhraseCatalogCacheEntry entry);
}

class SharedPreferencesPhraseCatalogCacheStore
    implements PhraseCatalogCacheStore {
  SharedPreferencesPhraseCatalogCacheStore({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    void Function(String message)? logger,
  })  : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance,
        _logger = logger ?? ((message) => debugPrint(message));

  static const int cacheSchemaVersion = 1;
  static const String rootPrefix = 'completed_day_phrase_catalog_v1';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;
  final void Function(String message)? _logger;

  static String _key(String locale, String slot) =>
      '$rootPrefix/${PhraseCatalogLocaleResolver.normalize(locale)}/$slot';

  static String activeSlotKey(String locale) => _key(locale, 'active_slot');

  @override
  Future<PhraseCatalogCacheEntry?> load(String locale) async {
    final prefs = await _sharedPreferencesProvider();
    final normalizedLocale = PhraseCatalogLocaleResolver.normalize(locale);
    final active = prefs.getString(activeSlotKey(normalizedLocale));
    final slots = <String>[
      if (active == 'a' || active == 'b') active!,
      'a',
      'b',
    ];
    final checked = <String>{};
    for (final slot in slots) {
      if (!checked.add(slot)) continue;
      final raw = prefs.getString(_key(normalizedLocale, 'slot_$slot'));
      final entry = _decode(raw, normalizedLocale);
      if (entry != null) return entry;
    }
    return null;
  }

  @override
  Future<void> save(PhraseCatalogCacheEntry entry) async {
    final prefs = await _sharedPreferencesProvider();
    final locale = PhraseCatalogLocaleResolver.normalize(entry.locale);
    final active = prefs.getString(activeSlotKey(locale));
    final inactive = active == 'a' ? 'b' : 'a';
    _log(
      'catalog_cache_write_start active_slot=${active ?? 'none'} '
      'inactive_slot=$inactive release=${entry.releaseVersion}',
    );
    final encoded = jsonEncode(<String, dynamic>{
      'cacheSchemaVersion': cacheSchemaVersion,
      'releaseId': entry.releaseId,
      'releaseVersion': entry.releaseVersion,
      'locale': locale,
      'downloadedAt': entry.downloadedAt.toUtc().toIso8601String(),
      'catalog': _catalogToJson(entry.catalog),
    });
    final slotWritten = await prefs.setString(
      _key(locale, 'slot_$inactive'),
      encoded,
    );
    if (!slotWritten) {
      throw StateError('Could not write phrase catalog cache slot.');
    }
    final pointerWritten = await prefs.setString(
      activeSlotKey(locale),
      inactive,
    );
    if (!pointerWritten) {
      throw StateError('Could not switch phrase catalog cache slot.');
    }
    _log(
      'catalog_cache_write_success release=${entry.releaseVersion} '
      'active_slot=${active ?? 'none'}->$inactive',
    );
  }

  PhraseCatalogCacheEntry? _decode(String? raw, String requestedLocale) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final json = Map<String, dynamic>.from(decoded.cast<String, dynamic>());
      if (json['cacheSchemaVersion'] != cacheSchemaVersion) return null;
      final locale = json['locale'];
      if (locale is! String ||
          PhraseCatalogLocaleResolver.normalize(locale) != requestedLocale) {
        return null;
      }
      final catalogJson = json['catalog'];
      if (catalogJson is! Map) return null;
      final catalog = PhraseCatalogJson.fromJson(
        Map<String, dynamic>.from(catalogJson.cast<String, dynamic>()),
      );
      final releaseId = json['releaseId'];
      final releaseVersion = json['releaseVersion'];
      final downloadedAt = json['downloadedAt'];
      if (releaseId is! String ||
          releaseId.trim().isEmpty ||
          releaseVersion is! String ||
          releaseVersion.trim().isEmpty ||
          downloadedAt is! String) {
        return null;
      }
      final parsedDate = DateTime.tryParse(downloadedAt);
      if (parsedDate == null) return null;
      if (catalog.catalogVersion != releaseVersion.trim() ||
          PhraseCatalogLocaleResolver.normalize(catalog.locale) !=
              requestedLocale) {
        return null;
      }
      return PhraseCatalogCacheEntry(
        releaseId: releaseId.trim(),
        releaseVersion: releaseVersion.trim(),
        locale: PhraseCatalogLocaleResolver.normalize(locale),
        downloadedAt: parsedDate,
        catalog: catalog,
      );
    } on PhraseCatalogValidationException {
      return null;
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _catalogToJson(PhraseCatalog catalog) =>
      <String, dynamic>{
        'schemaVersion': catalog.schemaVersion,
        'catalogVersion': catalog.catalogVersion,
        'locale': catalog.locale,
        'phrases': catalog.phrases.map(_phraseToJson).toList(growable: false),
      };

  Map<String, dynamic> _phraseToJson(MotivationalPhrase phrase) =>
      <String, dynamic>{
        'id': phrase.id,
        'category': phrase.category.wireName,
        'tone': phrase.tone.wireName,
        'sourceType': phrase.sourceType.wireName,
        'author': phrase.author,
        'template': phrase.template,
        'requiredTokens': phrase.requiredTokens,
        'weight': phrase.weight,
        'enabled': phrase.enabled,
        'contentVersion': phrase.contentVersion,
      };

  void _log(String message) {
    if (kDebugMode) _logger?.call('[COMPLETED_DAY_PHRASE] $message');
  }
}
