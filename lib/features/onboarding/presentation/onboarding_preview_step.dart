import 'package:flutter/material.dart';

import '../../../features/habits/domain/metrics/habit_snapshot.dart';
import '../../../features/habits/presentation/habit_schedule_label_resolver.dart';
import '../../../l10n/l10n.dart';
import '../../../screens/home/widgets/habit/habit_card_widget.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/family_theme.dart';
import '../domain/models/onboarding_habit_configuration.dart';
import '../domain/models/onboarding_reminder_configuration.dart';
import '../domain/models/onboarding_types.dart';
import '../domain/onboarding_goals.dart';

/// Read-only summary of the typed onboarding draft.
///
/// This widget receives resolved domain values instead of draft maps. Editing
/// and persistence remain intents owned by [OnboardingCoordinator].
class OnboardingPreviewStep extends StatelessWidget {
  const OnboardingPreviewStep({
    super.key,
    required this.goalCodes,
    required this.pace,
    required this.habit,
    required this.reminder,
    required this.onEdit,
    required this.onSave,
  });

  final Set<String> goalCodes;
  final OnboardingPace pace;
  final OnboardingHabitConfiguration habit;
  final OnboardingReminderConfiguration reminder;
  final ValueChanged<OnboardingStep> onEdit;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final schedule = const HabitScheduleLabelResolver().resolve(
      l10n,
      habit.schedule,
    );
    final reminderSummary = _reminderSummary(context, reminder);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.onboardingPreviewIntro,
          style: AppTextStyles.welcomeSub,
        ),
        const SizedBox(height: 22),
        _SummaryBlock(
          title: l10n.onboardingPreviewGoals,
          editLabel: l10n.onboardingPreviewEdit,
          editKey: const ValueKey('onboardingPreviewEditGoals'),
          onEdit: () => onEdit(OnboardingStep.goals),
          child: Text(
            _goalLabels(context).join(' · '),
            style: AppTextStyles.authTitle.copyWith(fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),
        _SummaryBlock(
          title: l10n.onboardingPreviewPace,
          editLabel: l10n.onboardingPreviewEdit,
          editKey: const ValueKey('onboardingPreviewEditPace'),
          onEdit: () => onEdit(OnboardingStep.pace),
          child: Text(
            _paceLabel(context, pace),
            style: AppTextStyles.authTitle.copyWith(fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),
        _SummaryBlock(
          title: l10n.onboardingPreviewHabit,
          editLabel: l10n.onboardingPreviewEdit,
          editKey: const ValueKey('onboardingPreviewEditHabit'),
          onEdit: () => onEdit(OnboardingStep.habit),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit.name,
                style: AppTextStyles.authTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 5),
              Text(
                '${_familyLabel(context, habit.primaryFamilyCode)} · '
                '${_kindLabel(context, habit.kind)} · $schedule',
                style: AppTextStyles.authSub,
              ),
              if (habit.isCount) ...[
                const SizedBox(height: 4),
                Text(
                  '${l10n.onboardingPreviewTarget}: '
                  '${habit.targetValue ?? 0}${habit.unit == null ? '' : ' ${habit.unit}'}',
                  style: AppTextStyles.authSub,
                ),
              ],
              const SizedBox(height: 16),
              Semantics(
                container: true,
                readOnly: true,
                label: '${habit.name}. ${l10n.onboardingPreviewReadOnly}',
                child: IgnorePointer(
                  child: HabitCardWidget(
                    key: const ValueKey('onboardingPreviewHabitCard'),
                    title: habit.name,
                    description: schedule,
                    emoji: habit.emoji,
                    familyColor: FamilyTheme.colorOf(habit.primaryFamilyCode),
                    progress: 0,
                    isCompleted: false,
                    isSkipped: false,
                    isCounting: habit.isCount,
                    targetCount: habit.targetValue ?? 1,
                    unitLabel: habit.unit,
                    reminderLabel:
                        reminder.enabled && reminder.selectedTime != null
                            ? _formatTime(context, reminder.selectedTime!)
                            : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SummaryBlock(
          title: l10n.onboardingPreviewReminder,
          editLabel: l10n.onboardingPreviewEdit,
          editKey: const ValueKey('onboardingPreviewEditReminder'),
          onEdit: () => onEdit(OnboardingStep.reminder),
          child: Text(reminderSummary,
              style: AppTextStyles.authTitle.copyWith(fontSize: 18)),
        ),
        const SizedBox(height: 22),
        Semantics(
          button: true,
          label: l10n.onboardingPreviewSave,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              key: const ValueKey('onboardingPreviewSave'),
              onPressed: onSave,
              child: Text(l10n.onboardingPreviewSave),
            ),
          ),
        ),
      ],
    );
  }

  List<String> _goalLabels(BuildContext context) {
    final l10n = context.l10n;
    return OnboardingGoalCatalog.definitions
        .where((definition) => goalCodes.contains(definition.code))
        .map((definition) => _goalLabel(l10n, definition.code))
        .toList(growable: false);
  }

  String _goalLabel(dynamic l10n, String code) {
    switch (code) {
      case 'care_body':
        return l10n.onboardingGoalCareBody;
      case 'find_calm':
        return l10n.onboardingGoalFindCalm;
      case 'organize_days':
        return l10n.onboardingGoalOrganizeDays;
      case 'learn_grow':
        return l10n.onboardingGoalLearnGrow;
      case 'care_relationships':
        return l10n.onboardingGoalCareRelationships;
      case 'build_discipline':
        return l10n.onboardingGoalBuildDiscipline;
      default:
        return code;
    }
  }

  String _paceLabel(BuildContext context, OnboardingPace value) {
    final l10n = context.l10n;
    switch (value) {
      case OnboardingPace.gentle:
        return l10n.onboardingPaceGentleTitle;
      case OnboardingPace.balanced:
        return l10n.onboardingPaceBalancedTitle;
      case OnboardingPace.energized:
        return l10n.onboardingPaceEnergizedTitle;
    }
  }

  String _kindLabel(BuildContext context, HabitKind value) {
    final l10n = context.l10n;
    return value == HabitKind.count
        ? l10n.habitConfigCounterOption
        : l10n.habitConfigCheckOption;
  }

  String _familyLabel(BuildContext context, String? familyCode) {
    final l10n = context.l10n;
    switch (familyCode) {
      case FamilyTheme.mind:
        return l10n.onboardingPreviewFamilyMind;
      case FamilyTheme.spirit:
        return l10n.onboardingPreviewFamilySpirit;
      case FamilyTheme.body:
        return l10n.onboardingPreviewFamilyBody;
      case FamilyTheme.emotional:
        return l10n.onboardingPreviewFamilyEmotional;
      case FamilyTheme.social:
        return l10n.onboardingPreviewFamilySocial;
      case FamilyTheme.discipline:
        return l10n.onboardingPreviewFamilyDiscipline;
      case FamilyTheme.professional:
        return l10n.onboardingPreviewFamilyProfessional;
      default:
        return l10n.onboardingPreviewFamilyMind;
    }
  }

  String _reminderSummary(
    BuildContext context,
    OnboardingReminderConfiguration value,
  ) {
    final l10n = context.l10n;
    if (!value.enabled) return l10n.onboardingPreviewNoReminder;
    if (value.permissionState == ReminderPermissionState.denied ||
        value.permissionState == ReminderPermissionState.restricted ||
        value.permissionState == ReminderPermissionState.notRequested) {
      return l10n.onboardingPreviewReminderPending;
    }
    return '${_formatTime(context, value.selectedTime!)} · '
        '${l10n.onboardingPreviewReminderReady}';
  }

  String _formatTime(BuildContext context, OnboardingReminderTime value) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: value.hour, minute: value.minute),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({
    required this.title,
    required this.editLabel,
    required this.editKey,
    required this.onEdit,
    required this.child,
  });

  final String title;
  final String editLabel;
  final Key editKey;
  final VoidCallback onEdit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.cream2.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: AppTextStyles.authSub.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: '$editLabel $title',
                child: ExcludeSemantics(
                  child: TextButton(
                    key: editKey,
                    onPressed: onEdit,
                    child: Text(editLabel),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
