import 'habit_date_utils.dart';

class WeeklyReportWeek {
  const WeeklyReportWeek({
    required this.weekStartDate,
    required this.weekEndDate,
  });

  factory WeeklyReportWeek.fromDate(DateTime date) {
    final weekStartDate = weekStartMonday(date);
    return WeeklyReportWeek(
      weekStartDate: weekStartDate,
      weekEndDate: weekStartDate.add(const Duration(days: 6)),
    );
  }

  final DateTime weekStartDate;
  final DateTime weekEndDate;

  int get weekStartsOn => DateTime.monday;

  List<DateTime> get days => List<DateTime>.generate(
        7,
        (index) => weekStartDate.add(Duration(days: index)),
        growable: false,
      );

  bool contains(DateTime date) {
    final normalized = dateOnly(date);
    return !normalized.isBefore(dateOnly(weekStartDate)) &&
        !normalized.isAfter(dateOnly(weekEndDate));
  }

  int get eligibleDaysCount => daysBetweenInclusive(weekStartDate, weekEndDate);

  WeeklyReportWeek copyWith({
    DateTime? weekStartDate,
    DateTime? weekEndDate,
  }) {
    return WeeklyReportWeek(
      weekStartDate: weekStartDate ?? this.weekStartDate,
      weekEndDate: weekEndDate ?? this.weekEndDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeeklyReportWeek &&
        sameDate(other.weekStartDate, weekStartDate) &&
        sameDate(other.weekEndDate, weekEndDate);
  }

  @override
  int get hashCode =>
      Object.hash(dateOnly(weekStartDate), dateOnly(weekEndDate));
}
