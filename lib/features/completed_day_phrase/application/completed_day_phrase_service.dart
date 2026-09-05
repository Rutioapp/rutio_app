import 'package:flutter/foundation.dart';

import '../domain/motivational_phrase.dart';
import '../domain/phrase_catalog_validator.dart';
import '../domain/phrase_date_key.dart';
import '../domain/phrase_catalog_locale_resolver.dart';
import '../domain/phrase_selection_engine.dart';
import '../domain/phrase_template_renderer.dart';

class CompletedDayPhraseService {
  CompletedDayPhraseService({
    required PhraseCatalogSource catalogSource,
    required PhraseHistoryStore historyStore,
    PhraseSelectionEngine? selectionEngine,
    PhraseTemplateRenderer? renderer,
  })  : _catalogSource = catalogSource,
        _historyStore = historyStore,
        _selectionEngine = selectionEngine ?? PhraseSelectionEngine(),
        _renderer = renderer ?? const PhraseTemplateRenderer();

  final PhraseCatalogSource _catalogSource;
  final PhraseHistoryStore _historyStore;
  final PhraseSelectionEngine _selectionEngine;
  final PhraseTemplateRenderer _renderer;

  Future<RenderedMotivationalPhrase?> resolvePhrase(
      PhraseContext context) async {
    final userId = context.userId.trim();
    if (userId.isEmpty) throw ArgumentError.value(context.userId, 'userId');
    final localDate = DateTime(
      context.localDate.year,
      context.localDate.month,
      context.localDate.day,
    );
    final locale = PhraseCatalogLocaleResolver.selectionLocale(context.locale);
    final PhraseCatalog catalog;
    try {
      catalog = await _catalogSource.load(locale);
    } on PhraseCatalogValidationException {
      // A corrupt catalog must not take down its future Home host.
      return null;
    } on FormatException {
      return null;
    } catch (_) {
      return null;
    }
    final daily = await _historyStore.loadDailySelection(
      userId,
      localDate,
      locale: locale,
    );
    if (daily != null &&
        PhraseCatalogLocaleResolver.selectionLocale(daily.locale) == locale) {
      final existing = _findAvailablePhrase(catalog, daily.phraseId, context);
      if (existing != null) {
        if (daily.catalogVersion != catalog.catalogVersion) {
          await _historyStore.saveDailySelection(
            userId,
            localDate,
            PhraseDailySelection(
              phraseId: existing.id,
              localDate: localDate,
              locale: locale,
              catalogVersion: catalog.catalogVersion,
            ),
          );
        }
        if (kDebugMode) {
          debugPrint(
            '[COMPLETED_DAY_PHRASE] daily_phrase_restored id=${existing.id}',
          );
        }
        return RenderedMotivationalPhrase(
          phrase: existing,
          text: _renderer.render(existing, context),
          localDate: localDate,
          fromDailySelection: true,
        );
      }
    }

    final history = await _historyStore.loadHistory(userId);
    final selection = _selectionEngine.select(
      phrases: catalog.phrases,
      context: context,
      history: history,
    );
    if (selection == null) return null;

    await _historyStore.saveDailySelection(
      userId,
      localDate,
      PhraseDailySelection(
        phraseId: selection.phrase.id,
        localDate: localDate,
        locale: locale,
        catalogVersion: catalog.catalogVersion,
      ),
    );
    await _historyStore.saveHistory(userId, selection.history);
    if (kDebugMode) {
      debugPrint(
        '[COMPLETED_DAY_PHRASE] daily_phrase_selected id=${selection.phrase.id}',
      );
    }
    return RenderedMotivationalPhrase(
      phrase: selection.phrase,
      text: selection.text,
      localDate: localDate,
      fromDailySelection: false,
    );
  }

  MotivationalPhrase? _findAvailablePhrase(
    PhraseCatalog catalog,
    String phraseId,
    PhraseContext context,
  ) {
    for (final phrase in catalog.phrases) {
      if (phrase.id == phraseId &&
          phrase.enabled &&
          _renderer.canRender(phrase, context)) {
        return phrase;
      }
    }
    return null;
  }
}

String phraseDateKey(DateTime localDate) => PhraseDateKey.format(localDate);
