part of 'package:rutio/screens/home/home_screen.dart';
// Estado + lifecycle (campos + init/dispose). La lógica pesada está en extensiones.

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // =========================
  // Drawer key (abrir menú lateral desde el header)
  // =========================
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // =========================
  // Confetti controller (necesario)
  // =========================
  late final ConfettiController _confettiController;

  // =========================
  // Controllers para hábitos tipo 'count'
  // =========================
  final Map<String, TextEditingController> _countControllers = {};

  // =========================
  // Estado/controles del formulario "Hábito personalizado"
  // =========================
  final TextEditingController _customTitleCtrl = TextEditingController();
  final TextEditingController _customDescCtrl = TextEditingController();
  final TextEditingController _customTargetCtrl = TextEditingController();
  final TextEditingController _customUnitsCtrl = TextEditingController();

  // =========================
  // Cache del catálogo
  // =========================
  final Map<String, Map<String, dynamic>> _catalogFamiliesById = {};
  final Map<String, Map<String, dynamic>> _catalogHabitsById = {};

  // =========================
  // Estado de calendario (selección)
  // =========================
  late DateTime _selectedDay;
  late DateTime _lastToday;
  bool _didSyncViewDate = false;

  // =========================
  // Secciones colapsables
  // =========================
  final ScrollController _homeScrollController = ScrollController();
  HomeHabitStatusFilter _habitStatusFilter = HomeHabitStatusFilter.pending;
  String? _homeScopeSignature;

  // Obsoleto desde Fase 6C: las secciones inferiores ya no se renderizan.
  bool _showCompleted = false;
  bool _showSkipped = false;
  String? _revealedHomeSwipeHabitId;
  int _habitCompletionTransitionSequence = 0;
  final Map<String, HomeHabitCompletionTransition> _habitCompletionTransitions =
      {};
  late final CompletedDayPhraseController _completedDayPhraseController;
  final NotificationPermissionController _notificationPermissionController =
      NotificationPermissionController();
  bool _didQueuePostLoginNotificationPrompt = false;
  bool _isPostLoginNotificationPromptVisible = false;
  bool _isCheckingPostLoginNotificationPrompt = false;
  bool _didTraceFirstBuild = false;
  int _postLoginPromptRetryCount = 0;
  static const int _maxPostLoginPromptRetries = 4;
  static const String _notificationOnboardingLogPrefix =
      '[NotificationPermissionOnboarding]';

  void _logNotificationOnboarding(String message) {
    if (!kDebugMode) return;
    debugPrint('$_notificationOnboardingLogPrefix $message');
  }

  void _applyHomeState(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  HomeHabitCompletionTransition? _registerHabitCompletionTransition({
    required String habitId,
    required Map<String, dynamic> habit,
    required int originalIndex,
    required HabitCardRightCommitVisualState visualState,
    bool useTapCompletionMotion = false,
  }) {
    final normalizedId = habitId.trim();
    if (normalizedId.isEmpty ||
        _habitCompletionTransitions.containsKey(normalizedId)) {
      return null;
    }

    final transition = HomeHabitCompletionTransition(
      transitionId: (++_habitCompletionTransitionSequence).toString(),
      habitId: normalizedId,
      kind: HomeHabitStatusFeedbackKind.completed,
      originalIndex: originalIndex,
      dateKey: _dateKey(_selectedDay),
      habitSnapshot: Map<String, dynamic>.from(habit),
      startedAt: DateTime.now(),
      initialOffsetX: visualState.offsetX,
      velocityX: visualState.velocityX,
      cardWidth: visualState.cardWidth,
      commitProgress: visualState.commitProgress,
      rightRevealProgress: visualState.rightRevealProgress,
      useTapCompletionMotion: useTapCompletionMotion,
    );
    _applyHomeState(() {
      _habitCompletionTransitions[normalizedId] = transition;
      if (_revealedHomeSwipeHabitId == normalizedId) {
        _revealedHomeSwipeHabitId = null;
      }
    });
    return transition;
  }

  HomeHabitCompletionTransition? _registerHabitSkipTransition({
    required String habitId,
    required Map<String, dynamic> habit,
    required int originalIndex,
    required HabitCardSkipVisualState visualState,
  }) {
    final normalizedId = habitId.trim();
    if (normalizedId.isEmpty ||
        _habitCompletionTransitions.containsKey(normalizedId)) {
      return null;
    }

    final transition = HomeHabitCompletionTransition(
      transitionId: (++_habitCompletionTransitionSequence).toString(),
      habitId: normalizedId,
      kind: HomeHabitStatusFeedbackKind.skipped,
      originalIndex: originalIndex,
      dateKey: _dateKey(_selectedDay),
      habitSnapshot: Map<String, dynamic>.from(habit),
      startedAt: DateTime.now(),
      initialOffsetX: visualState.offsetX,
      velocityX: visualState.velocityX,
      cardWidth: visualState.cardWidth,
      commitProgress: visualState.revealProgress,
      leftRevealProgress: visualState.leftRevealProgress,
    );
    _applyHomeState(() {
      _habitCompletionTransitions[normalizedId] = transition;
      if (_revealedHomeSwipeHabitId == normalizedId) {
        _revealedHomeSwipeHabitId = null;
      }
    });
    return transition;
  }

  void _removeHabitCompletionTransition({
    required String habitId,
    required String transitionId,
  }) {
    final current = _habitCompletionTransitions[habitId];
    if (current == null || current.transitionId != transitionId) return;
    _applyHomeState(() {
      _habitCompletionTransitions.remove(habitId);
    });
  }

  void _markHabitCompletionTransitionVisualCompleted({
    required String habitId,
    required String transitionId,
  }) {
    final current = _habitCompletionTransitions[habitId];
    if (current == null || current.transitionId != transitionId) return;
    final next = current.copyWith(visualAnimationCompleted: true);
    _applyHomeState(() {
      if (next.isReadyForCleanup) {
        _habitCompletionTransitions.remove(habitId);
      } else {
        _habitCompletionTransitions[habitId] = next;
      }
    });
  }

  void _reconcileHabitCompletionTransitions({
    required Set<String> pendingHabitIds,
    required String dateKey,
  }) {
    if (_habitCompletionTransitions.isEmpty) return;

    var hasChanges = false;
    for (final transition in _habitCompletionTransitions.values) {
      final pendingRemoved = transition.dateKey != dateKey ||
          !pendingHabitIds.contains(transition.habitId);
      if (transition.pendingRemoved != pendingRemoved ||
          transition
              .copyWith(pendingRemoved: pendingRemoved)
              .isReadyForCleanup) {
        hasChanges = true;
        break;
      }
    }
    if (!hasChanges) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _habitCompletionTransitions.isEmpty) return;
      var didChange = false;
      final next = Map<String, HomeHabitCompletionTransition>.from(
        _habitCompletionTransitions,
      );
      for (final entry in _habitCompletionTransitions.entries) {
        final transition = entry.value;
        final pendingRemoved = transition.dateKey != dateKey ||
            !pendingHabitIds.contains(transition.habitId);
        final updated = transition.copyWith(pendingRemoved: pendingRemoved);
        if (updated.isReadyForCleanup) {
          next.remove(entry.key);
          didChange = true;
        } else if (transition.pendingRemoved != pendingRemoved) {
          next[entry.key] = updated;
          didChange = true;
        }
      }
      if (!didChange) return;
      _applyHomeState(() {
        _habitCompletionTransitions
          ..clear()
          ..addAll(next);
      });
    });
  }

  void _clearHabitCompletionTransitions() {
    if (_habitCompletionTransitions.isEmpty) return;
    _applyHomeState(_habitCompletionTransitions.clear);
  }

  void _syncHomeUiScope(UserStateStore store) {
    String? safeString(dynamic Function() read) {
      try {
        final value = read()?.toString().trim();
        return value == null || value.isEmpty ? null : value;
      } catch (_) {
        return null;
      }
    }

    int safeInt(dynamic Function() read) {
      try {
        final value = read();
        if (value is int) return value;
        if (value is num) return value.toInt();
        return int.tryParse((value ?? '').toString()) ?? 0;
      } catch (_) {
        return 0;
      }
    }

    final signature = [
      safeString(() => store.activeLocalScopeUserId) ?? '',
      safeString(() => store.userId) ?? '',
      safeInt(() => store.scopeEpoch),
    ].join('|');
    if (_homeScopeSignature == signature) return;

    final hadPreviousScope = _homeScopeSignature != null;
    _homeScopeSignature = signature;
    if (!hadPreviousScope) return;

    _habitStatusFilter = HomeHabitStatusFilter.pending;
    _showCompleted = false;
    _showSkipped = false;
    _revealedHomeSwipeHabitId = null;
    _habitCompletionTransitions.clear();
  }

  void _markVisibleHabitStatusTransitionsFinished() {
    if (_habitCompletionTransitions.isEmpty) return;
    final next = Map<String, HomeHabitCompletionTransition>.from(
      _habitCompletionTransitions,
    );
    var didChange = false;
    for (final entry in _habitCompletionTransitions.entries) {
      final transition = entry.value;
      if (transition.visualAnimationCompleted) continue;
      final updated = transition.copyWith(visualAnimationCompleted: true);
      if (updated.isReadyForCleanup) {
        next.remove(entry.key);
      } else {
        next[entry.key] = updated;
      }
      didChange = true;
    }
    if (!didChange) return;
    _habitCompletionTransitions
      ..clear()
      ..addAll(next);
  }

  Future<void> _applyCountUpdateFromHome({
    required BuildContext context,
    required String habitId,
    required Map<String, dynamic> habit,
    required num currentValue,
    required num nextValue,
    required num targetValue,
    required double cardWidth,
    required Future<void> Function() productiveCallback,
  }) async {
    final crossesToCompleted = shouldAnimateCountCompletionUpdate(
      selectedFilter: _habitStatusFilter,
      currentValue: currentValue,
      nextValue: nextValue,
      targetValue: targetValue,
    );

    HomeHabitCompletionTransition? transition;
    if (crossesToCompleted) {
      transition = _registerHabitCompletionTransition(
        habitId: habitId,
        habit: habit,
        originalIndex: _pendingHabitIndexForTransition(context, habitId),
        visualState: HabitCardRightCommitVisualState(
          offsetX: 0,
          velocityX: homeHabitTapCompletionVelocityX,
          cardWidth: cardWidth,
          commitProgress: 0,
          rightRevealProgress: 0,
        ),
        useTapCompletionMotion: true,
      );
      if (transition == null) return;
    }

    try {
      await productiveCallback();
    } catch (_) {
      if (transition != null) {
        _removeHabitCompletionTransition(
          habitId: transition.habitId,
          transitionId: transition.transitionId,
        );
      }
      rethrow;
    }
  }

  void _scrollHomeToTopOnNextFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_homeScrollController.hasClients) return;
      final position = _homeScrollController.position;
      if (!position.hasPixels || !position.hasContentDimensions) return;
      final target = position.minScrollExtent;
      if (!target.isFinite) return;
      _homeScrollController.jumpTo(target);
    });
  }

  void _keepHomeScrollPositionValidOnNextFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_homeScrollController.hasClients) return;
      final position = _homeScrollController.position;
      if (!position.hasPixels || !position.hasContentDimensions) return;
      final current = position.pixels;
      final min = position.minScrollExtent;
      final max = position.maxScrollExtent;
      if (!current.isFinite || !min.isFinite || !max.isFinite) return;
      final clamped = current.clamp(min, max).toDouble();
      if (clamped != current) {
        _homeScrollController.jumpTo(clamped);
      }
    });
  }

  void _selectHabitStatusFilter(HomeHabitStatusFilter filter) {
    if (filter == _habitStatusFilter) {
      return;
    }

    _applyHomeState(() {
      _revealedHomeSwipeHabitId = null;
      _showCompleted = false;
      _showSkipped = false;
      _markVisibleHabitStatusTransitionsFinished();
      _habitStatusFilter = filter;
    });
    _scrollHomeToTopOnNextFrame();
  }

  Future<void> _handleManualRefresh(UserStateStore store) async {
    try {
      await store.maybeSyncHabitsFromRemoteBestEffort(ignoreCooldown: true);
    } catch (error) {
      debugPrint('[home_refresh] manual refresh failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    _traceFirstBuildCosmeticsContract(context);
    return buildContent(context);
  }

  @override
  void initState() {
    super.initState();
    _completedDayPhraseController = CompletedDayPhraseController();
    WidgetsBinding.instance.addObserver(this);

    _selectedDay = _onlyDate(DateTime.now());
    _lastToday = _selectedDay;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<UserStateStore>();
      if (s.state == null && !s.isLoading) {
        s.load();
      }
    });
    unawaited(
      context.read<UserStateStore>().maybeSyncHabitsFromRemoteBestEffort(),
    );
    _schedulePostLoginNotificationPrompt();

    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 650),
    );

    _primeCatalogFamilies();
  }

  void _traceFirstBuildCosmeticsContract(BuildContext context) {
    if (_didTraceFirstBuild || !kDebugMode) return;
    _didTraceFirstBuild = true;
    var valid = true;
    try {
      final bootstrap = context.read<BootstrapController>();
      final cosmetics = context.read<ShopCosmeticsController>();
      final token = bootstrap.state.cosmeticsReadyToken;
      final wallpaper =
          cosmetics.getEquippedWallpaperAssetOrNullSync()?.assetPath;
      final habitCard = cosmetics.getEquippedHabitCardAssetOrNullSync()?.id;
      final userCard = cosmetics.getEquippedUserCardAssetOrNullSync()?.id;
      debugPrint(
        '[BootstrapTrace] event=home_first_build '
        'runId=${bootstrap.state.runId} '
        'mode=${bootstrap.state.mode == BootstrapRunMode.coldStart ? 'cold_start' : 'in_app'} '
        'controllerIdentity=${identityHashCode(cosmetics)} '
        'scope=${token?.scope ?? 'none'} '
        'appliedRevision=${cosmetics.cloudSnapshotRevision} '
        'equippedWallpaperId=${token?.equippedWallpaperId ?? 'none'} '
        'equippedHabitCardId=${token?.equippedHabitCardId ?? 'none'} '
        'equippedUserCardId=${token?.equippedUserCardId ?? 'none'} '
        'wallpaperResolved=${wallpaper != null || token?.equippedWallpaperId == null} '
        'habitCardResolved=${habitCard != null || token?.equippedHabitCardId == null} '
        'userCardResolved=${userCard != null || token?.equippedUserCardId == null}',
      );
      valid = token != null && cosmetics.validateReadyToken(token);
      debugPrint(
        '[BootstrapTrace] event=home_cosmetics_resolved '
        'controllerIdentity=${identityHashCode(cosmetics)} '
        'scope=${token?.scope ?? 'none'} '
        'appliedRevision=${cosmetics.cloudSnapshotRevision} '
        'wallpaperResolved=${wallpaper != null || token?.equippedWallpaperId == null} '
        'habitCardResolved=${habitCard != null || token?.equippedHabitCardId == null} '
        'userCardResolved=${userCard != null || token?.equippedUserCardId == null}',
      );
      assert(valid, 'Home readiness cosmetics contract violated.');
    } catch (_) {
      debugPrint(
        '[BootstrapTrace] event=home_readiness_contract_violated '
        'reason=missing_provider_or_invalid_token',
      );
      return;
    }
    assert(valid, 'Home readiness cosmetics contract violated.');
  }

  void _schedulePostLoginNotificationPrompt() {
    if (_didQueuePostLoginNotificationPrompt) {
      _logNotificationOnboarding(
        '_schedulePostLoginNotificationPrompt(): skipped (already queued)',
      );
      return;
    }
    _didQueuePostLoginNotificationPrompt = true;
    _logNotificationOnboarding(
      '_schedulePostLoginNotificationPrompt(): queued',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logNotificationOnboarding(
        '_schedulePostLoginNotificationPrompt(): post frame callback fired',
      );
      _maybeShowPostLoginNotificationPrompt();
    });
  }

  Future<void> _maybeShowPostLoginNotificationPrompt() async {
    _logNotificationOnboarding(
      '_maybeShowPostLoginNotificationPrompt(): entered (mounted=$mounted, '
      'isVisible=$_isPostLoginNotificationPromptVisible, '
      'isChecking=$_isCheckingPostLoginNotificationPrompt, '
      'retryCount=$_postLoginPromptRetryCount)',
    );
    if (!mounted) {
      _logNotificationOnboarding(
        '_maybeShowPostLoginNotificationPrompt(): exit reason=not mounted',
      );
      return;
    }
    if (_isPostLoginNotificationPromptVisible) {
      _logNotificationOnboarding(
        '_maybeShowPostLoginNotificationPrompt(): exit reason=sheet already visible',
      );
      return;
    }
    if (_isCheckingPostLoginNotificationPrompt) {
      _logNotificationOnboarding(
        '_maybeShowPostLoginNotificationPrompt(): exit reason=check already in progress',
      );
      return;
    }

    final store = context.read<UserStateStore>();
    if ((store.state == null || store.isLoading) &&
        _postLoginPromptRetryCount < _maxPostLoginPromptRetries) {
      _postLoginPromptRetryCount += 1;
      _logNotificationOnboarding(
        '_maybeShowPostLoginNotificationPrompt(): postpone '
        '(reason=home initial state not ready, stateIsNull=${store.state == null}, '
        'isLoading=${store.isLoading}, retry=$_postLoginPromptRetryCount/$_maxPostLoginPromptRetries)',
      );
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        _maybeShowPostLoginNotificationPrompt();
      });
      return;
    }

    _isCheckingPostLoginNotificationPrompt = true;
    try {
      final shouldShow =
          await _notificationPermissionController.shouldShowPostLoginPrompt();
      _logNotificationOnboarding(
        '_maybeShowPostLoginNotificationPrompt(): shouldShowPostLoginPrompt=$shouldShow',
      );
      if (!mounted) {
        _logNotificationOnboarding(
          '_maybeShowPostLoginNotificationPrompt(): exit reason=unmounted after shouldShow check',
        );
        return;
      }
      if (!shouldShow) {
        _logNotificationOnboarding(
          '_maybeShowPostLoginNotificationPrompt(): exit reason=controller decided false',
        );
        return;
      }
      if (_isPostLoginNotificationPromptVisible) {
        _logNotificationOnboarding(
          '_maybeShowPostLoginNotificationPrompt(): exit reason=sheet became visible before opening',
        );
        return;
      }

      _isPostLoginNotificationPromptVisible = true;
      _logNotificationOnboarding(
        '_maybeShowPostLoginNotificationPrompt(): opening onboarding sheet',
      );
      NotificationPermissionOnboardingOutcome? result;
      try {
        result = await showNotificationPermissionOnboardingSheet(
          context,
          controller: _notificationPermissionController,
        );
      } finally {
        _isPostLoginNotificationPromptVisible = false;
      }
      if (!mounted) return;
      _logNotificationOnboarding(
        '_maybeShowPostLoginNotificationPrompt(): sheet dismissed with result=$result',
      );

      if (result == NotificationPermissionOnboardingOutcome.denied ||
          result == NotificationPermissionOnboardingOutcome.permanentlyDenied) {
        await _showNotificationPermissionDeniedFeedback();
      }
    } catch (error) {
      _logNotificationOnboarding(
        '_maybeShowPostLoginNotificationPrompt(): error=$error',
      );
      _isPostLoginNotificationPromptVisible = false;
    } finally {
      _isCheckingPostLoginNotificationPrompt = false;
    }
  }

  Future<void> _showNotificationPermissionDeniedFeedback() async {
    if (!mounted) return;
    final permissionResult =
        await _notificationPermissionController.getSystemPermissionResult();
    if (!mounted) return;
    await showNotificationPermissionRecoverySheet(
      context,
      controller: _notificationPermissionController,
      permissionResult: permissionResult,
    );
  }

  // ignore: unused_element
  Widget _skippedHeader({required int count}) {
    final hasItems = count > 0;

    // Obsoleto desde Fase 6C: se conserva temporalmente para facilitar retiro
    // posterior, pero ya no se pasa al arbol de Habit Cards.
    // IOS-FIRST IMPROVEMENT START
    return _HomeSectionToggle(
      icon: CupertinoIcons.forward_end_alt_fill,
      title: context.l10n.homeSkippedCount(count.toString()),
      isExpanded: _showSkipped,
      onTap: hasItems
          ? () => _applyHomeState(() => _showSkipped = !_showSkipped)
          : () {},
    );
    // IOS-FIRST IMPROVEMENT END
  }

  Future<void> _editCountValueDialog({
    required BuildContext context,
    required Map<String, dynamic> habit,
    required String habitId,
    required DateTime date,
    required num currentValue,
    required num targetValue,
    required double cardWidth,
    String? unitLabel,
  }) async {
    final controller = TextEditingController(text: currentValue.toString());
    // IOS-FIRST IMPROVEMENT START
    final result = await showCupertinoDialog<int>(
      context: context,
      builder: (ctx) {
        var didSubmit = false;
        return CupertinoAlertDialog(
          title: Text(context.l10n.homeEditCounterTitle),
          content: Padding(
            padding: const EdgeInsets.only(top: IosSpacing.sm),
            child: CupertinoTextField(
              controller: controller,
              keyboardType: TextInputType.number,
              placeholder: context.l10n.homeEditCounterHint,
              suffix: (unitLabel ?? '').trim().isEmpty
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: IosSpacing.sm),
                      child: Text(
                        unitLabel!.trim(),
                        style: IosTypography.caption(ctx),
                      ),
                    ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.commonCancel),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                if (didSubmit) return;
                final raw = controller.text.trim();
                final v = int.tryParse(raw);
                if (v == null) return;
                didSubmit = true;
                Navigator.pop(ctx, v);
              },
              child: Text(context.l10n.commonSave),
            ),
          ],
        );
      },
    );
    // IOS-FIRST IMPROVEMENT END

    if (result == null) return;

    final safe = result < 0 ? 0 : result;
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !context.mounted) return;

    await _applyCountUpdateFromHome(
      context: context,
      habitId: habitId,
      habit: habit,
      currentValue: currentValue,
      nextValue: safe,
      targetValue: targetValue,
      cardWidth: cardWidth,
      productiveCallback: () =>
          this.context.read<UserStateStore>().setCountHabitValueForDate(
                habitId: habitId,
                date: date,
                value: safe,
              ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      final store = context.read<UserStateStore>();
      store.state;
      unawaited(store.maybeSyncHabitsFromRemoteBestEffort());

      final today = _onlyDate(DateTime.now());
      if (today != _lastToday && _selectedDay == _lastToday) {
        setState(() {
          _selectedDay = today;
        });
        _clearHabitCompletionTransitions();
      }
      _lastToday = today;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    _homeScrollController.dispose();

    for (final c in _countControllers.values) {
      c.dispose();
    }

    _customTitleCtrl.dispose();
    _customDescCtrl.dispose();
    _customTargetCtrl.dispose();
    _customUnitsCtrl.dispose();
    _habitCompletionTransitions.clear();
    _completedDayPhraseController.dispose();

    super.dispose();
  }
}

enum HomeHabitStatusFilter {
  pending,
  completed,
  skipped,
}

@visibleForTesting
List<Map<String, dynamic>> habitsForFilter(
  HomeViewData viewData,
  HomeHabitStatusFilter filter,
) {
  return switch (filter) {
    HomeHabitStatusFilter.pending => viewData.pendingHabits,
    HomeHabitStatusFilter.completed => viewData.completedHabits,
    HomeHabitStatusFilter.skipped => viewData.skippedHabits,
  };
}

@visibleForTesting
bool shouldAnimateCountCompletionUpdate({
  required HomeHabitStatusFilter selectedFilter,
  required num currentValue,
  required num nextValue,
  required num targetValue,
}) {
  if (selectedFilter != HomeHabitStatusFilter.pending) return false;
  return currentValue < targetValue && nextValue >= targetValue;
}

@visibleForTesting
const double homeHabitStatusFeedbackExitMargin = 24;

@visibleForTesting
const double homeHabitTapCompletionVelocityX = 0;

@visibleForTesting
const double homeHabitTapCompletionSpringStiffness = 156.25;

@visibleForTesting
const double homeHabitTapCompletionSpringDamping = 26.25;

@visibleForTesting
class HomeHabitCompletionTransition {
  const HomeHabitCompletionTransition({
    required this.transitionId,
    required this.habitId,
    this.kind = HomeHabitStatusFeedbackKind.completed,
    required this.originalIndex,
    required this.dateKey,
    required this.habitSnapshot,
    required this.startedAt,
    required this.initialOffsetX,
    required this.velocityX,
    required this.cardWidth,
    required this.commitProgress,
    this.rightRevealProgress = 1,
    this.leftRevealProgress = 1,
    this.useTapCompletionMotion = false,
    this.visualAnimationCompleted = false,
    this.pendingRemoved = false,
  });

  final String transitionId;
  final String habitId;
  final HomeHabitStatusFeedbackKind kind;
  final int originalIndex;
  final String dateKey;
  final Map<String, dynamic> habitSnapshot;
  final DateTime startedAt;
  final double initialOffsetX;
  final double velocityX;
  final double cardWidth;
  final double commitProgress;
  final double rightRevealProgress;
  final double leftRevealProgress;
  final bool useTapCompletionMotion;
  final bool visualAnimationCompleted;
  final bool pendingRemoved;

  bool get isReadyForCleanup => visualAnimationCompleted && pendingRemoved;

  double get exitOffsetX {
    final offset = cardWidth + homeHabitStatusFeedbackExitMargin;
    return kind == HomeHabitStatusFeedbackKind.skipped ? -offset : offset;
  }

  Key get widgetKey =>
      ValueKey('habit_completion_transition_${transitionId}_$habitId');

  HomeHabitCompletionTransition copyWith({
    bool? visualAnimationCompleted,
    bool? pendingRemoved,
  }) {
    return HomeHabitCompletionTransition(
      transitionId: transitionId,
      habitId: habitId,
      kind: kind,
      originalIndex: originalIndex,
      dateKey: dateKey,
      habitSnapshot: habitSnapshot,
      startedAt: startedAt,
      initialOffsetX: initialOffsetX,
      velocityX: velocityX,
      cardWidth: cardWidth,
      commitProgress: commitProgress,
      rightRevealProgress: rightRevealProgress,
      leftRevealProgress: leftRevealProgress,
      useTapCompletionMotion: useTapCompletionMotion,
      visualAnimationCompleted:
          visualAnimationCompleted ?? this.visualAnimationCompleted,
      pendingRemoved: pendingRemoved ?? this.pendingRemoved,
    );
  }
}
