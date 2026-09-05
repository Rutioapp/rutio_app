import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';
import '../../domain/phrase_catalog_locale_resolver.dart';
import 'phrase_catalog_dto.dart';

abstract interface class PhraseCatalogRemoteDataSource {
  Future<PhraseCatalogReleaseDto?> fetchPublishedRelease(String locale);

  Future<PhraseCatalogSnapshotDto> fetchSnapshot(
    String locale,
    int releaseVersion,
  );
}

class SupabasePhraseCatalogDataSource implements PhraseCatalogRemoteDataSource {
  SupabasePhraseCatalogDataSource({SupabaseClient? client})
      : _client = client ?? RutioSupabaseClient.instance;

  final SupabaseClient _client;

  @override
  Future<PhraseCatalogReleaseDto?> fetchPublishedRelease(String locale) async {
    final response = await _client.rpc(
      'get_published_phrase_catalog_release',
      params: <String, dynamic>{
        'p_locale': PhraseCatalogLocaleResolver.normalize(locale),
      },
    );
    final row = _singleMap(response);
    return row == null ? null : PhraseCatalogReleaseDto.fromJson(row);
  }

  @override
  Future<PhraseCatalogSnapshotDto> fetchSnapshot(
    String locale,
    int releaseVersion,
  ) async {
    final response = await _client.rpc(
      'get_completed_day_phrase_catalog_snapshot',
      params: <String, dynamic>{
        'p_locale': PhraseCatalogLocaleResolver.normalize(locale),
        'p_release_version': releaseVersion,
      },
    );
    final row = _singleMap(response);
    if (row == null) {
      throw const FormatException('Phrase catalog snapshot was empty.');
    }
    return PhraseCatalogSnapshotDto.fromJson(row);
  }

  Map<String, dynamic>? _singleMap(Object? response) {
    if (response == null) return null;
    if (response is Map) {
      return Map<String, dynamic>.from(response.cast<String, dynamic>());
    }
    if (response is List) {
      if (response.isEmpty) return null;
      final first = response.first;
      if (first is Map) {
        return Map<String, dynamic>.from(first.cast<String, dynamic>());
      }
    }
    throw const FormatException('Unexpected phrase catalog RPC response.');
  }
}
