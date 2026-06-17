import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/models/daily_mood.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/screens/diary_v2/diary_v2_day_entries_screen.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  Provider.debugCheckInvalidValueType = null;

  testWidgets('tapping a day entry opens the detail screen',
      (tester) async {
    final entry = DiaryEntry(
      id: 'day-1',
      createdAt: DateTime(2026, 6, 17, 9, 30).millisecondsSinceEpoch,
      text: 'Morning note\n\nBody text',
      title: 'Morning note',
      body: 'Body text',
      mood: 1,
      tags: const <String>['gratitude'],
    );

    await tester.pumpWidget(
      _app(
        store: _DayEntriesStore(entries: [entry]),
        child: DiaryV2DayEntriesScreen(
          title: 'Day entries',
          dateLabel: 'June 17, 2026',
          selectedDay: DateTime(2026, 6, 17),
          entries: diaryV2DayEntryItemsForDate(
            entries: [entry],
            selectedDay: DateTime(2026, 6, 17),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Morning note'));
    await tester.pumpAndSettle();

    expect(find.text('Your entry'), findsOneWidget);
    expect(find.text('Morning note'), findsOneWidget);
    expect(find.text('Body text'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Gratitude'), findsOneWidget);
  });
}

Widget _app({
  required Widget child,
  required UserStateStore store,
}) {
  return Provider<UserStateStore>.value(
    value: store,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

class _DayEntriesStore extends ChangeNotifier implements UserStateStore {
  _DayEntriesStore({required this.entries});

  final List<DiaryEntry> entries;

  @override
  List<DiaryEntry> get diaryEntries => entries;

  @override
  List<DailyMood> get dailyMoods => const <DailyMood>[];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
