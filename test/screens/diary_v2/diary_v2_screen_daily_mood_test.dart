import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/models/daily_mood.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/screens/diary_v2/diary_v2_mood_visuals.dart';
import 'package:rutio/screens/diary_v2/diary_v2_screen.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  Provider.debugCheckInvalidValueType = null;

  testWidgets('selected day mood changes with the week strip and saves updates',
      (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final otherDay = today.weekday == DateTime.sunday
        ? today.subtract(const Duration(days: 1))
        : today.add(const Duration(days: 1));
    final store = _FakeDiaryV2Store(
      moods: [
        DailyMood(
          date: today,
          mood: 1,
          createdAt: 100,
          updatedAt: 100,
        ),
        DailyMood(
          date: otherDay,
          mood: -1,
          createdAt: 200,
          updatedAt: 200,
        ),
      ],
    );

    await tester.pumpWidget(_app(store: store));
    await tester.pumpAndSettle();

    expect(store.autoSyncDiaryV2FromRemoteIfNeededCalls, 1);
    expect(find.text('Estado del día'), findsOneWidget);
    expect(find.text('Bien'), findsOneWidget);

    await tester.tap(find.text(otherDay.day.toString()).first);
    await tester.pumpAndSettle();

    expect(find.text('Bajo'), findsOneWidget);

    await tester.tap(find.text(DiaryMoodVisuals.emojiFor(2)).first);
    await tester.pumpAndSettle();

    expect(store.dailyMoodForDate(otherDay)?.mood, 2);
    expect(find.text('Muy bien'), findsOneWidget);
  });
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

class _FakeDiaryV2Store extends ChangeNotifier implements UserStateStore {
  _FakeDiaryV2Store({
    required List<DailyMood> moods,
    List<DiaryEntry> entries = const <DiaryEntry>[],
  })  : entries = List<DiaryEntry>.from(entries),
        _moods = List<DailyMood>.from(moods);

  final List<DiaryEntry> entries;
  final List<DailyMood> _moods;
  int autoSyncDiaryV2FromRemoteIfNeededCalls = 0;

  @override
  List<DiaryEntry> get diaryEntries => entries;

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
  Future<void> autoSyncDiaryV2FromRemoteIfNeeded() async {
    autoSyncDiaryV2FromRemoteIfNeededCalls += 1;
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
