import '../../domain/motivational_phrase.dart';
import '../../domain/phrase_catalog_validator.dart';

class PhraseCatalogReleaseDto {
  const PhraseCatalogReleaseDto({
    required this.releaseId,
    required this.locale,
    required this.releaseVersion,
    required this.schemaVersion,
    this.publishedAt,
  });

  final String releaseId;
  final String locale;
  final String releaseVersion;
  final int schemaVersion;
  final DateTime? publishedAt;

  int get releaseVersionNumber => int.parse(releaseVersion);

  factory PhraseCatalogReleaseDto.fromJson(Map<String, dynamic> json) {
    final releaseId = _requiredString(json, 'releaseId');
    final locale = _requiredString(json, 'locale');
    final releaseVersion = _requiredVersion(json, 'releaseVersion');
    final schemaVersion = _requiredInt(json, 'schemaVersion');
    final publishedAt = _optionalDateTime(json['publishedAt']);
    return PhraseCatalogReleaseDto(
      releaseId: releaseId,
      locale: locale,
      releaseVersion: releaseVersion,
      schemaVersion: schemaVersion,
      publishedAt: publishedAt,
    );
  }
}

class PhraseCatalogSnapshotDto {
  const PhraseCatalogSnapshotDto({
    required this.releaseId,
    required this.catalog,
  });

  final String? releaseId;
  final PhraseCatalog catalog;

  factory PhraseCatalogSnapshotDto.fromJson(Map<String, dynamic> json) {
    final releaseId = _optionalString(json['releaseId']);
    final catalogJson = json['catalog'] is Map
        ? Map<String, dynamic>.from(
            (json['catalog'] as Map).cast<String, dynamic>(),
          )
        : json;
    final catalog = PhraseCatalogJson.fromJson(catalogJson);
    return PhraseCatalogSnapshotDto(releaseId: releaseId, catalog: catalog);
  }
}

class PhraseCatalogJson {
  const PhraseCatalogJson._();

  static PhraseCatalog fromJson(Map<String, dynamic> json) {
    final rawPhrases = json['phrases'];
    if (rawPhrases is! List) {
      throw const PhraseCatalogValidationException(
        'Remote phrase catalog must contain a phrases array.',
      );
    }
    final phrases =
        rawPhrases.map((raw) => _phraseFromJson(raw)).toList(growable: false);
    final catalog = PhraseCatalog(
      schemaVersion: _requiredInt(json, 'schemaVersion'),
      catalogVersion: _requiredString(json, 'catalogVersion'),
      locale: _requiredString(json, 'locale'),
      phrases: phrases,
    );
    const PhraseCatalogValidator().validateCatalog(catalog);
    return catalog;
  }

  static MotivationalPhrase _phraseFromJson(Object? raw) {
    if (raw is! Map) {
      throw const PhraseCatalogValidationException('Invalid remote phrase.');
    }
    final json = Map<String, dynamic>.from(raw.cast<String, dynamic>());
    final rawTokens = json['requiredTokens'];
    if (rawTokens is! List || rawTokens.any((token) => token is! String)) {
      throw const PhraseCatalogValidationException(
        'Remote requiredTokens must be a string array.',
      );
    }
    return MotivationalPhrase(
      id: _requiredString(json, 'id'),
      category: _parseCategory(_requiredString(json, 'category')),
      tone: _parseTone(_requiredString(json, 'tone')),
      sourceType: _parseSourceType(_requiredString(json, 'sourceType')),
      author: _optionalString(json['author']),
      template: _requiredString(json, 'template'),
      requiredTokens: rawTokens.cast<String>(),
      weight: _requiredNum(json, 'weight').toDouble(),
      enabled: _requiredBool(json, 'enabled'),
      contentVersion: _requiredInt(json, 'contentVersion'),
    );
  }

  static PhraseCategory _parseCategory(String value) {
    try {
      return PhraseCategoryWireName.parse(value);
    } catch (_) {
      throw PhraseCatalogValidationException('Invalid category "$value".');
    }
  }

  static PhraseTone _parseTone(String value) {
    try {
      return PhraseToneWireName.parse(value);
    } catch (_) {
      throw PhraseCatalogValidationException('Invalid tone "$value".');
    }
  }

  static PhraseSourceType _parseSourceType(String value) {
    try {
      return PhraseSourceTypeWireName.parse(value);
    } catch (_) {
      throw PhraseCatalogValidationException(
        'Invalid sourceType "$value".',
      );
    }
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw PhraseCatalogValidationException('Invalid remote field "$key".');
  }
  return value.trim();
}

String _requiredVersion(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int && value > 0) return value.toString();
  if (value is String) {
    final normalized = value.trim();
    final parsed = int.tryParse(normalized);
    if (parsed != null && parsed > 0) return parsed.toString();
  }
  throw PhraseCatalogValidationException('Invalid remote version "$key".');
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is! String) {
    throw const PhraseCatalogValidationException('Invalid nullable string.');
  }
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw PhraseCatalogValidationException('Invalid remote integer "$key".');
  }
  return value;
}

num _requiredNum(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) {
    throw PhraseCatalogValidationException('Invalid remote number "$key".');
  }
  return value;
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw PhraseCatalogValidationException('Invalid remote boolean "$key".');
  }
  return value;
}

DateTime? _optionalDateTime(Object? value) {
  if (value == null) return null;
  if (value is! String) {
    throw const PhraseCatalogValidationException('Invalid publishedAt.');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw const PhraseCatalogValidationException('Invalid publishedAt.');
  }
  return parsed;
}
