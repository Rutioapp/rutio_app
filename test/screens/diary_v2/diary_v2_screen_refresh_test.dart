import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/models/daily_mood.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/screens/diary_v2/diary_v2_screen.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  Provider.debugCheckInvalidValueType = null;
  final now = DateTime.now().millisecondsSinceEpoch;

  testWidgets('pull-to-refresh triggers Diary V2 remote sync', (tester) async {
    final store = _FakeDiaryV2Store(
      entries: <DiaryEntry>[
        DiaryEntry(
          id: 'entry-1',
          createdAt: now,
          text: 'Morning reset',
          mood: 1,
        ),
      ],
    );

    await tester.pumpWidget(_app(store: store));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(store.syncDiaryV2FromRemoteBestEffortCalls, 1);
  });

  testWidgets('pull-to-refresh failure keeps local Diary V2 content intact', (
    tester,
  ) async {
    final store = _FakeDiaryV2Store(
      entries: <DiaryEntry>[
        DiaryEntry(
          id: 'entry-1',
          createdAt: now,
          text: 'Morning reset',
          title: 'Morning reset',
          body: 'Still here after refresh failure',
          mood: -1,
        ),
      ],
      syncDiaryV2FromRemoteBestEffortError: StateError('offline'),
    );

    await tester.pumpWidget(_app(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Morning reset'), findsOneWidget);
    expect(find.text('Still here after refresh failure'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(store.syncDiaryV2FromRemoteBestEffortCalls, 1);
    expect(find.text('Morning reset'), findsOneWidget);
    expect(find.text('Still here after refresh failure'), findsOneWidget);
  });
}

Widget _app({required UserStateStore store}) {
  return ChangeNotifierProvider<UserStateStore>.value(
    value: store,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MediaQuery(
        data: MediaQueryData(size: Size(430, 932)),
        child: DiaryV2Screen(),
      ),
    ),
  );
}

class _FakeDiaryV2Store extends ChangeNotifier implements UserStateStore {
  _FakeDiaryV2Store({
    List<DiaryEntry> entries = const <DiaryEntry>[],
    List<DailyMood> moods = const <DailyMood>[],
    this.syncDiaryV2FromRemoteBestEffortError,
  })  : _entries = List<DiaryEntry>.from(entries),
        _moods = List<DailyMood>.from(moods);

  final List<DiaryEntry> _entries;

  final List<DailyMood> _moods;
  final Object? syncDiaryV2FromRemoteBestEffortError;

  int syncDiaryV2FromRemoteBestEffortCalls = 0;

  @override
  List<DiaryEntry> get diaryEntries => List<DiaryEntry>.unmodifiable(_entries);

  @override
  List<DailyMood> get dailyMoods => List<DailyMood>.unmodifiable(_moods);

  @override
  DailyMood? dailyMoodForDate(DateTime date) {
    final key = _dateKey(date);
    for (final mood in _moods) {
      if (_dateKey(mood.date) == key) {
        return mood;
      }
    }
    return null;
  }

  @override
  List<DailyMood> dailyMoodsForMonth(DateTime month) {
    return _moods
        .where(
          (mood) =>
              mood.date.year == month.year && mood.date.month == month.month,
        )
        .toList(growable: false);
  }

  @override
  Future<void> setDailyMood(DailyMood dailyMood) async {
    final existingIndex = _moods.indexWhere(
      (mood) => _dateKey(mood.date) == _dateKey(dailyMood.date),
    );
    if (existingIndex >= 0) {
      _moods[existingIndex] = dailyMood;
    } else {
      _moods.add(dailyMood);
    }
    notifyListeners();
  }

  @override
  Future<void> syncDiaryV2FromRemoteBestEffort() async {
    syncDiaryV2FromRemoteBestEffortCalls += 1;
    if (syncDiaryV2FromRemoteBestEffortError != null) {
      throw syncDiaryV2FromRemoteBestEffortError!;
    }
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
