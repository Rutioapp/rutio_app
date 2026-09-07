import '../../../l10n/gen/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../domain/metrics/habit_snapshot.dart';

/// Resolves a schedule into the short, user-facing summary used by habit
/// previews and other configuration summaries.
class HabitScheduleLabelResolver {
  const HabitScheduleLabelResolver();

  String resolve(AppLocalizations l10n, HabitSchedule schedule) {
    switch (schedule.type) {
      case HabitScheduleType.daily:
        return l10n.onboardingPreviewEveryDay;
      case HabitScheduleType.timesPerWeek:
        return l10n.habitScheduleTimesPerWeek(schedule.timesPerWeek ?? 1);
      case HabitScheduleType.weekly:
        final labels = schedule.weekdays
            .map(l10n.weekdayShort)
            .where((label) => label.trim().isNotEmpty)
            .join(' · ');
        return labels.isEmpty ? l10n.onboardingPreviewEveryDay : labels;
      case HabitScheduleType.once:
        return l10n.onboardingPreviewEveryDay;
    }
  }
}
