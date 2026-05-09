import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rutio/features/statistics/presentation/v3/models/statistics_v3_view_data.dart';

class StatisticsV3YearlyConsistencyShell extends StatelessWidget {
  const StatisticsV3YearlyConsistencyShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.months,
  });

  final String title;
  final String subtitle;
  final List<StatisticsV3YearlyConsistencyMonth> months;

  static const _border = Color(0xFFE9E3D9);
  static const _cream = Color(0xFFFDFBF7);
  static const _text = Color(0xFF2F251C);
  static const _mutedText = Color(0xFF6A6155);
  static const _cellBorder = Color(0xFFE5DED3);
  static const _futureFill = Color(0xFFF0EBE3);
  static const _todayBorder = Color(0xFF9AA789);

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final data = months.isEmpty ? _fallbackMonths() : months;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: _cream.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 24,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _todayBorder.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_view_month_rounded,
                    size: 16,
                    color: _todayBorder,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.2,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1.1,
              fontWeight: FontWeight.w500,
              color: _mutedText,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: data.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.32,
            ),
            itemBuilder: (context, index) {
              final month = data[index];
              final label = _monthLabel(
                localeName: localeName,
                year: month.year,
                month: month.month,
              );
              final tone = _toneForMonth(month);

              return _YearMonthCell(
                label: label,
                percentage: month.percentage,
                fillColor: tone.fillColor,
                borderColor: month.isCurrentMonth
                    ? _todayBorder.withValues(alpha: 0.82)
                    : tone.borderColor,
                textColor: tone.textColor,
                isFuture: month.isFuture,
              );
            },
          ),
        ],
      ),
    );
  }

  List<StatisticsV3YearlyConsistencyMonth> _fallbackMonths() {
    final now = DateTime.now();
    return List<StatisticsV3YearlyConsistencyMonth>.generate(12, (index) {
      final month = index + 1;
      return StatisticsV3YearlyConsistencyMonth(
        month: month,
        year: now.year,
        completedCount: 0,
        expectedCount: 0,
        percentage: 0,
        isCurrentMonth: month == now.month,
        isFuture: month > now.month,
      );
    }, growable: false);
  }

  _YearMonthTone _toneForMonth(StatisticsV3YearlyConsistencyMonth month) {
    if (month.isFuture) {
      return _YearMonthTone.future;
    }
    return _YearMonthTone.fromBucket(_bucketForPercentage(month.percentage));
  }

  _YearlyIntensityBucket _bucketForPercentage(int percentage) {
    final value = percentage.clamp(0, 100);
    if (value <= 24) {
      return _YearlyIntensityBucket.zero;
    }
    if (value <= 49) {
      return _YearlyIntensityBucket.low;
    }
    if (value <= 74) {
      return _YearlyIntensityBucket.medium;
    }
    if (value <= 89) {
      return _YearlyIntensityBucket.high;
    }
    return _YearlyIntensityBucket.full;
  }

  String _monthLabel({
    required String localeName,
    required int year,
    required int month,
  }) {
    final label = DateFormat.MMM(localeName).format(DateTime(year, month, 1));
    if (label.isEmpty) return '';
    final first = label.substring(0, 1).toUpperCase();
    final rest = label.length > 1 ? label.substring(1) : '';
    return '$first$rest';
  }
}

class _YearMonthCell extends StatelessWidget {
  const _YearMonthCell({
    required this.label,
    required this.percentage,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
    required this.isFuture,
  });

  final String label;
  final int percentage;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final alpha = isFuture ? 0.6 : 0.95;
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1,
              fontWeight: FontWeight.w700,
              color: textColor.withValues(alpha: alpha),
            ),
          ),
          Text(
            '$percentage%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w800,
              color: textColor.withValues(alpha: alpha),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearMonthTone {
  const _YearMonthTone({
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
  });

  final Color fillColor;
  final Color borderColor;
  final Color textColor;

  factory _YearMonthTone.fromBucket(_YearlyIntensityBucket bucket) {
    return _YearMonthTone(
      fillColor: bucket.color,
      borderColor: StatisticsV3YearlyConsistencyShell._cellBorder,
      textColor: StatisticsV3YearlyConsistencyShell._text,
    );
  }

  static const future = _YearMonthTone(
    fillColor: StatisticsV3YearlyConsistencyShell._futureFill,
    borderColor: StatisticsV3YearlyConsistencyShell._cellBorder,
    textColor: StatisticsV3YearlyConsistencyShell._mutedText,
  );
}

class _YearlyIntensityBucket {
  const _YearlyIntensityBucket._(this.color);

  final Color color;

  static const zero = _YearlyIntensityBucket._(Color(0xFFF4EAD7));
  static const low = _YearlyIntensityBucket._(Color(0xFFEEDDAF));
  static const medium = _YearlyIntensityBucket._(Color(0xFFD9A947));
  static const high = _YearlyIntensityBucket._(Color(0xFF8FA36C));
  static const full = _YearlyIntensityBucket._(Color(0xFF4F743B));
}
