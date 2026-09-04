import '../domain/motivational_phrase.dart';
import '../domain/phrase_catalog_validator.dart';
import '../domain/phrase_date_key.dart';
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
    final locale = PhraseLocale.canonicalize(context.locale);
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
    final daily = await _historyStore.loadDailySelection(userId, localDate);
    if (daily != null) {
      final existing = _findAvailablePhrase(catalog, daily.phraseId, context);
      if (existing != null) {
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
