part of 'package:rutio/screens/home/home_screen.dart';

/// HomeHabitsSliver pinta la lista principal de habitos de la Home.
///
/// Separa pendientes, completados y skipeados, reutiliza el builder de tarjetas existente
/// y mantiene el orden/keys de cada fila para evitar renders extranos.
class HomeHabitsSliver extends StatefulWidget {
  final List<Map<String, dynamic>> viewHabits;
  final List<Map<String, dynamic>> pendingHabits;
  final List<Map<String, dynamic>> completedHabits;
  final List<Map<String, dynamic>> skippedHabits;
  final List<HomeHabitCompletionTransition> completionTransitions;

  final bool showCompleted;
  final bool showSkipped;

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
  final Widget Function(int count) completedHeaderBuilder;
  final Widget Function(int count) skippedHeaderBuilder;
  final Future<void> Function(int oldIndex, int newIndex) onPendingReorder;
  final Future<void> Function(int oldIndex, int newIndex) onCompletedReorder;
  final Future<void> Function(int oldIndex, int newIndex) onSkippedReorder;

  const HomeHabitsSliver({
    super.key,
    required this.viewHabits,
    required this.pendingHabits,
    required this.completedHabits,
    required this.skippedHabits,
    required this.completionTransitions,
    required this.showCompleted,
    required this.showSkipped,
    required this.habitCardBuilder,
    required this.completionTransitionBuilder,
    required this.onCompletionTransitionDismissed,
    required this.completedHeaderBuilder,
    required this.skippedHeaderBuilder,
    required this.onPendingReorder,
    required this.onCompletedReorder,
    required this.onSkippedReorder,
  });

  @override
  State<HomeHabitsSliver> createState() => _HomeHabitsSliverState();
}

class _HomeHabitsSliverState extends State<HomeHabitsSliver> {
  String? _preparedHabitId;
  String? _draggingHabitId;
  bool _didFireDragHaptic = false;

  void _setPreparedHabit(String? habitId) {
    if (!mounted || _preparedHabitId == habitId) return;
    setState(() {
      _preparedHabitId = habitId;
    });
  }

  void _handleLongPressStart(String habitId) {
    if (_draggingHabitId != null) return;
    _setPreparedHabit(habitId);
  }

  void _handleLongPressEnd() {
    if (_draggingHabitId != null) return;
    _setPreparedHabit(null);
  }

  void _handleReorderStart(List<Map<String, dynamic>> habits, int index) {
    if (index < 0 || index >= habits.length) return;

    final habitId = (habits[index]['id'] ?? '').toString();
    if (habitId.isEmpty) return;

    // IOS-FIRST IMPROVEMENT START
    if (!_didFireDragHaptic) {
      IosFeedback.mediumImpact();
      _didFireDragHaptic = true;
    }
    // IOS-FIRST IMPROVEMENT END

    if (!mounted) return;
    setState(() {
      _preparedHabitId = null;
      _draggingHabitId = habitId;
    });
  }

  void _handleReorderEnd(int _) {
    _didFireDragHaptic = false;
    if (!mounted) return;
    setState(() {
      _preparedHabitId = null;
      _draggingHabitId = null;
    });
  }

  Widget _wrapHabitCard({
    required String habitId,
    required Widget child,
    required bool isProxy,
  }) {
    final isDragging = _draggingHabitId == habitId;
    final isPrepared = !isProxy && _preparedHabitId == habitId && !isDragging;
    final targetScale = isDragging ? 1.05 : (isPrepared ? 1.04 : 1.0);
    final shadowOpacity = isDragging ? 0.20 : (isPrepared ? 0.14 : 0.0);
    final shadowBlur = isDragging ? 28.0 : (isPrepared ? 18.0 : 0.0);
    final shadowOffset = isDragging ? const Offset(0, 14) : const Offset(0, 8);
    final backgroundOpacity = isDragging ? 0.96 : (isPrepared ? 0.96 : 1.0);

    return AnimatedScale(
      scale: targetScale,
      duration: Duration(milliseconds: isDragging ? 200 : 180),
      curve: isDragging ? Curves.easeInOut : Curves.easeOut,
      child: AnimatedContainer(
        duration: Duration(milliseconds: isDragging ? 200 : 180),
        curve: isDragging ? Curves.easeInOut : Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: shadowOpacity <= 0
              ? const []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: shadowOpacity),
                    blurRadius: shadowBlur,
                    offset: shadowOffset,
                  ),
                ],
        ),
        child: Opacity(
          opacity: backgroundOpacity,
          child: child,
        ),
      ),
    );
  }

  Widget _buildReorderItem({
    required BuildContext context,
    required Map<String, dynamic> habit,
    required bool compact,
    required int index,
    required String keyPrefix,
  }) {
    final habitId = (habit['id'] ?? '${keyPrefix}_$index').toString();
    final card = SizedBox(
      width: double.infinity,
      child: widget.habitCardBuilder(context, habit, compact: compact),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: (_) => _handleLongPressStart(habitId),
      onLongPressEnd: (_) => _handleLongPressEnd(),
      onLongPressCancel: _handleLongPressEnd,
      child: ReorderableDelayedDragStartListener(
        index: index,
        child: _wrapHabitCard(
          habitId: habitId,
          isProxy: false,
          child: card,
        ),
      ),
    );
  }

  Widget _buildStaticItem({
    required BuildContext context,
    required Map<String, dynamic> habit,
    required bool compact,
    required int index,
    required String keyPrefix,
    required double bottomPadding,
  }) {
    final habitId = (habit['id'] ?? '${keyPrefix}_$index').toString();
    final card = SizedBox(
      width: double.infinity,
      child: widget.habitCardBuilder(context, habit, compact: compact),
    );

    return Padding(
      key: ValueKey('${keyPrefix}_$habitId'),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: _wrapHabitCard(
        habitId: habitId,
        isProxy: false,
        child: card,
      ),
    );
  }

  SliverReorderableList _buildHabitSection({
    required List<Map<String, dynamic>> habits,
    required bool compact,
    required String keyPrefix,
    required Future<void> Function(int oldIndex, int newIndex) onReorder,
    double bottomPadding = 12,
  }) {
    return SliverReorderableList(
      itemCount: habits.length,
      onReorderItem: onReorder,
      onReorderStart: (index) => _handleReorderStart(habits, index),
      onReorderEnd: _handleReorderEnd,
      proxyDecorator: (child, index, animation) {
        final habitId =
            (habits[index]['id'] ?? '${keyPrefix}_$index').toString();
        return AnimatedBuilder(
          animation: animation,
          child: _wrapHabitCard(
            habitId: habitId,
            isProxy: true,
            child: child,
          ),
          builder: (context, proxyChild) {
            final lift = Tween<double>(begin: 0, end: -6).evaluate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );
            return Transform.translate(
              offset: Offset(0, lift),
              child: proxyChild,
            );
          },
        );
      },
      itemBuilder: (ctx, index) {
        final h = habits[index];
        final id = (h['id'] ?? '${keyPrefix}_$index').toString();
        return Padding(
          key: ValueKey('${keyPrefix}_$id'),
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: _buildReorderItem(
            context: ctx,
            habit: h,
            compact: compact,
            index: index,
            keyPrefix: keyPrefix,
          ),
        );
      },
    );
  }

  Widget _buildStaticHabitSection({
    required List<Map<String, dynamic>> habits,
    required bool compact,
    required String keyPrefix,
    double bottomPadding = 12,
  }) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, index) => _buildStaticItem(
          context: ctx,
          habit: habits[index],
          compact: compact,
          index: index,
          keyPrefix: keyPrefix,
          bottomPadding: bottomPadding,
        ),
        childCount: habits.length,
      ),
    );
  }

  Widget _buildCompletionTransitionItem({
    required BuildContext context,
    required HomeHabitCompletionTransition transition,
    double bottomPadding = IosSpacing.sm,
  }) {
    return _HomeHabitCompletionTransitionTile(
      key: transition.widgetKey,
      transition: transition,
      bottomPadding: bottomPadding,
      onDismissed: widget.onCompletionTransitionDismissed,
      child: widget.completionTransitionBuilder(context, transition),
    );
  }

  Widget _buildPendingSectionWithCompletionTransitions({
    required BuildContext context,
  }) {
    final entries = <_PendingCompletionVisualEntry>[];
    final sortedTransitions = widget.completionTransitions.toList()
      ..sort((a, b) {
        final byIndex = a.originalIndex.compareTo(b.originalIndex);
        if (byIndex != 0) return byIndex;
        return a.transitionId.compareTo(b.transitionId);
      });
    var transitionCursor = 0;

    for (var index = 0; index < widget.pendingHabits.length; index += 1) {
      while (transitionCursor < sortedTransitions.length &&
          sortedTransitions[transitionCursor].originalIndex <= index) {
        entries.add(
          _PendingCompletionVisualEntry.transition(
            sortedTransitions[transitionCursor],
          ),
        );
        transitionCursor += 1;
      }
      entries.add(
        _PendingCompletionVisualEntry.habit(
          habit: widget.pendingHabits[index],
          originalIndex: index,
        ),
      );
    }

    while (transitionCursor < sortedTransitions.length) {
      entries.add(
        _PendingCompletionVisualEntry.transition(
          sortedTransitions[transitionCursor],
        ),
      );
      transitionCursor += 1;
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, index) {
          final entry = entries[index];
          final transition = entry.transition;
          if (transition != null) {
            return _buildCompletionTransitionItem(
              context: ctx,
              transition: transition,
            );
          }

          final habit = entry.habit!;
          return _buildStaticItem(
            context: ctx,
            habit: habit,
            compact: false,
            index: entry.originalIndex,
            keyPrefix: 'habit_pending',
            bottomPadding: IosSpacing.sm,
          );
        },
        childCount: entries.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.viewHabits.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          width: double.infinity,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Text(
              context.l10n.homeEmptyStateMultiline,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.65),
              ),
            ),
          ),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        widget.pendingHabits.length < 2
            ? (widget.completionTransitions.isEmpty
                ? _buildStaticHabitSection(
                    habits: widget.pendingHabits,
                    compact: false,
                    keyPrefix: 'habit_pending',
                    bottomPadding: IosSpacing.sm,
                  )
                : _buildPendingSectionWithCompletionTransitions(
                    context: context,
                  ))
            : (widget.completionTransitions.isEmpty
                ? _buildHabitSection(
                    habits: widget.pendingHabits,
                    compact: false,
                    keyPrefix: 'habit_pending',
                    onReorder: widget.onPendingReorder,
                    bottomPadding: IosSpacing.sm,
                  )
                : _buildPendingSectionWithCompletionTransitions(
                    context: context,
                  )),
        if (widget.completedHabits.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: IosSpacing.xs,
                bottom: IosSpacing.xs,
              ),
              child: SizedBox(
                width: double.infinity,
                child: widget
                    .completedHeaderBuilder(widget.completedHabits.length),
              ),
            ),
          ),
        if (widget.completedHabits.isNotEmpty && widget.showCompleted)
          (widget.completedHabits.length < 2)
              ? _buildStaticHabitSection(
                  habits: widget.completedHabits,
                  compact: true,
                  keyPrefix: 'habit_done',
                  bottomPadding: IosSpacing.xs,
                )
              : _buildHabitSection(
                  habits: widget.completedHabits,
                  compact: true,
                  keyPrefix: 'habit_done',
                  onReorder: widget.onCompletedReorder,
                  bottomPadding: IosSpacing.xs,
                ),
        if (widget.skippedHabits.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: IosSpacing.xs,
                bottom: IosSpacing.xs,
              ),
              child: SizedBox(
                width: double.infinity,
                child: widget.skippedHeaderBuilder(widget.skippedHabits.length),
              ),
            ),
          ),
        if (widget.skippedHabits.isNotEmpty && widget.showSkipped)
          (widget.skippedHabits.length < 2)
              ? _buildStaticHabitSection(
                  habits: widget.skippedHabits,
                  compact: true,
                  keyPrefix: 'habit_skipped',
                  bottomPadding: IosSpacing.xs,
                )
              : _buildHabitSection(
                  habits: widget.skippedHabits,
                  compact: true,
                  keyPrefix: 'habit_skipped',
                  onReorder: widget.onSkippedReorder,
                  bottomPadding: IosSpacing.xs,
                ),
      ],
    );
  }
}

class _PendingCompletionVisualEntry {
  const _PendingCompletionVisualEntry._({
    this.habit,
    this.transition,
    required this.originalIndex,
  });

  factory _PendingCompletionVisualEntry.habit({
    required Map<String, dynamic> habit,
    required int originalIndex,
  }) {
    return _PendingCompletionVisualEntry._(
      habit: habit,
      originalIndex: originalIndex,
    );
  }

  factory _PendingCompletionVisualEntry.transition(
    HomeHabitCompletionTransition transition,
  ) {
    return _PendingCompletionVisualEntry._(
      transition: transition,
      originalIndex: transition.originalIndex,
    );
  }

  final Map<String, dynamic>? habit;
  final HomeHabitCompletionTransition? transition;
  final int originalIndex;
}

class _HomeHabitCompletionTransitionTile extends StatefulWidget {
  const _HomeHabitCompletionTransitionTile({
    super.key,
    required this.transition,
    required this.child,
    required this.bottomPadding,
    required this.onDismissed,
  });

  final HomeHabitCompletionTransition transition;
  final Widget child;
  final double bottomPadding;
  final void Function({
    required String habitId,
    required String transitionId,
  }) onDismissed;

  @override
  State<_HomeHabitCompletionTransitionTile> createState() =>
      _HomeHabitCompletionTransitionTileState();
}

class _HomeHabitCompletionTransitionTileState
    extends State<_HomeHabitCompletionTransitionTile>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 220);

  late final AnimationController _controller;
  late final Animation<double> _sizeFactor;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slideOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _sizeFactor = Tween<double>(begin: 1, end: 0).animate(curved);
    _opacity = Tween<double>(begin: 0.92, end: 0).animate(curved);
    _slideOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.035, 0),
    ).animate(curved);
    _controller.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      widget.onDismissed(
        habitId: widget.transition.habitId,
        transitionId: widget.transition.transitionId,
      );
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: ClipRect(
        child: SizeTransition(
          sizeFactor: _sizeFactor,
          axisAlignment: -1,
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _slideOffset,
              child: Padding(
                padding: EdgeInsets.only(bottom: widget.bottomPadding),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
