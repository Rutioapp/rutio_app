part of '../habit_stats_tab.dart';

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
    required this.weekText,
    required this.monthText,
    required this.yearText,
  });

  final _HabitStatsPeriod selected;
  final ValueChanged<_HabitStatsPeriod> onChanged;
  final String weekText;
  final String monthText;
  final String yearText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2ECE2),
        borderRadius: BorderRadius.circular(26),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _PeriodSegment(
            label: weekText,
            selected: selected == _HabitStatsPeriod.week,
            onTap: () => onChanged(_HabitStatsPeriod.week),
          ),
          _PeriodSegment(
            label: monthText,
            selected: selected == _HabitStatsPeriod.month,
            onTap: () => onChanged(_HabitStatsPeriod.month),
          ),
          _PeriodSegment(
            label: yearText,
            selected: selected == _HabitStatsPeriod.year,
            onTap: () => onChanged(_HabitStatsPeriod.year),
          ),
        ],
      ),
    );
  }
}

class _PeriodSegment extends StatelessWidget {
  const _PeriodSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 10),
        minimumSize: const Size(40, 40),
        onPressed: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF5D3217), Color(0xFF3B210F)],
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.sansFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFFFAF6EF)
                    : const Color(0xFF3E2A1D),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
