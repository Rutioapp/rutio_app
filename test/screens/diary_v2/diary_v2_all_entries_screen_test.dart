import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/models/daily_mood.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/screens/diary_v2/diary_v2_all_entries_screen.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  Provider.debugCheckInvalidValueType = null;

  group('DiaryV2AllEntriesScreen', () {
    testWidgets('shows empty state when there are no entries', (tester) async {
      await tester.pumpWidget(
        _app(
          child: const DiaryV2AllEntriesScreen(
            entries: [],
            dailyMoods: [],
          ),
        ),
      );

      expect(find.text('Aún no hay entradas'), findsOneWidget);
      expect(
        find.text(
            'Cuando escribas en tu diario, tus entradas aparecerán aquí.'),
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
              ),
              _entry(
                id: 'newer-same-day',
                createdAt: DateTime(2026, 6, 12, 22, 45),
                title: 'Newer same day',
                body: 'Body 3',
              ),
            ],
            dailyMoods: [
              DailyMood(
                date: DateTime(2026, 6, 13),
                mood: 2,
                createdAt: 1,
                updatedAt: 1,
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
      expect(find.text('♥️'), findsOneWidget);
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
            dailyMoods: const [],
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
            dailyMoods: const [],
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

DiaryEntry _entry({
  required String id,
  required DateTime createdAt,
  required String title,
  required String body,
}) {
  return DiaryEntry(
    id: id,
    createdAt: createdAt.millisecondsSinceEpoch,
    text: '$title\n\n$body',
    title: title,
    body: body,
  );
}

class _FakeDiaryStore extends ChangeNotifier implements UserStateStore {
  _FakeDiaryStore({
    required this.entries,
  });

  final List<DiaryEntry> entries;

  @override
  List<DiaryEntry> get diaryEntries => entries;

  @override
  List<DailyMood> get dailyMoods => const [];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MutableFakeDiaryStore extends ChangeNotifier implements UserStateStore {
  _MutableFakeDiaryStore({
    required List<DiaryEntry> entries,
  }) : _entries = List<DiaryEntry>.from(entries);

  final List<DiaryEntry> _entries;
  final List<String> deletedEntryIds = <String>[];

  @override
  List<DiaryEntry> get diaryEntries => List<DiaryEntry>.unmodifiable(_entries);

  @override
  List<DailyMood> get dailyMoods => const [];

  @override
  Future<void> deleteDiaryEntry(String id) async {
    deletedEntryIds.add(id);
    _entries.removeWhere((entry) => entry.id == id);
    notifyListeners();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
