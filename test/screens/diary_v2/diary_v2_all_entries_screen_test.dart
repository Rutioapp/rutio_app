import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/models/daily_mood.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/screens/diary_v2/diary_v2_all_entries_screen.dart';

void main() {
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
    });
  });
}

Widget _app({required Widget child}) {
  return MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
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
