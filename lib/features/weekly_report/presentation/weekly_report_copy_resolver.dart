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
      'weekly_report_summary_first_partial_09' =>
        l10n.weeklyReportSummaryFirstPartial09,
      'weekly_report_summary_first_partial_10' =>
        l10n.weeklyReportSummaryFirstPartial10,
      'weekly_report_summary_first_partial_11' =>
        l10n.weeklyReportSummaryFirstPartial11,
      'weekly_report_summary_first_partial_12' =>
        l10n.weeklyReportSummaryFirstPartial12,
      'weekly_report_summary_first_partial_13' =>
        l10n.weeklyReportSummaryFirstPartial13,
      'weekly_report_summary_first_partial_14' =>
        l10n.weeklyReportSummaryFirstPartial14,
      'weekly_report_summary_first_partial_15' =>
        l10n.weeklyReportSummaryFirstPartial15,
      'weekly_report_summary_first_partial_16' =>
        l10n.weeklyReportSummaryFirstPartial16,
      'weekly_report_summary_first_partial_17' =>
        l10n.weeklyReportSummaryFirstPartial17,
      'weekly_report_summary_first_partial_18' =>
        l10n.weeklyReportSummaryFirstPartial18,
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
      'weekly_report_summary_provisional_09' =>
        l10n.weeklyReportSummaryProvisional09,
      'weekly_report_summary_provisional_10' =>
        l10n.weeklyReportSummaryProvisional10,
      'weekly_report_summary_provisional_11' =>
        l10n.weeklyReportSummaryProvisional11,
      'weekly_report_summary_provisional_12' =>
        l10n.weeklyReportSummaryProvisional12,
      'weekly_report_summary_provisional_13' =>
        l10n.weeklyReportSummaryProvisional13,
      'weekly_report_summary_provisional_14' =>
        l10n.weeklyReportSummaryProvisional14,
      'weekly_report_summary_provisional_15' =>
        l10n.weeklyReportSummaryProvisional15,
      'weekly_report_summary_provisional_16' =>
        l10n.weeklyReportSummaryProvisional16,
      'weekly_report_summary_provisional_17' =>
        l10n.weeklyReportSummaryProvisional17,
      'weekly_report_summary_provisional_18' =>
        l10n.weeklyReportSummaryProvisional18,
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
      'weekly_report_summary_no_schedule_07' =>
        l10n.weeklyReportSummaryNoSchedule07,
      'weekly_report_summary_no_schedule_08' =>
        l10n.weeklyReportSummaryNoSchedule08,
      'weekly_report_summary_no_schedule_09' =>
        l10n.weeklyReportSummaryNoSchedule09,
      'weekly_report_summary_no_schedule_10' =>
        l10n.weeklyReportSummaryNoSchedule10,
      'weekly_report_summary_no_schedule_11' =>
        l10n.weeklyReportSummaryNoSchedule11,
      'weekly_report_summary_no_schedule_12' =>
        l10n.weeklyReportSummaryNoSchedule12,
      'weekly_report_summary_no_schedule_13' =>
        l10n.weeklyReportSummaryNoSchedule13,
      'weekly_report_summary_no_schedule_14' =>
        l10n.weeklyReportSummaryNoSchedule14,
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
      'weekly_report_summary_strong_11' => l10n.weeklyReportSummaryStrong11,
      'weekly_report_summary_strong_12' => l10n.weeklyReportSummaryStrong12,
      'weekly_report_summary_strong_13' => l10n.weeklyReportSummaryStrong13,
      'weekly_report_summary_strong_14' => l10n.weeklyReportSummaryStrong14,
      'weekly_report_summary_strong_15' => l10n.weeklyReportSummaryStrong15,
      'weekly_report_summary_strong_16' => l10n.weeklyReportSummaryStrong16,
      'weekly_report_summary_strong_17' => l10n.weeklyReportSummaryStrong17,
      'weekly_report_summary_strong_18' => l10n.weeklyReportSummaryStrong18,
      'weekly_report_summary_strong_19' => l10n.weeklyReportSummaryStrong19,
      'weekly_report_summary_strong_20' => l10n.weeklyReportSummaryStrong20,
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
      'weekly_report_summary_good_11' => l10n.weeklyReportSummaryGood11,
      'weekly_report_summary_good_12' => l10n.weeklyReportSummaryGood12,
      'weekly_report_summary_good_13' => l10n.weeklyReportSummaryGood13,
      'weekly_report_summary_good_14' => l10n.weeklyReportSummaryGood14,
      'weekly_report_summary_good_15' => l10n.weeklyReportSummaryGood15,
      'weekly_report_summary_good_16' => l10n.weeklyReportSummaryGood16,
      'weekly_report_summary_good_17' => l10n.weeklyReportSummaryGood17,
      'weekly_report_summary_good_18' => l10n.weeklyReportSummaryGood18,
      'weekly_report_summary_good_19' => l10n.weeklyReportSummaryGood19,
      'weekly_report_summary_good_20' => l10n.weeklyReportSummaryGood20,
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
      'weekly_report_summary_mixed_11' => l10n.weeklyReportSummaryMixed11,
      'weekly_report_summary_mixed_12' => l10n.weeklyReportSummaryMixed12,
      'weekly_report_summary_mixed_13' => l10n.weeklyReportSummaryMixed13,
      'weekly_report_summary_mixed_14' => l10n.weeklyReportSummaryMixed14,
      'weekly_report_summary_mixed_15' => l10n.weeklyReportSummaryMixed15,
      'weekly_report_summary_mixed_16' => l10n.weeklyReportSummaryMixed16,
      'weekly_report_summary_mixed_17' => l10n.weeklyReportSummaryMixed17,
      'weekly_report_summary_mixed_18' => l10n.weeklyReportSummaryMixed18,
      'weekly_report_summary_mixed_19' => l10n.weeklyReportSummaryMixed19,
      'weekly_report_summary_mixed_20' => l10n.weeklyReportSummaryMixed20,
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
      'weekly_report_summary_needs_recovery_11' =>
        l10n.weeklyReportSummaryNeedsRecovery11,
      'weekly_report_summary_needs_recovery_12' =>
        l10n.weeklyReportSummaryNeedsRecovery12,
      'weekly_report_summary_needs_recovery_13' =>
        l10n.weeklyReportSummaryNeedsRecovery13,
      'weekly_report_summary_needs_recovery_14' =>
        l10n.weeklyReportSummaryNeedsRecovery14,
      'weekly_report_summary_needs_recovery_15' =>
        l10n.weeklyReportSummaryNeedsRecovery15,
      'weekly_report_summary_needs_recovery_16' =>
        l10n.weeklyReportSummaryNeedsRecovery16,
      'weekly_report_summary_needs_recovery_17' =>
        l10n.weeklyReportSummaryNeedsRecovery17,
      'weekly_report_summary_needs_recovery_18' =>
        l10n.weeklyReportSummaryNeedsRecovery18,
      'weekly_report_summary_needs_recovery_19' =>
        l10n.weeklyReportSummaryNeedsRecovery19,
      'weekly_report_summary_needs_recovery_20' =>
        l10n.weeklyReportSummaryNeedsRecovery20,
      'weekly_report_summary_improved_01' => l10n.weeklyReportSummaryImproved01,
      'weekly_report_summary_improved_02' => l10n.weeklyReportSummaryImproved02,
      'weekly_report_summary_improved_03' => l10n.weeklyReportSummaryImproved03,
      'weekly_report_summary_improved_04' => l10n.weeklyReportSummaryImproved04,
      'weekly_report_summary_improved_05' => l10n.weeklyReportSummaryImproved05,
      'weekly_report_summary_improved_06' => l10n.weeklyReportSummaryImproved06,
      'weekly_report_summary_improved_07' => l10n.weeklyReportSummaryImproved07,
      'weekly_report_summary_improved_08' => l10n.weeklyReportSummaryImproved08,
      'weekly_report_summary_improved_09' => l10n.weeklyReportSummaryImproved09,
      'weekly_report_summary_improved_10' => l10n.weeklyReportSummaryImproved10,
      'weekly_report_summary_improved_11' => l10n.weeklyReportSummaryImproved11,
      'weekly_report_summary_improved_12' => l10n.weeklyReportSummaryImproved12,
      'weekly_report_summary_improved_13' => l10n.weeklyReportSummaryImproved13,
      'weekly_report_summary_improved_14' => l10n.weeklyReportSummaryImproved14,
      'weekly_report_summary_improved_15' => l10n.weeklyReportSummaryImproved15,
      'weekly_report_summary_improved_16' => l10n.weeklyReportSummaryImproved16,
      'weekly_report_summary_improved_17' => l10n.weeklyReportSummaryImproved17,
      'weekly_report_summary_improved_18' => l10n.weeklyReportSummaryImproved18,
      'weekly_report_summary_declined_01' => l10n.weeklyReportSummaryDeclined01,
      'weekly_report_summary_declined_02' => l10n.weeklyReportSummaryDeclined02,
      'weekly_report_summary_declined_03' => l10n.weeklyReportSummaryDeclined03,
      'weekly_report_summary_declined_04' => l10n.weeklyReportSummaryDeclined04,
      'weekly_report_summary_declined_05' => l10n.weeklyReportSummaryDeclined05,
      'weekly_report_summary_declined_06' => l10n.weeklyReportSummaryDeclined06,
      'weekly_report_summary_declined_07' => l10n.weeklyReportSummaryDeclined07,
      'weekly_report_summary_declined_08' => l10n.weeklyReportSummaryDeclined08,
      'weekly_report_summary_declined_09' => l10n.weeklyReportSummaryDeclined09,
      'weekly_report_summary_declined_10' => l10n.weeklyReportSummaryDeclined10,
      'weekly_report_summary_declined_11' => l10n.weeklyReportSummaryDeclined11,
      'weekly_report_summary_declined_12' => l10n.weeklyReportSummaryDeclined12,
      'weekly_report_summary_declined_13' => l10n.weeklyReportSummaryDeclined13,
      'weekly_report_summary_declined_14' => l10n.weeklyReportSummaryDeclined14,
      'weekly_report_summary_declined_15' => l10n.weeklyReportSummaryDeclined15,
      'weekly_report_summary_declined_16' => l10n.weeklyReportSummaryDeclined16,
      'weekly_report_summary_declined_17' => l10n.weeklyReportSummaryDeclined17,
      'weekly_report_summary_declined_18' => l10n.weeklyReportSummaryDeclined18,
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
      'weekly_report_habit_highlighted_09' =>
        l10n.weeklyReportHabitHighlighted09,
      'weekly_report_habit_highlighted_10' =>
        l10n.weeklyReportHabitHighlighted10,
      'weekly_report_habit_highlighted_11' =>
        l10n.weeklyReportHabitHighlighted11,
      'weekly_report_habit_highlighted_12' =>
        l10n.weeklyReportHabitHighlighted12,
      'weekly_report_habit_highlighted_13' =>
        l10n.weeklyReportHabitHighlighted13,
      'weekly_report_habit_highlighted_14' =>
        l10n.weeklyReportHabitHighlighted14,
      'weekly_report_habit_highlighted_15' =>
        l10n.weeklyReportHabitHighlighted15,
      'weekly_report_habit_highlighted_16' =>
        l10n.weeklyReportHabitHighlighted16,
      'weekly_report_habit_stable_01' => l10n.weeklyReportHabitStable01,
      'weekly_report_habit_stable_02' => l10n.weeklyReportHabitStable02,
      'weekly_report_habit_stable_03' => l10n.weeklyReportHabitStable03,
      'weekly_report_habit_stable_04' => l10n.weeklyReportHabitStable04,
      'weekly_report_habit_stable_05' => l10n.weeklyReportHabitStable05,
      'weekly_report_habit_stable_06' => l10n.weeklyReportHabitStable06,
      'weekly_report_habit_stable_07' => l10n.weeklyReportHabitStable07,
      'weekly_report_habit_stable_08' => l10n.weeklyReportHabitStable08,
      'weekly_report_habit_stable_09' => l10n.weeklyReportHabitStable09,
      'weekly_report_habit_stable_10' => l10n.weeklyReportHabitStable10,
      'weekly_report_habit_stable_11' => l10n.weeklyReportHabitStable11,
      'weekly_report_habit_stable_12' => l10n.weeklyReportHabitStable12,
      'weekly_report_habit_stable_13' => l10n.weeklyReportHabitStable13,
      'weekly_report_habit_stable_14' => l10n.weeklyReportHabitStable14,
      'weekly_report_habit_stable_15' => l10n.weeklyReportHabitStable15,
      'weekly_report_habit_stable_16' => l10n.weeklyReportHabitStable16,
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
      'weekly_report_habit_needs_attention_09' =>
        l10n.weeklyReportHabitNeedsAttention09,
      'weekly_report_habit_needs_attention_10' =>
        l10n.weeklyReportHabitNeedsAttention10,
      'weekly_report_habit_needs_attention_11' =>
        l10n.weeklyReportHabitNeedsAttention11,
      'weekly_report_habit_needs_attention_12' =>
        l10n.weeklyReportHabitNeedsAttention12,
      'weekly_report_habit_needs_attention_13' =>
        l10n.weeklyReportHabitNeedsAttention13,
      'weekly_report_habit_needs_attention_14' =>
        l10n.weeklyReportHabitNeedsAttention14,
      'weekly_report_habit_needs_attention_15' =>
        l10n.weeklyReportHabitNeedsAttention15,
      'weekly_report_habit_needs_attention_16' =>
        l10n.weeklyReportHabitNeedsAttention16,
      _ => null,
    };
  }
}
