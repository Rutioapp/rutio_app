part of 'package:rutio/screens/home/home_screen.dart';

/// HomeScrollableContentSliver agrupa la zona scrolleable de la Home.
///
/// Su mision es decidir si se muestra el estado vacio o la lista de habitos,
/// aplicando el padding general una sola vez para mantener el layout limpio.
class HomeScrollableContentSliver extends StatelessWidget {
  const HomeScrollableContentSliver({
    super.key,
    required this.viewHabits,
    required this.pendingHabits,
    required this.completedHabits,
    required this.skippedHabits,
    required this.showCompleted,
    required this.showSkipped,
    required this.habitCardBuilder,
    required this.completedHeaderBuilder,
    required this.skippedHeaderBuilder,
    required this.onPendingReorder,
    required this.onCompletedReorder,
    required this.onSkippedReorder,
    required this.bottomPadding,
  });

  final List<Map<String, dynamic>> viewHabits;
  final List<Map<String, dynamic>> pendingHabits;
  final List<Map<String, dynamic>> completedHabits;
  final List<Map<String, dynamic>> skippedHabits;
  final bool showCompleted;
  final bool showSkipped;
  final Widget Function(BuildContext ctx, Map<String, dynamic> habit,
      {bool compact}) habitCardBuilder;
  final Widget Function(int count) completedHeaderBuilder;
  final Widget Function(int count) skippedHeaderBuilder;
  final Future<void> Function(int oldIndex, int newIndex) onPendingReorder;
  final Future<void> Function(int oldIndex, int newIndex) onCompletedReorder;
  final Future<void> Function(int oldIndex, int newIndex) onSkippedReorder;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      // IOS-FIRST IMPROVEMENT START
      padding: EdgeInsets.fromLTRB(
        IosSpacing.lg,
        IosSpacing.sm,
        IosSpacing.lg,
        bottomPadding,
      ),
      sliver: viewHabits.isEmpty
          ? const SliverToBoxAdapter(
              child: SizedBox.shrink(),
            )
          : HomeHabitsSliver(
              viewHabits: viewHabits,
              pendingHabits: pendingHabits,
              completedHabits: completedHabits,
              skippedHabits: skippedHabits,
              showCompleted: showCompleted,
              showSkipped: showSkipped,
              habitCardBuilder: habitCardBuilder,
              completedHeaderBuilder: completedHeaderBuilder,
              skippedHeaderBuilder: skippedHeaderBuilder,
              onPendingReorder: onPendingReorder,
              onCompletedReorder: onCompletedReorder,
              onSkippedReorder: onSkippedReorder,
            ),
      // IOS-FIRST IMPROVEMENT END
    );
  }
}
