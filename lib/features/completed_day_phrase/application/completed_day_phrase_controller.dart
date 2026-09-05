import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../data/local/shared_preferences_completed_day_phrase_store.dart';
import '../data/local/shared_preferences_phrase_catalog_cache_store.dart';
import '../data/phrase_catalog_repository.dart';
import '../data/remote/phrase_catalog_dto.dart';
import '../data/remote/supabase_phrase_catalog_data_source.dart';
import '../domain/completed_day_eligibility.dart';
import '../domain/motivational_phrase.dart';
import '../domain/phrase_catalog_locale_resolver.dart';
import '../domain/phrase_date_key.dart';
import '../infrastructure/bundled_phrase_catalog.dart';
import 'completed_day_phrase_service.dart';

enum CompletedDayPhraseStatus { hidden, resolving, ready, unavailable }

class CompletedDayPhraseState {
  const CompletedDayPhraseState({
    required this.status,
    this.phrase,
  });

  const CompletedDayPhraseState.hidden()
      : status = CompletedDayPhraseStatus.hidden,
        phrase = null;

  final CompletedDayPhraseStatus status;
  final RenderedMotivationalPhrase? phrase;

  bool get isVisible =>
      status == CompletedDayPhraseStatus.ready && phrase != null;
}

/// Inputs supplied by Home. The controller turns them into PhraseContext.
class CompletedDayPhraseInput {
  const CompletedDayPhraseInput({
    required this.userId,
    required this.localDate,
    required this.locale,
    required this.name,
    required this.streak,
    required this.streakLabel,
  });

  final String? userId;
  final DateTime localDate;
  final String locale;
  final String? name;
  final int streak;
  final String streakLabel;
}

class CompletedDayPhraseController extends ChangeNotifier {
  CompletedDayPhraseController({
    CompletedDayPhraseService? service,
  }) : _service = service ??
            CompletedDayPhraseService(
              catalogSource: PhraseCatalogRepository(
                cache: SharedPreferencesPhraseCatalogCacheStore(),
                remote: _NoopPhraseCatalogRemoteDataSource(),
                bundled: BundledPhraseCatalog(),
              ),
              historyStore: SharedPreferencesCompletedDayPhraseStore(),
            );

  final CompletedDayPhraseService _service;

  CompletedDayPhraseState _state = const CompletedDayPhraseState.hidden();
  String? _requestKey;
  int _requestSequence = 0;

  CompletedDayPhraseState get state => _state;

  /// Starts a best-effort local resolution without blocking Home.
  void resolve({
    required CompletedDayEligibility eligibility,
    required CompletedDayPhraseInput input,
  }) {
    final userId = input.userId?.trim();
    if (!eligibility.isCompletedDay || userId == null || userId.isEmpty) {
      _requestSequence += 1;
      _requestKey = null;
      _setState(const CompletedDayPhraseState.hidden());
      return;
    }

    final localDate = DateTime(
      input.localDate.year,
      input.localDate.month,
      input.localDate.day,
    );
    final locale = PhraseCatalogLocaleResolver.selectionLocale(input.locale);
    final requestKey = '$userId|${PhraseDateKey.format(localDate)}|$locale';
    if (_requestKey == requestKey) return;

    _requestKey = requestKey;
    final sequence = ++_requestSequence;
    _setState(const CompletedDayPhraseState(
      status: CompletedDayPhraseStatus.resolving,
    ));
    if (kDebugMode) {
      debugPrint('[COMPLETED_DAY_PHRASE] resolve_start');
    }
    unawaited(_resolve(
      sequence: sequence,
      requestKey: requestKey,
      userId: userId,
      localDate: localDate,
      input: input,
      progress: eligibility.progress,
    ));
  }

  Future<void> _resolve({
    required int sequence,
    required String requestKey,
    required String userId,
    required DateTime localDate,
    required CompletedDayPhraseInput input,
    required double progress,
  }) async {
    try {
      final locale = PhraseCatalogLocaleResolver.selectionLocale(input.locale);
      final phraseContext = PhraseContext(
        userId: userId,
        localDate: localDate,
        locale: locale,
        name: _nullableName(input.name),
        streak: input.streak,
        streakLabel:
            input.streakLabel.trim().isEmpty ? null : input.streakLabel.trim(),
        progressLabel: NumberFormat.percentPattern(locale).format(progress),
      );
      final phrase = await _service.resolvePhrase(phraseContext);
      if (kDebugMode) {
        debugPrint(
          '[COMPLETED_DAY_PHRASE] resolved id=${phrase?.phrase.id ?? 'none'}',
        );
      }
      if (!_isCurrent(sequence, requestKey)) return;
      _setState(phrase == null
          ? const CompletedDayPhraseState(
              status: CompletedDayPhraseStatus.unavailable,
            )
          : CompletedDayPhraseState(
              status: CompletedDayPhraseStatus.ready,
              phrase: phrase,
            ));
    } catch (_) {
      if (_isCurrent(sequence, requestKey)) {
        _setState(const CompletedDayPhraseState(
          status: CompletedDayPhraseStatus.unavailable,
        ));
      }
    }
  }

  bool _isCurrent(int sequence, String requestKey) {
    return sequence == _requestSequence && requestKey == _requestKey;
  }

  static String? _nullableName(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  void _setState(CompletedDayPhraseState next) {
    if (_state.status == next.status && _state.phrase == next.phrase) return;
    _state = next;
    notifyListeners();
  }
}

/// The controller never performs remote work while resolving Home content.
class _NoopPhraseCatalogRemoteDataSource
    implements PhraseCatalogRemoteDataSource {
  @override
  Future<PhraseCatalogReleaseDto?> fetchPublishedRelease(String locale) async =>
      null;

  @override
  Future<PhraseCatalogSnapshotDto> fetchSnapshot(
    String locale,
    int releaseVersion,
  ) {
    throw StateError('Remote phrase catalog access is sync-only in Home.');
  }
}
