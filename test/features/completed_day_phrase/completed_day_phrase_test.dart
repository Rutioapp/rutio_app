import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutio/features/completed_day_phrase/completed_day_phrase.dart';

class FixedPhraseRandomSource implements PhraseRandomSource {
  FixedPhraseRandomSource(this.values);

  final List<double> values;
  var _index = 0;

  @override
  double nextDouble() {
    if (values.isEmpty) return 0;
    final value = values[_index % values.length];
    _index += 1;
    return value;
  }
}

MotivationalPhrase phrase(
  String id, {
  PhraseCategory category = PhraseCategory.motivation,
  String template = 'Done',
  List<String> requiredTokens = const <String>[],
  double weight = 1,
  bool enabled = true,
}) {
  return MotivationalPhrase(
    id: id,
    category: category,
    tone: PhraseTone.balanced,
    sourceType: PhraseSourceType.original,
    author: null,
    template: template,
    requiredTokens: requiredTokens,
    weight: weight,
    enabled: enabled,
    contentVersion: 1,
  );
}

PhraseContext context({
  String userId = 'user-1',
  String? name = 'Nora',
  int streak = 4,
  String? streakLabel = '4 días',
  String progress = '100 %',
  DateTime? date,
}) {
  return PhraseContext(
    userId: userId,
    localDate: date ?? DateTime(2026, 9, 4, 23, 59),
    locale: 'es-ES',
    name: name,
    streak: streak,
    streakLabel: streakLabel,
    progressLabel: progress,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhraseTemplateRenderer', () {
    final renderer = const PhraseTemplateRenderer();

    test('renders every supported token and repeated tokens', () {
      final item = phrase(
        'p',
        template: '{name}: {streak_label}; {progress}; {name}',
        requiredTokens: const <String>['name', 'streak_label', 'progress'],
      );
      expect(renderer.render(item, context()), 'Nora: 4 días; 100 %; Nora');
    });

    test('rejects unknown and unavailable tokens', () {
      final unknown = phrase('p', template: 'Hi {unknown}');
      expect(renderer.canRender(unknown, context()), isFalse);
      expect(() => renderer.render(unknown, context()),
          throwsA(isA<PhraseTemplateRenderException>()));

      final needsName = phrase('name',
          template: '{name}', requiredTokens: const <String>['name']);
      expect(renderer.canRender(needsName, context(name: '')), isFalse);
      final needsStreak = phrase('streak',
          template: '{streak_label}',
          requiredTokens: const <String>['streak_label']);
      expect(
          renderer.canRender(needsStreak, context(streakLabel: null)), isFalse);
    });
  });

  group('PhraseSelectionEngine', () {
    PhraseSelectionEngine engine(List<double> values) => PhraseSelectionEngine(
          randomSource: FixedPhraseRandomSource(values),
        );

    test('filters disabled, unresolved and streak-dependent phrases', () {
      final result = engine(<double>[0]).select(
        phrases: <MotivationalPhrase>[
          phrase('disabled', enabled: false),
          phrase('needs-name',
              template: '{name}', requiredTokens: const <String>['name']),
          phrase('needs-streak',
              template: '{streak_label}',
              requiredTokens: const <String>['streak_label']),
          phrase('valid'),
        ],
        context: context(name: null, streak: 0, streakLabel: null),
        history: const PhraseHistory(),
      );
      expect(result?.phrase.id, 'valid');
    });

    test('excludes recent IDs and selects an alternative', () {
      final result = engine(<double>[0]).select(
        phrases: <MotivationalPhrase>[phrase('a'), phrase('b')],
        context: context(),
        history: const PhraseHistory(phraseIds: <String>['a']),
      );
      expect(result?.phrase.id, 'b');
    });

    test('relaxes oldest history entry when there are no alternatives', () {
      final result = engine(<double>[0]).select(
        phrases: <MotivationalPhrase>[phrase('old'), phrase('new')],
        context: context(),
        history: const PhraseHistory(phraseIds: <String>['old', 'new']),
      );
      expect(result?.phrase.id, 'old');
      expect(result?.relaxedHistoryCount, 1);
    });

    test('raises personal category weight when name and streak are available',
        () {
      final result = engine(<double>[0.75]).select(
        phrases: <MotivationalPhrase>[
          phrase('m', category: PhraseCategory.motivation),
          phrase('c', category: PhraseCategory.consistency),
          phrase('p', category: PhraseCategory.personal),
        ],
        context: context(),
        history: const PhraseHistory(),
      );
      expect(result?.phrase.category, PhraseCategory.personal);
    });

    test('uses individual phrase weights inside a category', () {
      final result = engine(<double>[0.2]).select(
        phrases: <MotivationalPhrase>[
          phrase('low', weight: 1),
          phrase('high', weight: 9),
        ],
        context: context(),
        history: const PhraseHistory(),
      );
      expect(result?.phrase.id, 'high');
    });
  });

  group('SharedPreferencesCompletedDayPhraseStore', () {
    late SharedPreferencesCompletedDayPhraseStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      store = SharedPreferencesCompletedDayPhraseStore();
    });

    test('keeps at most 30 IDs, restores order and isolates users', () async {
      var history = const PhraseHistory();
      for (var index = 1; index <= 31; index++) {
        history = history.append('p$index');
      }
      await store.saveHistory('user-1', history);
      expect((await store.loadHistory('user-1')).phraseIds,
          containsAllInOrder(<String>['p2', 'p31']));
      expect((await store.loadHistory('user-1')).phraseIds.length, 30);
      expect((await store.loadHistory('user-2')).phraseIds, isEmpty);
    });

    test('restores a daily selection without changing history', () async {
      final date = DateTime(2026, 9, 4);
      await store.saveDailySelection(
        'user-1',
        date,
        PhraseDailySelection(
          phraseId: 'p1',
          localDate: date,
          locale: 'es',
          catalogVersion: 'v1',
        ),
      );
      expect((await store.loadDailySelection('user-1', date))?.phraseId, 'p1');
      expect((await store.loadHistory('user-1')).phraseIds, isEmpty);
      expect(await store.loadDailySelection('user-2', date), isNull);
    });
  });

  group('PhraseCatalogValidator and bundled catalog', () {
    final validator = const PhraseCatalogValidator();

    test('loads the offline Spanish catalog and required IDs', () async {
      final catalog = await BundledPhraseCatalog().load('es-ES');
      final ids = catalog.phrases.map((item) => item.id).toSet();
      expect(
          ids,
          containsAll(<String>[
            'motivation_001',
            'motivation_008',
            'motivation_015',
            'motivation_029',
            'motivation_045',
            'motivation_068',
            'motivation_090',
            'consistency_001',
            'consistency_019',
            'consistency_040',
            'consistency_068',
            'personal_001',
          ]));
    });

    test('rejects duplicate IDs and incoherent required tokens', () {
      expect(
        () => validator.validatePhrases(
            <MotivationalPhrase>[phrase('same'), phrase('same')]),
        throwsA(isA<PhraseCatalogValidationException>()),
      );
      expect(
        () => validator.validatePhrases(<MotivationalPhrase>[
          phrase('bad',
              template: '{progress}', requiredTokens: const <String>[])
        ]),
        throwsA(isA<PhraseCatalogValidationException>()),
      );
      expect(
        () => validator.validatePhrases(<MotivationalPhrase>[
          phrase('unknown',
              template: '{other}', requiredTokens: const <String>['other'])
        ]),
        throwsA(isA<PhraseCatalogValidationException>()),
      );
    });
  });

  test('service persists once and returns the same daily selection offline',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final date = DateTime(2026, 9, 4, 14);
    final catalog = PhraseCatalog(
      schemaVersion: 1,
      catalogVersion: 'test-v1',
      locale: 'es',
      phrases: <MotivationalPhrase>[
        phrase('only',
            template: 'Completado {progress}',
            requiredTokens: const <String>['progress'])
      ],
    );
    final store = SharedPreferencesCompletedDayPhraseStore();
    final service = CompletedDayPhraseService(
      catalogSource: _FakeCatalogSource(catalog),
      historyStore: store,
      selectionEngine: PhraseSelectionEngine(
          randomSource: FixedPhraseRandomSource(<double>[0])),
    );
    final first = await service.resolvePhrase(context(date: date));
    final second = await service.resolvePhrase(context(date: date));
    expect(first?.phrase.id, 'only');
    expect(second?.phrase.id, 'only');
    expect(second?.fromDailySelection, isTrue);
    expect((await store.loadHistory('user-1')).phraseIds, <String>['only']);
  });
}

class _FakeCatalogSource implements PhraseCatalogSource {
  _FakeCatalogSource(this.catalog);

  final PhraseCatalog catalog;

  @override
  Future<PhraseCatalog> load(String locale) async => catalog;
}
