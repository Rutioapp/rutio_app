import 'package:flutter/material.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/l10n/l10n.dart';

class StatisticsV3YearlyConsistencyShell extends StatelessWidget {
  const StatisticsV3YearlyConsistencyShell({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  static const _border = Color(0xFFE9E3D9);
  static const _cream = Color(0xFFFDFBF7);
  static const _text = Color(0xFF2F251C);
  static const _mutedText = Color(0xFF6A6155);
  static const _cellBorder = Color(0xFFE4DCCC);
  static const _futureFill = Color(0xFFF5F0E8);
  static const _accent = Color(0xFF8FA789);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentMonth = DateTime.now().month;
    final months = List.generate(12, (index) {
      final monthNumber = index + 1;
      return _YearMonthItem(
        label: _monthLabel(monthNumber, l10n),
        isCurrent: monthNumber == currentMonth,
        isFuture: monthNumber > currentMonth,
      );
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: _cream.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 172;
          final crossAxisCount = constraints.maxWidth < 340 ? 3 : 4;
          final mainAxisExtent = crossAxisCount == 3 ? 72.0 : 68.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: compact ? 23 : 24,
                child: Row(
                  children: [
                    Container(
                      width: compact ? 22 : 24,
                      height: compact ? 22 : 24,
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        size: compact ? 15 : 16,
                        color: _accent,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: compact ? 13.4 : 14.2,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            color: _text,
                          ),
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
                itemCount: months.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: mainAxisExtent,
                ),
                itemBuilder: (context, index) {
                  final month = months[index];
                  return _YearMonthCell(
                    label: month.label,
                    isCurrent: month.isCurrent,
                    isFuture: month.isFuture,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  String _monthLabel(int month, AppLocalizations l10n) {
    switch (month) {
      case 1:
        return l10n.monthShortJan;
      case 2:
        return l10n.monthShortFeb;
      case 3:
        return l10n.monthShortMar;
      case 4:
        return l10n.monthShortApr;
      case 5:
        return l10n.monthShortMay;
      case 6:
        return l10n.monthShortJun;
      case 7:
        return l10n.monthShortJul;
      case 8:
        return l10n.monthShortAug;
      case 9:
        return l10n.monthShortSep;
      case 10:
        return l10n.monthShortOct;
      case 11:
        return l10n.monthShortNov;
      case 12:
        return l10n.monthShortDec;
      default:
        return '';
    }
  }
}

class _YearMonthItem {
  const _YearMonthItem({
    required this.label,
    required this.isCurrent,
    required this.isFuture,
  });

  final String label;
  final bool isCurrent;
  final bool isFuture;
}

class _YearMonthCell extends StatelessWidget {
  const _YearMonthCell({
    required this.label,
    required this.isCurrent,
    required this.isFuture,
  });

  final String label;
  final bool isCurrent;
  final bool isFuture;

  static const _cardFill = Color(0xFFF2ECE3);
  static const _cardText = Color(0xFF2F251C);
  static const _cardFutureText = Color(0xFF8A8176);
  static const _cardBorder = Color(0xFFE4DCCC);
  static const _cardAccent = Color(0xFF8FA789);
  static const _dotBase = Color(0xFFD7D0C4);

  @override
  Widget build(BuildContext context) {
    final fillColor = isFuture
        ? StatisticsV3YearlyConsistencyShell._futureFill.withValues(alpha: 0.72)
        : _cardFill.withValues(alpha: 0.92);
    final borderColor = isCurrent ? _cardAccent.withValues(alpha: 0.42) : _cardBorder;
    final textColor = isFuture ? _cardFutureText : _cardText;
    final dotAlphas = isFuture
        ? const [0.18, 0.24, 0.30, 0.22]
        : isCurrent
            ? const [0.30, 0.44, 0.58, 0.40]
            : const [0.24, 0.36, 0.50, 0.32];

    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              height: 1,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (var index = 0; index < dotAlphas.length; index += 1)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _dotBase.withValues(alpha: dotAlphas[index]),
                        borderRadius: BorderRadius.circular(4),
                        border: isCurrent && index == 1
                            ? Border.all(
                                color: _cardAccent.withValues(alpha: 0.34),
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
