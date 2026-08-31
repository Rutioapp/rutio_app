import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/models/daily_mood.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/screens/diary_v2/diary_v2_all_entries_screen.dart';
import 'package:rutio/screens/diary_v2/diary_v2_screen.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  Provider.debugCheckInvalidValueType = null;

  testWidgets(
      'explore cards open all entries with the correct initial entry type',
      (tester) async {
    final store = _FakeDiaryV2Store(
      entries: [
        _entry(
          id: 'learning-entry',
          title: 'Learning note',
          body: 'Body',
          entryType: DiaryEntryContentType.learning,
        ),
        _entry(
          id: 'reflection-entry',
          title: 'Reflection note',
          body: 'Body',
          entryType: DiaryEntryContentType.reflection,
        ),
        _entry(
          id: 'moment-entry',
          title: 'Moment note',
          body: 'Body',
          entryType: DiaryEntryContentType.moment,
        ),
      ],
    );

    await tester.pumpWidget(_app(store: store));
    await tester.pumpAndSettle();

    await _tapExploreCardAndVerify(
      tester,
      cardTitle: 'Aprendizajes',
      visibleEntry: 'Learning note',
    );

    await _tapExploreCardAndVerify(
      tester,
      cardTitle: 'Reflexiones',
      visibleEntry: 'Reflection note',
    );

    await _tapExploreCardAndVerify(
      tester,
      cardTitle: 'Momentos',
      visibleEntry: 'Moment note',
    );

    await tester.tap(find.text('Gratitud').first);
    await tester.pumpAndSettle();

    expect(find.byType(DiaryV2AllEntriesScreen), findsOneWidget);
    expect(find.text('Learning note'), findsNothing);
    expect(find.text('Reflection note'), findsNothing);
    expect(find.text('Moment note'), findsNothing);
    expect(find.text('No hay entradas con estos filtros'), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.back));
    await tester.pumpAndSettle();

    expect(find.text('Explora tu diario'), findsOneWidget);
  });
}

Future<void> _tapExploreCardAndVerify(
  WidgetTester tester, {
  required String cardTitle,
  required String visibleEntry,
}) async {
  final cardFinder = find.text(cardTitle);
  var attempts = 0;
  while (cardFinder.evaluate().isEmpty && attempts < 6) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    attempts += 1;
  }

  await tester.tap(cardFinder.first);
  await tester.pumpAndSettle();

  expect(find.byType(DiaryV2AllEntriesScreen), findsOneWidget);
  expect(find.text(visibleEntry), findsOneWidget);

  await tester.tap(find.byIcon(CupertinoIcons.back));
  await tester.pumpAndSettle();

  expect(find.text('Explora tu diario'), findsOneWidget);
}

Widget _app({required UserStateStore store}) {
  return ChangeNotifierProvider<UserStateStore>.value(
    value: store,
    child: MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MediaQuery(
        data: MediaQueryData(size: Size(430, 932)),
        child: DiaryV2Screen(),
      ),
    ),
  );
}

DiaryEntry _entry({
  required String id,
  required String title,
  required String body,
  DiaryEntryContentType? entryType,
}) {
  return DiaryEntry(
    id: id,
    createdAt: DateTime(2026, 6, 13, 20, 15).millisecondsSinceEpoch,
    text: '$title\n\n$body',
    title: title,
    body: body,
    entryType: entryType,
  );
}

class _FakeDiaryV2Store extends ChangeNotifier implements UserStateStore {
  _FakeDiaryV2Store({
    List<DiaryEntry> entries = const <DiaryEntry>[],
  }) : _entries = List<DiaryEntry>.from(entries);

  final List<DiaryEntry> _entries;
  final List<DailyMood> _moods = <DailyMood>[];

  @override
  List<DiaryEntry> get diaryEntries => List<DiaryEntry>.unmodifiable(_entries);

  @override
  List<DailyMood> get dailyMoods => List<DailyMood>.unmodifiable(_moods);

  @override
  DailyMood? dailyMoodForDate(DateTime date) => null;

  @override
  List<DailyMood> dailyMoodsForMonth(DateTime month) =>
      List<DailyMood>.unmodifiable(_moods);

  @override
  Future<void> autoSyncDiaryV2FromRemoteIfNeeded() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
