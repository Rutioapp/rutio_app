part of '../habit_stats_tab.dart';

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1A2A2118)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D2A2118),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTextStyles.sansFamily,
              fontSize: 36,
              height: 0.95,
              letterSpacing: -0.4,
              fontWeight: FontWeight.w700,
              color: Color(0xFF22201B),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CheckLast7Indicators extends StatelessWidget {
  const _CheckLast7Indicators({
    super.key,
    required this.rows,
    required this.l10n,
  });

  final List<_DayRow> rows;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: rows
          .map(
            (row) => Expanded(
              child: Column(
                children: [
                  Text(
                    l10n.weekdayShort(row.date.weekday),
                    style: const TextStyle(
                      fontFamily: AppTextStyles.sansFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF514D48),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DayCheckIndicator(row: row),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _DayCheckIndicator extends StatelessWidget {
  const _DayCheckIndicator({
    required this.row,
  });

  final _DayRow row;

  @override
  Widget build(BuildContext context) {
    if (row.skipped) {
      return Container(
        width: 39,
        height: 39,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E4DC),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFCEC8BC)),
        ),
        child: const Icon(
          CupertinoIcons.minus,
          color: Color(0xFF8F887A),
          size: 18,
        ),
      );
    }

    final completed = row.checkCompleted;
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: completed ? const Color(0xFF5F9A57) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: completed ? const Color(0xFF5F9A57) : const Color(0xFFCAC4B8),
          width: 1.6,
        ),
      ),
      child: completed
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
          : null,
    );
  }
}

class _CountLast7Chart extends StatelessWidget {
  const _CountLast7Chart({
    super.key,
    required this.rows,
    required this.unit,
    required this.target,
    required this.l10n,
  });

  final List<_DayRow> rows;
  final String unit;
  final num target;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    const chartHeight = 124.0;
    final showTarget = target > 0;

    return Column(
      children: [
        SizedBox(
          height: chartHeight,
          child: Stack(
            children: [
              if (showTarget)
                Align(
                  alignment: Alignment(
                    0,
                    1 - ((target / target).clamp(0, 1) * 2),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 1,
                    color: const Color(0xA0B8B09F),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: rows
                    .map(
                      (row) => Expanded(
                        child: Column(
                          children: [
                            Text(
                              l10n.weekdayShort(row.date.weekday),
                              style: const TextStyle(
                                fontFamily: AppTextStyles.sansFamily,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF514D48),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: _CountBar(
                                  value: row.countValue,
                                  target: target,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: rows
              .map(
                (row) => Expanded(
                  child: Text(
                    _valueWithUnit(row.countValue, unit),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.sansFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3E3A35),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _CountBar extends StatelessWidget {
  const _CountBar({
    required this.value,
    required this.target,
  });

  final num value;
  final num target;

  @override
  Widget build(BuildContext context) {
    final ratio =
        target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 30,
      height: 86,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 20,
            height: 86,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9DF),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Container(
            width: 20,
            height: 86 * ratio,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xFF5D9457), Color(0xFF90B689)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}
