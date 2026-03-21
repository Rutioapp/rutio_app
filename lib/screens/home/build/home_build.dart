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

    return _HomeLoadedView(
      scaffoldKey: _scaffoldKey,
      username: username,
      homeData: homeData,
      showCompleted: _showCompleted,
      showSkipped: _showSkipped,
      onOpenDrawer: () => _buildViewDrawer(context),
      onOpenAddHabit: () => showHomeAddHabitSheet(context),
      statsHeader: _statsHeader(
        context: context,
        username: username,
        level: homeData.level,
        xp: homeData.xpInLevel,
        coins: homeData.coins,
        xpToNext: homeData.xpToNext,
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
      habitCardBuilder: (ctx, h, {bool compact = false}) =>
          _habitCard(context: ctx, habit: h, compact: compact),
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
  final bool showCompleted;
  final bool showSkipped;
  final Widget Function() onOpenDrawer;
  final VoidCallback onOpenAddHabit;
  final Widget statsHeader;
  final Widget weekStrip;
  final Widget dayProgress;
  final Widget Function(BuildContext ctx, Map<String, dynamic> habit,
      {bool compact}) habitCardBuilder;
  final Widget Function(int count) completedHeaderBuilder;
  final Widget Function(int count) skippedHeaderBuilder;
  final Future<void> Function(int oldIndex, int newIndex) onPendingReorder;
  final Future<void> Function(int oldIndex, int newIndex) onCompletedReorder;
  final Future<void> Function(int oldIndex, int newIndex) onSkippedReorder;

  const _HomeLoadedView({
    required this.scaffoldKey,
    required this.username,
    required this.homeData,
    required this.showCompleted,
    required this.showSkipped,
    required this.onOpenDrawer,
    required this.onOpenAddHabit,
    required this.statsHeader,
    required this.weekStrip,
    required this.dayProgress,
    required this.habitCardBuilder,
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
                          showCompleted: showCompleted,
                          showSkipped: showSkipped,
                          habitCardBuilder: habitCardBuilder,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
