part of 'package:rutio/screens/home/home_screen.dart';

/// HomeHabitsSliver pinta la lista principal de habitos de la Home.
///
/// Desde Fase 6C renderiza una unica lista filtrada. Los builders antiguos de
/// secciones desplegables quedan fuera del arbol y pendientes de retirada.
class HomeHabitsSliver extends StatefulWidget {
  final HomeHabitStatusFilter selectedFilter;
  final List<Map<String, dynamic>> visibleHabits;
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

  const HomeHabitsSliver({
    super.key,
    required this.selectedFilter,
    required this.visibleHabits,
    required this.completionTransitions,
    required this.habitCardBuilder,
    required this.completionTransitionBuilder,
    required this.onCompletionTransitionDismissed,
    required this.onPendingReorder,
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
    final activeTransitionHabitIds =
        sortedTransitions.map((transition) => transition.habitId).toSet();
    var transitionCursor = 0;

    for (var index = 0; index < widget.visibleHabits.length; index += 1) {
      while (transitionCursor < sortedTransitions.length &&
          sortedTransitions[transitionCursor].originalIndex <= index) {
        entries.add(
          _PendingCompletionVisualEntry.transition(
            sortedTransitions[transitionCursor],
          ),
        );
        transitionCursor += 1;
      }
      final habitId = (widget.visibleHabits[index]['id'] ??
              widget.visibleHabits[index]['habitId'] ??
              '')
          .toString();
      if (activeTransitionHabitIds.contains(habitId)) {
        continue;
      }
      entries.add(
        _PendingCompletionVisualEntry.habit(
          habit: widget.visibleHabits[index],
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
    final isPending = widget.selectedFilter == HomeHabitStatusFilter.pending;
    final hasPendingTransitions =
        isPending && widget.completionTransitions.isNotEmpty;
    final canReorder =
        isPending && widget.visibleHabits.length >= 2 && !hasPendingTransitions;

    return SliverMainAxisGroup(
      slivers: [
        if (widget.visibleHabits.isEmpty && !hasPendingTransitions)
          SliverToBoxAdapter(
            child: HomeHabitFilterEmptyState(
              selectedFilter: widget.selectedFilter,
            ),
          )
        else if (hasPendingTransitions)
          _buildPendingSectionWithCompletionTransitions(context: context)
        else if (canReorder)
          _buildHabitSection(
            habits: widget.visibleHabits,
            compact: false,
            keyPrefix: 'habit_pending',
            onReorder: widget.onPendingReorder,
            bottomPadding: IosSpacing.sm,
          )
        else
          _buildStaticHabitSection(
            habits: widget.visibleHabits,
            compact: !isPending,
            keyPrefix: _keyPrefixForFilter(widget.selectedFilter),
            bottomPadding: isPending ? IosSpacing.sm : IosSpacing.xs,
          ),
      ],
    );
  }

  String _keyPrefixForFilter(HomeHabitStatusFilter filter) {
    return switch (filter) {
      HomeHabitStatusFilter.pending => 'habit_pending',
      HomeHabitStatusFilter.completed => 'habit_done',
      HomeHabitStatusFilter.skipped => 'habit_skipped',
    };
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
    with TickerProviderStateMixin {
  static const SpringDescription _horizontalSpring = SpringDescription(
    mass: HabitCardStatusFeedbackMotionConfig.springMass,
    stiffness: HabitCardStatusFeedbackMotionConfig.springStiffness,
    damping: HabitCardStatusFeedbackMotionConfig.springDamping,
  );
  static const SpringDescription _skippedEntrySpring = SpringDescription(
    mass: HabitCardStatusFeedbackMotionConfig.springMass,
    stiffness: HabitCardStatusFeedbackMotionConfig.skippedEntrySpringStiffness,
    damping: HabitCardStatusFeedbackMotionConfig.skippedEntrySpringDamping,
  );
  static const SpringDescription _tapCompletionSpring = SpringDescription(
    mass: HabitCardStatusFeedbackMotionConfig.springMass,
    stiffness: homeHabitTapCompletionSpringStiffness,
    damping: homeHabitTapCompletionSpringDamping,
  );

  late final AnimationController _holdController;
  late final AnimationController _collapseController;
  late final AnimationController _horizontalController;
  late final AnimationController _feedbackHorizontalController;
  late final Animation<double> _sizeFactor;
  late final Animation<double> _feedbackOpacity;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: HabitCardStatusFeedbackMotionConfig.holdDurationFor(
        widget.transition.kind,
      ),
    );
    _collapseController = AnimationController(
      vsync: this,
      duration: HabitCardStatusFeedbackMotionConfig.collapseDurationFor(
        widget.transition.kind,
      ),
    );
    _horizontalController = AnimationController.unbounded(
      vsync: this,
      value: widget.transition.initialOffsetX,
    );
    _feedbackHorizontalController = AnimationController.unbounded(
      vsync: this,
      value: _initialFeedbackOffset,
    );
    _sizeFactor = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _collapseController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _feedbackOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _collapseController,
        curve: const Interval(
          HabitCardStatusFeedbackMotionConfig.fadeStartCollapseFraction,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    _collapseController.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      widget.onDismissed(
        habitId: widget.transition.habitId,
        transitionId: widget.transition.transitionId,
      );
    });
    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.wait([
      _horizontalController.animateWith(
        SpringSimulation(
          _foregroundSpring,
          widget.transition.initialOffsetX,
          widget.transition.exitOffsetX,
          _initialVelocity,
          tolerance: const Tolerance(distance: 0.5, velocity: 5),
        ),
      ),
      if (widget.transition.kind == HomeHabitStatusFeedbackKind.skipped)
        _feedbackHorizontalController.animateWith(
          SpringSimulation(
            _skippedEntrySpring,
            _initialFeedbackOffset,
            0,
            _feedbackInitialVelocity,
            tolerance: const Tolerance(distance: 0.5, velocity: 5),
          ),
        ),
    ]);
    if (!mounted) return;
    await _holdController.forward();
    if (!mounted) return;
    await _collapseController.forward();
  }

  double get _initialVelocity {
    if (widget.transition.kind == HomeHabitStatusFeedbackKind.skipped) {
      return widget.transition.velocityX.clamp(-2800.0, 0.0).toDouble();
    }
    return widget.transition.velocityX.clamp(0.0, 2800.0).toDouble();
  }

  SpringDescription get _foregroundSpring {
    if (widget.transition.useTapCompletionMotion) {
      return _tapCompletionSpring;
    }
    return _horizontalSpring;
  }

  double get _initialFeedbackOffset {
    if (widget.transition.kind != HomeHabitStatusFeedbackKind.skipped) return 0;
    return widget.transition.cardWidth + homeHabitStatusFeedbackExitMargin;
  }

  double get _feedbackInitialVelocity {
    if (widget.transition.kind != HomeHabitStatusFeedbackKind.skipped) return 0;
    return widget.transition.velocityX.clamp(-2800.0, 0.0).toDouble();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _feedbackHorizontalController.dispose();
    _collapseController.dispose();
    _holdController.dispose();
    super.dispose();
  }

  double get _displayHorizontalOffset {
    final value = _horizontalController.value;
    final start = widget.transition.initialOffsetX;
    final end = widget.transition.exitOffsetX;
    if (end < start) {
      return value.clamp(end, start).toDouble();
    }
    return value.clamp(start, end).toDouble();
  }

  double get _feedbackIconProgress {
    if (widget.transition.kind == HomeHabitStatusFeedbackKind.skipped) {
      return 1;
    }
    final revealExtent = widget.transition.cardWidth * 0.5;
    if (revealExtent <= 0) return widget.transition.rightRevealProgress;
    return (_displayHorizontalOffset / revealExtent).clamp(
      widget.transition.rightRevealProgress.clamp(0.0, 1.0),
      1.0,
    );
  }

  double get _displayFeedbackHorizontalOffset {
    if (widget.transition.kind != HomeHabitStatusFeedbackKind.skipped) return 0;
    final value = _feedbackHorizontalController.value;
    return value.clamp(0.0, _initialFeedbackOffset).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _holdController,
            _collapseController,
            _horizontalController,
            _feedbackHorizontalController,
          ]),
          builder: (context, child) {
            return SizeTransition(
              sizeFactor: _sizeFactor,
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: widget.bottomPadding),
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    Positioned.fill(
                      child: FadeTransition(
                        opacity: _feedbackOpacity,
                        child: Transform.translate(
                          offset: Offset(_displayFeedbackHorizontalOffset, 0),
                          child: HabitCardStatusFeedback(
                            key: ValueKey(
                              'habit_status_feedback_'
                              '${widget.transition.kind.name}_'
                              '${widget.transition.transitionId}_'
                              '${widget.transition.habitId}',
                            ),
                            kind: widget.transition.kind,
                            borderRadius: BorderRadius.circular(20),
                            iconProgress: _feedbackIconProgress,
                          ),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(_displayHorizontalOffset, 0),
                      child: child,
                    ),
                  ],
                ),
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
