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

  String _homeSwipeDeleteConfirmBody(BuildContext context) => _isSpanishHomeSwipe(
          context)
      ? 'Se borrará el hábito y su historial. Esta acción no se puede deshacer.'
      : 'The habit and its history will be deleted. This action cannot be undone.';

  String _homeSwipeDeleteConfirmAction(BuildContext context) =>
      _isSpanishHomeSwipe(context) ? 'Eliminar' : 'Delete';

  int _pendingHabitIndexForTransition(BuildContext context, String habitId) {
    final root = context.read<UserStateStore>().state;
    if (root == null) return 0;
    final pending = buildHomeViewData(root, _selectedDay).pendingHabits;
    final index = pending.indexWhere(
      (habit) => (habit['id'] ?? habit['habitId'] ?? '').toString() == habitId,
    );
    return index < 0 ? pending.length : index;
  }

  String _homeTimesPerWeekProgressLabel(
    BuildContext context, {
    required int completed,
    required int target,
  }) {
    final base = '$completed/$target';
    return _isSpanishHomeSwipe(context)
        ? '$base esta semana'
        : '$base this week';
  }

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

  Future<void> _deleteHabitInStoreFromHome(
      UserStateStore store, String id) async {
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
    ShopAsset? backgroundAsset,
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
    final isTimesPerWeekCheck = habit['isTimesPerWeekCheck'] == true;
    final weeklyCompletedCount =
        toNum(habit['weeklyCompletedCount'], fallback: 0).toInt();
    final weeklyTargetCount =
        toPositiveNum(habit['weeklyTargetCount'], fallback: 1).toInt();
    final String? weeklyProgressLabel = isTimesPerWeekCheck
        ? _homeTimesPerWeekProgressLabel(
            context,
            completed: weeklyCompletedCount,
            target: weeklyTargetCount,
          )
        : null;

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

    void openHabitDetails({
      required HabitDetailScreenMode mode,
      int initialTab = 0,
    }) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => HabitDetailScreen(
            habit: habit,
            familyColor: familyColor,
            mode: mode,
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
      backgroundImageAssetPath: backgroundAsset?.assetPath,
      backgroundImageProvider: backgroundAsset?.imageProvider,
      backgroundImageFit: backgroundAsset?.imageFit ?? BoxFit.cover,
      backgroundImageAlignment:
          backgroundAsset?.imageAlignment ?? Alignment.center,
      backgroundOverlayColor: backgroundAsset?.overlayColor,
      backgroundOverlayOpacity: backgroundAsset?.overlayOpacity ?? 0,
      contentTone: backgroundAsset?.contentTone ?? HabitCardContentTone.dark,
      useContentScrim: backgroundAsset?.useContentScrim ?? false,
      emoji: resolvedEmoji.isEmpty ? null : resolvedEmoji,
      onEmojiTap: resolvedEmoji.isEmpty
          ? null
          : () async {
              final selectedEmoji = await showEmojiPickerBottomSheet(
                context,
                currentEmoji: resolvedEmoji,
                currentHabitName:
                    (habit['title'] ?? habit['name'] ?? '').toString(),
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
      isSkipped: skippedToday,
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
      weeklyProgressLabel: weeklyProgressLabel,
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
              openHabitDetails(
                mode: HabitDetailScreenMode.statsOnly,
                initialTab: initialTab,
              );
              // IOS-FIRST IMPROVEMENT END
            },
      onTap: isTrayOpen ? closeTrayIfOpen : null,
    );

    final revealCard = HabitCardSwipeShell(
      cardId: id,
      isOpen: isTrayOpen,
      compact: compact,
      canSwipeRightComplete: !isCounting,
      skipLabel: _homeSwipeSkipLabel(context),
      editLabel: _homeSwipeEditLabel(context),
      deleteLabel: _homeSwipeDeleteLabel(context),
      onRequestCloseOtherCards: (cardId) {
        if (_revealedHomeSwipeHabitId == null ||
            _revealedHomeSwipeHabitId == cardId) {
          return;
        }
        _applyHomeState(() => _revealedHomeSwipeHabitId = null);
      },
      onRequestOpen: (cardId) {
        if (_revealedHomeSwipeHabitId == cardId) return;
        _applyHomeState(() => _revealedHomeSwipeHabitId = cardId);
      },
      onRequestClose: closeTrayIfOpen,
      onSwipeRightComplete: !isCounting
          ? () async {
              final transition = _registerHabitCompletionTransition(
                habitId: id,
                habit: habit,
                originalIndex: _pendingHabitIndexForTransition(context, id),
              );
              IosFeedback.lightImpact();
              try {
                await context.read<UserStateStore>().setHabitCompletionForKey(
                      habitId: id,
                      dateKey: _dateKey(_selectedDay),
                      done: !doneToday,
                    );
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
          : null,
      onSkip: () async {
        await context.read<UserStateStore>().setHabitSkipForKey(
              habitId: id,
              dateKey: _dateKey(_selectedDay),
              skipped: !skippedToday,
            );
      },
      onEdit: () => openHabitDetails(mode: HabitDetailScreenMode.editOnly),
      onDelete: () async {
        await _confirmAndDeleteHabitFromHome(context, habitId: id);
      },
      child: card,
    );

    return revealCard;
  }

  Widget _habitCompletionTransitionCard({
    required BuildContext context,
    required HomeHabitCompletionTransition transition,
    ShopAsset? backgroundAsset,
  }) {
    final habit = transition.habitSnapshot;
    final familyId =
        (habit['familyId'] ?? habit['family'] ?? habit['familyKey'] ?? '')
            .toString();
    final familyColor = _familyColor(familyId);
    final familyMeta = _catalogFamiliesById[familyId];
    final familyEmoji = (familyMeta?['emoji'] ?? '').toString().trim();
    final habitEmoji =
        (habit['emoji'] ?? habit['habitEmoji'] ?? '').toString().trim();
    final resolvedEmoji = habitEmoji.isNotEmpty ? habitEmoji : familyEmoji;
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
    final isCounting = type != 'check';

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
    final unitLabel = _localizedUnitLabel(
      context,
      (habit['unit'] ?? habit['unitLabel'] ?? habit['units'] ?? '').toString(),
    );
    final reminderLabel = _habitReminderLabel(habit);
    final isTimesPerWeekCheck = habit['isTimesPerWeekCheck'] == true;
    final weeklyCompletedCount =
        toNum(habit['weeklyCompletedCount'], fallback: 0).toInt();
    final weeklyTargetCount =
        toPositiveNum(habit['weeklyTargetCount'], fallback: 1).toInt();
    final String? weeklyProgressLabel = isTimesPerWeekCheck
        ? _homeTimesPerWeekProgressLabel(
            context,
            completed: weeklyCompletedCount + 1,
            target: weeklyTargetCount,
          )
        : null;

    String completionBurstText = context.l10n.homeHabitCompletionBurstDefault;
    final rawXpReward = habit['xpReward'] ??
        habit['xp'] ??
        habit['rewardXp'] ??
        habit['habitXp'];
    if (rawXpReward is num) {
      completionBurstText = '+${rawXpReward.toInt()} XP';
    } else {
      final raw = (rawXpReward ?? '').toString().trim();
      if (raw.isNotEmpty) completionBurstText = raw;
    }

    return HabitCardWidget(
      title: title,
      description: description,
      backgroundImageAssetPath: backgroundAsset?.assetPath,
      backgroundImageProvider: backgroundAsset?.imageProvider,
      backgroundImageFit: backgroundAsset?.imageFit ?? BoxFit.cover,
      backgroundImageAlignment:
          backgroundAsset?.imageAlignment ?? Alignment.center,
      backgroundOverlayColor: backgroundAsset?.overlayColor,
      backgroundOverlayOpacity: backgroundAsset?.overlayOpacity ?? 0,
      contentTone: backgroundAsset?.contentTone ?? HabitCardContentTone.dark,
      useContentScrim: backgroundAsset?.useContentScrim ?? false,
      emoji: resolvedEmoji.isEmpty ? null : resolvedEmoji,
      familyColor: familyColor,
      progress: isCounting ? (target <= 0 ? 0 : current / target) : 1,
      isCompleted: !isCounting,
      isSkipped: false,
      isCounting: isCounting,
      completionBurstText: completionBurstText,
      currentCount: current,
      targetCount: target,
      unitLabel: unitLabel.isEmpty ? null : unitLabel,
      reminderLabel: reminderLabel,
      weeklyProgressLabel: weeklyProgressLabel,
    );
  }
}
