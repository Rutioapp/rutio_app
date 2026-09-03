import '../../../l10n/gen/app_localizations.dart';
import '../domain/weekly_report.dart';

/// Resolves persisted backend copy keys to the active localized catalog.
///
/// The backend owns classification and deterministic key selection. This
/// resolver only performs an exhaustive, typed key-to-localization mapping.
class WeeklyReportCopyResolver {
  const WeeklyReportCopyResolver._();

  static String summary(AppLocalizations l10n, WeeklyReport report) {
    return switch (report.summaryMessageKey) {
      'weekly_report_summary_first_partial_01' =>
        l10n.weeklyReportSummaryFirstPartial01,
      'weekly_report_summary_first_partial_02' =>
        l10n.weeklyReportSummaryFirstPartial02,
      'weekly_report_summary_first_partial_03' =>
        l10n.weeklyReportSummaryFirstPartial03,
      'weekly_report_summary_first_partial_04' =>
        l10n.weeklyReportSummaryFirstPartial04,
      'weekly_report_summary_first_partial_05' =>
        l10n.weeklyReportSummaryFirstPartial05,
      'weekly_report_summary_first_partial_06' =>
        l10n.weeklyReportSummaryFirstPartial06,
      'weekly_report_summary_first_partial_07' =>
        l10n.weeklyReportSummaryFirstPartial07,
      'weekly_report_summary_first_partial_08' =>
        l10n.weeklyReportSummaryFirstPartial08,
      'weekly_report_summary_provisional_01' =>
        l10n.weeklyReportSummaryProvisional01,
      'weekly_report_summary_provisional_02' =>
        l10n.weeklyReportSummaryProvisional02,
      'weekly_report_summary_provisional_03' =>
        l10n.weeklyReportSummaryProvisional03,
      'weekly_report_summary_provisional_04' =>
        l10n.weeklyReportSummaryProvisional04,
      'weekly_report_summary_provisional_05' =>
        l10n.weeklyReportSummaryProvisional05,
      'weekly_report_summary_provisional_06' =>
        l10n.weeklyReportSummaryProvisional06,
      'weekly_report_summary_provisional_07' =>
        l10n.weeklyReportSummaryProvisional07,
      'weekly_report_summary_provisional_08' =>
        l10n.weeklyReportSummaryProvisional08,
      'weekly_report_summary_no_schedule_01' =>
        l10n.weeklyReportSummaryNoSchedule01,
      'weekly_report_summary_no_schedule_02' =>
        l10n.weeklyReportSummaryNoSchedule02,
      'weekly_report_summary_no_schedule_03' =>
        l10n.weeklyReportSummaryNoSchedule03,
      'weekly_report_summary_no_schedule_04' =>
        l10n.weeklyReportSummaryNoSchedule04,
      'weekly_report_summary_no_schedule_05' =>
        l10n.weeklyReportSummaryNoSchedule05,
      'weekly_report_summary_no_schedule_06' =>
        l10n.weeklyReportSummaryNoSchedule06,
      'weekly_report_summary_strong_01' => l10n.weeklyReportSummaryStrong01,
      'weekly_report_summary_strong_02' => l10n.weeklyReportSummaryStrong02,
      'weekly_report_summary_strong_03' => l10n.weeklyReportSummaryStrong03,
      'weekly_report_summary_strong_04' => l10n.weeklyReportSummaryStrong04,
      'weekly_report_summary_strong_05' => l10n.weeklyReportSummaryStrong05,
      'weekly_report_summary_strong_06' => l10n.weeklyReportSummaryStrong06,
      'weekly_report_summary_strong_07' => l10n.weeklyReportSummaryStrong07,
      'weekly_report_summary_strong_08' => l10n.weeklyReportSummaryStrong08,
      'weekly_report_summary_strong_09' => l10n.weeklyReportSummaryStrong09,
      'weekly_report_summary_strong_10' => l10n.weeklyReportSummaryStrong10,
      'weekly_report_summary_good_01' => l10n.weeklyReportSummaryGood01,
      'weekly_report_summary_good_02' => l10n.weeklyReportSummaryGood02,
      'weekly_report_summary_good_03' => l10n.weeklyReportSummaryGood03,
      'weekly_report_summary_good_04' => l10n.weeklyReportSummaryGood04,
      'weekly_report_summary_good_05' => l10n.weeklyReportSummaryGood05,
      'weekly_report_summary_good_06' => l10n.weeklyReportSummaryGood06,
      'weekly_report_summary_good_07' => l10n.weeklyReportSummaryGood07,
      'weekly_report_summary_good_08' => l10n.weeklyReportSummaryGood08,
      'weekly_report_summary_good_09' => l10n.weeklyReportSummaryGood09,
      'weekly_report_summary_good_10' => l10n.weeklyReportSummaryGood10,
      'weekly_report_summary_mixed_01' => l10n.weeklyReportSummaryMixed01,
      'weekly_report_summary_mixed_02' => l10n.weeklyReportSummaryMixed02,
      'weekly_report_summary_mixed_03' => l10n.weeklyReportSummaryMixed03,
      'weekly_report_summary_mixed_04' => l10n.weeklyReportSummaryMixed04,
      'weekly_report_summary_mixed_05' => l10n.weeklyReportSummaryMixed05,
      'weekly_report_summary_mixed_06' => l10n.weeklyReportSummaryMixed06,
      'weekly_report_summary_mixed_07' => l10n.weeklyReportSummaryMixed07,
      'weekly_report_summary_mixed_08' => l10n.weeklyReportSummaryMixed08,
      'weekly_report_summary_mixed_09' => l10n.weeklyReportSummaryMixed09,
      'weekly_report_summary_mixed_10' => l10n.weeklyReportSummaryMixed10,
      'weekly_report_summary_needs_recovery_01' =>
        l10n.weeklyReportSummaryNeedsRecovery01,
      'weekly_report_summary_needs_recovery_02' =>
        l10n.weeklyReportSummaryNeedsRecovery02,
      'weekly_report_summary_needs_recovery_03' =>
        l10n.weeklyReportSummaryNeedsRecovery03,
      'weekly_report_summary_needs_recovery_04' =>
        l10n.weeklyReportSummaryNeedsRecovery04,
      'weekly_report_summary_needs_recovery_05' =>
        l10n.weeklyReportSummaryNeedsRecovery05,
      'weekly_report_summary_needs_recovery_06' =>
        l10n.weeklyReportSummaryNeedsRecovery06,
      'weekly_report_summary_needs_recovery_07' =>
        l10n.weeklyReportSummaryNeedsRecovery07,
      'weekly_report_summary_needs_recovery_08' =>
        l10n.weeklyReportSummaryNeedsRecovery08,
      'weekly_report_summary_needs_recovery_09' =>
        l10n.weeklyReportSummaryNeedsRecovery09,
      'weekly_report_summary_needs_recovery_10' =>
        l10n.weeklyReportSummaryNeedsRecovery10,
      'weekly_report_summary_improved_01' => l10n.weeklyReportSummaryImproved01,
      'weekly_report_summary_improved_02' => l10n.weeklyReportSummaryImproved02,
      'weekly_report_summary_improved_03' => l10n.weeklyReportSummaryImproved03,
      'weekly_report_summary_improved_04' => l10n.weeklyReportSummaryImproved04,
      'weekly_report_summary_improved_05' => l10n.weeklyReportSummaryImproved05,
      'weekly_report_summary_improved_06' => l10n.weeklyReportSummaryImproved06,
      'weekly_report_summary_improved_07' => l10n.weeklyReportSummaryImproved07,
      'weekly_report_summary_improved_08' => l10n.weeklyReportSummaryImproved08,
      'weekly_report_summary_declined_01' => l10n.weeklyReportSummaryDeclined01,
      'weekly_report_summary_declined_02' => l10n.weeklyReportSummaryDeclined02,
      'weekly_report_summary_declined_03' => l10n.weeklyReportSummaryDeclined03,
      'weekly_report_summary_declined_04' => l10n.weeklyReportSummaryDeclined04,
      'weekly_report_summary_declined_05' => l10n.weeklyReportSummaryDeclined05,
      'weekly_report_summary_declined_06' => l10n.weeklyReportSummaryDeclined06,
      'weekly_report_summary_declined_07' => l10n.weeklyReportSummaryDeclined07,
      'weekly_report_summary_declined_08' => l10n.weeklyReportSummaryDeclined08,
      _ => !report.summary.hasScheduledCount
          ? l10n.weeklyReportSummaryNoSchedule01
          : report.isProvisional
              ? l10n.weeklyReportSummaryProvisional01
              : l10n.weeklyReportSummaryGood01,
    };
  }

  static String? observation(AppLocalizations l10n, WeeklyReportHabit habit) {
    return switch (habit.observationKey) {
      'weekly_report_habit_highlighted_01' =>
        l10n.weeklyReportHabitHighlighted01,
      'weekly_report_habit_highlighted_02' =>
        l10n.weeklyReportHabitHighlighted02,
      'weekly_report_habit_highlighted_03' =>
        l10n.weeklyReportHabitHighlighted03,
      'weekly_report_habit_highlighted_04' =>
        l10n.weeklyReportHabitHighlighted04,
      'weekly_report_habit_highlighted_05' =>
        l10n.weeklyReportHabitHighlighted05,
      'weekly_report_habit_highlighted_06' =>
        l10n.weeklyReportHabitHighlighted06,
      'weekly_report_habit_highlighted_07' =>
        l10n.weeklyReportHabitHighlighted07,
      'weekly_report_habit_highlighted_08' =>
        l10n.weeklyReportHabitHighlighted08,
      'weekly_report_habit_stable_01' => l10n.weeklyReportHabitStable01,
      'weekly_report_habit_stable_02' => l10n.weeklyReportHabitStable02,
      'weekly_report_habit_stable_03' => l10n.weeklyReportHabitStable03,
      'weekly_report_habit_stable_04' => l10n.weeklyReportHabitStable04,
      'weekly_report_habit_stable_05' => l10n.weeklyReportHabitStable05,
      'weekly_report_habit_stable_06' => l10n.weeklyReportHabitStable06,
      'weekly_report_habit_stable_07' => l10n.weeklyReportHabitStable07,
      'weekly_report_habit_stable_08' => l10n.weeklyReportHabitStable08,
      'weekly_report_habit_needs_attention_01' =>
        l10n.weeklyReportHabitNeedsAttention01,
      'weekly_report_habit_needs_attention_02' =>
        l10n.weeklyReportHabitNeedsAttention02,
      'weekly_report_habit_needs_attention_03' =>
        l10n.weeklyReportHabitNeedsAttention03,
      'weekly_report_habit_needs_attention_04' =>
        l10n.weeklyReportHabitNeedsAttention04,
      'weekly_report_habit_needs_attention_05' =>
        l10n.weeklyReportHabitNeedsAttention05,
      'weekly_report_habit_needs_attention_06' =>
        l10n.weeklyReportHabitNeedsAttention06,
      'weekly_report_habit_needs_attention_07' =>
        l10n.weeklyReportHabitNeedsAttention07,
      'weekly_report_habit_needs_attention_08' =>
        l10n.weeklyReportHabitNeedsAttention08,
      _ => null,
    };
  }
}
