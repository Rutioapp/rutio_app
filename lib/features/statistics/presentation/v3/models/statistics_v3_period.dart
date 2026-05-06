import 'package:rutio/l10n/gen/app_localizations.dart';

enum StatisticsV3Period {
  day,
  week,
  month,
  year,
}

extension StatisticsV3PeriodX on StatisticsV3Period {
  int get trailingDays {
    switch (this) {
      case StatisticsV3Period.day:
        return 1;
      case StatisticsV3Period.week:
        return 7;
      case StatisticsV3Period.month:
        return 30;
      case StatisticsV3Period.year:
        return 365;
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case StatisticsV3Period.day:
        return l10n.habitStatsPeriodDay;
      case StatisticsV3Period.week:
        return l10n.habitStatsPeriodWeek;
      case StatisticsV3Period.month:
        return l10n.habitStatsPeriodMonth;
      case StatisticsV3Period.year:
        return l10n.habitStatsPeriodYear;
    }
  }
}
