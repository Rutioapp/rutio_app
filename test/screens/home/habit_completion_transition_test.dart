import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:rutio/screens/home/widgets/habit/habit_card_swipe_shell.dart';

void main() {
  testWidgets('completion snapshot is visual-only and uses a temporary key',
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

    expect(find.byKey(transition.widgetKey), findsOneWidget);
    expect(find.byKey(const ValueKey('habit_pending_a')), findsNothing);
    expect(find.byKey(const ValueKey('habit_done_a')), findsNothing);
    expect(find.byType(HabitCardSwipeShell), findsNothing);
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

  testWidgets('completion snapshot keeps space before it exits',
      (tester) async {
    final transition = _transition('a', originalIndex: 0);

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
}) {
  return HomeHabitCompletionTransition(
    transitionId: 't-$id',
    habitId: id,
    originalIndex: originalIndex,
    dateKey: '2026-07-29',
    habitSnapshot: _habit(id),
    startedAt: DateTime(2026, 7, 29, 12),
  );
}
