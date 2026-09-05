import '../../../../core/assets/app_assets.dart';
import '../../../../data/local/asset_json_loader.dart';
import '../domain/motivational_phrase.dart';
import '../domain/phrase_catalog_validator.dart';
import '../domain/phrase_date_key.dart';

class BundledPhraseCatalog implements PhraseCatalogSource {
  BundledPhraseCatalog({
    AssetJsonLoader? assetJsonLoader,
    PhraseCatalogValidator? validator,
  })  : _assetJsonLoader = assetJsonLoader ?? AssetJsonLoader(),
        _validator = validator ?? const PhraseCatalogValidator();

  final AssetJsonLoader _assetJsonLoader;
  final PhraseCatalogValidator _validator;
  final Map<String, PhraseCatalog> _cache = <String, PhraseCatalog>{};

  @override
  Future<PhraseCatalog> load(String locale) async {
    final canonicalLocale = PhraseLocale.canonicalize(locale);
    final cached = _cache[canonicalLocale];
    if (cached != null) return cached;
    final decoded = await _assetJsonLoader.loadJsonMap(
      AppAssets.completedDayPhraseFallback(canonicalLocale),
    );
    final catalog = _decodeCatalog(decoded);
    if (catalog.locale != canonicalLocale) {
      throw PhraseCatalogValidationException(
        'Catalog locale ${catalog.locale} does not match $canonicalLocale.',
      );
    }
    _validator.validateCatalog(catalog);
    _cache[canonicalLocale] = catalog;
    return catalog;
  }

  PhraseCatalog _decodeCatalog(Map<String, dynamic> raw) {
    final schemaVersion = _readInt(raw, 'schemaVersion');
    final catalogVersion = _readString(raw, 'catalogVersion');
    final locale = PhraseLocale.canonicalize(_readString(raw, 'locale'));
    final rawPhrases = raw['phrases'];
    if (rawPhrases is! List) {
      throw const PhraseCatalogValidationException(
        'Phrase catalog must contain a phrases array.',
      );
    }
    final phrases = rawPhrases.map(_decodePhrase).toList(growable: false);
    return PhraseCatalog(
      schemaVersion: schemaVersion,
      catalogVersion: catalogVersion,
      locale: locale,
      phrases: phrases,
    );
  }

  MotivationalPhrase _decodePhrase(Object? raw) {
    if (raw is! Map) {
      throw const PhraseCatalogValidationException('Invalid phrase entry.');
    }
    final map = Map<String, dynamic>.from(raw.cast<String, dynamic>());
    final rawTokens = map['requiredTokens'];
    if (rawTokens is! List || rawTokens.any((token) => token is! String)) {
      throw const PhraseCatalogValidationException(
        'Phrase requiredTokens must be a string array.',
      );
    }
    return MotivationalPhrase(
      id: _readString(map, 'id'),
      category: _parseCategory(_readString(map, 'category')),
      tone: _parseTone(_readString(map, 'tone')),
      sourceType: _parseSourceType(_readString(map, 'sourceType')),
      author: _readNullableString(map, 'author'),
      template: _readString(map, 'template'),
      requiredTokens: rawTokens.cast<String>(),
      weight: _readDouble(map, 'weight'),
      enabled: _readBool(map, 'enabled'),
      contentVersion: _readInt(map, 'contentVersion'),
    );
  }

  String _readString(Map<String, dynamic> raw, String key) {
    final value = raw[key];
    if (value is! String || value.trim().isEmpty) {
      throw PhraseCatalogValidationException('Invalid phrase field "$key".');
    }
    return value.trim();
  }

  String? _readNullableString(Map<String, dynamic> raw, String key) {
    final value = raw[key];
    if (value == null) return null;
    if (value is! String) {
      throw PhraseCatalogValidationException('Invalid phrase field "$key".');
    }
    return value.trim().isEmpty ? null : value.trim();
  }

  int _readInt(Map<String, dynamic> raw, String key) {
    final value = raw[key];
    if (value is! int) {
      throw PhraseCatalogValidationException('Invalid catalog field "$key".');
    }
    return value;
  }

  double _readDouble(Map<String, dynamic> raw, String key) {
    final value = raw[key];
    if (value is! num) {
      throw PhraseCatalogValidationException('Invalid phrase field "$key".');
    }
    return value.toDouble();
  }

  bool _readBool(Map<String, dynamic> raw, String key) {
    final value = raw[key];
    if (value is! bool) {
      throw PhraseCatalogValidationException('Invalid phrase field "$key".');
    }
    return value;
  }

  PhraseCategory _parseCategory(String value) {
    try {
      return PhraseCategoryWireName.parse(value);
    } catch (_) {
      throw PhraseCatalogValidationException('Invalid category "$value".');
    }
  }

  PhraseTone _parseTone(String value) {
    try {
      return PhraseToneWireName.parse(value);
    } catch (_) {
      throw PhraseCatalogValidationException('Invalid tone "$value".');
    }
  }

  PhraseSourceType _parseSourceType(String value) {
    try {
      return PhraseSourceTypeWireName.parse(value);
    } catch (_) {
      throw PhraseCatalogValidationException('Invalid sourceType "$value".');
    }
  }
}
