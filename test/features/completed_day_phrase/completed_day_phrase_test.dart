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

  group('CompletedDayEligibility', () {
    final today = DateTime(2026, 9, 4, 23, 30);

    CompletedDayEligibility eligibility({
      bool ready = true,
      DateTime? selectedDay,
      int scheduled = 3,
      int completed = 3,
      int pending = 0,
      int skipped = 0,
    }) {
      return CompletedDayEligibility(
        isReady: ready,
        isLocalToday: (selectedDay ?? today).year == today.year &&
            (selectedDay ?? today).month == today.month &&
            (selectedDay ?? today).day == today.day,
        scheduledHabitCount: scheduled,
        completedHabitCount: completed,
        pendingHabitCount: pending,
        skippedHabitCount: skipped,
      );
    }

    test('ready + 3 completed of 3 is eligible', () {
      expect(eligibility().isCompletedDay, isTrue);
    });

    test('pending, skipped, zero scheduled, loading and another date are not',
        () {
      expect(eligibility(completed: 2, pending: 1).isCompletedDay, isFalse);
      expect(eligibility(completed: 2, skipped: 1).isCompletedDay, isFalse);
      expect(eligibility(scheduled: 0).isCompletedDay, isFalse);
      expect(eligibility(ready: false).isCompletedDay, isFalse);
      expect(
        eligibility(selectedDay: DateTime(2026, 9, 3)).isCompletedDay,
        isFalse,
      );
    });

    test('timesPerWeek does not create daily obligations', () {
      final result = buildCompletedDayEligibility(
        viewHabits: <Map<String, dynamic>>[
          <String, dynamic>{
            'isTimesPerWeekCheck': true,
            'doneToday': false,
            'isWeeklyTargetMet': false,
          },
        ],
        selectedDay: today,
        localToday: today,
        isReady: true,
      );
      expect(result.scheduledHabitCount, 0);
      expect(result.isCompletedDay, isFalse);
    });

    test('timesPerWeek pending beside completed daily habits does not block',
        () {
      final result = buildCompletedDayEligibility(
        viewHabits: <Map<String, dynamic>>[
          <String, dynamic>{'doneToday': true},
          <String, dynamic>{
            'schedule': <String, dynamic>{'type': 'timesPerWeek'},
            'doneToday': false,
          },
        ],
        selectedDay: today,
        localToday: today,
        isReady: true,
      );
      expect(result.scheduledHabitCount, 1);
      expect(result.completedHabitCount, 1);
      expect(result.pendingHabitCount, 0);
      expect(result.isCompletedDay, isTrue);
    });
  });

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

    test('namespaces daily selections by locale', () async {
      final date = DateTime(2026, 9, 4);
      await store.saveDailySelection(
        'user-1',
        date,
        PhraseDailySelection(
          phraseId: 'es-phrase',
          localDate: date,
          locale: 'es',
          catalogVersion: 'v1',
        ),
      );
      expect(
        await store.loadDailySelection('user-1', date, locale: 'en'),
        isNull,
      );
      expect(
        (await store.loadDailySelection('user-1', date, locale: 'es'))
            ?.phraseId,
        'es-phrase',
      );
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

  group('CompletedDayPhraseController', () {
    late SharedPreferencesCompletedDayPhraseStore store;
    late CompletedDayPhraseController controller;
    final date = DateTime(2026, 9, 4, 18);
    final eligible = const CompletedDayEligibility(
      isReady: true,
      isLocalToday: true,
      scheduledHabitCount: 1,
      completedHabitCount: 1,
      pendingHabitCount: 0,
      skippedHabitCount: 0,
    );

    CompletedDayPhraseInput input({String userId = 'user-a', DateTime? day}) {
      return CompletedDayPhraseInput(
        userId: userId,
        localDate: day ?? date,
        locale: 'es-ES',
        name: 'Nora',
        streak: 2,
        streakLabel: '2 días',
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      store = SharedPreferencesCompletedDayPhraseStore();
      controller = CompletedDayPhraseController(
        service: CompletedDayPhraseService(
          catalogSource: _FakeCatalogSource(
            PhraseCatalog(
              schemaVersion: 1,
              catalogVersion: 'controller-v1',
              locale: 'es',
              phrases: <MotivationalPhrase>[
                phrase('stable',
                    template: 'Hecho {progress}',
                    requiredTokens: const ['progress']),
              ],
            ),
          ),
          historyStore: store,
          selectionEngine: PhraseSelectionEngine(
            randomSource: FixedPhraseRandomSource(<double>[0]),
          ),
        ),
      );
    });

    tearDown(() => controller.dispose());

    test('resolves once and keeps the same phrase across repeated updates',
        () async {
      controller.resolve(eligibility: eligible, input: input());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final first = controller.state.phrase;
      expect(first?.phrase.id, 'stable');

      controller.resolve(eligibility: eligible, input: input());
      expect(controller.state.phrase?.phrase.id, 'stable');
    });

    test('reopening hides and completing again restores the same daily ID',
        () async {
      controller.resolve(eligibility: eligible, input: input());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.phrase?.phrase.id, 'stable');

      controller.resolve(
        eligibility: const CompletedDayEligibility(
          isReady: true,
          isLocalToday: true,
          scheduledHabitCount: 1,
          completedHabitCount: 0,
          pendingHabitCount: 1,
          skippedHabitCount: 0,
        ),
        input: input(),
      );
      expect(controller.state.status, CompletedDayPhraseStatus.hidden);

      controller.resolve(eligibility: eligible, input: input());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.phrase?.phrase.id, 'stable');
      expect(controller.state.phrase?.fromDailySelection, isTrue);
    });

    test('a different user or local date cannot reuse the previous result',
        () async {
      controller.resolve(eligibility: eligible, input: input());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.phrase?.phrase.id, 'stable');

      controller.resolve(eligibility: eligible, input: input(userId: 'user-b'));
      expect(controller.state.status, CompletedDayPhraseStatus.resolving);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.phrase?.phrase.id, 'stable');
      expect(controller.state.phrase?.fromDailySelection, isFalse);

      controller.resolve(
        eligibility: eligible,
        input: input(userId: 'user-b', day: DateTime(2026, 9, 5)),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.phrase?.localDate, DateTime(2026, 9, 5));
      expect(controller.state.phrase?.fromDailySelection, isFalse);
    });
  });
}

class _FakeCatalogSource implements PhraseCatalogSource {
  _FakeCatalogSource(this.catalog);

  final PhraseCatalog catalog;

  @override
  Future<PhraseCatalog> load(String locale) async => catalog;
}
