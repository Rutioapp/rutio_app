import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/models/daily_mood.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/screens/diary_v2/diary_v2_all_entries_screen.dart';
import 'package:rutio/screens/diary_v2/diary_v2_mood_visuals.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  Provider.debugCheckInvalidValueType = null;

  group('DiaryV2AllEntriesScreen', () {
    testWidgets('shows empty state when there are no entries', (tester) async {
      await tester.pumpWidget(
        _app(
          child: const DiaryV2AllEntriesScreen(
            entries: [],
          ),
        ),
      );

      expect(find.text('Aún no hay entradas'), findsOneWidget);
      expect(
        find.text(
          'Cuando escribas en tu diario, tus entradas aparecerán aquí.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders newest entries first grouped by date', (tester) async {
      await tester.pumpWidget(
        _app(
          child: DiaryV2AllEntriesScreen(
            entries: [
              _entry(
                id: 'older-same-day',
                createdAt: DateTime(2026, 6, 12, 8, 0),
                title: 'Older same day',
                body: 'Body 1',
              ),
              _entry(
                id: 'newest',
                createdAt: DateTime(2026, 6, 13, 20, 15),
                title: 'Newest entry',
                body: 'Body 2',
                tags: const <String>['gratitude', 'energy', 'focus', 'sleep'],
              ),
              _entry(
                id: 'newer-same-day',
                createdAt: DateTime(2026, 6, 12, 22, 45),
                title: 'Newer same day',
                body: 'Body 3',
              ),
            ],
          ),
        ),
      );

      final newestTop = tester.getTopLeft(find.text('Newest entry')).dy;
      final newerSameDayTop = tester.getTopLeft(find.text('Newer same day')).dy;
      final olderSameDayTop = tester.getTopLeft(find.text('Older same day')).dy;

      expect(newestTop, lessThan(newerSameDayTop));
      expect(newerSameDayTop, lessThan(olderSameDayTop));
      expect(find.text('Newest entry'), findsOneWidget);
      expect(find.text('Newer same day'), findsOneWidget);
      expect(find.text('Older same day'), findsOneWidget);
      expect(find.text('Gratitud'), findsNWidgets(2));
      expect(find.text('Energía'), findsNWidgets(2));
      expect(find.text('+1'), findsOneWidget);
    });

    testWidgets('does not render entry tag chips when entry tags are empty',
        (tester) async {
      await tester.pumpWidget(
        _app(
          child: DiaryV2AllEntriesScreen(
            entries: [
              _entry(
                id: 'plain-entry',
                createdAt: DateTime(2026, 6, 13, 20, 15),
                title: 'Plain entry',
                body: 'Body',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Gratitud'), findsOneWidget);
      expect(find.text('Energía'), findsOneWidget);
      expect(find.text('+1'), findsNothing);
    });

    testWidgets('all filter is selected by default and shows all entries',
        (tester) async {
      await tester.pumpWidget(
        _app(
          child: DiaryV2AllEntriesScreen(
            entries: [
              _entry(
                id: 'gratitude-entry',
                createdAt: DateTime(2026, 6, 13, 20, 15),
                title: 'Gratitude entry',
                body: 'Body 1',
                tags: const <String>['gratitude'],
              ),
              _entry(
                id: 'sleep-entry',
                createdAt: DateTime(2026, 6, 12, 21, 30),
                title: 'Sleep entry',
                body: 'Body 2',
                tags: const <String>['sleep'],
              ),
            ],
          ),
        ),
      );

      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Gratitude entry'), findsOneWidget);
      expect(find.text('Sleep entry'), findsOneWidget);
    });

    testWidgets('empty search shows all entries under all filter',
        (tester) async {
      await tester.pumpWidget(
        _app(
          child: DiaryV2AllEntriesScreen(
            entries: [
              _entry(
                id: 'first',
                createdAt: DateTime(2026, 6, 13, 20, 15),
                title: 'Morning note',
                body: 'Fresh start',
              ),
              _entry(
                id: 'second',
                createdAt: DateTime(2026, 6, 12, 21, 30),
                title: 'Evening recap',
                body: 'Quiet close',
              ),
            ],
          ),
        ),
      );

      await tester.enterText(_searchField(), '   ');
      await tester.pumpAndSettle();

      expect(find.text('Morning note'), findsOneWidget);
      expect(find.text('Evening recap'), findsOneWidget);
    });

    testWidgets('search by title finds matching entries', (tester) async {
      await tester.pumpWidget(
        _app(
          child: DiaryV2AllEntriesScreen(
            entries: [
              _entry(
                id: 'match',
                createdAt: DateTime(2026, 6, 13, 20, 15),
                title: 'Sunset walk',
                body: 'Body 1',
              ),
              _entry(
                id: 'other',
                createdAt: DateTime(2026, 6, 12, 21, 30),
                title: 'Morning pages',
                body: 'Body 2',
              ),
            ],
          ),
        ),
      );

      await tester.enterText(_searchField(), 'sunset');
      await tester.pumpAndSettle();

      expect(find.text('Sunset walk'), findsOneWidget);
      expect(find.text('Morning pages'), findsNothing);
    });

    testWidgets('search by body finds matching entries', (tester) async {
      await tester.pumpWidget(
        _app(
          child: DiaryV2AllEntriesScreen(
            entries: [
              _entry(
                id: 'match',
                createdAt: DateTime(2026, 6, 13, 20, 15),
                title: 'Daily check-in',
                body: 'Breathing room after lunch',
              ),
              _entry(
                id: 'other',
                createdAt: DateTime(2026, 6, 12, 21, 30),
                title: 'Gym',
                body: 'Evening stretch',
              ),
            ],
          ),
        ),
      );

      await tester.enterText(_searchField(), 'lunch');
      await tester.pumpAndSettle();

      expect(find.text('Daily check-in'), findsOneWidget);
      expect(find.text('Gym'), findsNothing);
    });

    testWidgets('search by tag finds matching entries', (tester) async {
      await tester.pumpWidget(
        _app(
          child: DiaryV2AllEntriesScreen(
            entries: [
              _entry(
                id: 'match',
                createdAt: DateTime(2026, 6, 13, 20, 15),
                title: 'Thankful moment',
                body: 'Body 1',
                tags: const <String>['gratitude'],
              ),
              _entry(
                id: 'other',
                createdAt: DateTime(2026, 6, 12, 21, 30),
                title: 'Deep sleep',
                body: 'Body 2',
                tags: const <String>['sleep'],
              ),
            ],
          ),
        ),
      );

      await tester.enterText(_searchField(), 'gratitude');
      await tester.pumpAndSettle();

      expect(find.text('Thankful moment'), findsOneWidget);
      expect(find.text('Deep sleep'), findsNothing);
    });

    testWidgets('search is case-insensitive', (tester) async {
      await tester.pumpWidget(
        _app(
          child: DiaryV2AllEntriesScreen(
            entries: [
              _entry(
                id: 'match',
                createdAt: DateTime(2026, 6, 13, 20, 15),
                title: 'Calm Reset',
                body: 'Body 1',
              ),
            ],
          ),
        ),
      );

      await tester.enterText(_searchField(), 'reset');
      await tester.pumpAndSettle();
      expect(find.text('Calm Reset'), findsOneWidget);

      await tester.enterText(_searchField(), 'CALM');
      await tester.pumpAndSettle();
      expect(find.text('Calm Reset'), findsOneWidget);
    });

    testWidgets('search trims whitespace', (tester) async {
      await tester.pumpWidget(
        _app(
          child: DiaryV2AllEntriesScreen(
            entries: [
              _entry(
                id: 'match',
                createdAt: DateTime(2026, 6, 13, 20, 15),
                title: 'Notebook',
                body: 'Body 1',
              ),
            ],
          ),
        ),
      );

      await tester.enterText(_searchField(), '   note   ');
      await tester.pumpAndSettle();

      expect(find.text('Notebook'), findsOneWidget);
    });

    testWidgets('gratitude filter shows only entries with gratitude tag',
        (tester) async {
      await tester.pumpWidget(
        _app(
          child: DiaryV2AllEntriesScreen(
            entries: [
              _entry(
                id: 'gratitude-entry',
                createdAt: DateTime(2026, 6, 13, 20, 15),
                title: 'Gratitude entry',
                body: 'Body 1',
                tags: const <String>['gratitude'],
              ),
              _entry(
                id: 'energy-entry',
                createdAt: DateTime(2026, 6, 12, 21, 30),
                title: 'Energy entry',
                body: 'Body 2',
                tags: const <String>['energy'],
              ),
            ],
          ),
        ),
      );

      await tester.tap(_filterChip('gratitude'));
      await tester.pumpAndSettle();

      expect(find.text('Gratitude entry'), findsOneWidget);
      expect(find.text('Energy entry'), findsNothing);
    });

    testWidgets('search combines with selected tag filter', (tester) async {
      await tester.pumpWidget(
        _app(
          child: DiaryV2AllEntriesScreen(
            entries: [
              _entry(
                id: 'gratitude-match',
                createdAt: DateTime(2026, 6, 13, 20, 15),
                title: 'Family dinner',
                body: 'Warm evening together',
                tags: const <String>['gratitude'],
              ),
              _entry(
                id: 'gratitude-other',
                createdAt: DateTime(2026, 6, 12, 21, 30),
                title: 'Quiet tea',
                body: 'Slow moment',
                tags: const <String>['gratitude'],
              ),
              _entry(
                id: 'sleep-match-text',
                createdAt: DateTime(2026, 6, 11, 21, 30),
                title: 'Dinner prep',
                body: 'Set up for tomorrow',
                tags: const <String>['sleep'],
              ),
            ],
          ),
        ),
      );

      await tester.tap(_filterChip('gratitude'));
      await tester.pumpAndSettle();
      await tester.enterText(_searchField(), 'dinner');
      await tester.pumpAndSettle();

      expect(find.text('Family dinner'), findsOneWidget);
      expect(find.text('Quiet tea'), findsNothing);
      expect(find.text('Dinner prep'), findsNothing);
    });

    testWidgets('entry with multiple tags appears under either matching tag',
        (tester) async {
      await tester.pumpWidget(
        _app(
          child: DiaryV2AllEntriesScreen(
            entries: [
              _entry(
                id: 'multi-tag-entry',
                createdAt: DateTime(2026, 6, 13, 20, 15),
                title: 'Multi tag entry',
                body: 'Body',
                tags: const <String>['gratitude', 'sleep'],
              ),
              _entry(
                id: 'focus-entry',
                createdAt: DateTime(2026, 6, 12, 21, 30),
                title: 'Focus entry',
                body: 'Body 2',
                tags: const <String>['focus'],
              ),
            ],
          ),
        ),
      );

      await tester.tap(_filterChip('gratitude'));
      await tester.pumpAndSettle();
      expect(find.text('Multi tag entry'), findsOneWidget);

      await tester.tap(_filterChip('sleep'));
      await tester.pumpAndSettle();
      expect(find.text('Multi tag entry'), findsOneWidget);
      expect(find.text('Focus entry'), findsNothing);
    });

    testWidgets('shows tag-specific empty state when filter has no matches',
        (tester) async {
      await tester.pumpWidget(
        _app(
          child: DiaryV2AllEntriesScreen(
            entries: [
              _entry(
                id: 'gratitude-entry',
                createdAt: DateTime(2026, 6, 13, 20, 15),
                title: 'Gratitude entry',
                body: 'Body',
                tags: const <String>['gratitude'],
              ),
            ],
          ),
        ),
      );

      await tester.tap(_filterChip('idea'));
      await tester.pumpAndSettle();

      expect(find.text('No hay entradas con esta etiqueta'), findsOneWidget);
      expect(
        find.text('Cuando uses esta etiqueta en una entrada, aparecerá aquí.'),
        findsOneWidget,
      );
    });

    testWidgets('shows no results empty state when search has no matches',
        (tester) async {
      await tester.pumpWidget(
        _app(
          child: DiaryV2AllEntriesScreen(
            entries: [
              _entry(
                id: 'gratitude-entry',
                createdAt: DateTime(2026, 6, 13, 20, 15),
                title: 'Gratitude entry',
                body: 'Body',
                tags: const <String>['gratitude'],
              ),
            ],
          ),
        ),
      );

      await tester.enterText(_searchField(), 'missing');
      await tester.pumpAndSettle();

      expect(find.text('No hay resultados'), findsOneWidget);
      expect(
        find.text('Prueba con otra palabra o cambia el filtro.'),
        findsOneWidget,
      );
    });

    testWidgets('preserves grouping and newest-first sorting after search',
        (tester) async {
      await tester.pumpWidget(
        _app(
          child: DiaryV2AllEntriesScreen(
            entries: [
              _entry(
                id: 'older',
                createdAt: DateTime(2026, 6, 12, 8, 0),
                title: 'Alpha note',
                body: 'shared keyword',
              ),
              _entry(
                id: 'newest',
                createdAt: DateTime(2026, 6, 13, 20, 15),
                title: 'Beta note',
                body: 'shared keyword',
              ),
              _entry(
                id: 'newer-same-day',
                createdAt: DateTime(2026, 6, 12, 22, 45),
                title: 'Gamma note',
                body: 'shared keyword',
              ),
              _entry(
                id: 'other',
                createdAt: DateTime(2026, 6, 11, 12, 0),
                title: 'Different',
                body: 'other body',
              ),
            ],
          ),
        ),
      );

      await tester.enterText(_searchField(), 'shared');
      await tester.pumpAndSettle();

      final newestTop = tester.getTopLeft(find.text('Beta note')).dy;
      final newerSameDayTop = tester.getTopLeft(find.text('Gamma note')).dy;
      final olderTop = tester.getTopLeft(find.text('Alpha note')).dy;

      expect(newestTop, lessThan(newerSameDayTop));
      expect(newerSameDayTop, lessThan(olderTop));
      expect(find.textContaining('13 de junio'), findsOneWidget);
      expect(find.textContaining('12 de junio'), findsOneWidget);
      expect(find.text('Different'), findsNothing);
    });

    testWidgets('preserves grouping and newest-first sorting after filtering',
        (tester) async {
      await tester.pumpWidget(
        _app(
          child: DiaryV2AllEntriesScreen(
            entries: [
              _entry(
                id: 'older-sleep',
                createdAt: DateTime(2026, 6, 12, 8, 0),
                title: 'Older sleep',
                body: 'Body 1',
                tags: const <String>['sleep'],
              ),
              _entry(
                id: 'newest-sleep',
                createdAt: DateTime(2026, 6, 13, 20, 15),
                title: 'Newest sleep',
                body: 'Body 2',
                tags: const <String>['sleep'],
              ),
              _entry(
                id: 'newer-same-day-sleep',
                createdAt: DateTime(2026, 6, 12, 22, 45),
                title: 'Newer same day sleep',
                body: 'Body 3',
                tags: const <String>['sleep'],
              ),
              _entry(
                id: 'gratitude-entry',
                createdAt: DateTime(2026, 6, 11, 12, 0),
                title: 'Gratitude entry',
                body: 'Body 4',
                tags: const <String>['gratitude'],
              ),
            ],
          ),
        ),
      );

      await tester.tap(_filterChip('sleep'));
      await tester.pumpAndSettle();

      final newestTop = tester.getTopLeft(find.text('Newest sleep')).dy;
      final newerSameDayTop =
          tester.getTopLeft(find.text('Newer same day sleep')).dy;
      final olderTop = tester.getTopLeft(find.text('Older sleep')).dy;

      expect(newestTop, lessThan(newerSameDayTop));
      expect(newerSameDayTop, lessThan(olderTop));
      expect(find.text('sábado, 13 de junio'), findsOneWidget);
      expect(find.text('viernes, 12 de junio'), findsOneWidget);
      expect(find.text('Gratitude entry'), findsNothing);
    });

    testWidgets('tap opens editor in edit mode', (tester) async {
      final entry = _entry(
        id: 'edit-me',
        createdAt: DateTime(2026, 6, 13, 20, 15),
        title: 'Existing title',
        body: 'Existing body',
      );

      await tester.pumpWidget(
        _app(
          store: _FakeDiaryStore(entries: [entry]),
          child: DiaryV2AllEntriesScreen(
            entries: [entry],
          ),
        ),
      );

      await tester.tap(find.text('Existing title'));
      await tester.pumpAndSettle();

      expect(find.text('Editar entrada'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsWidgets);
      expect(find.text('Existing title'), findsOneWidget);
      expect(find.text('Existing body'), findsOneWidget);
    });

    testWidgets('confirm delete removes only the selected entry',
        (tester) async {
      final firstEntry = _entry(
        id: 'delete-me',
        createdAt: DateTime(2026, 6, 13, 20, 15),
        title: 'Delete me',
        body: 'Body 1',
      );
      final secondEntry = _entry(
        id: 'keep-me',
        createdAt: DateTime(2026, 6, 13, 18, 15),
        title: 'Keep me',
        body: 'Body 2',
      );
      final store = _MutableFakeDiaryStore(entries: [firstEntry, secondEntry]);

      await tester.pumpWidget(
        _app(
          store: store,
          child: DiaryV2AllEntriesScreen(
            entries: [firstEntry, secondEntry],
          ),
        ),
      );

      await tester.tap(find.text('Delete me'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();

      expect(find.text('Editar entrada'), findsNothing);
      expect(find.text('Keep me'), findsOneWidget);
      expect(store.deletedEntryIds, <String>['delete-me']);
      expect(
        store.diaryEntries.map((entry) => entry.id).toList(),
        <String>['keep-me'],
      );
    });

    testWidgets('renders DiaryEntry mood instead of DailyMood for the same day',
        (tester) async {
      final entry = _entry(
        id: 'mood-mismatch',
        createdAt: DateTime(2026, 6, 13, 20, 15),
        title: 'Mood mismatch',
        body: 'Body',
        mood: -1,
      );

      await tester.pumpWidget(
        _app(
          store: _FakeDiaryStore(
            entries: [entry],
            dailyMoods: [
              DailyMood(
                date: DateTime(2026, 6, 13),
                mood: 1,
                createdAt: 1,
                updatedAt: 1,
              ),
            ],
          ),
          child: DiaryV2AllEntriesScreen(
            entries: [entry],
          ),
        ),
      );

      expect(find.text(DiaryMoodVisuals.emojiFor(-1)), findsOneWidget);
      expect(find.text(DiaryMoodVisuals.emojiFor(1)), findsNothing);
    });

    testWidgets('updates displayed mood after editing from all entries',
        (tester) async {
      final entry = _entry(
        id: 'edit-mood',
        createdAt: DateTime(2026, 6, 13, 20, 15),
        title: 'Edit mood',
        body: 'Body',
        mood: -1,
      );
      final store = _MutableFakeDiaryStore(
        entries: [entry],
        dailyMoods: [
          DailyMood(
            date: DateTime(2026, 6, 13),
            mood: 1,
            createdAt: 1,
            updatedAt: 1,
          ),
        ],
      );

      await tester.pumpWidget(
        _app(
          store: store,
          child: DiaryV2AllEntriesScreen(
            entries: [entry],
          ),
        ),
      );

      expect(find.text(DiaryMoodVisuals.emojiFor(-1)), findsOneWidget);
      expect(find.text(DiaryMoodVisuals.emojiFor(2)), findsNothing);

      await tester.tap(find.text('Edit mood'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(DiaryMoodVisuals.emojiFor(2)));
      await tester.pumpAndSettle();

      final editSaveButton = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('Guardar cambios'),
          matching: find.byType(InkWell),
        ).first,
      );
      editSaveButton.onTap!.call();
      await tester.pumpAndSettle();

      expect(store.updatedEntries, hasLength(1));
      expect(store.updatedEntries.single.mood, 2);
      expect(find.text(DiaryMoodVisuals.emojiFor(2)), findsOneWidget);
      expect(find.text(DiaryMoodVisuals.emojiFor(-1)), findsNothing);
      expect(store.diaryEntries, hasLength(1));
      expect(store.diaryEntries.single.id, 'edit-mood');
    });

    testWidgets('editing an entry updates the filtered list', (tester) async {
      final initialEntry = _entry(
        id: 'edit-tags',
        createdAt: DateTime(2026, 6, 13, 20, 15),
        title: 'Edit tags',
        body: 'Body',
      );
      final store = _MutableFakeDiaryStore(entries: [initialEntry]);

      await tester.pumpWidget(
        _app(
          store: store,
          child: DiaryV2AllEntriesScreen(
            entries: [initialEntry],
          ),
        ),
      );

      await tester.tap(_filterChip('sleep'));
      await tester.pumpAndSettle();

      expect(find.text('No hay entradas con esta etiqueta'), findsOneWidget);

      await tester.tap(_filterChip('all'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit tags'));
      await tester.pumpAndSettle();

      final editorSleepChip = find.widgetWithText(FilterChip, 'Sueño');
      await tester.ensureVisible(editorSleepChip);
      await tester.tap(editorSleepChip);
      await tester.pumpAndSettle();

      final editSaveButton = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('Guardar cambios'),
          matching: find.byType(InkWell),
        ).first,
      );
      editSaveButton.onTap!.call();
      await tester.pumpAndSettle();

      expect(store.updatedEntries, hasLength(1));
      expect(store.updatedEntries.single.tags, contains('sleep'));

      await tester.tap(_filterChip('sleep'));
      await tester.pumpAndSettle();

      expect(find.text('Edit tags'), findsOneWidget);
      expect(find.text('No hay entradas con esta etiqueta'), findsNothing);
    });

    testWidgets('editing an entry updates visible search results', (tester) async {
      final initialEntry = _entry(
        id: 'search-edit',
        createdAt: DateTime(2026, 6, 13, 20, 15),
        title: 'Sunrise',
        body: 'Body',
      );
      final store = _MutableFakeDiaryStore(entries: [initialEntry]);

      await tester.pumpWidget(
        _app(
          store: store,
          child: DiaryV2AllEntriesScreen(
            entries: [initialEntry],
          ),
        ),
      );

      await tester.enterText(_searchField(), 'sunrise');
      await tester.pumpAndSettle();
      expect(find.text('Sunrise'), findsOneWidget);

      await tester.tap(find.text('Sunrise'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Moonlight');
      await tester.pumpAndSettle();

      final editSaveButton = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('Guardar cambios'),
          matching: find.byType(InkWell),
        ).first,
      );
      editSaveButton.onTap!.call();
      await tester.pumpAndSettle();

      expect(find.text('Sunrise'), findsNothing);
      expect(find.text('No hay resultados'), findsOneWidget);
      expect(store.updatedEntries, hasLength(1));
      expect(store.updatedEntries.single.title, 'Moonlight');
    });
  });
}

Widget _app({
  required Widget child,
  UserStateStore? store,
}) {
  Widget appShell() => Provider<UserStateStore?>.value(
        value: store,
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );

  if (store is ChangeNotifier) {
    return ListenableBuilder(
      listenable: store as ChangeNotifier,
      builder: (_, __) => appShell(),
    );
  }

  return appShell();
}

Finder _filterChip(String tag) {
  return find.byKey(ValueKey<String>('diary-all-entries-filter-$tag'));
}

Finder _searchField() {
  return find.byKey(const ValueKey<String>('diary-all-entries-search-field'));
}

DiaryEntry _entry({
  required String id,
  required DateTime createdAt,
  required String title,
  required String body,
  int? mood,
  List<String> tags = const <String>[],
}) {
  return DiaryEntry(
    id: id,
    createdAt: createdAt.millisecondsSinceEpoch,
    text: '$title\n\n$body',
    title: title,
    body: body,
    mood: mood,
    tags: tags,
  );
}

class _FakeDiaryStore extends ChangeNotifier implements UserStateStore {
  _FakeDiaryStore({
    required this.entries,
    this.dailyMoods = const [],
  });

  final List<DiaryEntry> entries;
  @override
  final List<DailyMood> dailyMoods;

  @override
  List<DiaryEntry> get diaryEntries => entries;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MutableFakeDiaryStore extends ChangeNotifier implements UserStateStore {
  _MutableFakeDiaryStore({
    required List<DiaryEntry> entries,
    List<DailyMood> dailyMoods = const [],
  })  : _entries = List<DiaryEntry>.from(entries),
        _dailyMoods = List<DailyMood>.from(dailyMoods);

  final List<DiaryEntry> _entries;
  final List<DailyMood> _dailyMoods;
  final List<String> deletedEntryIds = <String>[];
  final List<DiaryEntry> updatedEntries = <DiaryEntry>[];

  @override
  List<DiaryEntry> get diaryEntries => List<DiaryEntry>.unmodifiable(_entries);

  @override
  List<DailyMood> get dailyMoods => List<DailyMood>.unmodifiable(_dailyMoods);

  @override
  Future<void> updateDiaryEntry(DiaryEntry entry) async {
    updatedEntries.add(entry);
    final index = _entries.indexWhere((current) => current.id == entry.id);
    if (index >= 0) {
      _entries[index] = entry;
    } else {
      _entries.add(entry);
    }
    notifyListeners();
  }

  @override
  Future<void> deleteDiaryEntry(String id) async {
    deletedEntryIds.add(id);
    _entries.removeWhere((entry) => entry.id == id);
    notifyListeners();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
