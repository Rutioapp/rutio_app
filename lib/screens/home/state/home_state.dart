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
  late final OnboardingController _onboardingController;

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
  bool _didPrimeHomeOnboarding = false;
  bool _isHomeOnboardingSyncScheduled = false;
  bool _isLaunchingAddHabitSheetFromOnboarding = false;
  bool? _lastHomeOnboardingHasAnyHabits;
  String? _lastHomeOnboardingScopeId;

  // =========================
  // Secciones colapsables
  // =========================
  bool _showCompleted = false;
  bool _showSkipped = false;

  void _applyHomeState(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  List<OnboardingStep> _buildHomeOnboardingSteps(HomeViewData homeData) {
    final steps = <OnboardingStep>[
      OnboardingStep(
        id: 'home_create_first_habit_phase_1',
        screenId: OnboardingScreens.home,
        message: 'Empieza creando tu primer hábito.',
        primaryLabel: 'Continuar',
        contentType: OnboardingContentType.cta,
        targetId: OnboardingTargetIds.homeAddHabitFab,
        shouldDisplay: _shouldShowHomeFirstHabitOnboarding,
      ),
    ];

    steps.addAll(_buildHomeHabitUsageOnboardingSteps(homeData));

    return steps;
  }

  List<OnboardingStep> _buildHomeHabitUsageOnboardingSteps(
    HomeViewData homeData,
  ) {
    final candidates = _resolveHomeHabitUsageCandidates(homeData);

    return candidates.map((candidate) {
      final isCheck = candidate.trackingType == 'check';

      return OnboardingStep(
        id: isCheck
            ? 'home_first_habit_check_usage_phase_2'
            : 'home_first_habit_count_usage_phase_2',
        screenId: OnboardingScreens.home,
        message: isCheck
            ? 'Pulsa el círculo para marcarlo como realizado.'
            : 'Usa + y − para registrar tu progreso.',
        primaryLabel: 'Entendido',
        priority: candidate.priority,
        targetId: isCheck
            ? OnboardingTargetIds.homeFirstHabitCheckControl
            : OnboardingTargetIds.homeFirstHabitCountControls,
        targetEntityId: candidate.habitId,
        contentType: OnboardingContentType.cta,
        shouldDisplay: _shouldShowHomeHabitUsageOnboarding,
      );
    }).toList(growable: false);
  }

  List<_HomeOnboardingHabitCandidate> _resolveHomeHabitUsageCandidates(
    HomeViewData homeData,
  ) {
    final prioritizedHabits = <Map<String, dynamic>>[];
    final seenHabitIds = <String>{};
    final seenTrackingTypes = <String>{};

    void collect(List<Map<String, dynamic>> habits) {
      for (final habit in habits) {
        final habitId =
            (habit['id'] ?? habit['habitId'] ?? '').toString().trim();
        if (habitId.isEmpty || !seenHabitIds.add(habitId)) {
          continue;
        }

        prioritizedHabits.add(habit);
      }
    }

    collect(homeData.pendingHabits);
    collect(homeData.viewHabits);
    collect(homeData.visibleHabits);

    final candidates = <_HomeOnboardingHabitCandidate>[];

    for (final habit in prioritizedHabits) {
      final habitId = (habit['id'] ?? habit['habitId'] ?? '').toString().trim();
      final trackingType = (habit['type'] ?? habit['kind'] ?? 'check')
          .toString()
          .trim()
          .toLowerCase();

      if (habitId.isEmpty ||
          (trackingType != 'check' && trackingType != 'count')) {
        continue;
      }

      if (!seenTrackingTypes.add(trackingType)) {
        continue;
      }

      candidates.add(
        _HomeOnboardingHabitCandidate(
          habitId: habitId,
          trackingType: trackingType,
          priority: 10 + candidates.length,
        ),
      );
    }

    return candidates;
  }

  Future<void> _maybeCompleteOnboardingFromTargetInteraction({
    required String targetId,
    required String habitId,
  }) async {
    if (_onboardingController.isMutating) {
      return;
    }

    final shouldComplete = _onboardingController.isCurrentTarget(
      targetId,
      targetEntityId: habitId,
    );

    if (!shouldComplete) {
      return;
    }

    await _onboardingController.completeCurrent();
  }

  void _scheduleHomeOnboardingSync(
    UserStateStore store,
    HomeViewData homeData,
  ) {
    final hasAnyHabits = store.activeHabits.isNotEmpty;
    final scopeId = store.userId ?? store.authEmail;
    final shouldSync = !_didPrimeHomeOnboarding ||
        _lastHomeOnboardingHasAnyHabits != hasAnyHabits ||
        _lastHomeOnboardingScopeId != scopeId;

    if (!shouldSync || _isHomeOnboardingSyncScheduled) {
      return;
    }

    _isHomeOnboardingSyncScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _isHomeOnboardingSyncScheduled = false;
      if (!mounted) {
        return;
      }

      final latestStore = context.read<UserStateStore>();
      final latestRoot = latestStore.state;
      if (latestRoot == null) {
        return;
      }

      final latestHomeData = buildHomeViewData(latestRoot, _selectedDay);
      await _syncHomeOnboarding(latestStore, latestHomeData);
    });
  }

  Future<void> _syncHomeOnboarding(
    UserStateStore store,
    HomeViewData homeData,
  ) async {
    final hasAnyHabits = store.activeHabits.isNotEmpty;
    final scopeId = store.userId ?? store.authEmail;

    _lastHomeOnboardingHasAnyHabits = hasAnyHabits;
    _lastHomeOnboardingScopeId = scopeId;
    _didPrimeHomeOnboarding = true;

    await _onboardingController.configure(
      steps: _buildHomeOnboardingSteps(homeData),
      displayContext: OnboardingDisplayContext(
        screenId: OnboardingScreens.home,
        hasAnyHabits: hasAnyHabits,
        userScopeId: scopeId,
        availableTargetIds: const <String>{
          OnboardingTargetIds.homeAddHabitFab,
          OnboardingTargetIds.homeFirstHabitCheckControl,
          OnboardingTargetIds.homeFirstHabitCountControls,
        },
      ),
    );
  }

  Future<void> _handleHomeOnboardingDismiss(OnboardingStep _) async {
    await _onboardingController.dismissCurrent();
  }

  Future<void> _handleHomeAddHabitPressed() async {
    if (_isLaunchingAddHabitSheetFromOnboarding ||
        _onboardingController.isMutating) {
      return;
    }

    final shouldCompleteCurrentStep = _onboardingController.isCurrentTarget(
      OnboardingTargetIds.homeAddHabitFab,
    );

    await _showAddHabitSheet(
      completeCurrentOnboardingStep: shouldCompleteCurrentStep,
    );
  }

  Future<void> _handleHomeOnboardingContinue(OnboardingStep _) async {
    await _showAddHabitSheet(completeCurrentOnboardingStep: true);
  }

  Future<void> _showAddHabitSheet({
    required bool completeCurrentOnboardingStep,
  }) async {
    if (!completeCurrentOnboardingStep) {
      if (!mounted) {
        return;
      }

      await showHomeAddHabitSheet(context);
      return;
    }

    if (_isLaunchingAddHabitSheetFromOnboarding) {
      return;
    }

    _isLaunchingAddHabitSheetFromOnboarding = true;
    final didComplete = await _onboardingController.completeCurrent();
    if (!didComplete) {
      _isLaunchingAddHabitSheetFromOnboarding = false;
      return;
    }

    if (!mounted) {
      _isLaunchingAddHabitSheetFromOnboarding = false;
      return;
    }

    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(OnboardingOverlay.sheetLaunchDelay);

    if (!mounted) {
      _isLaunchingAddHabitSheetFromOnboarding = false;
      return;
    }

    try {
      await showHomeAddHabitSheet(context);
    } finally {
      _isLaunchingAddHabitSheetFromOnboarding = false;
    }
  }

  @override
  Widget build(BuildContext context) => buildContent(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _selectedDay = _onlyDate(DateTime.now());
    _lastToday = _selectedDay;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<UserStateStore>();
      if (s.state == null && !s.isLoading) {
        s.load();
      }
    });

    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 650),
    );
    _onboardingController = OnboardingController(
      persistenceService: OnboardingPersistenceService(),
    );

    _primeCatalogFamilies();
  }

  Widget _skippedHeader({required int count}) {
    final hasItems = count > 0;

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
    required String habitId,
    required DateTime date,
    required int currentValue,
    String? unitLabel,
  }) async {
    final store = this.context.read<UserStateStore>();
    final controller = TextEditingController(text: currentValue.toString());
    // IOS-FIRST IMPROVEMENT START
    final result = await showCupertinoDialog<int>(
      context: context,
      builder: (ctx) {
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
                final raw = controller.text.trim();
                final v = int.tryParse(raw);
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

    store.setCountHabitValueForDate(
      habitId: habitId,
      date: date,
      value: safe,
    );

    await _maybeCompleteOnboardingFromTargetInteraction(
      targetId: OnboardingTargetIds.homeFirstHabitCountControls,
      habitId: habitId,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      final store = context.read<UserStateStore>();
      store.state;

      final today = _onlyDate(DateTime.now());
      if (today != _lastToday && _selectedDay == _lastToday) {
        setState(() {
          _selectedDay = today;
        });
      }
      _lastToday = today;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    _onboardingController.dispose();

    for (final c in _countControllers.values) {
      c.dispose();
    }

    _customTitleCtrl.dispose();
    _customDescCtrl.dispose();
    _customTargetCtrl.dispose();
    _customUnitsCtrl.dispose();

    super.dispose();
  }
}

class _HomeOnboardingHabitCandidate {
  const _HomeOnboardingHabitCandidate({
    required this.habitId,
    required this.trackingType,
    required this.priority,
  });

  final String habitId;
  final String trackingType;
  final int priority;
}
