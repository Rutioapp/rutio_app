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
  bool _showCompleted = false;
  bool _showSkipped = false;
  final NotificationPermissionController _notificationPermissionController =
      NotificationPermissionController();
  bool _didQueuePostLoginNotificationPrompt = false;
  bool _isPostLoginNotificationPromptVisible = false;
  bool _isCheckingPostLoginNotificationPrompt = false;
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
    _schedulePostLoginNotificationPrompt();

    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 650),
    );

    _primeCatalogFamilies();
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
