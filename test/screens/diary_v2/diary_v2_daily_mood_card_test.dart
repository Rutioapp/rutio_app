import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/diary_v2/diary_v2_mood_visuals.dart';
import 'package:rutio/screens/diary_v2/widgets/diary_v2_daily_mood_card.dart';

void main() {
  testWidgets('renders five standardized mood icons and selected label', (
    tester,
  ) async {
    var selectedMood = 1;

    await tester.pumpWidget(
      _app(
        child: DiaryV2DailyMoodCard(
          title: 'Estado del día',
          helperText: 'Marca cómo ha ido tu día en general.',
          selectedMood: selectedMood,
          onMoodSelected: (mood) async {
            selectedMood = mood;
          },
        ),
      ),
    );

    for (final mood in DiaryMoodVisuals.values) {
      expect(find.text(DiaryMoodVisuals.emojiFor(mood)), findsOneWidget);
    }
    expect(find.text('Bien'), findsOneWidget);
  });

  testWidgets('tapping a mood notifies selection changes', (tester) async {
    int? tappedMood;

    await tester.pumpWidget(
      _app(
        child: DiaryV2DailyMoodCard(
          title: 'Day state',
          helperText: 'Mark how your day felt overall.',
          selectedMood: null,
          onMoodSelected: (mood) async {
            tappedMood = mood;
          },
        ),
      ),
    );

    await tester.tap(find.text(DiaryMoodVisuals.emojiFor(2)));
    await tester.pumpAndSettle();

    expect(tappedMood, 2);
  });
}

Widget _app({required Widget child}) {
  return MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}
