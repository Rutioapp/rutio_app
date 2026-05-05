import 'package:flutter/widgets.dart';

enum StatisticsPeriod {
  day,
  week,
  month,
  year,
}

extension StatisticsPeriodX on StatisticsPeriod {
  String label(BuildContext context) {
    switch (this) {
      case StatisticsPeriod.day:
        return 'Dia';
      case StatisticsPeriod.week:
        return 'Semana';
      case StatisticsPeriod.month:
        return 'Mes';
      case StatisticsPeriod.year:
        return 'Ano';
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
