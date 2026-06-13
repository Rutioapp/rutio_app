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
      expect(store.addedEntries.single.tags, isEmpty);
      expect(find.byTooltip('Eliminar'), findsNothing);
    });

    testWidgets('create mode stores selected predefined tags', (tester) async {
      final store = _FakeDiaryEditorStore();

      await tester.pumpWidget(
        _app(
          store: store,
          child: const DiaryV2EntryEditorScreen(),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'Fresh title');
      await tester.enterText(find.byType(TextField).last, 'Fresh body');
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Gratitud'));
      await tester.tap(find.widgetWithText(FilterChip, 'Gratitud'));
      await tester.tap(find.widgetWithText(FilterChip, 'Energía'));
      await tester.pumpAndSettle();

      final createSaveButton = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('Guardar'),
          matching: find.byType(InkWell),
        ).first,
      );
      createSaveButton.onTap!.call();
      await tester.pumpAndSettle();

      expect(store.addedEntries, hasLength(1));
      expect(store.addedEntries.single.tags, <String>['gratitude', 'energy']);
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
        tags: const <String>['gratitude', 'energy'],
        isPinned: true,
      );

      await tester.pumpWidget(
        _app(
          store: store,
          child: DiaryV2EntryEditorScreen(editing: existing),
        ),
      );

      expect(find.text('Editar entrada'), findsOneWidget);
      expect(find.byTooltip('Eliminar'), findsOneWidget);
      expect(find.text('Old title'), findsOneWidget);
      expect(find.text('Old body'), findsOneWidget);
      expect(
        tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Gratitud')).selected,
        isTrue,
      );
      expect(
        tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Energía')).selected,
        isTrue,
      );

      await tester.enterText(find.byType(TextField).first, 'Updated title');
      await tester.enterText(find.byType(TextField).last, 'Updated body');
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'Gratitud'));
      await tester.tap(find.widgetWithText(FilterChip, 'Gratitud'));
      await tester.tap(find.widgetWithText(FilterChip, 'Sueño'));
      await tester.pumpAndSettle();
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
      expect(updated.tags, <String>['energy', 'sleep']);
    });

    testWidgets('delete action opens confirmation dialog and cancel keeps entry',
        (tester) async {
      final store = _FakeDiaryEditorStore();
      final existing = DiaryEntry(
        id: 'entry-1',
        createdAt: DateTime(2026, 6, 13, 8, 30).millisecondsSinceEpoch,
        text: 'Old title\n\nOld body',
        title: 'Old title',
        body: 'Old body',
      );

      await tester.pumpWidget(
        _app(
          store: store,
          child: DiaryV2EntryEditorScreen(editing: existing),
        ),
      );

      await tester.tap(find.byTooltip('Eliminar'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar entrada'), findsOneWidget);
      expect(find.text('Esta acción no se puede deshacer.'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(store.deletedEntryIds, isEmpty);
      expect(find.text('Editar entrada'), findsOneWidget);
    });

    testWidgets('confirm delete removes the edited entry', (tester) async {
      final store = _FakeDiaryEditorStore();
      final existing = DiaryEntry(
        id: 'entry-1',
        createdAt: DateTime(2026, 6, 13, 8, 30).millisecondsSinceEpoch,
        text: 'Old title\n\nOld body',
        title: 'Old title',
        body: 'Old body',
      );

      await tester.pumpWidget(
        _app(
          store: store,
          child: DiaryV2EntryEditorScreen(editing: existing),
        ),
      );

      await tester.tap(find.byTooltip('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();

      expect(store.deletedEntryIds, <String>['entry-1']);
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
  final List<String> deletedEntryIds = <String>[];

  @override
  Future<void> addDiaryEntry(DiaryEntry entry) async {
    addedEntries.add(entry);
  }

  @override
  Future<void> updateDiaryEntry(DiaryEntry entry) async {
    updatedEntries.add(entry);
  }

  @override
  Future<void> deleteDiaryEntry(String id) async {
    deletedEntryIds.add(id);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
