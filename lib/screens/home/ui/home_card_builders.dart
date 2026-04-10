part of 'package:rutio/screens/home/home_screen.dart';

/// Habit card builders for Home.
///
/// Mantiene en un ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Âºnico sitio la transformaciÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³n de un hÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡bito raw del store a
/// la UI final de `HabitCardWidget`, incluyendo swipe de check y accesos a
/// ediciÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â³n/contador.
extension _HomeScreenCardBuilders on _HomeScreenState {
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

    final card = Selector<OnboardingController, bool>(
      selector: (_, onboarding) => onboarding.isTargetActive(
        isCounting
            ? OnboardingTargetIds.homeFirstHabitCountControls
            : OnboardingTargetIds.homeFirstHabitCheckControl,
        targetEntityId: id,
      ),
      builder: (context, isTargetActive, _) {
        return HabitCardWidget(
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
          highlightCheckControl: !isCounting && isTargetActive,
          highlightCountControls: isCounting && isTargetActive,
          onCheckTap: () async {
            await IosFeedback.success();
            if (!context.mounted) return;

            await context.read<UserStateStore>().setHabitCompletionForKey(
                  habitId: id,
                  dateKey: _dateKey(_selectedDay),
                  done: !(doneToday && !skippedToday),
                );

            await _maybeCompleteOnboardingFromTargetInteraction(
              targetId: OnboardingTargetIds.homeFirstHabitCheckControl,
              habitId: id,
            );
          },
          currentCount: current,
          targetCount: target,
          unitLabel: unitLabel.isEmpty ? null : unitLabel,
          reminderLabel: reminderLabel,
          onIncrement: isCounting
              ? () async {
                  final step = toPositiveNum(
                    habit['counterStep'] ?? habit['step'] ?? 1,
                    fallback: 1,
                  ).toDouble();
                  final next = current + step;
                  await context.read<UserStateStore>().setCountHabitValueForDate(
                        habitId: id,
                        date: _selectedDay,
                        value: next,
                      );

                  await _maybeCompleteOnboardingFromTargetInteraction(
                    targetId: OnboardingTargetIds.homeFirstHabitCountControls,
                    habitId: id,
                  );
                }
              : null,
          onDecrement: isCounting
              ? () async {
                  final step = toPositiveNum(
                    habit['counterStep'] ?? habit['step'] ?? 1,
                    fallback: 1,
                  ).toDouble();
                  final next = current - step;
                  await context.read<UserStateStore>().setCountHabitValueForDate(
                        habitId: id,
                        date: _selectedDay,
                        value: next < 0 ? 0 : next,
                      );

                  await _maybeCompleteOnboardingFromTargetInteraction(
                    targetId: OnboardingTargetIds.homeFirstHabitCountControls,
                    habitId: id,
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

                            _tryUpdateHabit(
                              context,
                              habitId: id,
                              updates: updates,
                            );
                          }
                        },
                        onOpenStats: (ctx) {
                          _openMonthlyOverview(ctx);
                        },
                      ),
                    ),
                  );
                },
          onTap: null,
        );
      },
    );

    if (!isCounting) {
      return Dismissible(
        key: ValueKey('habit_${id}_${_dateKey(_selectedDay)}'),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            IosFeedback.lightImpact();
            await context.read<UserStateStore>().setHabitCompletionForKey(
                  habitId: id,
                  dateKey: _dateKey(_selectedDay),
                  done: !doneToday,
                );
            return false;
          }

          if (direction == DismissDirection.endToStart) {
            await context.read<UserStateStore>().setHabitSkipForKey(
                  habitId: id,
                  dateKey: _dateKey(_selectedDay),
                  skipped: !skippedToday,
                );
            return false;
          }

          return false;
        },
        background: Container(
          margin: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 16,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: familyColor.withAlpha((0.18 * 255).round()),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 18),
          child: Icon(
            CupertinoIcons.check_mark_circled_solid,
            color: familyColor,
            size: 28,
          ),
        ),
        secondaryBackground: Container(
          margin: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 16,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha((0.18 * 255).round()),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 18),
          child: const Icon(
            CupertinoIcons.forward_end_fill,
            color: Colors.orange,
            size: 28,
          ),
        ),
        child: card,
      );
    }

    return card;
  }
}
