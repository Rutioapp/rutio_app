import 'package:flutter/widgets.dart';
import 'package:rutio/l10n/l10n.dart';

enum StatisticsPeriod {
  day,
  week,
  month,
  year,
}

extension StatisticsPeriodX on StatisticsPeriod {
  String label(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case StatisticsPeriod.day:
        return l10n.statisticsV2PeriodDay;
      case StatisticsPeriod.week:
        return l10n.statisticsV2PeriodWeek;
      case StatisticsPeriod.month:
        return l10n.statisticsV2PeriodMonth;
      case StatisticsPeriod.year:
        return l10n.statisticsV2PeriodYear;
    }
  }

  String overviewSubtitle(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case StatisticsPeriod.day:
        return l10n.statisticsV2OverviewSubtitleToday;
      case StatisticsPeriod.week:
        return l10n.statisticsV2OverviewSubtitleThisWeek;
      case StatisticsPeriod.month:
        return l10n.statisticsV2OverviewSubtitleThisMonth;
      case StatisticsPeriod.year:
        return l10n.statisticsV2OverviewSubtitleThisYear;
    }
  }

  int get approximateDays {
    switch (this) {
      case StatisticsPeriod.day:
        return 1;
      case StatisticsPeriod.week:
        return 7;
      case StatisticsPeriod.month:
        return 30;
      case StatisticsPeriod.year:
        return 365;
    }
  }
}
