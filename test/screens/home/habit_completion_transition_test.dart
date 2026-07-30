import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:rutio/screens/home/widgets/habit/habit_card_status_feedback.dart';
import 'package:rutio/screens/home/widgets/habit/habit_card_swipe_shell.dart';

void main() {
  test('status feedback motion uses calmer phase 6B.1 timings', () {
    expect(HabitCardStatusFeedbackMotionConfig.completedHoldDuration,
        const Duration(milliseconds: 100));
    expect(HabitCardStatusFeedbackMotionConfig.skippedHoldDuration,
        const Duration(milliseconds: 210));
    expect(HabitCardStatusFeedbackMotionConfig.completedCollapseDuration,
        const Duration(milliseconds: 300));
    expect(HabitCardStatusFeedbackMotionConfig.skippedCollapseDuration,
        const Duration(milliseconds: 290));
    expect(HabitCardStatusFeedbackMotionConfig.springStiffness, 400);
    expect(HabitCardStatusFeedbackMotionConfig.springDamping, 42);
    expect(
        HabitCardStatusFeedbackMotionConfig.skippedEntrySpringStiffness, 280);
    expect(HabitCardStatusFeedbackMotionConfig.skippedEntrySpringDamping, 38);
    expect(HabitCardStatusFeedbackMotionConfig.fadeStartCollapseFraction,
        greaterThanOrEqualTo(0.60));
    expect(HabitCardStatusFeedbackMotionConfig.statusIconHorizontalInset, 24);
    expect(HabitCardStatusFeedbackMotionConfig.tickRevealStartFraction, 0.10);
    expect(HabitCardStatusFeedbackMotionConfig.tickRevealEndFraction, 0.75);
    expect(HabitCardStatusFeedbackMotionConfig.tickInitialScale, 0.94);
    expect(HabitCardStatusFeedbackMotionConfig.tickFinalScale, 1);
  });

  testWidgets('status feedback renders completed and skipped variants',
      (tester) async {
    const completedKey = ValueKey('completed_feedback');
    const skippedKey = ValueKey('skipped_feedback');

    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            SizedBox(
              height: 88,
              child: HabitCardStatusFeedback(
                key: completedKey,
                kind: HomeHabitStatusFeedbackKind.completed,
              ),
            ),
            SizedBox(
              height: 88,
              child: HabitCardStatusFeedback(
                key: skippedKey,
                kind: HomeHabitStatusFeedbackKind.skipped,
              ),
            ),
          ],
        ),
      ),
    );

    expect(
        find.byIcon(CupertinoIcons.check_mark_circled_solid), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.forward_end_fill), findsOneWidget);
    expect(find.text('Hecho'), findsNothing);
    expect(find.text('Saltado'), findsNothing);
    expect(find.byType(HabitCardSwipeShell), findsNothing);

    final completedDecoration = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(completedKey),
        matching: find.byType(DecoratedBox),
      ),
    );
    final skippedDecoration = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(skippedKey),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      (completedDecoration.decoration as BoxDecoration).color,
      isNot((skippedDecoration.decoration as BoxDecoration).color),
    );
    expect(
      (completedDecoration.decoration as BoxDecoration).color,
      HabitCardStatusFeedback.completedBackground,
    );
    expect(
      (completedDecoration.decoration as BoxDecoration).color,
      isNot(HabitCardStatusFeedback.previousCompletedBackground),
    );
    expect(
      (skippedDecoration.decoration as BoxDecoration).color,
      HabitCardStatusFeedback.skippedBackground,
    );
    expect(
      (skippedDecoration.decoration as BoxDecoration).color,
      isNot(HabitCardStatusFeedback.previousSkippedBackground),
    );

    final completedIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(completedKey),
        matching: find.byIcon(CupertinoIcons.check_mark_circled_solid),
      ),
    );
    final skippedIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(skippedKey),
        matching: find.byIcon(CupertinoIcons.forward_end_fill),
      ),
    );
    expect(completedIcon.color, HabitCardStatusFeedback.completedIcon);
    expect(skippedIcon.color, HabitCardStatusFeedback.skippedIcon);
  });

  testWidgets('completion snapshot is visual-only and uses a temporary key',
      (tester) async {
    final transition = _transition('a', originalIndex: 0, initialOffsetX: 190);
    final dismissed = <String>[];

    await tester.pumpWidget(
      _testApp(
        transitions: [transition],
        onDismissed: ({required habitId, required transitionId}) {
          dismissed.add('$transitionId:$habitId');
        },
      ),
    );

    expect(find.byKey(transition.widgetKey), findsOneWidget);
    expect(find.byKey(_feedbackKey(transition)), findsOneWidget);
    expect(find.byKey(const ValueKey('habit_pending_a')), findsNothing);
    expect(find.byKey(const ValueKey('habit_done_a')), findsNothing);
    expect(find.byType(HabitCardSwipeShell), findsNothing);
    expect(_transitionOffsetX(tester, 'a'), closeTo(190, 0.1));
    final ignorePointers = tester.widgetList<IgnorePointer>(
      find.ancestor(
        of: find.byKey(const ValueKey('transition_visual_a')),
        matching: find.byType(IgnorePointer),
      ),
    );
    expect(ignorePointers.any((widget) => widget.ignoring), isTrue);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('transition_visual_a')),
        matching: find.byType(ReorderableDelayedDragStartListener),
      ),
      findsNothing,
    );
    expect(dismissed, isEmpty);
  });

  testWidgets('completed feedback stays fixed while foreground exits',
      (tester) async {
    final transition = _transition('a', originalIndex: 0, initialOffsetX: 190);

    await tester.pumpWidget(_testApp(transitions: [transition]));

    final feedbackLeft =
        tester.getTopLeft(find.byKey(_feedbackKey(transition))).dx;
    expect(feedbackLeft, closeTo(0, 0.1));

    await tester.pump(const Duration(milliseconds: 70));

    expect(_transitionOffsetX(tester, 'a'), greaterThan(190));
    expect(tester.getTopLeft(find.byKey(_feedbackKey(transition))).dx,
        closeTo(feedbackLeft, 0.1));
    expect(
        find.byIcon(CupertinoIcons.check_mark_circled_solid), findsOneWidget);
  });

  testWidgets('completed handoff keeps tick left inset opacity and scale',
      (tester) async {
    final transition = _transition(
      'a',
      originalIndex: 0,
      initialOffsetX: 40,
      velocityX: 0,
      rightRevealProgress: 0.25,
    );

    await tester.pumpWidget(_testApp(transitions: [transition]));

    final feedbackLeft =
        tester.getTopLeft(find.byKey(_feedbackKey(transition))).dx;
    final feedbackCenter =
        tester.getCenter(find.byKey(_feedbackKey(transition))).dx;
    final iconCenter =
        tester.getCenter(find.byKey(const Key('habitCardStatusFeedbackIcon')));
    final iconOpacity = _statusIconOpacity(tester);
    final iconScale = _statusIconScale(tester);

    expect(
      iconCenter.dx,
      closeTo(
        feedbackLeft +
            HabitCardStatusFeedbackMotionConfig.statusIconHorizontalInset +
            16,
        0.1,
      ),
    );
    expect(iconCenter.dx, lessThan(feedbackCenter));
    expect(iconOpacity, greaterThan(0));
    expect(iconOpacity, lessThan(1));
    expect(iconScale, greaterThanOrEqualTo(0.94));
    expect(iconScale, lessThan(1));
  });

  testWidgets('completion snapshot keeps space before it exits',
      (tester) async {
    final transition = _transition('a', originalIndex: 0, initialOffsetX: 190);

    await tester.pumpWidget(
      _testApp(
        pendingHabits: [_habit('b')],
        transitions: [transition],
      ),
    );

    final transitionTop =
        tester.getTopLeft(find.byKey(const ValueKey('transition_visual_a'))).dy;
    final nextCardTop =
        tester.getTopLeft(find.byKey(const ValueKey('habit_visual_b'))).dy;

    expect(nextCardTop - transitionTop, greaterThan(70));

    await tester.pump(const Duration(milliseconds: 20));
    final nextCardEarly =
        tester.getTopLeft(find.byKey(const ValueKey('habit_visual_b'))).dy;
    expect(nextCardEarly, closeTo(nextCardTop, 0.1));
  });

  testWidgets('completion snapshot exits right before height collapses',
      (tester) async {
    final transition = _transition('a', originalIndex: 0, initialOffsetX: 190);

    await tester.pumpWidget(
      _testApp(
        pendingHabits: [_habit('b')],
        transitions: [transition],
      ),
    );

    final initialNextCardTop =
        tester.getTopLeft(find.byKey(const ValueKey('habit_visual_b'))).dy;
    expect(_transitionOffsetX(tester, 'a'), closeTo(190, 0.1));

    await tester.pump(const Duration(milliseconds: 70));
    final midExitOffset = _transitionOffsetX(tester, 'a');
    final midExitNextCardTop =
        tester.getTopLeft(find.byKey(const ValueKey('habit_visual_b'))).dy;
    expect(midExitOffset, greaterThan(190));
    expect(midExitOffset, lessThanOrEqualTo(384));
    expect(midExitNextCardTop, closeTo(initialNextCardTop, 0.1));

    await tester.pumpAndSettle();
    final midCollapseNextCardTop =
        tester.getTopLeft(find.byKey(const ValueKey('habit_visual_b'))).dy;
    expect(midCollapseNextCardTop, lessThan(initialNextCardTop));
    expect(midCollapseNextCardTop, greaterThanOrEqualTo(0));
  });

  testWidgets('completed feedback holds full height before a late fade',
      (tester) async {
    final transition = _transition(
      'a',
      originalIndex: 0,
      initialOffsetX: 383,
      velocityX: 0,
    );

    await tester.pumpWidget(
      _testApp(
        pendingHabits: [_habit('b')],
        transitions: [transition],
      ),
    );

    final initialNextCardTop =
        tester.getTopLeft(find.byKey(const ValueKey('habit_visual_b'))).dy;

    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump(
      HabitCardStatusFeedbackMotionConfig.completedHoldDuration ~/ 2,
    );

    expect(_transitionSizeFactor(tester, transition), closeTo(1, 0.01));
    expect(_feedbackOpacity(tester, transition), closeTo(1, 0.01));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('habit_visual_b'))).dy,
      closeTo(initialNextCardTop, 0.1),
    );

    await _pumpUntilCollapseStarts(tester, transition);

    final midCollapseTop =
        tester.getTopLeft(find.byKey(const ValueKey('habit_visual_b'))).dy;
    expect(_transitionSizeFactor(tester, transition), inExclusiveRange(0, 1));
    expect(midCollapseTop, inExclusiveRange(0, initialNextCardTop));
    expect(_feedbackOpacity(tester, transition), greaterThan(0.95));
  });

  testWidgets('skipped snapshot exits left and keeps the real card suppressed',
      (tester) async {
    final transition = _transition(
      'a',
      originalIndex: 0,
      kind: HomeHabitStatusFeedbackKind.skipped,
      initialOffsetX: -234,
      velocityX: 0,
    );

    await tester.pumpWidget(
      _testApp(
        pendingHabits: [_habit('a'), _habit('b')],
        transitions: [transition],
      ),
    );

    expect(find.byKey(transition.widgetKey), findsOneWidget);
    expect(find.byKey(_feedbackKey(transition)), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.forward_end_fill), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.check_mark_circled_solid), findsNothing);
    final feedbackRight =
        tester.getTopRight(find.byKey(_feedbackKey(transition))).dx;
    final iconCenter =
        tester.getCenter(find.byKey(const Key('habitCardStatusFeedbackIcon')));
    expect(
      iconCenter.dx,
      closeTo(
        feedbackRight -
            HabitCardStatusFeedbackMotionConfig.statusIconHorizontalInset -
            16,
        0.1,
      ),
    );
    expect(find.byKey(const ValueKey('habit_visual_a')), findsNothing);
    expect(find.byType(SliverReorderableList), findsNothing);
    expect(_transitionOffsetX(tester, 'a'), closeTo(-234, 0.1));

    await tester.pump(const Duration(milliseconds: 70));

    expect(_transitionOffsetX(tester, 'a'), lessThan(-234));
    expect(_transitionOffsetX(tester, 'a'), greaterThanOrEqualTo(-384));
    expect(find.byKey(const ValueKey('habit_visual_a')), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('habit_visual_a')), findsNothing);
    expect(find.byKey(const ValueKey('habit_visual_b')), findsOneWidget);
  });

  testWidgets('skipped feedback enters from the right before hold and collapse',
      (tester) async {
    final transition = _transition(
      'a',
      originalIndex: 0,
      kind: HomeHabitStatusFeedbackKind.skipped,
      initialOffsetX: -383,
      velocityX: 0,
    );

    await tester.pumpWidget(
      _testApp(
        pendingHabits: [_habit('b')],
        transitions: [transition],
      ),
    );

    final initialNextCardTop =
        tester.getTopLeft(find.byKey(const ValueKey('habit_visual_b'))).dy;
    final feedbackStartOffset =
        transition.cardWidth + homeHabitStatusFeedbackExitMargin;

    expect(_feedbackTransitionOffsetX(tester, transition),
        closeTo(feedbackStartOffset, 0.1));
    expect(_transitionOffsetX(tester, 'a'), closeTo(-383, 0.1));

    final offsets = <double>[_feedbackTransitionOffsetX(tester, transition)];

    for (final delta in const [
      Duration(milliseconds: 60),
      Duration(milliseconds: 60),
      Duration(milliseconds: 60),
      Duration(milliseconds: 60),
    ]) {
      await tester.pump(delta);
      offsets.add(_feedbackTransitionOffsetX(tester, transition));
    }

    expect(offsets[3], inExclusiveRange(0, feedbackStartOffset));
    expect(offsets[3], greaterThan(24));
    for (var index = 1; index < offsets.length; index += 1) {
      expect(offsets[index], lessThanOrEqualTo(offsets[index - 1]));
      expect(offsets[index], inInclusiveRange(0, feedbackStartOffset));
    }
    expect(_transitionSizeFactor(tester, transition), closeTo(1, 0.01));
    expect(_feedbackOpacity(tester, transition), closeTo(1, 0.01));

    await _pumpUntilFeedbackCentered(tester, transition);
    await tester.pump(
      HabitCardStatusFeedbackMotionConfig.skippedHoldDuration ~/ 2,
    );

    expect(_transitionSizeFactor(tester, transition), closeTo(1, 0.01));
    expect(_feedbackOpacity(tester, transition), closeTo(1, 0.01));
    expect(_feedbackTransitionOffsetX(tester, transition), closeTo(0, 0.5));

    await _pumpUntilCollapseStarts(tester, transition);

    expect(_transitionSizeFactor(tester, transition), inExclusiveRange(0, 1));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('habit_visual_b'))).dy,
      inExclusiveRange(0, initialNextCardTop),
    );
    expect(_feedbackOpacity(tester, transition), greaterThan(0.95));
  });

  testWidgets('skipped handoff starts offscreen right with full icon',
      (tester) async {
    final transition = _transition(
      'a',
      originalIndex: 0,
      kind: HomeHabitStatusFeedbackKind.skipped,
      initialOffsetX: -60,
      velocityX: 0,
      leftRevealProgress: 0.25,
    );

    await tester.pumpWidget(_testApp(transitions: [transition]));

    final feedbackStartOffset =
        transition.cardWidth + homeHabitStatusFeedbackExitMargin;
    final feedbackRight =
        tester.getTopRight(find.byKey(_feedbackKey(transition))).dx;
    final feedbackCenter =
        tester.getCenter(find.byKey(_feedbackKey(transition))).dx;
    final iconCenter =
        tester.getCenter(find.byKey(const Key('habitCardStatusFeedbackIcon')));
    final iconOpacity = _statusIconOpacity(tester);
    final iconScale = _statusIconScale(tester);

    expect(_feedbackTransitionOffsetX(tester, transition),
        closeTo(feedbackStartOffset, 0.1));
    expect(_transitionOffsetX(tester, 'a'), closeTo(-60, 0.1));
    expect(
      iconCenter.dx,
      closeTo(
        feedbackRight -
            HabitCardStatusFeedbackMotionConfig.statusIconHorizontalInset -
            16,
        0.1,
      ),
    );
    expect(iconCenter.dx, greaterThan(feedbackCenter));
    expect(iconOpacity, 1);
    expect(iconScale, 1);

    await tester.pump(const Duration(milliseconds: 16));

    expect(_feedbackTransitionOffsetX(tester, transition),
        lessThan(feedbackStartOffset));
  });

  testWidgets('completion snapshot dismisses itself after the transition',
      (tester) async {
    final transition = _transition('a', originalIndex: 0);
    final dismissed = <String>[];

    await tester.pumpWidget(
      _testApp(
        transitions: [transition],
        onDismissed: ({required habitId, required transitionId}) {
          dismissed.add('$transitionId:$habitId');
        },
      ),
    );

    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(transition.widgetKey), findsOneWidget);
    expect(dismissed, isEmpty);

    await tester.pumpAndSettle();
    expect(dismissed, ['t-a:a']);
  });

  testWidgets('two completion snapshots do not overwrite each other',
      (tester) async {
    final first = _transition('a', originalIndex: 0);
    final second = _transition('b', originalIndex: 1);
    final dismissed = <String>[];

    await tester.pumpWidget(
      _testApp(
        pendingHabits: const [],
        transitions: [first, second],
        onDismissed: ({required habitId, required transitionId}) {
          dismissed.add('$transitionId:$habitId');
        },
      ),
    );

    expect(find.byKey(first.widgetKey), findsOneWidget);
    expect(find.byKey(second.widgetKey), findsOneWidget);

    await tester.pumpAndSettle();
    expect(dismissed.toSet(), {'t-a:a', 't-b:b'});
  });

  testWidgets('real pending list keeps reorder only when no snapshot is active',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        pendingHabits: [_habit('a'), _habit('b')],
      ),
    );
    expect(find.byType(SliverReorderableList), findsOneWidget);
    expect(find.byType(ReorderableDelayedDragStartListener), findsNWidgets(2));

    await tester.pumpWidget(
      _testApp(
        pendingHabits: [_habit('b')],
        transitions: [_transition('a', originalIndex: 0)],
      ),
    );
    expect(find.byType(SliverReorderableList), findsNothing);
    expect(find.byType(ReorderableDelayedDragStartListener), findsNothing);
  });

  testWidgets('active snapshot suppresses the real pending card as a tombstone',
      (tester) async {
    final transition = _transition('a', originalIndex: 0);
    final visualCompleted = <String>[];

    await tester.pumpWidget(
      _testApp(
        pendingHabits: [_habit('a'), _habit('b')],
        transitions: [transition],
        onDismissed: ({required habitId, required transitionId}) {
          visualCompleted.add('$transitionId:$habitId');
        },
      ),
    );

    expect(find.byKey(transition.widgetKey), findsOneWidget);
    expect(find.byKey(const ValueKey('transition_visual_a')), findsOneWidget);
    expect(find.byKey(const ValueKey('habit_visual_a')), findsNothing);
    expect(find.byKey(const ValueKey('habit_visual_b')), findsOneWidget);

    await tester.pumpAndSettle();

    expect(visualCompleted, ['t-a:a']);
    expect(find.byKey(const ValueKey('habit_visual_a')), findsNothing);
    expect(find.byKey(const ValueKey('habit_visual_b')), findsOneWidget);
  });

  testWidgets('completion snapshot carries right-commit velocity into exit',
      (tester) async {
    final slow = _transition(
      'a',
      originalIndex: 0,
      initialOffsetX: 180,
      velocityX: 0,
    );
    final fast = _transition(
      'c',
      originalIndex: 0,
      initialOffsetX: 180,
      velocityX: 2400,
    );

    await tester.pumpWidget(_testApp(transitions: [slow]));
    await tester.pump(const Duration(milliseconds: 16));
    final slowOffset = _transitionOffsetX(tester, 'a');

    await tester.pumpWidget(_testApp(transitions: [fast]));
    await tester.pump(const Duration(milliseconds: 16));
    final fastOffset = _transitionOffsetX(tester, 'c');

    expect(fastOffset, greaterThan(slowOffset));
  });

  testWidgets('completion snapshot horizontal offset never moves backwards',
      (tester) async {
    final transition = _transition(
      'a',
      originalIndex: 0,
      initialOffsetX: 180,
      velocityX: 2400,
    );

    await tester.pumpWidget(_testApp(transitions: [transition]));
    final offsets = <double>[_transitionOffsetX(tester, 'a')];

    for (final delta in const [
      Duration(milliseconds: 16),
      Duration(milliseconds: 24),
      Duration(milliseconds: 40),
      Duration(milliseconds: 80),
    ]) {
      await tester.pump(delta);
      offsets.add(_transitionOffsetX(tester, 'a'));
    }

    expect(offsets.first, closeTo(180, 0.1));
    for (var index = 1; index < offsets.length; index += 1) {
      expect(offsets[index], greaterThanOrEqualTo(offsets[index - 1]));
    }
    expect(offsets.last, lessThanOrEqualTo(transition.exitOffsetX));
  });
}

Widget _testApp({
  List<Map<String, dynamic>>? pendingHabits,
  List<HomeHabitCompletionTransition> transitions = const [],
  void Function({
    required String habitId,
    required String transitionId,
  })? onDismissed,
}) {
  final pending = pendingHabits ?? [_habit('b')];
  return MaterialApp(
    home: Scaffold(
      body: CustomScrollView(
        slivers: [
          HomeHabitsSliver(
            viewHabits: [
              ...pending,
              for (final t in transitions) t.habitSnapshot
            ],
            pendingHabits: pending,
            completedHabits: const [],
            skippedHabits: const [],
            completionTransitions: transitions,
            showCompleted: false,
            showSkipped: false,
            habitCardBuilder: (context, habit, {bool compact = false}) {
              final id = habit['id'].toString();
              return _box(
                key: ValueKey('habit_visual_$id'),
                label: 'Habit $id',
                height: compact ? 68 : 88,
              );
            },
            completionTransitionBuilder: (context, transition) {
              return _box(
                key: ValueKey('transition_visual_${transition.habitId}'),
                label: 'Transition ${transition.habitId}',
                height: 88,
              );
            },
            onCompletionTransitionDismissed:
                onDismissed ?? ({required habitId, required transitionId}) {},
            completedHeaderBuilder: (count) => Text('Completed $count'),
            skippedHeaderBuilder: (count) => Text('Skipped $count'),
            onPendingReorder: (_, __) async {},
            onCompletedReorder: (_, __) async {},
            onSkippedReorder: (_, __) async {},
          ),
        ],
      ),
    ),
  );
}

Widget _box({
  required Key key,
  required String label,
  required double height,
}) {
  return Container(
    key: key,
    height: height,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    color: Colors.white,
    child: Text(label),
  );
}

Map<String, dynamic> _habit(String id) {
  return {
    'id': id,
    'title': 'Habit $id',
    'type': 'check',
    'doneToday': false,
    'skippedToday': false,
  };
}

HomeHabitCompletionTransition _transition(
  String id, {
  required int originalIndex,
  HomeHabitStatusFeedbackKind kind = HomeHabitStatusFeedbackKind.completed,
  double initialOffsetX = 180,
  double velocityX = 760,
  double cardWidth = 360,
  double rightRevealProgress = 1,
  double leftRevealProgress = 1,
}) {
  return HomeHabitCompletionTransition(
    transitionId: 't-$id',
    habitId: id,
    kind: kind,
    originalIndex: originalIndex,
    dateKey: '2026-07-29',
    habitSnapshot: _habit(id),
    startedAt: DateTime(2026, 7, 29, 12),
    initialOffsetX: initialOffsetX,
    velocityX: velocityX,
    cardWidth: cardWidth,
    commitProgress: 1,
    rightRevealProgress: rightRevealProgress,
    leftRevealProgress: leftRevealProgress,
  );
}

Key _feedbackKey(HomeHabitCompletionTransition transition) {
  return ValueKey(
    'habit_status_feedback_'
    '${transition.kind.name}_'
    '${transition.transitionId}_'
    '${transition.habitId}',
  );
}

double _transitionOffsetX(WidgetTester tester, String id) {
  final transformFinder = find.ancestor(
    of: find.byKey(ValueKey('transition_visual_$id')),
    matching: find.byType(Transform),
  );
  final transform = tester.widget<Transform>(transformFinder.first);
  return transform.transform.getTranslation().x;
}

double _transitionSizeFactor(
  WidgetTester tester,
  HomeHabitCompletionTransition transition,
) {
  final sizeFinder = find.ancestor(
    of: find.byKey(_feedbackKey(transition)),
    matching: find.byType(SizeTransition),
  );
  final sizeTransition = tester.widget<SizeTransition>(sizeFinder.first);
  return sizeTransition.sizeFactor.value;
}

double _feedbackOpacity(
  WidgetTester tester,
  HomeHabitCompletionTransition transition,
) {
  final fadeFinder = find.ancestor(
    of: find.byKey(_feedbackKey(transition)),
    matching: find.byType(FadeTransition),
  );
  final fadeTransition = tester.widget<FadeTransition>(fadeFinder.first);
  return fadeTransition.opacity.value;
}

double _feedbackTransitionOffsetX(
  WidgetTester tester,
  HomeHabitCompletionTransition transition,
) {
  final transformFinder = find.ancestor(
    of: find.byKey(_feedbackKey(transition)),
    matching: find.byType(Transform),
  );
  final transform = tester.widget<Transform>(transformFinder.first);
  return transform.transform.getTranslation().x;
}

double _statusIconOpacity(WidgetTester tester) {
  final opacityFinder = find.ancestor(
    of: find.byKey(const Key('habitCardStatusFeedbackIcon')),
    matching: find.byType(Opacity),
  );
  final opacity = tester.widget<Opacity>(opacityFinder.first);
  return opacity.opacity;
}

double _statusIconScale(WidgetTester tester) {
  final scale = tester.widget<Transform>(
    find.byKey(const Key('habitCardStatusFeedbackIconScale')),
  );
  return scale.transform.storage[0];
}

Future<void> _pumpUntilFeedbackCentered(
  WidgetTester tester,
  HomeHabitCompletionTransition transition,
) async {
  for (var frame = 0; frame < 90; frame += 1) {
    await tester.pump(const Duration(milliseconds: 16));
    if (_feedbackTransitionOffsetX(tester, transition) <= 0.5) {
      return;
    }
  }
  fail('Expected skipped status feedback to enter from the right.');
}

Future<void> _pumpUntilCollapseStarts(
  WidgetTester tester,
  HomeHabitCompletionTransition transition,
) async {
  for (var frame = 0; frame < 90; frame += 1) {
    await tester.pump(const Duration(milliseconds: 16));
    if (_transitionSizeFactor(tester, transition) < 0.98) {
      return;
    }
  }
  fail('Expected status feedback collapse to start.');
}
