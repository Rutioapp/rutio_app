import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/home/home_screen.dart';

void main() {
  group('Home habit status filter date row and menu', () {
    testWidgets(
      'date row keeps the date, removes completed summary, and shows one menu button',
      (tester) async {
        var openCount = 0;
        final semantics = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: HomeDayProgressFilterRow(
                  label: '30 jul 2026',
                  onOpenFilter: (_) => openCount += 1,
                ),
              ),
            ),
          ),
        );

        expect(find.text('30 jul 2026'), findsOneWidget);
        expect(find.text('Completados'), findsNothing);
        expect(find.text('2/8'), findsNothing);
        expect(
          find.byKey(const Key('homeHabitStatusFilterButton')),
          findsOneWidget,
        );
        expect(
          tester.getSemantics(
            find.byKey(const Key('homeHabitStatusFilterButton')),
          ),
          matchesSemantics(
            label: 'Cambiar filtro de hábitos',
            hasTapAction: true,
            isButton: true,
          ),
        );

        await tester.tap(find.byKey(const Key('homeHabitStatusFilterButton')));
        await tester.pump();
        expect(openCount, 1);

        final dateCenter =
            tester.getCenter(find.byKey(const Key('homeDayProgressDateLabel')));
        final buttonCenter = tester.getCenter(
          find.byKey(const Key('homeHabitStatusFilterButton')),
        );
        expect((dateCenter.dy - buttonCenter.dy).abs(), lessThan(1));
        expect(buttonCenter.dx, greaterThan(dateCenter.dx));

        semantics.dispose();
      },
    );

    testWidgets('anchored menu shows three counted options and closes',
        (tester) async {
      HomeHabitStatusFilter? selected;
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 120, right: 16),
                    child: HomeDayProgressFilterRow(
                      label: '30 jul 2026',
                      onOpenFilter: (anchorContext) async {
                        selected = await showHomeHabitStatusFilterMenu(
                          context: context,
                          anchorContext: anchorContext,
                          selectedFilter: HomeHabitStatusFilter.skipped,
                          pendingCount: 4,
                          completedCount: 2,
                          skippedCount: 1,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      final buttonFinder = find.byKey(const Key('homeHabitStatusFilterButton'));
      final buttonRect = tester.getRect(buttonFinder);

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Mostrar hábitos'), findsNothing);
      expect(find.text('Pendientes'), findsOneWidget);
      expect(find.text('Completados'), findsOneWidget);
      expect(find.text('Saltados'), findsOneWidget);
      expect(find.text('Omitidos'), findsNothing);
      expect(find.text('Todos'), findsNothing);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);

      final menuRect = tester.getRect(find.text('Pendientes'));
      expect(menuRect.top, greaterThan(buttonRect.bottom));
      expect(menuRect.right, lessThanOrEqualTo(800));

      expect(find.bySemanticsLabel('Saltados, 1 hábitos'), findsOneWidget);

      await tester.tap(find.text('Pendientes'));
      await tester.pumpAndSettle();
      expect(selected, HomeHabitStatusFilter.pending);
      expect(find.text('Pendientes'), findsNothing);

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Saltados'), findsNothing);

      semantics.dispose();
    });
  });

  group('HomeHabitsSliver single filtered list', () {
    testWidgets('pending uses reorderable list with pending keys only',
        (tester) async {
      await tester.pumpWidget(
        _testApp(
          filter: HomeHabitStatusFilter.pending,
          visibleHabits: [_habit('pending-a'), _habit('pending-b')],
        ),
      );

      expect(find.byType(SliverReorderableList), findsOneWidget);
      expect(
        find.byType(ReorderableDelayedDragStartListener),
        findsNWidgets(2),
      );
      expect(
        find.byKey(const ValueKey('habit_pending_pending-a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('habit_pending_pending-b')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('habit_done_completed-a')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('habit_skipped_skipped-a')),
        findsNothing,
      );
      expect(find.text('Pendientes · 2'), findsNothing);
      expect(find.text('Completados · 1'), findsNothing);
      expect(find.text('Omitidos · 1'), findsNothing);
      expect(find.text('Saltados · 1'), findsNothing);
      expect(
        find.byKey(const Key('homeHabitStatusFilterButton')),
        findsNothing,
      );
    });

    testWidgets('completed and skipped use static lists without reorder',
        (tester) async {
      await tester.pumpWidget(
        _testApp(
          filter: HomeHabitStatusFilter.completed,
          visibleHabits: [_habit('completed-a')],
        ),
      );

      expect(find.text('Completados · 1'), findsNothing);
      expect(find.byType(SliverReorderableList), findsNothing);
      expect(find.byType(ReorderableDelayedDragStartListener), findsNothing);
      expect(
        find.byKey(const ValueKey('habit_done_completed-a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('habit_pending_pending-a')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('habit_skipped_skipped-a')),
        findsNothing,
      );

      await tester.pumpWidget(
        _testApp(
          filter: HomeHabitStatusFilter.skipped,
          visibleHabits: [_habit('skipped-a')],
        ),
      );

      expect(find.text('Omitidos · 1'), findsNothing);
      expect(find.text('Saltados · 1'), findsNothing);
      expect(find.byType(SliverReorderableList), findsNothing);
      expect(find.byType(ReorderableDelayedDragStartListener), findsNothing);
      expect(
        find.byKey(const ValueKey('habit_skipped_skipped-a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('habit_pending_pending-a')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('habit_done_completed-a')),
        findsNothing,
      );
    });

    testWidgets('empty state is contextual per filter', (tester) async {
      await tester.pumpWidget(
        _testApp(
          filter: HomeHabitStatusFilter.pending,
          visibleHabits: const [],
        ),
      );
      expect(find.text('No tienes hábitos pendientes.'), findsOneWidget);

      await tester.pumpWidget(
        _testApp(
          filter: HomeHabitStatusFilter.completed,
          visibleHabits: const [],
        ),
      );
      expect(find.text('Aún no has completado hábitos hoy.'), findsOneWidget);

      await tester.pumpWidget(
        _testApp(
          filter: HomeHabitStatusFilter.skipped,
          visibleHabits: const [],
        ),
      );
      expect(find.text('No has saltado hábitos hoy.'), findsOneWidget);
    });

    testWidgets('snapshots and tombstones are pending-only and non-reorderable',
        (tester) async {
      final transition = _transition('pending-a', originalIndex: 0);

      await tester.pumpWidget(
        _testApp(
          filter: HomeHabitStatusFilter.pending,
          visibleHabits: [_habit('pending-a'), _habit('pending-b')],
          transitions: [transition],
        ),
      );

      expect(find.byKey(transition.widgetKey), findsOneWidget);
      expect(
        find.byKey(const ValueKey('habit_visual_pending-a')),
        findsNothing,
      );
      expect(find.byType(SliverReorderableList), findsNothing);

      await tester.pumpWidget(
        _testApp(
          filter: HomeHabitStatusFilter.completed,
          visibleHabits: [_habit('completed-a')],
          transitions: [transition],
        ),
      );

      expect(find.byKey(transition.widgetKey), findsNothing);
      expect(
        find.byKey(const ValueKey('habit_done_completed-a')),
        findsOneWidget,
      );
    });
  });
}

Widget _testApp({
  required HomeHabitStatusFilter filter,
  required List<Map<String, dynamic>> visibleHabits,
  List<HomeHabitCompletionTransition> transitions = const [],
}) {
  return MaterialApp(
    home: Scaffold(
      body: CustomScrollView(
        slivers: [
          HomeHabitsSliver(
            selectedFilter: filter,
            visibleHabits: visibleHabits,
            completionTransitions: transitions,
            habitCardBuilder: (context, habit, {bool compact = false}) {
              final id = habit['id'].toString();
              return Container(
                key: ValueKey('habit_visual_$id'),
                height: compact ? 68 : 88,
                alignment: Alignment.centerLeft,
                child: Text('Habit $id'),
              );
            },
            completionTransitionBuilder: (context, transition) {
              return Container(
                key: ValueKey('transition_visual_${transition.habitId}'),
                height: 88,
                alignment: Alignment.centerLeft,
                child: Text('Transition ${transition.habitId}'),
              );
            },
            onCompletionTransitionDismissed: (
                {required habitId, required transitionId}) {},
            onPendingReorder: (_, __) async {},
          ),
        ],
      ),
    ),
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
    dateKey: '2026-07-30',
    habitSnapshot: _habit(id),
    startedAt: DateTime(2026, 7, 30, 12),
    initialOffsetX: 180,
    velocityX: 760,
    cardWidth: 360,
    commitProgress: 1,
  );
}
