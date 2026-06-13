import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/screens/diary_v2/diary_v2_entry_editor_screen.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  Provider.debugCheckInvalidValueType = null;

  group('DiaryV2EntryEditorScreen', () {
    testWidgets('create mode still adds a new entry', (tester) async {
      final store = _FakeDiaryEditorStore();

      await tester.pumpWidget(
        _app(
          store: store,
          child: const DiaryV2EntryEditorScreen(),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'Fresh title');
      await tester.enterText(find.byType(TextField).last, 'Fresh body');
      final createSaveButton = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('Guardar'),
          matching: find.byType(InkWell),
        ).first,
      );
      createSaveButton.onTap!.call();
      await tester.pumpAndSettle();

      expect(store.addedEntries, hasLength(1));
      expect(store.updatedEntries, isEmpty);
      expect(store.addedEntries.single.id, isNotEmpty);
      expect(store.addedEntries.single.title, 'Fresh title');
      expect(store.addedEntries.single.body, 'Fresh body');
    });

    testWidgets('renders standardized mood icons in the selector',
        (tester) async {
      final store = _FakeDiaryEditorStore();

      await tester.pumpWidget(
        _app(
          store: store,
          child: const DiaryV2EntryEditorScreen(),
        ),
      );

      expect(find.text('☁️'), findsOneWidget);
      expect(find.text('🌙'), findsOneWidget);
      expect(find.text('○'), findsOneWidget);
      expect(find.text('☀️'), findsOneWidget);
      expect(find.text('♥️'), findsOneWidget);
    });

    testWidgets('edit mode preloads content and updates existing entry',
        (tester) async {
      final store = _FakeDiaryEditorStore();
      final existing = DiaryEntry(
        id: 'entry-1',
        createdAt: DateTime(2026, 6, 13, 8, 30).millisecondsSinceEpoch,
        text: 'Old title\n\nOld body',
        title: 'Old title',
        body: 'Old body',
        mood: -1,
        remoteId: '123e4567-e89b-12d3-a456-426614174000',
        habitId: 'habit-1',
        familyId: 'mind',
        isPinned: true,
      );

      await tester.pumpWidget(
        _app(
          store: store,
          child: DiaryV2EntryEditorScreen(editing: existing),
        ),
      );

      expect(find.text('Editar entrada'), findsOneWidget);
      expect(find.text('Old title'), findsOneWidget);
      expect(find.text('Old body'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Updated title');
      await tester.enterText(find.byType(TextField).last, 'Updated body');
      final editSaveButton = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('Guardar cambios'),
          matching: find.byType(InkWell),
        ).first,
      );
      editSaveButton.onTap!.call();
      await tester.pumpAndSettle();

      expect(store.addedEntries, isEmpty);
      expect(store.updatedEntries, hasLength(1));

      final updated = store.updatedEntries.single;
      expect(updated.id, existing.id);
      expect(updated.createdAt, existing.createdAt);
      expect(updated.remoteId, existing.remoteId);
      expect(updated.habitId, existing.habitId);
      expect(updated.familyId, existing.familyId);
      expect(updated.isPinned, isTrue);
      expect(updated.title, 'Updated title');
      expect(updated.body, 'Updated body');
    });
  });
}

Widget _app({
  required UserStateStore store,
  required Widget child,
}) {
  return Provider<UserStateStore>.value(
    value: store,
    child: MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(430, 932),
        ),
        child: child,
      ),
    ),
  );
}

class _FakeDiaryEditorStore implements UserStateStore {
  final List<DiaryEntry> addedEntries = <DiaryEntry>[];
  final List<DiaryEntry> updatedEntries = <DiaryEntry>[];

  @override
  Future<void> addDiaryEntry(DiaryEntry entry) async {
    addedEntries.add(entry);
  }

  @override
  Future<void> updateDiaryEntry(DiaryEntry entry) async {
    updatedEntries.add(entry);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
