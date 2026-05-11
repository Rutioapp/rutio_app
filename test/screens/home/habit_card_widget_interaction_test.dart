import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/home/widgets/habit/habit_card_widget.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('main card tap opens details on stats/progress tab by default',
      (tester) async {
    int? openedTab;
    var editTapCount = 0;

    await tester.pumpWidget(
      _testApp(
        HabitCardWidget(
          title: 'Read',
          description: '20 min',
          familyColor: Colors.blue,
          progress: 0,
          onOpenDetails: (initialTab) => openedTab = initialTab,
          onEditTap: () => editTapCount += 1,
        ),
      ),
    );

    await tester.tap(find.text('Read'));
    await tester.pumpAndSettle();

    expect(openedTab, 1);
    expect(editTapCount, 0);
  });

  testWidgets('emoji tap keeps its own callback and does not open details',
      (tester) async {
    var emojiTapCount = 0;
    var openDetailCount = 0;

    await tester.pumpWidget(
      _testApp(
        HabitCardWidget(
          title: 'Hydrate',
          description: '',
          emoji: '💧',
          onEmojiTap: () => emojiTapCount += 1,
          familyColor: Colors.cyan,
          progress: 0,
          onOpenDetails: (_) => openDetailCount += 1,
        ),
      ),
    );

    await tester.tap(find.text('💧'));
    await tester.pumpAndSettle();

    expect(emojiTapCount, 1);
    expect(openDetailCount, 0);
  });

  testWidgets('check control tap toggles check callback without opening details',
      (tester) async {
    var checkTapCount = 0;
    var openDetailCount = 0;

    await tester.pumpWidget(
      _testApp(
        HabitCardWidget(
          title: 'Stretch',
          description: '5 min',
          familyColor: Colors.green,
          progress: 0,
          onCheckTap: () => checkTapCount += 1,
          onOpenDetails: (_) => openDetailCount += 1,
        ),
      ),
    );

    final cardRect = tester.getRect(find.byType(HabitCardWidget));
    await tester.tapAt(Offset(cardRect.right - 28, cardRect.center.dy));
    await tester.pumpAndSettle();

    expect(checkTapCount, 1);
    expect(openDetailCount, 0);
  });

  testWidgets(
      'count controls keep separate callbacks and main body tap opens details',
      (tester) async {
    var incrementTapCount = 0;
    var decrementTapCount = 0;
    var countTapCount = 0;
    var openDetailCount = 0;

    await tester.pumpWidget(
      _testApp(
        HabitCardWidget(
          title: 'Water',
          description: '',
          familyColor: Colors.indigo,
          progress: 0.4,
          isCounting: true,
          currentCount: 2,
          targetCount: 5,
          onIncrement: () => incrementTapCount += 1,
          onDecrement: () => decrementTapCount += 1,
          onCountTap: () => countTapCount += 1,
          onOpenDetails: (_) => openDetailCount += 1,
        ),
      ),
    );

    await tester.tap(find.byIcon(CupertinoIcons.add));
    await tester.pumpAndSettle();
    expect(incrementTapCount, 1);
    expect(openDetailCount, 0);

    await tester.tap(find.byIcon(CupertinoIcons.minus));
    await tester.pumpAndSettle();
    expect(decrementTapCount, 1);
    expect(openDetailCount, 0);

    await tester.tap(find.text('2/5'));
    await tester.pumpAndSettle();
    expect(countTapCount, 1);
    expect(openDetailCount, 0);

    await tester.tap(find.text('Water'));
    await tester.pumpAndSettle();
    expect(openDetailCount, 1);
  });
}
