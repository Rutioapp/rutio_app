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
    testWidgets('shows a reflection prompt without pre-filling the body',
        (tester) async {
      final store = _FakeDiaryEditorStore();

      await tester.pumpWidget(
        _app(
          store: store,
          child: const DiaryV2EntryEditorScreen(
            reflectionPrompt: '¿Qué te gustaría observar de hoy?',
            source: 'journalNudge',
            templateId: 'journal.nudge.end_of_day.reflection_01',
            journalNudgeContext: 'endOfDay',
          ),
        ),
      );

      expect(find.text('¿Qué te gustaría observar de hoy?'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        isEmpty,
      );

      await tester.tap(find.byTooltip('Ocultar sugerencia'));
      await tester.pump();
      expect(find.text('¿Qué te gustaría observar de hoy?'), findsNothing);
    });

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
        find
            .ancestor(
              of: find.text('Guardar'),
              matching: find.byType(InkWell),
            )
            .first,
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
      await tester.ensureVisible(_tagChip('gratitude'));
      await tester.tap(_tagChip('gratitude'));
      await tester.tap(_tagChip('energy'));
      await tester.pumpAndSettle();

      final createSaveButton = tester.widget<InkWell>(
        find
            .ancestor(
              of: find.text('Guardar'),
              matching: find.byType(InkWell),
            )
            .first,
      );
      createSaveButton.onTap!.call();
      await tester.pumpAndSettle();

      expect(store.addedEntries, hasLength(1));
      expect(store.addedEntries.single.tags, <String>['gratitude', 'energy']);
    });

    testWidgets('entry type chips render and start unselected', (tester) async {
      final store = _FakeDiaryEditorStore();

      await tester.pumpWidget(
        _app(
          store: store,
          child: const DiaryV2EntryEditorScreen(),
        ),
      );

      expect(_typeChip('Aprendizaje'), findsOneWidget);
      expect(_typeChip('Reflexión'), findsOneWidget);
      expect(_typeChip('Momento'), findsOneWidget);
      expect(_typeChip('Gratitud'), findsOneWidget);
      expect(tester.widget<FilterChip>(_typeChip('Aprendizaje')).selected,
          isFalse);
      expect(
          tester.widget<FilterChip>(_typeChip('Reflexión')).selected, isFalse);
      expect(tester.widget<FilterChip>(_typeChip('Momento')).selected, isFalse);
      expect(
          tester.widget<FilterChip>(_typeChip('Gratitud')).selected, isFalse);
    });

    testWidgets('selecting a type saves learning', (tester) async {
      final store = _FakeDiaryEditorStore();

      await tester.pumpWidget(
        _app(
          store: store,
          child: const DiaryV2EntryEditorScreen(),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'Fresh title');
      await tester.enterText(find.byType(TextField).last, 'Fresh body');
      await tester.ensureVisible(_typeChip('Aprendizaje'));
      await tester.tap(_typeChip('Aprendizaje'));
      await tester.pumpAndSettle();

      final createSaveButton = tester.widget<InkWell>(
        find
            .ancestor(
              of: find.text('Guardar'),
              matching: find.byType(InkWell),
            )
            .first,
      );
      createSaveButton.onTap!.call();
      await tester.pumpAndSettle();

      expect(store.addedEntries, hasLength(1));
      expect(
          store.addedEntries.single.entryType, DiaryEntryContentType.learning);
    });

    testWidgets('changing a type leaves a single selection and saves it',
        (tester) async {
      final store = _FakeDiaryEditorStore();

      await tester.pumpWidget(
        _app(
          store: store,
          child: const DiaryV2EntryEditorScreen(),
        ),
      );

      await tester.ensureVisible(_typeChip('Aprendizaje'));
      await tester.tap(_typeChip('Aprendizaje'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(_typeChip('Reflexión'));
      await tester.tap(_typeChip('Reflexión'));
      await tester.pumpAndSettle();

      expect(tester.widget<FilterChip>(_typeChip('Aprendizaje')).selected,
          isFalse);
      expect(
          tester.widget<FilterChip>(_typeChip('Reflexión')).selected, isTrue);
      expect(tester.widget<FilterChip>(_typeChip('Momento')).selected, isFalse);
      expect(
          tester.widget<FilterChip>(_typeChip('Gratitud')).selected, isFalse);

      await tester.enterText(find.byType(TextField).first, 'Fresh title');
      await tester.enterText(find.byType(TextField).last, 'Fresh body');
      final createSaveButton = tester.widget<InkWell>(
        find
            .ancestor(
              of: find.text('Guardar'),
              matching: find.byType(InkWell),
            )
            .first,
      );
      createSaveButton.onTap!.call();
      await tester.pumpAndSettle();

      expect(store.addedEntries, hasLength(1));
      expect(
        store.addedEntries.single.entryType,
        DiaryEntryContentType.reflection,
      );
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
        tester.widget<FilterChip>(_tagChip('gratitude')).selected,
        isTrue,
      );
      expect(
        tester.widget<FilterChip>(_tagChip('energy')).selected,
        isTrue,
      );

      await tester.enterText(find.byType(TextField).first, 'Updated title');
      await tester.enterText(find.byType(TextField).last, 'Updated body');
      await tester.ensureVisible(_tagChip('gratitude'));
      await tester.tap(_tagChip('gratitude'));
      await tester.tap(_tagChip('sleep'));
      await tester.pumpAndSettle();
      final editSaveButton = tester.widget<InkWell>(
        find
            .ancestor(
              of: find.text('Guardar cambios'),
              matching: find.byType(InkWell),
            )
            .first,
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

    testWidgets('edit mode preloads and can clear an existing type',
        (tester) async {
      final store = _FakeDiaryEditorStore();
      final existing = DiaryEntry(
        id: 'entry-type-1',
        createdAt: DateTime(2026, 6, 13, 8, 30).millisecondsSinceEpoch,
        text: 'Old title\n\nOld body',
        title: 'Old title',
        body: 'Old body',
        entryType: DiaryEntryContentType.moment,
      );

      await tester.pumpWidget(
        _app(
          store: store,
          child: DiaryV2EntryEditorScreen(editing: existing),
        ),
      );

      expect(tester.widget<FilterChip>(_typeChip('Aprendizaje')).selected,
          isFalse);
      expect(
          tester.widget<FilterChip>(_typeChip('Reflexión')).selected, isFalse);
      expect(tester.widget<FilterChip>(_typeChip('Momento')).selected, isTrue);
      expect(
          tester.widget<FilterChip>(_typeChip('Gratitud')).selected, isFalse);

      await tester.ensureVisible(_typeChip('Momento'));
      await tester.tap(_typeChip('Momento'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilterChip>(_typeChip('Momento')).selected, isFalse);

      final editSaveButton = tester.widget<InkWell>(
        find
            .ancestor(
              of: find.text('Guardar cambios'),
              matching: find.byType(InkWell),
            )
            .first,
      );
      editSaveButton.onTap!.call();
      await tester.pumpAndSettle();

      expect(store.updatedEntries, hasLength(1));
      expect(store.updatedEntries.single.entryType, isNull);
    });

    testWidgets(
        'delete action opens confirmation dialog and cancel keeps entry',
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

Finder _typeChip(String label) {
  return find.byKey(ValueKey<String>('diary-entry-type-${_typeName(label)}'));
}

Finder _tagChip(String tag) {
  return find.byKey(ValueKey<String>('diary-entry-tag-$tag'));
}

String _typeName(String label) {
  switch (label) {
    case 'Aprendizaje':
      return 'learning';
    case 'Reflexión':
      return 'reflection';
    case 'Momento':
      return 'moment';
    case 'Gratitud':
      return 'gratitude';
    default:
      return label.toLowerCase();
  }
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
