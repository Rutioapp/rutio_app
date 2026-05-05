import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';

import '../../../../stores/user_state_store.dart';
import '../../../../utils/family_theme.dart';
import '../../application/adapters/statistics_data_adapter.dart';
import '../../domain/statistics_models.dart';
import '../../domain/statistics_period.dart';
import 'habits/statistics_habit_list_card.dart';
import 'habits/statistics_habits_empty_state.dart';
import 'habits/statistics_habits_type_filter.dart';

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
  StatisticsHabitListTypeFilter _typeFilter = StatisticsHabitListTypeFilter.all;
  String _selectedFamilyId = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeHabits = widget.store.activeHabits;
    final habits = widget.adapter.buildHabitList(
      store: widget.store,
      period: widget.period,
      query: _searchController.text,
      familyId: _selectedFamilyId,
      typeFilter: _typeFilter,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              TextField(
                key: const Key('statistics_habits_search_field'),
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: context.l10n.statisticsV2HabitsSearchHint,
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: StatisticsHabitsTypeFilter(
                      value: _typeFilter,
                      onChanged: (value) {
                        setState(() {
                          _typeFilter = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedFamilyId,
                    borderRadius: BorderRadius.circular(12),
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(context.l10n.statisticsV2HabitsAllFamilies),
                      ),
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
            ],
          ),
        ),
        Expanded(
          child: activeHabits.isEmpty
              ? StatisticsHabitsEmptyState(
                  title: context.l10n.statisticsV2HabitsEmptyTitle,
                  subtitle: context.l10n.statisticsV2HabitsEmptySubtitle,
                )
              : habits.isEmpty
                  ? StatisticsHabitsEmptyState(
                      title: context.l10n.statisticsV2HabitsNoMatchesTitle,
                      subtitle: context.l10n.statisticsV2HabitsNoMatchesSubtitle,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: StatisticsHabitListCard(
                            item: habit,
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
