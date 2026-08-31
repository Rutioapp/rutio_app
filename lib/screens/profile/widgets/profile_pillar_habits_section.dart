import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/utils/app_theme.dart';

import '../../../features/achievements/domain/models/habit_streak_snapshot.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../stores/user_state_store.dart';
import 'pill_button.dart';
import 'section_card.dart';

@immutable
class ProfilePillarHabitCardData {
  const ProfilePillarHabitCardData({
    required this.id,
    required this.name,
    required this.currentStreakDays,
    this.emoji,
    this.isArchived = false,
    this.isPaused = false,
  });

  final String id;
  final String name;
  final String? emoji;
  final int currentStreakDays;
  final bool isArchived;
  final bool isPaused;
}

List<ProfilePillarHabitCardData> buildProfilePillarHabitCards(
  UserStateStore store,
) {
  final selectedIds = store.pillarHabitIds;
  if (selectedIds.isEmpty) return const <ProfilePillarHabitCardData>[];

  final habitsById = <String, Map<String, dynamic>>{
    for (final habit in store.activeHabits)
      if ((habit['id'] ?? '').toString().trim().isNotEmpty)
        (habit['id'] ?? '').toString().trim(): habit,
  };

  final items = <ProfilePillarHabitCardData>[];
  for (final habitId in selectedIds) {
    final habit = habitsById[habitId];
    if (habit == null) continue;

    items.add(
      ProfilePillarHabitCardData(
        id: habitId,
        name: _habitName(habit),
        emoji: _habitEmoji(habit),
        currentStreakDays:
            store.habitStreakSnapshotForHabitId(habitId).currentStreak,
        isArchived: _isArchivedHabit(habit),
        isPaused: _isPausedHabit(habit),
      ),
    );
  }

  return List<ProfilePillarHabitCardData>.unmodifiable(items);
}

Future<void> showPillarHabitPickerSheet(
  BuildContext context, {
  required UserStateStore store,
  required List<String> selectedIds,
  required ValueChanged<List<String>> onSave,
}) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (sheetContext) => _PillarHabitPickerSheet(
      store: store,
      selectedIds: selectedIds,
      onSave: onSave,
    ),
  );
}

class ProfilePillarHabitsSection extends StatelessWidget {
  const ProfilePillarHabitsSection({
    super.key,
    required this.accent,
    required this.pillarHabits,
    required this.onTap,
  });

  final Color accent;
  final List<ProfilePillarHabitCardData> pillarHabits;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasHabits = pillarHabits.isNotEmpty;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center_rounded, color: accent, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.profilePillarHabitsTitle,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E241A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PillButton(
                accent: accent,
                icon: hasHabits ? Icons.edit_rounded : Icons.add_rounded,
                label: hasHabits
                    ? l10n.profilePillarHabitsEditAction
                    : l10n.profilePillarHabitsAddAction,
                onTap: onTap,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasHabits
                ? l10n.profilePillarHabitsHint
                : l10n.profilePillarHabitsEmptyTitle,
            style: const TextStyle(
              fontSize: 14.2,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4F4A42),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasHabits
                ? l10n.profilePillarHabitsSubtitle
                : l10n.profilePillarHabitsEmptySubtitle,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.28,
              color: Color(0xFF736A61),
            ),
          ),
          if (hasHabits) ...[
            const SizedBox(height: 14),
            Column(
              children: [
                for (final habit in pillarHabits) ...[
                  _PillarHabitCard(
                    habit: habit,
                    accent: accent,
                    l10n: l10n,
                  ),
                  if (habit != pillarHabits.last) const SizedBox(height: 10),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PillarHabitCard extends StatelessWidget {
  const _PillarHabitCard({
    required this.habit,
    required this.accent,
    required this.l10n,
  });

  final ProfilePillarHabitCardData habit;
  final Color accent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final status = _statusLabelForHabit(l10n, habit);
    final habitName = habit.name.trim().isEmpty
        ? l10n.homeFallbackHabitTitle
        : habit.name.trim();
    final streakText =
        '${habit.currentStreakDays} ${l10n.profilePillarHabitDaysUnit}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E1D4)),
      ),
      child: Row(
        children: [
          _HabitEmojiBubble(emoji: habit.emoji, accent: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habitName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF241A12),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${l10n.profilePillarHabitStreakLabel}: $streakText',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6E6257),
                      ),
                    ),
                    if (status != null)
                      _StatusChip(
                        label: status,
                        isAlert: habit.isArchived || habit.isPaused,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isAlert,
  });

  final String label;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAlert ? const Color(0xFFF7E8E3) : AppColors.cream,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: isAlert ? const Color(0xFF9F5D49) : AppColors.earth,
        ),
      ),
    );
  }
}

class _HabitEmojiBubble extends StatelessWidget {
  const _HabitEmojiBubble({
    required this.accent,
    required this.emoji,
  });

  final Color accent;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final content = (emoji ?? '').trim();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        content.isEmpty ? '•' : content,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}

class _PillarHabitPickerSheet extends StatefulWidget {
  const _PillarHabitPickerSheet({
    required this.store,
    required this.selectedIds,
    required this.onSave,
  });

  final UserStateStore store;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onSave;

  @override
  State<_PillarHabitPickerSheet> createState() =>
      _PillarHabitPickerSheetState();
}

class _PillarHabitPickerSheetState extends State<_PillarHabitPickerSheet> {
  late final List<String> _selectedIds = _normalize(widget.selectedIds);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = _habitOptions(widget.store);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return CupertinoPageScaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.18),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: AppColors.cream2,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.profilePillarHabitsPickerTitle,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.profilePillarHabitsPickerSubtitle(
                                _selectedIds.length,
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 44),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          MaterialLocalizations.of(context).closeButtonLabel,
                          style: const TextStyle(
                            color: AppColors.earth,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: options.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              l10n.diaryComposerNoActiveHabits,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14.5,
                                color: Color(0xFF625A50),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: options.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final option = options[index];
                            final optionName = option.name.trim().isEmpty
                                ? l10n.homeFallbackHabitTitle
                                : option.name.trim();
                            final isSelected = _selectedIds.contains(option.id);
                            final canSelect =
                                isSelected || _selectedIds.length < 3;

                            return CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: canSelect
                                  ? () => setState(() {
                                        if (isSelected) {
                                          _selectedIds.remove(option.id);
                                        } else {
                                          _selectedIds.add(option.id);
                                        }
                                      })
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.cream
                                      : AppColors.cream2,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.earth
                                            .withValues(alpha: 0.22)
                                        : AppColors.earth
                                            .withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _HabitEmojiBubble(
                                      accent: AppColors.earth,
                                      emoji: option.emoji,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            optionName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              Text(
                                                '${l10n.profilePillarHabitStreakLabel}: ${option.currentStreakDays} ${l10n.profilePillarHabitDaysUnit}',
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  color: AppColors.inkSoft,
                                                ),
                                              ),
                                              if (option.statusLabel(l10n) !=
                                                  null)
                                                _StatusChip(
                                                  label:
                                                      option.statusLabel(l10n)!,
                                                  isAlert: option.isAlert,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      isSelected
                                          ? CupertinoIcons
                                              .check_mark_circled_solid
                                          : CupertinoIcons.circle,
                                      color: isSelected
                                          ? AppColors.earth
                                          : AppColors.inkFaint,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      color: AppColors.earth,
                      borderRadius: BorderRadius.circular(18),
                      onPressed: () {
                        widget.onSave(_selectedIds);
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.commonSave),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _normalize(List<String> values) {
    final output = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty) continue;
      if (!seen.add(normalized)) continue;
      output.add(normalized);
      if (output.length == 3) break;
    }
    return output;
  }
}

List<_PillarHabitOption> _habitOptions(UserStateStore store) {
  final streakCache = <String, HabitStreakSnapshot>{};
  final options = <_PillarHabitOption>[];

  for (final habit in store.activeHabits) {
    final id = _habitId(habit);
    if (id == null) continue;

    final snapshot = streakCache.putIfAbsent(
      id,
      () => store.habitStreakSnapshotForHabitId(id),
    );

    options.add(
      _PillarHabitOption(
        id: id,
        name: _habitName(habit),
        emoji: _habitEmoji(habit),
        currentStreakDays: snapshot.currentStreak,
        isArchived: _isArchivedHabit(habit),
        isPaused: _isPausedHabit(habit),
        isAlert: _isArchivedHabit(habit) || _isPausedHabit(habit),
      ),
    );
  }

  return List<_PillarHabitOption>.unmodifiable(options);
}

@immutable
class _PillarHabitOption {
  const _PillarHabitOption({
    required this.id,
    required this.name,
    required this.currentStreakDays,
    required this.isArchived,
    required this.isPaused,
    required this.isAlert,
    this.emoji,
  });

  final String id;
  final String name;
  final String? emoji;
  final int currentStreakDays;
  final bool isArchived;
  final bool isPaused;
  final bool isAlert;

  String? statusLabel(AppLocalizations l10n) {
    if (isArchived) return l10n.profilePillarHabitArchivedLabel;
    if (isPaused) return l10n.profilePillarHabitPausedLabel;
    return null;
  }
}

String? _habitId(Map<String, dynamic> habit) {
  final value = (habit['id'] ?? '').toString().trim();
  return value.isEmpty ? null : value;
}

String _habitName(Map<String, dynamic> habit) {
  final value = (habit['name'] ?? habit['title'] ?? '').toString().trim();
  return value.isEmpty ? '' : value;
}

String? _habitEmoji(Map<String, dynamic> habit) {
  final value = (habit['emoji'] ?? habit['habitEmoji'] ?? '').toString().trim();
  return value.isEmpty ? null : value;
}

bool _isArchivedHabit(Map<String, dynamic> habit) {
  return habit['archived'] == true ||
      habit['isArchived'] == true ||
      habit['is_archived'] == true;
}

bool _isPausedHabit(Map<String, dynamic> habit) {
  final status = (habit['status'] ?? '').toString().trim().toLowerCase();
  return status == 'paused' ||
      habit['paused'] == true ||
      habit['isPaused'] == true;
}

String? _statusLabelForHabit(
  AppLocalizations l10n,
  ProfilePillarHabitCardData habit,
) {
  if (habit.isArchived) return l10n.profilePillarHabitArchivedLabel;
  if (habit.isPaused) return l10n.profilePillarHabitPausedLabel;
  return null;
}
