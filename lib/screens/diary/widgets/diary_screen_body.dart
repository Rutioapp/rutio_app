import 'package:flutter/material.dart';

import '../../../models/diary_entry.dart';
import '../../../stores/user_state_store.dart';
import '../helpers/diary_screen_view_data.dart';
import '../models/diary_types.dart';
import '../sections/diary_entries_section.dart';
import '../sections/diary_summary_section.dart';
import 'diary_header.dart';
import 'diary_screen_header.dart';

class DiaryScreenBody extends StatelessWidget {
  const DiaryScreenBody({
    super.key,
    required this.scrollController,
    required this.store,
    required this.allEntries,
    required this.viewData,
    required this.period,
    required this.searchOpen,
    required this.searchController,
    required this.searchScope,
    required this.onSearchToggle,
    required this.onFiltersTap,
    required this.onPeriodChanged,
    required this.onSearchScopeChanged,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onEntryTap,
    required this.onEntryEdit,
    required this.onEntryDelete,
    required this.onEntryDismiss,
  });

  final ScrollController scrollController;
  final UserStateStore store;
  final List<DiaryEntry> allEntries;
  final DiaryScreenViewData viewData;
  final DiaryPeriod period;
  final bool searchOpen;
  final TextEditingController searchController;
  final SearchScope? searchScope;
  final VoidCallback onSearchToggle;
  final VoidCallback onFiltersTap;
  final ValueChanged<DiaryPeriod> onPeriodChanged;
  final ValueChanged<SearchScope> onSearchScopeChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final ValueChanged<DiaryEntryUi> onEntryTap;
  final ValueChanged<DiaryEntryUi> onEntryEdit;
  final ValueChanged<DiaryEntryUi> onEntryDelete;
  final Future<bool> Function(
    DiaryEntryUi entry,
    DismissDirection direction,
  ) onEntryDismiss;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: DiaryScreenHeader(
              searchOpen: searchOpen,
              onSearchTap: onSearchToggle,
              onFiltersTap: onFiltersTap,
            ),
          ),
          const SizedBox(height: 18),
          DiarySummarySection(
            period: period,
            entriesCount: viewData.entriesCount,
            todayEntriesCount: viewData.todayEntriesCount,
            dailyXp: viewData.dailyXp,
            entries: allEntries,
            searchOpen: searchOpen,
            searchController: searchController,
            searchScope: searchScope,
            onPeriodChanged: onPeriodChanged,
            onSearchScopeChanged: onSearchScopeChanged,
            onSearchChanged: onSearchChanged,
            onSearchClear: onSearchClear,
          ),
          const SizedBox(height: 18),
          DiaryEntriesSection(
            store: store,
            sortedDays: viewData.sortedDays,
            groupedEntries: viewData.groupedEntries,
            onEntryTap: onEntryTap,
            onEntryEdit: onEntryEdit,
            onEntryDelete: onEntryDelete,
            onEntryDismiss: onEntryDismiss,
          ),
        ],
      ),
    );
  }
}
