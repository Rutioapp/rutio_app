import 'package:flutter/material.dart';

import '../../../../stores/user_state_store.dart';
import '../../../../utils/family_theme.dart';
import '../../../../widgets/stats/helpers/stats_card_surface.dart';
import '../../../../widgets/stats/helpers/stats_number_formatter.dart';
import '../../application/adapters/statistics_data_adapter.dart';
import '../../domain/statistics_models.dart';
import '../../domain/statistics_period.dart';

class StatisticsHabitsTab extends StatefulWidget {
  const StatisticsHabitsTab({
    super.key,
    required this.adapter,
    required this.store,
    required this.period,
    required this.onOpenHabit,
  });

  final StatisticsDataAdapter adapter;
  final UserStateStore store;
  final StatisticsPeriod period;
  final ValueChanged<String> onOpenHabit;

  @override
  State<StatisticsHabitsTab> createState() => _StatisticsHabitsTabState();
}

class _StatisticsHabitsTabState extends State<StatisticsHabitsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFamilyId = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habits = widget.adapter.buildHabits(
      store: widget.store,
      period: widget.period,
      query: _searchController.text,
      familyId: _selectedFamilyId,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Buscar habito',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _selectedFamilyId,
                borderRadius: BorderRadius.circular(12),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todas')),
                  ...FamilyTheme.order.map(
                    (familyId) => DropdownMenuItem(
                      value: familyId,
                      child: Text(FamilyTheme.nameOf(familyId)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFamilyId = value ?? '';
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: habits.isEmpty
              ? Center(
                  child: Text(
                    'No hay habitos para este filtro.',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
                    final habit = habits[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HabitCard(
                        habit: habit,
                        onTap: () => widget.onOpenHabit(habit.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.onTap,
  });

  final StatisticsHabitSummary habit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final familyColor = FamilyTheme.colorOf(habit.familyId);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        decoration: StatsCardSurface.decoration(context),
        padding: StatsCardSurface.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    habit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: familyColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    FamilyTheme.nameOf(habit.familyId),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: familyColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _metric(
                    'Completado',
                    '${habit.doneDays}/${habit.scheduledDays}',
                  ),
                ),
                Expanded(
                  child: _metric('Consistencia', '${habit.completionPct}%'),
                ),
                Expanded(
                  child: _metric('Racha', '${habit.currentStreak} d'),
                ),
              ],
            ),
            if (habit.type == StatisticsHabitType.count &&
                habit.countProgress != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _metric(
                      'Volumen',
                      habit.countProgress!.totalAccumulated.toString(),
                    ),
                  ),
                  Expanded(
                    child: _metric(
                      'Media',
                      StatsNumberFormatter.compact1(
                        habit.countProgress!.dailyAverage,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _metric(
                      'Cumplimiento',
                      '${habit.countProgress!.compliancePct.round()}%',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black.withValues(alpha: 0.56),
          ),
        ),
      ],
    );
  }
}
