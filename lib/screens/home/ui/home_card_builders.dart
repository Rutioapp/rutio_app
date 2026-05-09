part of 'package:rutio/screens/home/home_screen.dart';

/// Habit card builders for Home.
///
/// Mantiene en un ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Âºnico sitio la transformaciÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³n de un hÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡bito raw del store a
/// la UI final de `HabitCardWidget`, incluyendo swipe de check y accesos a
/// ediciÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³n/contador.
extension _HomeScreenCardBuilders on _HomeScreenState {
  bool _isSpanishHomeSwipe(BuildContext context) =>
      context.l10n.localeName.toLowerCase().startsWith('es');

  String _homeSwipeSkipLabel(BuildContext context) =>
      _isSpanishHomeSwipe(context) ? 'Saltar' : 'Skip';

  String _homeSwipeEditLabel(BuildContext context) =>
      _isSpanishHomeSwipe(context) ? 'Editar' : 'Edit';

  String _homeSwipeDeleteLabel(BuildContext context) =>
      _isSpanishHomeSwipe(context) ? 'Eliminar' : 'Delete';

  String _homeSwipeDeleteConfirmTitle(BuildContext context) =>
      _isSpanishHomeSwipe(context) ? 'Eliminar hábito' : 'Delete habit';

  String _homeSwipeDeleteConfirmBody(BuildContext context) =>
      _isSpanishHomeSwipe(context)
          ? 'Se borrará el hábito y su historial. Esta acción no se puede deshacer.'
          : 'The habit and its history will be deleted. This action cannot be undone.';

  String _homeSwipeDeleteConfirmAction(BuildContext context) =>
      _isSpanishHomeSwipe(context) ? 'Eliminar' : 'Delete';

  Future<void> _confirmAndDeleteHabitFromHome(
    BuildContext context, {
    required String habitId,
  }) async {
    final normalizedId = habitId.trim();
    if (normalizedId.isEmpty) return;

    final l10n = context.l10n;
    final shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(_homeSwipeDeleteConfirmTitle(context)),
        content: Text(_homeSwipeDeleteConfirmBody(context)),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_homeSwipeDeleteConfirmAction(context)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    if (!context.mounted) return;

    final store = context.read<UserStateStore>();
    await _deleteHabitInStoreFromHome(store, normalizedId);
  }

  Future<void> _deleteHabitInStoreFromHome(UserStateStore store, String id) async {
    final s = store as dynamic;

    for (final fn in <dynamic Function()>[
      () => s.deleteHabit(id),
      () => s.deleteHabitById(id),
      () => s.deleteHabitForever(id),
      () => s.removeHabit(id),
      () => s.removeHabitById(id),
      () => s.deleteHabitAndHistory(id),
      () => s.deleteHabitWithHistory(id),
    ]) {
      try {
        final result = fn();
        if (result is Future) await result;
        return;
      } catch (_) {}
    }

    try {
      final dynamic active = s.activeHabits;
      if (active is List) {
        active.removeWhere((h) {
          final value = (h is Map) ? (h['id'] ?? h['habitId']) : null;
          return value?.toString() == id;
        });
      }
    } catch (_) {}

    try {
      final dynamic all = s.habits;
      if (all is List) {
        all.removeWhere((h) {
          final value = (h is Map) ? (h['id'] ?? h['habitId']) : null;
          return value?.toString() == id;
        });
      }
    } catch (_) {}

    try {
      final saved = s.save();
      if (saved is Future) await saved;
    } catch (_) {}
    try {
      s.notifyListeners();
    } catch (_) {}
  }

  Widget _habitCard({
    required BuildContext context,
    required Map<String, dynamic> habit,
    bool compact = false,
  }) {
    final familyId =
        (habit['familyId'] ?? habit['family'] ?? habit['familyKey'] ?? '')
            .toString();
    final familyColor = _familyColor(familyId);

    final familyMeta = _catalogFamiliesById[familyId];
    final familyEmoji = (familyMeta?['emoji'] ?? '').toString().trim();
    final habitEmoji =
        (habit['emoji'] ?? habit['habitEmoji'] ?? '').toString().trim();
    final resolvedEmoji = habitEmoji.isNotEmpty ? habitEmoji : familyEmoji;

    final id = (habit['id'] ?? habit['habitId'] ?? '').toString();
    final rawTitle =
        (habit['title'] ?? habit['name'] ?? habit['habitName'] ?? '')
            .toString();

    final description = (habit['description'] ??
            habit['subtitle'] ??
            habit['detail'] ??
            habit['goalText'] ??
            habit['note'] ??
            '')
        .toString();

    final type = (habit['type'] ?? habit['kind'] ?? 'check').toString();

    final doneToday = (habit['doneToday'] == true);
    final skippedToday = (habit['skippedToday'] == true);

    num toNum(dynamic v, {num fallback = 0}) {
      if (v is num) {
        if (v is double && !v.isFinite) return fallback;
        return v;
      }
      final raw = (v ?? '').toString().trim();
      if (raw.isEmpty) return fallback;
      final parsed = num.tryParse(raw.replaceAll(',', '.'));
      if (parsed == null) return fallback;
      if (parsed is double && !parsed.isFinite) return fallback;
      return parsed;
    }

    num toPositiveNum(dynamic v, {num fallback = 1}) {
      final parsed = toNum(v, fallback: fallback);
      return parsed > 0 ? parsed : fallback;
    }

    final current = toNum(
      habit['progress'] ?? habit['current'] ?? habit['value'],
      fallback: 0,
    );
    final target =
        toPositiveNum(habit['target'] ?? habit['goal'] ?? 1, fallback: 1);
    final title = _localizedHabitTitle(
      context,
      habit: habit,
      fallbackTitle: rawTitle,
      target: target,
    );
    final isCounting = type != 'check';

    final progress01 = isCounting
        ? (target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0).toDouble())
        : (doneToday && !skippedToday ? 1.0 : 0.0);

    final unitLabel = _localizedUnitLabel(
      context,
      (habit['unit'] ?? habit['unitLabel'] ?? habit['units'] ?? '').toString(),
    );
    final reminderLabel = _habitReminderLabel(habit);

    String completionBurstText = context.l10n.homeHabitCompletionBurstDefault;

    final rawXpReward = habit['xpReward'] ??
        habit['xp'] ??
        habit['rewardXp'] ??
        habit['habitXp'];

    if (rawXpReward is num) {
      completionBurstText = '+${rawXpReward.toInt()} XP';
    } else {
      final raw = (rawXpReward ?? '').toString().trim();
      if (raw.isNotEmpty) {
        completionBurstText = raw;
      }
    }

    void openHabitDetails(int initialTab) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => HabitDetailScreen(
            habit: habit,
            familyColor: familyColor,
            initialTab: initialTab,
            onSaveHabit: (updatedHabit) {
              if (updatedHabit is Map) {
                final updates = <String, dynamic>{};

                for (final k in [
                  'title',
                  'name',
                  'description',
                  'desc',
                  'emoji',
                  'habitEmoji',
                  'notes',
                  'frequency',
                  'cadence',
                  'targetCount',
                  'target',
                  'goal',
                  'times',
                  'type',
                  'trackingType',
                  'habitType',
                  'unit',
                  'unitLabel',
                  'counterUnit',
                  'counterStep',
                  'step',
                  'remindersEnabled',
                  'reminderEnabled',
                  'reminderTime',
                  'archived',
                  'isArchived',
                ]) {
                  if (updatedHabit.containsKey(k)) {
                    updates[k] = updatedHabit[k];
                  }
                }

                _tryUpdateHabit(context, habitId: id, updates: updates);
              }
            },
            onOpenStats: (ctx) {
              _openMonthlyOverview(ctx);
            },
          ),
        ),
      );
    }

    final isTrayOpen = _revealedHomeSwipeHabitId == id;
    void closeTrayIfOpen() {
      if (_revealedHomeSwipeHabitId != id) return;
      _applyHomeState(() => _revealedHomeSwipeHabitId = null);
    }

    final card = HabitCardWidget(
      title: title,
      description: description,
      emoji: resolvedEmoji.isEmpty ? null : resolvedEmoji,
      onEmojiTap: resolvedEmoji.isEmpty
          ? null
          : () async {
              final selectedEmoji = await showEmojiPickerBottomSheet(
                context,
                currentEmoji: resolvedEmoji,
                accentColor: familyColor,
              );
              if (!context.mounted) return;
              final nextEmoji = selectedEmoji?.trim();
              if (nextEmoji == null ||
                  nextEmoji.isEmpty ||
                  nextEmoji == resolvedEmoji) {
                return;
              }

              final store = context.read<UserStateStore>();
              await store.updateHabitDetailsFromEdit({
                'id': id,
                'emoji': nextEmoji,
                'habitEmoji': nextEmoji,
              });
            },
      familyColor: familyColor,
      progress: progress01,
      isCompleted: doneToday && !skippedToday,
      isCounting: isCounting,
      completionBurstText: completionBurstText,
      onCheckTap: () async {
        // IOS-FIRST IMPROVEMENT START
        await IosFeedback.success();
        if (!context.mounted) return;

        context.read<UserStateStore>().setHabitCompletionForKey(
              habitId: id,
              dateKey: _dateKey(_selectedDay),
              done: !(doneToday && !skippedToday),
            );
      },
      currentCount: current,
      targetCount: target,
      unitLabel: unitLabel.isEmpty ? null : unitLabel,
      reminderLabel: reminderLabel,
      onIncrement: isCounting
          ? () {
              final step = toPositiveNum(
                habit['counterStep'] ?? habit['step'] ?? 1,
                fallback: 1,
              ).toDouble();
              final next = current + step;
              context.read<UserStateStore>().setCountHabitValueForDate(
                    habitId: id,
                    date: _selectedDay,
                    value: next,
                  );
            }
          : null,
      onDecrement: isCounting
          ? () {
              final step = toPositiveNum(
                habit['counterStep'] ?? habit['step'] ?? 1,
                fallback: 1,
              ).toDouble();
              final next = current - step;
              context.read<UserStateStore>().setCountHabitValueForDate(
                    habitId: id,
                    date: _selectedDay,
                    value: next < 0 ? 0 : next,
                  );
            }
          : null,
      onCountTap: isCounting
          ? () => _editCountValueDialog(
                context: context,
                habitId: id,
                date: _selectedDay,
                currentValue: current.toInt(),
                unitLabel: unitLabel.isEmpty ? null : unitLabel,
              )
          : null,
      compact: compact,
      onOpenDetails: compact
          ? null
          : (initialTab) {
              openHabitDetails(initialTab);
              // IOS-FIRST IMPROVEMENT END
            },
      onTap: isTrayOpen ? closeTrayIfOpen : null,
    );

    final revealCard = _HomeSwipeActionTray(
      isOpen: isTrayOpen,
      compact: compact,
      canSwipeRightComplete: !isCounting,
      skipLabel: _homeSwipeSkipLabel(context),
      editLabel: _homeSwipeEditLabel(context),
      deleteLabel: _homeSwipeDeleteLabel(context),
      onRequestCloseOthers: () {
        if (_revealedHomeSwipeHabitId == null || _revealedHomeSwipeHabitId == id) {
          return;
        }
        _applyHomeState(() => _revealedHomeSwipeHabitId = null);
      },
      onOpen: () {
        if (_revealedHomeSwipeHabitId == id) return;
        _applyHomeState(() => _revealedHomeSwipeHabitId = id);
      },
      onClose: closeTrayIfOpen,
      onSwipeRightComplete: !isCounting
          ? () async {
              IosFeedback.lightImpact();
              await context.read<UserStateStore>().setHabitCompletionForKey(
                    habitId: id,
                    dateKey: _dateKey(_selectedDay),
                    done: !doneToday,
                  );
            }
          : null,
      onSkip: () async {
        await context.read<UserStateStore>().setHabitSkipForKey(
              habitId: id,
              dateKey: _dateKey(_selectedDay),
              skipped: !skippedToday,
            );
      },
      onEdit: () => openHabitDetails(0),
      onDelete: () async {
        await _confirmAndDeleteHabitFromHome(context, habitId: id);
      },
      child: card,
    );

    return revealCard;
  }
}

class _HomeSwipeActionTray extends StatefulWidget {
  const _HomeSwipeActionTray({
    required this.child,
    required this.isOpen,
    required this.compact,
    required this.canSwipeRightComplete,
    required this.skipLabel,
    required this.editLabel,
    required this.deleteLabel,
    required this.onRequestCloseOthers,
    required this.onOpen,
    required this.onClose,
    required this.onSwipeRightComplete,
    required this.onSkip,
    required this.onEdit,
    required this.onDelete,
  });

  final Widget child;
  final bool isOpen;
  final bool compact;
  final bool canSwipeRightComplete;
  final String skipLabel;
  final String editLabel;
  final String deleteLabel;
  final VoidCallback onRequestCloseOthers;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final Future<void> Function()? onSwipeRightComplete;
  final Future<void> Function() onSkip;
  final VoidCallback? onEdit;
  final Future<void> Function() onDelete;

  static const double _actionWidth = 78;
  static const double _openThresholdRatio = 0.30;
  static const double _rightCompleteThreshold = 72;

  @override
  State<_HomeSwipeActionTray> createState() => _HomeSwipeActionTrayState();
}

class _HomeSwipeActionTrayState extends State<_HomeSwipeActionTray>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _offsetAnimation;

  double _offset = 0;
  bool _isDragging = false;
  double _rightDragDistance = 0;

  double get _revealWidth => _HomeSwipeActionTray._actionWidth * 3;
  double get _openOffset => -_revealWidth;

  @override
  void initState() {
    super.initState();
    _offset = widget.isOpen ? _openOffset : 0;
    _offsetAnimation = AlwaysStoppedAnimation<double>(_offset);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )
      ..addListener(() {
        setState(() {
          _offset = _offsetAnimation.value;
        });
      });
  }

  @override
  void didUpdateWidget(covariant _HomeSwipeActionTray oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isDragging) return;

    if (oldWidget.isOpen != widget.isOpen) {
      _animateTo(widget.isOpen ? _openOffset : 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    final clampedTarget = target.clamp(_openOffset, 0.0);
    if ((_offset - clampedTarget).abs() < 0.5) {
      setState(() => _offset = clampedTarget);
      return;
    }

    _controller.stop();
    _offsetAnimation = Tween<double>(
      begin: _offset,
      end: clampedTarget,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller
      ..value = 0
      ..forward();
  }

  Future<void> _handleAction(Future<void> Function() callback) async {
    widget.onClose();
    await callback();
  }

  void _handleHorizontalStart(DragStartDetails details) {
    _isDragging = true;
    _rightDragDistance = 0;
    widget.onRequestCloseOthers();
    _controller.stop();
  }

  void _handleHorizontalUpdate(DragUpdateDetails details) {
    final dx = details.delta.dx;
    if (dx == 0) return;

    if (dx > 0 && _offset == 0) {
      _rightDragDistance += dx;
      return;
    }

    final nextOffset = (_offset + dx).clamp(_openOffset, 0.0);
    if (nextOffset == _offset) return;

    setState(() {
      _offset = nextOffset;
      if (_offset < -2 && !widget.isOpen) {
        widget.onOpen();
      }
    });
  }

  Future<void> _handleHorizontalEnd(DragEndDetails details) async {
    _isDragging = false;
    final rightVelocity = details.velocity.pixelsPerSecond.dx;

    if (_offset == 0 &&
        widget.canSwipeRightComplete &&
        widget.onSwipeRightComplete != null &&
        (_rightDragDistance >= _HomeSwipeActionTray._rightCompleteThreshold ||
            rightVelocity >= 420)) {
      _rightDragDistance = 0;
      await widget.onSwipeRightComplete!.call();
      return;
    }
    _rightDragDistance = 0;

    if (_offset >= 0) {
      _animateTo(0);
      return;
    }

    final openThreshold = _revealWidth * _HomeSwipeActionTray._openThresholdRatio;
    final shouldOpen =
        _offset.abs() >= openThreshold || details.velocity.pixelsPerSecond.dx < -320;

    if (shouldOpen) {
      widget.onOpen();
      _animateTo(_openOffset);
      return;
    }

    widget.onClose();
    _animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final revealWidth = _revealWidth;
    final verticalInset = widget.compact ? 6.0 : 8.0;
    final radius = widget.compact ? 18.0 : 20.0;
    final progress = (_offset.abs() / revealWidth).clamp(0.0, 1.0);
    final showTray = progress > 0.001;

    return Stack(
      children: [
        if (showTray)
          Positioned.fill(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: verticalInset),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: revealWidth,
                  child: Row(
                    children: [
                      _SwipeTrayActionButton(
                        icon: CupertinoIcons.forward_end_fill,
                        label: widget.skipLabel,
                        onTap: () => _handleAction(widget.onSkip),
                      ),
                      _SwipeTrayActionButton(
                        icon: CupertinoIcons.pencil,
                        label: widget.editLabel,
                        onTap: widget.onEdit == null
                            ? null
                            : () {
                                widget.onClose();
                                widget.onEdit!.call();
                              },
                      ),
                      _SwipeTrayActionButton(
                        icon: CupertinoIcons.delete,
                        label: widget.deleteLabel,
                        isDestructive: true,
                        onTap: () => _handleAction(widget.onDelete),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(_offset, 0, 0),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _handleHorizontalStart,
            onHorizontalDragUpdate: _handleHorizontalUpdate,
            onHorizontalDragEnd: _handleHorizontalEnd,
            onTap: widget.isOpen ? widget.onClose : null,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _SwipeTrayActionButton extends StatelessWidget {
  const _SwipeTrayActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final foreground = isDestructive
        ? CupertinoColors.destructiveRed
        : CupertinoColors.label.withValues(alpha: 0.82);

    return Expanded(
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        minSize: 42,
        onPressed: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: foreground),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
