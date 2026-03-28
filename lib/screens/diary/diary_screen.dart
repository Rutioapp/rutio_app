import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import 'package:rutio/screens/habit_archived_screen.dart';
import 'package:rutio/screens/habit_monthly_screen.dart';
import 'package:rutio/screens/habit_stats_overview_screen.dart';
import 'package:rutio/screens/habit_weekly_screen.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:rutio/screens/profile/profile_screen.dart';
import 'package:rutio/widgets/app_view_drawer.dart';

import '../../l10n/l10n.dart';
import '../../stores/user_state_store.dart';
import 'helpers/diary_screen_actions.dart';
import 'helpers/diary_screen_view_data.dart';
import 'models/diary_types.dart';
import 'screens/diary_entry_detail_screen.dart';
import 'widgets/diary_header.dart';
import 'widgets/diary_screen_background.dart';
import 'widgets/diary_screen_body.dart';
import 'widgets/diary_screen_fab.dart';

export 'helpers/diary_screen_actions.dart'
    show showAfterHabitCompleteNotePrompt;

void _navReplace(BuildContext context, Widget screen) {
  final scaffold = Scaffold.maybeOf(context);
  if (scaffold != null && scaffold.isDrawerOpen) {
    Navigator.of(context).pop();
  }
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => screen),
  );
}

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  DiaryPeriod _period = DiaryPeriod.today;
  bool _searchOpen = false;
  bool _fabCollapsed = false;
  String _searchQuery = '';
  SearchScope? _searchScope;
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && !_fabCollapsed) {
      setState(() => _fabCollapsed = true);
    } else if (direction == ScrollDirection.forward && _fabCollapsed) {
      setState(() => _fabCollapsed = false);
    }
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (_searchOpen) {
        _searchCtrl.text = _searchQuery;
        _searchCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchCtrl.text.length),
        );
      } else {
        FocusScope.of(context).unfocus();
      }
    });
  }

  DiaryScreenViewData _buildViewData(UserStateStore store) {
    return buildDiaryScreenViewData(
      entries: store.diaryEntries,
      period: _period,
      searchQuery: _searchQuery,
      searchScope: _searchScope,
      store: store,
    );
  }

  Future<bool> _handleEntryDismiss(
    DiaryEntryUi entry,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      _openCreateEntrySheet(editing: entry);
      return false;
    }

    final confirmed = await showDiaryDeleteConfirmationDialog(context);
    if (!mounted || !confirmed) return false;

    context.read<UserStateStore>().deleteDiaryEntry(entry.id);
    return true;
  }

  Future<void> _openEntryDetail(DiaryEntryUi entry) async {
    final action = await Navigator.of(context).push<DiaryEntryDetailAction>(
      CupertinoPageRoute(
        builder: (_) => DiaryEntryDetailScreen(entry: entry),
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case DiaryEntryDetailAction.edit:
        _openCreateEntrySheet(editing: entry);
        break;
      case DiaryEntryDetailAction.delete:
        await _confirmDelete(entry);
        break;
    }
  }

  Future<void> _confirmDelete(DiaryEntryUi entry) async {
    final confirmed = await showDiaryDeleteConfirmationDialog(context);
    if (!mounted || !confirmed) return;

    await context.read<UserStateStore>().deleteDiaryEntry(entry.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.diaryEntryDeleted)),
    );
  }

  void _openFiltersSheet() => showDiaryFiltersBottomSheet(context);

  void _openCreateEntrySheet({DiaryEntryUi? editing}) {
    showDiaryEntryComposerBottomSheet(
      context,
      editing: editing,
      successMessage: context.l10n.diaryEntrySaved,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserStateStore>();
    final viewData = _buildViewData(store);
    return Scaffold(
      drawer: AppViewDrawer(
        selected: 'diary',
        onGoDaily: () => _navReplace(context, const HomeScreen()),
        onGoWeekly: () => _navReplace(context, const HabitWeeklyScreen()),
        onGoMonthly: () => _navReplace(context, const HabitMonthlyScreen()),
        onGoTodo: () => Navigator.pushNamed(context, '/todo'),
        onGoDiary: () => _navReplace(context, const DiaryScreen()),
        onGoArchived: () => _navReplace(context, const ArchivedHabitsScreen()),
        onGoStats: () => _navReplace(context, const HabitStatsOverviewHost()),
        onGoProfile: () => _navReplace(context, const ProfileScreen()),
      ),
      backgroundColor: Colors.transparent,
      floatingActionButton: DiaryScreenFab(
        collapsed: _fabCollapsed,
        onPressed: _openCreateEntrySheet,
      ),
      body: DiaryScreenBackground(
        child: DiaryScreenBody(
          scrollController: _scrollController,
          store: store,
          allEntries: store.diaryEntries,
          viewData: viewData,
          period: _period,
          searchOpen: _searchOpen,
          searchController: _searchCtrl,
          searchScope: _searchScope,
          onSearchToggle: _toggleSearch,
          onFiltersTap: _openFiltersSheet,
          onPeriodChanged: (period) => setState(() => _period = period),
          onSearchScopeChanged: (scope) => setState(() => _searchScope = scope),
          onSearchChanged: (value) => setState(() => _searchQuery = value),
          onSearchClear: () => setState(() {
            _searchQuery = '';
            _searchCtrl.clear();
          }),
          onEntryTap: _openEntryDetail,
          onEntryEdit: (entry) => _openCreateEntrySheet(editing: entry),
          onEntryDelete: _confirmDelete,
          onEntryDismiss: _handleEntryDismiss,
        ),
      ),
    );
  }
}
