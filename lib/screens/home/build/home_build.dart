part of 'package:rutio/screens/home/home_screen.dart';

/// buildContent compone la Home principal a partir del estado del usuario.
///
/// Segunda ronda de optimizacion:
/// - mantiene la separacion de `_HomeLoadedView`
/// - conserva el arbol visual mas limpio
/// - vuelve a usar `context.watch` para que los cambios del store
///   se reflejen al instante en la lista de habitos
extension _HomeScreenBuild on _HomeScreenState {
  Widget buildContent(BuildContext context) {
    final store = context.watch<UserStateStore>();
    final walletController = context.watch<GlobalWalletController>();
    final isLoading = store.isLoading;
    final error = store.error;
    final root = store.state;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: _HomeStatusScaffold(
          child: CupertinoActivityIndicator(radius: 16),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: _HomeStatusScaffold(
          child: Text(
            context.l10n.homeErrorMessage(error.toString()),
            textAlign: TextAlign.center,
            style: IosTypography.body(context),
          ),
        ),
      );
    }

    if (root == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: _HomeStatusScaffold(
          child: CupertinoActivityIndicator(radius: 16),
        ),
      );
    }

    if (!_didSyncViewDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final store = context.read<UserStateStore>();
        await store.setActiveViewDate(_selectedDay);

        _applyHomeState(() => _didSyncViewDate = true);
      });
    }

    final homeData = buildHomeViewData(root, _selectedDay);
    final selectedDateKey = _dateKey(_selectedDay);
    final completionTransitions = _habitCompletionTransitions.values
        .where((transition) => transition.dateKey == selectedDateKey)
        .toList(growable: false)
      ..sort((a, b) => a.originalIndex.compareTo(b.originalIndex));

    final args = ModalRoute.of(context)?.settings.arguments;
    final argsMap = (args is Map) ? args : const <String, dynamic>{};

    final rootMap = _map(root);
    final profile = _map(_map(rootMap['userState'])['profile']);
    final dynamic rawUsername = profile['name'] ??
        profile['displayName'] ??
        profile['username'] ??
        rootMap['username'];
    final String routeUsername =
        ((argsMap['username'] as String?) ?? '').trim();
    final String profileUsername = (rawUsername?.toString() ?? '').trim();
    final String username = (store.displayName?.trim().isNotEmpty ?? false)
        ? store.displayName!.trim()
        : routeUsername.isNotEmpty
            ? routeUsername
            : profileUsername.isNotEmpty
                ? profileUsername
                : context.l10n.homeFallbackUsername;

    final habitCardBackgroundAsset = _equippedHabitCardAsset();
    final coins = walletController.resolveCoinsForUi(
      legacyCoinsBuilder: () =>
          _readInt(rootMap, ['userState', 'wallet', 'coins'], fallback: 0),
    );

    return _HomeLoadedView(
      scaffoldKey: _scaffoldKey,
      username: username,
      homeData: homeData,
      completionTransitions: completionTransitions,
      showCompleted: _showCompleted,
      showSkipped: _showSkipped,
      onOpenDrawer: () => _buildViewDrawer(context),
      onOpenAddHabit: () => showHomeAddHabitSheet(context),
      onManualRefresh: () => _handleManualRefresh(store),
      statsHeader: _statsHeader(
        context: context,
        username: username,
        level: homeData.level,
        xpProgress: homeData.xpProgress,
        coins: coins,
        avatarUrl: store.avatarUrl,
      ),
      weekStrip: _weekStrip(),
      dayProgress: _dayProgressMini(
        label: MaterialLocalizations.of(context).formatMediumDate(
          _selectedDay,
        ),
        done: homeData.doneCount,
        total: homeData.totalCount,
      ),
      habitCardBuilder: (ctx, h, {bool compact = false}) => _habitCard(
        context: ctx,
        habit: h,
        compact: compact,
        backgroundAsset: habitCardBackgroundAsset,
      ),
      completionTransitionBuilder: (ctx, transition) =>
          _habitCompletionTransitionCard(
        context: ctx,
        transition: transition,
        backgroundAsset: habitCardBackgroundAsset,
      ),
      onCompletionTransitionDismissed: _removeHabitCompletionTransition,
      completedHeaderBuilder: (count) => _completedHeader(count: count),
      skippedHeaderBuilder: (count) => _skippedHeader(count: count),
      onPendingReorder: (oldIndex, newIndex) => _reorderHabitSection(
        context,
        sectionHabits: homeData.pendingHabits,
        viewHabits: homeData.viewHabits,
        oldIndex: oldIndex,
        newIndex: newIndex,
      ),
      onCompletedReorder: (oldIndex, newIndex) => _reorderHabitSection(
        context,
        sectionHabits: homeData.completedHabits,
        viewHabits: homeData.viewHabits,
        oldIndex: oldIndex,
        newIndex: newIndex,
      ),
      onSkippedReorder: (oldIndex, newIndex) => _reorderHabitSection(
        context,
        sectionHabits: homeData.skippedHabits,
        viewHabits: homeData.viewHabits,
        oldIndex: oldIndex,
        newIndex: newIndex,
      ),
    );
  }
}

/// Vista cargada de Home.
/// Recibe datos ya preparados para que el build principal sea mas estable
/// y para aislar mejor los rebuilds locales del arbol visual.
class _HomeLoadedView extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String username;
  final HomeViewData homeData;
  final List<HomeHabitCompletionTransition> completionTransitions;
  final bool showCompleted;
  final bool showSkipped;
  final Widget Function() onOpenDrawer;
  final VoidCallback onOpenAddHabit;
  final Future<void> Function() onManualRefresh;
  final Widget statsHeader;
  final Widget weekStrip;
  final Widget dayProgress;
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

  const _HomeLoadedView({
    required this.scaffoldKey,
    required this.username,
    required this.homeData,
    required this.completionTransitions,
    required this.showCompleted,
    required this.showSkipped,
    required this.onOpenDrawer,
    required this.onOpenAddHabit,
    required this.onManualRefresh,
    required this.statsHeader,
    required this.weekStrip,
    required this.dayProgress,
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
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return _LevelUpConfettiEffect(
      level: homeData.level,
      controller: _confettiController,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.transparent,
        drawer: onOpenDrawer(),
        floatingActionButton: HomeAddFab(
          onPressed: onOpenAddHabit,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: Stack(
          children: [
            const _HomeCosmeticsTraceListener(),
            const HomeBackground(),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      IosSpacing.lg,
                      IosSpacing.xs,
                      IosSpacing.lg,
                      0,
                    ),
                    child: _HomeHeroTopArea(
                      statsHeader: statsHeader,
                    ),
                  ),
                  const SizedBox(height: IosSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      IosSpacing.lg,
                      IosSpacing.xs,
                      IosSpacing.lg,
                      IosSpacing.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        weekStrip,
                        const SizedBox(height: IosSpacing.xs),
                        dayProgress,
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator.adaptive(
                      onRefresh: onManualRefresh,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          HomeScrollableContentSliver(
                            viewHabits: homeData.viewHabits,
                            pendingHabits: homeData.pendingHabits,
                            completedHabits: homeData.completedHabits,
                            skippedHabits: homeData.skippedHabits,
                            completionTransitions: completionTransitions,
                            showCompleted: showCompleted,
                            showSkipped: showSkipped,
                            habitCardBuilder: habitCardBuilder,
                            completionTransitionBuilder:
                                completionTransitionBuilder,
                            onCompletionTransitionDismissed:
                                onCompletionTransitionDismissed,
                            completedHeaderBuilder: completedHeaderBuilder,
                            skippedHeaderBuilder: skippedHeaderBuilder,
                            onPendingReorder: onPendingReorder,
                            onCompletedReorder: onCompletedReorder,
                            onSkippedReorder: onSkippedReorder,
                            onOpenAddHabit: onOpenAddHabit,
                            bottomPadding: bottomInset + 112,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCosmeticsTraceListener extends StatelessWidget {
  const _HomeCosmeticsTraceListener();

  @override
  Widget build(BuildContext context) {
    ShopCosmeticsController controller;
    try {
      controller = context.watch<ShopCosmeticsController>();
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (kDebugMode) {
      debugPrint(
        '[cosmetic_trace] stage=home_listener '
        'traceId=${controller.lastTraceId ?? 'none'} '
        'userId=${controller.cloudState.userId ?? 'none'} '
        'revision=${controller.cloudSnapshotRevision} '
        'controllerHash=${identityHashCode(controller)} '
        'snapshotHash=${controller.cloudState.snapshot == null ? 'none' : identityHashCode(controller.cloudState.snapshot)}',
      );
    }
    return const SizedBox.shrink();
  }
}

// IOS-FIRST IMPROVEMENT START
class _HomeHeroTopArea extends StatelessWidget {
  final Widget statsHeader;

  const _HomeHeroTopArea({
    required this.statsHeader,
  });

  @override
  Widget build(BuildContext context) {
    return statsHeader;
  }
}

class _HomeStatusScaffold extends StatelessWidget {
  final Widget child;

  const _HomeStatusScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const HomeBackground(),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: IosSpacing.lg),
              child: IosFrostedCard(
                elevated: true,
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// IOS-FIRST IMPROVEMENT END

/// Efecto aislado para lanzar confeti SOLO cuando sube el nivel.
/// Evita programar addPostFrameCallback en cada build.
class _LevelUpConfettiEffect extends StatefulWidget {
  final int level;
  final ConfettiController controller;
  final Widget child;

  const _LevelUpConfettiEffect({
    required this.level,
    required this.controller,
    required this.child,
  });

  @override
  State<_LevelUpConfettiEffect> createState() => _LevelUpConfettiEffectState();
}

class _LevelUpConfettiEffectState extends State<_LevelUpConfettiEffect> {
  int? _lastLevel;
  Timer? _stopTimer;

  @override
  void didUpdateWidget(covariant _LevelUpConfettiEffect oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_lastLevel == null) {
      _lastLevel = widget.level;
      return;
    }

    if (widget.level > _lastLevel!) {
      widget.controller.play();

      _stopTimer?.cancel();
      _stopTimer = Timer(const Duration(seconds: 2), () {
        widget.controller.stop();
      });
    }

    _lastLevel = widget.level;
  }

  @override
  void dispose() {
    _stopTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
