import 'package:flutter/material.dart';

import '../../../models/diary_entry.dart';
import '../models/diary_types.dart';
import '../widgets/diary_header.dart';
import '../widgets/diary_overview_card.dart';

class DiarySummarySection extends StatelessWidget {
  const DiarySummarySection({
    super.key,
    required this.period,
    required this.entriesCount,
    required this.todayEntriesCount,
    required this.dailyXp,
    required this.entries,
    required this.searchOpen,
    required this.searchController,
    required this.searchScope,
    required this.onPeriodChanged,
    required this.onSearchScopeChanged,
    required this.onSearchChanged,
    required this.onSearchClear,
  });

  final DiaryPeriod period;
  final int entriesCount;
  final int todayEntriesCount;
  final int dailyXp;
  final List<DiaryEntry> entries;
  final bool searchOpen;
  final TextEditingController searchController;
  final SearchScope? searchScope;
  final ValueChanged<DiaryPeriod> onPeriodChanged;
  final ValueChanged<SearchScope> onSearchScopeChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DiaryTopControls(
            period: period,
            entriesCount: entriesCount,
            onPeriodChanged: onPeriodChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: DiaryOverviewCard(
            entriesCount: todayEntriesCount,
            emotionalXp: dailyXp,
            entries: entries,
          ),
        ),
        if (searchOpen)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: DiarySearchPanel(
              controller: searchController,
              scope: searchScope,
              onScopeChanged: onSearchScopeChanged,
              onChanged: onSearchChanged,
              onClear: onSearchClear,
            ),
          ),
      ],
    );
  }
}
