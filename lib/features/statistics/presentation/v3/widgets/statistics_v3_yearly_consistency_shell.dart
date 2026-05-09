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

    return LayoutBuilder(
      builder: (context, constraints) {
        final useFourColumns = constraints.maxWidth >= 336;
        final crossAxisCount = useFourColumns ? 4 : 3;
        final gridSpacing = useFourColumns ? 6.0 : 5.0;
        final childAspectRatio = useFourColumns ? 1.58 : 1.82;

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
              const SizedBox(height: 5),
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
              const SizedBox(height: 9),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: data.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: gridSpacing,
                  crossAxisSpacing: gridSpacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemBuilder: (context, index) {
                  final month = data[index];
                  final label = _monthLabel(
                    localeName: localeName,
                    year: month.year,
                    month: month.month,
                  );
                  final tone = _toneForMonth(month);
                  final percentageLabel =
                      month.isFuture ? null : '${month.percentage}%';

                  return _YearMonthCell(
                    label: label,
                    percentageLabel: percentageLabel,
                    fillColor: tone.fillColor,
                    borderColor: month.isCurrentMonth
                        ? _todayBorder.withValues(alpha: 0.52)
                        : tone.borderColor,
                    textColor: tone.textColor,
                    isFuture: month.isFuture,
                    isCurrentMonth: month.isCurrentMonth,
                  );
                },
              ),
            ],
          ),
        );
      },
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
    required this.percentageLabel,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
    required this.isFuture,
    required this.isCurrentMonth,
  });

  final String label;
  final String? percentageLabel;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final bool isFuture;
  final bool isCurrentMonth;

  @override
  Widget build(BuildContext context) {
    final alpha = isFuture ? 0.58 : 0.94;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6.5, 8, 6.5),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: borderColor,
          width: isCurrentMonth ? 1.25 : 1,
        ),
        boxShadow: isCurrentMonth
            ? [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.12),
                  blurRadius: 7,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
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
              fontSize: 10.6,
              height: 1,
              fontWeight: FontWeight.w700,
              color: textColor.withValues(alpha: alpha),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              percentageLabel ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.8,
                height: 1,
                fontWeight: FontWeight.w800,
                color: textColor.withValues(alpha: alpha),
              ),
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
    final fillColor = Color.alphaBlend(
      bucket.color.withValues(alpha: bucket.fillAlpha),
      StatisticsV3YearlyConsistencyShell._cream,
    );
    final borderColor = Color.alphaBlend(
      bucket.color.withValues(alpha: bucket.borderAlpha),
      StatisticsV3YearlyConsistencyShell._cellBorder,
    );
    final textColor = Color.lerp(
      StatisticsV3YearlyConsistencyShell._text,
      bucket.color,
      bucket.textBlend,
    )!;

    return _YearMonthTone(
      fillColor: fillColor,
      borderColor: borderColor,
      textColor: textColor,
    );
  }

  static final future = _YearMonthTone(
    fillColor: Color.alphaBlend(
      StatisticsV3YearlyConsistencyShell._futureFill.withValues(alpha: 0.82),
      StatisticsV3YearlyConsistencyShell._cream,
    ),
    borderColor:
        StatisticsV3YearlyConsistencyShell._cellBorder.withValues(alpha: 0.88),
    textColor:
        StatisticsV3YearlyConsistencyShell._mutedText.withValues(alpha: 0.90),
  );
}

class _YearlyIntensityBucket {
  const _YearlyIntensityBucket._(
    this.color, {
    required this.fillAlpha,
    required this.borderAlpha,
    required this.textBlend,
  });

  final Color color;
  final double fillAlpha;
  final double borderAlpha;
  final double textBlend;

  static const zero = _YearlyIntensityBucket._(
    Color(0xFFF4EAD7),
    fillAlpha: 0.18,
    borderAlpha: 0.24,
    textBlend: 0.10,
  );
  static const low = _YearlyIntensityBucket._(
    Color(0xFFEEDDAF),
    fillAlpha: 0.24,
    borderAlpha: 0.30,
    textBlend: 0.14,
  );
  static const medium = _YearlyIntensityBucket._(
    Color(0xFFD9A947),
    fillAlpha: 0.31,
    borderAlpha: 0.40,
    textBlend: 0.20,
  );
  static const high = _YearlyIntensityBucket._(
    Color(0xFF8FA36C),
    fillAlpha: 0.36,
    borderAlpha: 0.46,
    textBlend: 0.26,
  );
  static const full = _YearlyIntensityBucket._(
    Color(0xFF4F743B),
    fillAlpha: 0.42,
    borderAlpha: 0.52,
    textBlend: 0.33,
  );
}
