import 'package:flutter/foundation.dart';

import '../domain/motivational_phrase.dart';
import '../domain/phrase_catalog_locale_resolver.dart';
import '../domain/phrase_catalog_validator.dart';
import '../infrastructure/bundled_phrase_catalog.dart';
import 'local/shared_preferences_phrase_catalog_cache_store.dart';
import 'remote/phrase_catalog_dto.dart';
import 'remote/supabase_phrase_catalog_data_source.dart';

class PhraseCatalogRepository implements PhraseCatalogSource {
  PhraseCatalogRepository({
    required PhraseCatalogCacheStore cache,
    required PhraseCatalogRemoteDataSource remote,
    BundledPhraseCatalog? bundled,
    DateTime Function()? nowProvider,
    void Function(String message)? logger,
  })  : _cache = cache,
        _remote = remote,
        _bundled = bundled ?? BundledPhraseCatalog(),
        _nowProvider = nowProvider ?? DateTime.now,
        _logger = logger ?? ((message) => debugPrint(message));

  final PhraseCatalogCacheStore _cache;
  final PhraseCatalogRemoteDataSource _remote;
  final BundledPhraseCatalog _bundled;
  final DateTime Function() _nowProvider;
  final void Function(String message)? _logger;

  @override
  Future<PhraseCatalog> load(String locale) async {
    for (final candidate in PhraseCatalogLocaleResolver.candidates(locale)) {
      final cached = await _cache.load(candidate);
      if (cached != null) {
        _log(
          'catalog_source=cache locale=$candidate '
          'release=${cached.releaseVersion}',
        );
        return cached.catalog;
      }
    }

    final bundledLocale = PhraseCatalogLocaleResolver.baseLanguage(locale);
    try {
      final bundled = await _bundled.load(bundledLocale);
      _log('catalog_source=bundled locale=$bundledLocale');
      return bundled;
    } catch (_) {
      final fallback = await _bundled.load('es');
      _log('catalog_source=bundled locale=es');
      return fallback;
    }
  }

  Future<bool> sync(String requestedLocale) async {
    final normalizedRequested =
        PhraseCatalogLocaleResolver.normalize(requestedLocale);
    _log('catalog_sync_start locale=$normalizedRequested');
    try {
      final candidates =
          PhraseCatalogLocaleResolver.candidates(normalizedRequested);
      for (final candidate in candidates) {
        final release = await _remote.fetchPublishedRelease(candidate);
        if (release == null) continue;
        final locale = PhraseCatalogLocaleResolver.normalize(release.locale);
        if (PhraseCatalogLocaleResolver.baseLanguage(normalizedRequested) ==
                'es' &&
            locale != 'es-ES') {
          throw const FormatException(
            'Spanish phrase catalog must resolve to es-ES.',
          );
        }
        _log(
          'catalog_release_found version=${release.releaseVersion} '
          'locale=$locale',
        );
        final current = await _cache.load(locale);
        if (current != null &&
            current.releaseId == release.releaseId &&
            current.releaseVersion == release.releaseVersion) {
          _log(
            'catalog_release_unchanged version=${release.releaseVersion}',
          );
          return false;
        }
        if (release.schemaVersion != 1) {
          throw PhraseCatalogValidationException(
            'Unsupported phrase catalog schema ${release.schemaVersion}.',
          );
        }
        _log(
          'catalog_snapshot_download_start version=${release.releaseVersion}',
        );
        final snapshot = await _remote.fetchSnapshot(
          locale,
          release.releaseVersionNumber,
        );
        _log(
          'catalog_snapshot_downloaded entries='
          '${snapshot.catalog.phrases.length}',
        );
        _validateSnapshot(release, snapshot, locale);
        _log(
          'catalog_snapshot_validated entries=${snapshot.catalog.phrases.length}',
        );
        await _cache.save(
          PhraseCatalogCacheEntry(
            releaseId: release.releaseId,
            releaseVersion: release.releaseVersion,
            locale: locale,
            downloadedAt: _nowProvider(),
            catalog: snapshot.catalog,
          ),
        );
        _log('catalog_sync_success release=${release.releaseVersion}');
        return true;
      }
      _log('catalog_sync_success release=none');
      return false;
    } catch (error) {
      _log('catalog_sync_failed reason=${error.runtimeType}');
      rethrow;
    }
  }

  void _validateSnapshot(
    PhraseCatalogReleaseDto release,
    PhraseCatalogSnapshotDto snapshot,
    String locale,
  ) {
    if (snapshot.releaseId != null &&
        snapshot.releaseId != release.releaseId &&
        snapshot.releaseId != release.releaseVersion) {
      throw const FormatException('Phrase snapshot release identity mismatch.');
    }
    const PhraseCatalogValidator().validateCatalog(snapshot.catalog);
    if (snapshot.catalog.schemaVersion != release.schemaVersion ||
        snapshot.catalog.catalogVersion != release.releaseVersion ||
        PhraseCatalogLocaleResolver.normalize(snapshot.catalog.locale) !=
            locale) {
      throw const FormatException('Phrase snapshot metadata mismatch.');
    }
  }

  void _log(String message) {
    if (kDebugMode) _logger?.call('[COMPLETED_DAY_PHRASE] $message');
  }
}
