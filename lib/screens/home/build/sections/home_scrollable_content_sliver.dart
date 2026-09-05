part of 'package:rutio/screens/home/home_screen.dart';

/// HomeScrollableContentSliver agrupa la zona scrolleable de la Home.
///
/// Su mision es decidir si se muestra el estado vacio o la lista de habitos,
/// aplicando el padding general una sola vez para mantener el layout limpio.
class HomeScrollableContentSliver extends StatelessWidget {
  const HomeScrollableContentSliver({
    super.key,
    required this.homeData,
    required this.selectedFilter,
    required this.completedDayEligibility,
    required this.completionTransitions,
    required this.habitCardBuilder,
    required this.completionTransitionBuilder,
    required this.onCompletionTransitionDismissed,
    required this.onPendingReorder,
    required this.onOpenAddHabit,
    required this.bottomPadding,
  });

  final HomeViewData homeData;
  final HomeHabitStatusFilter selectedFilter;
  final CompletedDayEligibility completedDayEligibility;
  final List<HomeHabitCompletionTransition> completionTransitions;
  final Widget Function(BuildContext ctx, Map<String, dynamic> habit,
      {bool compact}) habitCardBuilder;
  final Widget Function(
    BuildContext ctx,
    HomeHabitCompletionTransition transition,
  ) completionTransitionBuilder;
  final void Function({
    required String habitId,
    required String transitionId,
  }) onCompletionTransitionDismissed;
  final Future<void> Function(int oldIndex, int newIndex) onPendingReorder;
  final VoidCallback onOpenAddHabit;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final visibleHabits = habitsForFilter(homeData, selectedFilter);

    return SliverPadding(
      // IOS-FIRST IMPROVEMENT START
      padding: EdgeInsets.fromLTRB(
        IosSpacing.lg,
        IosSpacing.sm,
        IosSpacing.lg,
        bottomPadding,
      ),
      sliver: homeData.viewHabits.isEmpty
          ? SliverToBoxAdapter(
              child: HomeEmptyStateCard(
                onPrimaryAction: onOpenAddHabit,
              ),
            )
          : HomeHabitsSliver(
              selectedFilter: selectedFilter,
              suppressPendingEmptyState: completedDayEligibility.isCompletedDay,
              visibleHabits: visibleHabits,
              completionTransitions: completionTransitions,
              habitCardBuilder: habitCardBuilder,
              completionTransitionBuilder: completionTransitionBuilder,
              onCompletionTransitionDismissed: onCompletionTransitionDismissed,
              onPendingReorder: onPendingReorder,
            ),
      // IOS-FIRST IMPROVEMENT END
    );
  }
}
