import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/domain/models/habit_card_content_tone.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/home/widgets/habit/habit_card_swipe_shell.dart';
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

  testWidgets('emoji is left of title and check control stays right',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        HabitCardWidget(
          title: 'Hydrate',
          description: 'A glass of water',
          emoji: 'ðŸ’§',
          familyColor: Colors.cyan,
          progress: 0,
          onCheckTap: () {},
        ),
      ),
    );

    expect(
      tester.getCenter(find.byKey(const Key('habitCardEmoji'))).dx,
      lessThan(tester.getCenter(find.byKey(const Key('habitCardTitle'))).dx),
    );
    expect(
      tester.getCenter(find.byKey(const Key('habitCardTitle'))).dx,
      lessThan(
        tester.getCenter(find.byKey(const Key('habitCardCheckControl'))).dx,
      ),
    );
  });

  testWidgets('emoji is left of title and count controls stay right',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        HabitCardWidget(
          title: 'Read pages',
          description: '',
          emoji: 'ðŸ“š',
          familyColor: Colors.indigo,
          progress: 0.4,
          isCounting: true,
          currentCount: 2,
          targetCount: 5,
          onIncrement: () {},
          onDecrement: () {},
        ),
      ),
    );

    final emojiX = tester.getCenter(find.byKey(const Key('habitCardEmoji'))).dx;
    final titleX = tester.getCenter(find.byKey(const Key('habitCardTitle'))).dx;
    final decrementX = tester
        .getCenter(find.byKey(const Key('habitCardCountDecrementControl')))
        .dx;
    final valueX = tester
        .getCenter(find.byKey(const Key('habitCardCountValueControl')))
        .dx;
    final incrementX = tester
        .getCenter(find.byKey(const Key('habitCardCountIncrementControl')))
        .dx;

    expect(emojiX, lessThan(titleX));
    expect(titleX, lessThan(decrementX));
    expect(decrementX, lessThan(valueX));
    expect(valueX, lessThan(incrementX));
  });

  testWidgets('long title with emoji and trailing check does not overflow',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        const SizedBox(
          width: 260,
          child: HabitCardWidget(
            title: 'A very very long habit title that should ellipsize safely',
            description: 'Small description',
            emoji: 'ðŸ§˜',
            familyColor: Colors.green,
            progress: 0,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'check control tap toggles check callback without opening details',
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

  testWidgets('check control guards double taps while callback is pending',
      (tester) async {
    var checkTapCount = 0;
    final completer = Completer<void>();

    await tester.pumpWidget(
      _testApp(
        HabitCardWidget(
          title: 'Stretch',
          description: '5 min',
          familyColor: Colors.green,
          progress: 0,
          isCompleted: true,
          onCheckTap: () {
            checkTapCount += 1;
            return completer.future;
          },
        ),
      ),
    );

    final cardRect = tester.getRect(find.byType(HabitCardWidget));
    final checkPoint = Offset(cardRect.right - 28, cardRect.center.dy);
    await tester.tapAt(checkPoint);
    await tester.pump();
    await tester.tapAt(checkPoint);
    await tester.pump();

    expect(checkTapCount, 1);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('uncomplete does not play completion burst while pending',
      (tester) async {
    final completer = Completer<void>();

    await tester.pumpWidget(
      _testApp(
        HabitCardWidget(
          title: 'Stretch',
          description: '5 min',
          familyColor: Colors.green,
          progress: 1,
          isCompleted: true,
          completionBurstText: '+10 XP',
          onCheckTap: () => completer.future,
        ),
      ),
    );

    final cardRect = tester.getRect(find.byType(HabitCardWidget));
    await tester.tapAt(Offset(cardRect.right - 28, cardRect.center.dy));
    for (final delta in const [
      Duration(milliseconds: 16),
      Duration(milliseconds: 48),
      Duration(milliseconds: 120),
    ]) {
      await tester.pump(delta);
      expect(find.text('+10 XP'), findsNothing);
    }

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('completed card uncheck stays centered inside swipe shell',
      (tester) async {
    final completer = Completer<void>();
    var uncompleteCalls = 0;
    HabitCardRightCommitVisualState? rightCommitVisualState;

    await tester.pumpWidget(
      _testApp(
        SizedBox(
          width: 360,
          child: HabitCardSwipeShell(
            cardId: 'a',
            isOpen: false,
            compact: true,
            canSwipeRightComplete: false,
            skipLabel: 'Saltar',
            editLabel: 'Editar',
            deleteLabel: 'Eliminar',
            onRequestCloseOtherCards: (_) {},
            onRequestOpen: (_) {},
            onRequestClose: () {},
            onSwipeRightComplete: (visualState) async {
              rightCommitVisualState = visualState;
            },
            onSkip: (_) async {},
            onEdit: null,
            onDelete: () async {},
            child: HabitCardWidget(
              title: 'Stretch',
              description: '5 min',
              familyColor: Colors.green,
              progress: 1,
              isCompleted: true,
              compact: true,
              completionBurstText: '+10 XP',
              onCheckTap: () {
                uncompleteCalls += 1;
                return completer.future;
              },
            ),
          ),
        ),
      ),
    );

    final cardRect = tester.getRect(find.byType(HabitCardWidget));
    await tester.tapAt(Offset(cardRect.right - 28, cardRect.center.dy));
    await tester.pump();

    expect(uncompleteCalls, 1);
    expect(rightCommitVisualState, isNull);
    expect(find.byKey(const Key('habitCardRightCommitFeedback')), findsNothing);
    expect(find.byIcon(CupertinoIcons.check_mark_circled_solid), findsNothing);
    expect(find.byType(HabitCardWidget), findsOneWidget);
    expect(_swipeShellCardOffsetX(tester), closeTo(0, 0.1));

    for (final delta in const [
      Duration(milliseconds: 16),
      Duration(milliseconds: 48),
      Duration(milliseconds: 120),
    ]) {
      await tester.pump(delta);
      expect(uncompleteCalls, 1);
      expect(rightCommitVisualState, isNull);
      expect(
        find.byKey(const Key('habitCardRightCommitFeedback')),
        findsNothing,
      );
      expect(find.text('+10 XP'), findsNothing);
      expect(_swipeShellCardOffsetX(tester), closeTo(0, 0.1));
    }

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('complete still plays the completion burst on false to true',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        HabitCardWidget(
          title: 'Stretch',
          description: '5 min',
          familyColor: Colors.green,
          progress: 0,
          isCompleted: false,
          completionBurstText: '+10 XP',
        ),
      ),
    );

    await tester.pumpWidget(
      _testApp(
        HabitCardWidget(
          title: 'Stretch',
          description: '5 min',
          familyColor: Colors.green,
          progress: 1,
          isCompleted: true,
          completionBurstText: '+10 XP',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('+10 XP'), findsOneWidget);
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

  testWidgets('habit card draws a single outer border above its content',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        HabitCardWidget(
          title: 'Read',
          description: '20 min',
          familyColor: Colors.blue,
          progress: 0,
          backgroundImageAssetPath:
              'assets/shop/habit_cards/common/habit_card_rutio_beige.webp',
        ),
      ),
    );

    final outer = _habitCardShell(tester);
    final outerDecoration = outer.foregroundDecoration as BoxDecoration;
    final outerBorder = outerDecoration.border as Border;
    final clip = _habitCardClip(tester);

    expect(outer.decoration, isA<BoxDecoration>());
    expect((outer.decoration as BoxDecoration).border, isNull);
    expect(outerDecoration.borderRadius, BorderRadius.circular(20));
    expect(outerBorder.top.width, 1.0);
    expect(outerBorder.top.color, const Color(0x57FFFFFF));
    expect(outerBorder.bottom.width, 1.0);
    expect(clip.borderRadius, BorderRadius.circular(19));
    expect(
      _habitCardBorderPadding(tester).padding,
      const EdgeInsets.all(1.0),
    );
  });

  testWidgets('habit card keeps the same border shell for check and count',
      (tester) async {
    Future<void> pumpCard({required bool isCounting}) async {
      await tester.pumpWidget(
        _testApp(
          HabitCardWidget(
            title: isCounting ? 'Water' : 'Read',
            description: isCounting ? '' : '20 min',
            familyColor: Colors.indigo,
            progress: isCounting ? 0.4 : 0,
            isCounting: isCounting,
            currentCount: isCounting ? 2 : 0,
            targetCount: isCounting ? 5 : 1,
          ),
        ),
      );
    }

    await pumpCard(isCounting: false);
    expect(
      (_habitCardShell(tester).foregroundDecoration as BoxDecoration)
          .borderRadius,
      BorderRadius.circular(20),
    );
    expect(_habitCardClip(tester).borderRadius, BorderRadius.circular(19));

    await pumpCard(isCounting: true);
    expect(
      (_habitCardShell(tester).foregroundDecoration as BoxDecoration)
          .borderRadius,
      BorderRadius.circular(20),
    );
    expect(_habitCardClip(tester).borderRadius, BorderRadius.circular(19));
  });

  testWidgets('habit card defaults to dark content tone without scrim',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        HabitCardWidget(
          title: 'Read',
          description: '20 min',
          familyColor: Colors.blue,
          progress: 0,
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('Read'));
    final description = tester.widget<Text>(find.text('20 min'));

    expect(find.byKey(const Key('habitCardContentScrim')), findsNothing);
    expect(title.style?.color, const Color(0xFF25221F));
    expect(description.style?.color, const Color(0xB325221F));
  });

  testWidgets('habit card applies light content tone and scrim when configured',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        HabitCardWidget(
          title: 'Moon walk',
          description: 'Night focus',
          familyColor: Colors.deepPurple,
          progress: 0.5,
          contentTone: HabitCardContentTone.light,
          useContentScrim: true,
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('Moon walk'));
    final description = tester.widget<Text>(find.text('Night focus'));

    expect(find.byKey(const Key('habitCardContentScrim')), findsOneWidget);
    expect(title.style?.color, const Color(0xFFF9F7F2));
    expect(title.style?.shadows, isNotEmpty);
    expect(description.style?.color, const Color(0xD9F9F7F2));
  });
}

Container _habitCardShell(WidgetTester tester) {
  final containers = tester.widgetList<Container>(
    find.descendant(
      of: find.byType(HabitCardWidget),
      matching: find.byType(Container),
    ),
  );

  return containers.firstWhere((container) {
    final foreground = container.foregroundDecoration;
    if (foreground is! BoxDecoration) return false;
    return foreground.border is Border;
  });
}

ClipRRect _habitCardClip(WidgetTester tester) {
  return tester.widget<ClipRRect>(
    find.descendant(
      of: find.byType(HabitCardWidget),
      matching: find.byType(ClipRRect),
    ),
  );
}

Padding _habitCardBorderPadding(WidgetTester tester) {
  final paddingFinder = find.descendant(
    of: find.byType(HabitCardWidget),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Padding &&
          widget.padding is EdgeInsets &&
          (widget.padding as EdgeInsets).left == 1.0 &&
          (widget.padding as EdgeInsets).top == 1.0,
    ),
  );

  return tester.widget<Padding>(paddingFinder.first);
}

double _swipeShellCardOffsetX(WidgetTester tester) {
  final transformFinder = find.ancestor(
    of: find.byType(HabitCardWidget),
    matching: find.byType(Transform),
  );
  final transform = tester.widget<Transform>(transformFinder.first);
  return transform.transform.getTranslation().x;
}
