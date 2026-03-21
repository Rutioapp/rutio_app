import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/diary/diary_screen.dart';
import 'package:rutio/screens/habit_archived_screen.dart';
import 'package:rutio/screens/habit_monthly_screen.dart';
import 'package:rutio/screens/habit_stats_overview_screen.dart';
import 'package:rutio/screens/habit_weekly_screen.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:rutio/screens/profile/profile_screen.dart';
import 'package:rutio/screens/shop_screen.dart';
import 'package:rutio/screens/todo/create_todo_screen.dart';
import 'package:rutio/screens/todo/edit_todo_screen.dart';
import 'package:rutio/screens/todo/helpers/todo_date_formatter.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';
import 'package:rutio/screens/todo/models/todo_filter.dart';
import 'package:rutio/screens/todo/models/todo_item.dart';
import 'package:rutio/screens/todo/widgets/todo_completed_header.dart';
import 'package:rutio/screens/todo/widgets/todo_completed_task_card.dart';
import 'package:rutio/screens/todo/widgets/todo_filter_row.dart';
import 'package:rutio/screens/todo/widgets/todo_progress_card.dart';
import 'package:rutio/screens/todo/widgets/todo_task_card.dart';
import 'package:rutio/screens/todo/widgets/todo_title_block.dart';
import 'package:rutio/screens/todo/widgets/todo_top_bar.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/widgets/app_view_drawer.dart';
import 'package:rutio/widgets/home/home_add_fab.dart';

void _navReplace(BuildContext context, Widget screen) {
  final scaffold = Scaffold.maybeOf(context);
  if (scaffold != null && scaffold.isDrawerOpen) {
    Navigator.of(context).pop();
  }
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => screen),
  );
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  static const String route = '/todo';

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  TodoFilter _selectedFilter = TodoFilter.all;
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserStateStore>();
    final todos = store.todoItems;
    final now = DateTime.now();
    final pendingItems = todos
        .where((item) => !item.isCompleted)
        .where((item) =>
            TodoDateFormatter.matchesFilter(item, _selectedFilter, now))
        .toList();
    final completedItems = todos
        .where((item) => item.isCompleted)
        .where((item) =>
            TodoDateFormatter.matchesFilter(item, _selectedFilter, now))
        .toList();
    final completedCount = todos.where((item) => item.isCompleted).length;
    final showCompletedInline = _selectedFilter == TodoFilter.completed;

    return Scaffold(
      drawer: AppViewDrawer(
        selected: 'todo',
        onGoDaily: () => _navReplace(context, const HomeScreen()),
        onGoWeekly: () => _navReplace(context, const HabitWeeklyScreen()),
        onGoMonthly: () => _navReplace(context, const HabitMonthlyScreen()),
        onGoTodo: () => Navigator.pop(context),
        onGoDiary: () => _navReplace(context, const DiaryScreen()),
        onGoArchived: () => _navReplace(context, const ArchivedHabitsScreen()),
        onGoStats: () => _navReplace(context, const HabitStatsOverviewHost()),
        onGoShop: () => _navReplace(context, const ShopScreen()),
        onGoProfile: () => _navReplace(context, const ProfileScreen()),
      ),
      backgroundColor: Colors.transparent,
      floatingActionButton: HomeAddFab(
        onPressed: _openCreateTodo,
        heroTag: 'todo_add_fab',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
        decoration: BoxDecoration(
          gradient: TodoStyleResolver.backgroundGradient(),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: <Widget>[
              Builder(
                builder: (ctx) => TodoTopBar(
                  title: context.l10n.todoTitle,
                  onMenuTap: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              TodoTitleBlock(
                dateLabel: TodoDateFormatter.headerDate(context, now),
              ),
              const SizedBox(height: 18),
              TodoFilterRow(
                selectedFilter: _selectedFilter,
                onSelected: (filter) {
                  setState(() => _selectedFilter = filter);
                },
              ),
              const SizedBox(height: 10),
              TodoProgressCard(
                completedCount: completedCount,
                totalCount: todos.length,
              ),
              const SizedBox(height: 10),
              if (pendingItems.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                ...pendingItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TodoTaskCard(
                      item: item,
                      now: now,
                      onToggleCompleted: () => _toggleCompleted(item.id),
                      onTap: () => _openEditTodo(item),
                    ),
                  ),
                ),
              ],
              if (showCompletedInline && completedItems.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                ...completedItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TodoCompletedTaskCard(
                      item: item,
                      onTap: () => _openEditTodo(item),
                    ),
                  ),
                ),
              ] else ...<Widget>[
                if (pendingItems.isEmpty) const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TodoCompletedHeader(
                    count: completedItems.length,
                    expanded: _showCompleted,
                    onTap: () {
                      setState(() => _showCompleted = !_showCompleted);
                    },
                  ),
                ),
                if (_showCompleted) ...<Widget>[
                  ...completedItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TodoCompletedTaskCard(
                        item: item,
                        onTap: () => _openEditTodo(item),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateTodo() async {
    final created = await Navigator.of(context).push<TodoItem>(
      CupertinoPageRoute<TodoItem>(
        fullscreenDialog: true,
        builder: (_) => const CreateTodoScreen(),
      ),
    );

    if (!mounted || created == null) return;

    await context.read<UserStateStore>().upsertTodoItem(created);
    if (!mounted) return;

    setState(() {
      _selectedFilter = TodoFilter.all;
    });
  }

  Future<void> _openEditTodo(TodoItem item) async {
    final edited = await Navigator.of(context).push<TodoItem>(
      CupertinoPageRoute<TodoItem>(
        fullscreenDialog: true,
        builder: (_) => EditTodoScreen(item: item),
      ),
    );

    if (!mounted || edited == null) return;

    await context.read<UserStateStore>().upsertTodoItem(edited);
    if (!mounted) return;

    setState(() {
      _selectedFilter = TodoFilter.all;
    });
  }

  Future<void> _toggleCompleted(String todoId) async {
    await context.read<UserStateStore>().setTodoCompleted(
          todoId: todoId,
          isCompleted: true,
        );
  }
}
