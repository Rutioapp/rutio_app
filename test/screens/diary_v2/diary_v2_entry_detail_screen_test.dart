import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/screens/diary_v2/diary_v2_entry_detail_screen.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  Provider.debugCheckInvalidValueType = null;

  group('DiaryV2EntryDetailScreen', () {
    testWidgets('renders title body date mood tags and saved state',
        (tester) async {
      final entry = DiaryEntry(
        id: 'detail-1',
        createdAt: DateTime(2026, 6, 17, 19, 53).millisecondsSinceEpoch,
        text: 'Evening reset\n\nA calm walk and a quiet tea.',
        title: 'Evening reset',
        body: 'A calm walk and a quiet tea.',
        mood: 1,
        tags: const <String>['gratitude', 'energy'],
        isPinned: true,
      );

      await tester.pumpWidget(
        _app(
          store: _MutableDetailStore(entries: [entry]),
          child: DiaryV2EntryDetailScreen(entry: entry),
        ),
      );

      expect(find.text('Wednesday, June 17 · 19:53'), findsOneWidget);
      expect(find.text('Evening reset'), findsOneWidget);
      expect(find.text('A calm walk and a quiet tea.'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Gratitude'), findsOneWidget);
      expect(find.text('Energy'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('uses DiaryEntry mood and legacy fallback safely',
        (tester) async {
      final entry = DiaryEntry(
        id: 'legacy-1',
        createdAt: DateTime(2026, 6, 17, 19, 53).millisecondsSinceEpoch,
        text: 'Legacy only entry text',
        mood: -1,
      );

      await tester.pumpWidget(
        _app(
          store: _MutableDetailStore(entries: [entry]),
          child: DiaryV2EntryDetailScreen(entry: entry),
        ),
      );

      expect(find.text('Legacy only entry text'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('No content'), findsOneWidget);
    });

    testWidgets('edit action opens existing editor in edit mode',
        (tester) async {
      final entry = DiaryEntry(
        id: 'edit-1',
        createdAt: DateTime(2026, 6, 17, 19, 53).millisecondsSinceEpoch,
        text: 'Title\n\nBody',
        title: 'Title',
        body: 'Body',
      );

      await tester.pumpWidget(
        _app(
          store: _MutableDetailStore(entries: [entry]),
          child: DiaryV2EntryDetailScreen(entry: entry),
        ),
      );

      await tester.tap(find.text('Edit').first);
      await tester.pumpAndSettle();

      expect(find.text('Edit entry'), findsOneWidget);
      expect(find.text('Save changes'), findsWidgets);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('pops safely when edited entry is deleted', (tester) async {
      final entry = DiaryEntry(
        id: 'delete-1',
        createdAt: DateTime(2026, 6, 17, 19, 53).millisecondsSinceEpoch,
        text: 'Title\n\nBody',
        title: 'Title',
        body: 'Body',
      );
      final store = _MutableDetailStore(entries: [entry]);

      await tester.pumpWidget(
        _app(
          store: store,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DiaryV2EntryDetailScreen(entry: entry),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Your entry'), findsOneWidget);

      await tester.tap(find.text('Edit').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(find.text('Your entry'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
      expect(store.deletedEntryIds, <String>['delete-1']);
    });
  });
}

Widget _app({
  required Widget child,
  required UserStateStore store,
}) {
  return ListenableBuilder(
    listenable: store as ChangeNotifier,
    builder: (_, __) {
      return Provider<UserStateStore>.value(
        value: store,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );
    },
  );
}

class _MutableDetailStore extends ChangeNotifier implements UserStateStore {
  _MutableDetailStore({required List<DiaryEntry> entries})
      : _entries = List<DiaryEntry>.from(entries);

  final List<DiaryEntry> _entries;
  final List<String> deletedEntryIds = <String>[];

  @override
  List<DiaryEntry> get diaryEntries => List<DiaryEntry>.unmodifiable(_entries);

  @override
  Future<void> updateDiaryEntry(DiaryEntry entry) async {
    final index = _entries.indexWhere((current) => current.id == entry.id);
    if (index >= 0) {
      _entries[index] = entry;
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
