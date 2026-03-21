import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rutio/constants/color_palette.dart';

import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/ui/foundations/ios_foundations.dart';
import 'package:rutio/utils/family_theme.dart';
import 'package:rutio/widgets/app_view_drawer.dart';
import 'package:rutio/widgets/backgrounds/home_landscape_background.dart';

import 'package:rutio/screens/home/ui/header/home_stats_header.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:rutio/screens/habit_weekly_screen.dart';
import 'package:rutio/screens/diary/diary_screen.dart';
import 'package:rutio/screens/habit_archived_screen.dart';
import 'package:rutio/screens/habit_stats_overview_screen.dart';
import 'package:rutio/screens/shop_screen.dart';
import 'package:rutio/screens/profile/profile_screen.dart';

import 'package:rutio/screens/habit_monthly/utils/month_utils.dart';
import 'package:rutio/screens/habit_monthly/utils/monthly_state_utils.dart';
import 'package:rutio/screens/habit_monthly/widgets/monthly_filter_bar.dart';
import 'package:rutio/screens/habit_monthly/widgets/monthly_title_section.dart';
import 'package:rutio/screens/habit_monthly/widgets/monthly_stats_row.dart';
import 'package:rutio/screens/habit_monthly/widgets/monthly_habit_selector.dart';
import 'package:rutio/screens/habit_monthly/widgets/monthly_calendar_card.dart';

void _navReplace(BuildContext context, Widget screen) {
  final st = Scaffold.maybeOf(context);
  if (st != null && st.isDrawerOpen) {
    Navigator.of(context).pop();
  }
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => screen),
  );
}

class HabitMonthlyScreen extends StatefulWidget {
  const HabitMonthlyScreen({
    super.key,
    this.initialMode = MonthlyFilterMode.all,
    this.initialFamilyId,
    this.initialHabitId,
    this.habitId,
    this.habitTitle,
    this.habitEmoji,
  });

  final MonthlyFilterMode initialMode;
  final String? initialFamilyId;
  final String? initialHabitId;
  final String? habitId;
  final String? habitTitle;
  final String? habitEmoji;

  @override
  State<HabitMonthlyScreen> createState() => _HabitMonthlyScreenState();
}

class _HabitMonthlyScreenState extends State<HabitMonthlyScreen> {
  DateTime _monthCursor =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  String? _selectedHabitId;

  @override
  void initState() {
    super.initState();
    _selectedHabitId = widget.habitId ?? widget.initialHabitId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = context.watch<UserStateStore>();
    final root = store.state;

    if (store.isLoading || root == null) {
      return const Stack(
        children: [
          HomeBackground(),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    final rootMap = _map(root);
    final userState = _map(rootMap['userState']);
    final profile = _map(userState['profile']);
    final activeHabits = _listMap(userState['activeHabits']);

    final visibleHabits = activeHabits.where((h) {
      final archived = h['archived'] == true || h['isArchived'] == true;
      return !archived;
    }).toList(growable: false);

    final history = _map(userState['history']);
    final habitCompletions = _map(history['habitCompletions']);
    final habitCountValues = _map(history['habitCountValues']);
    final habitSkips = _map(history['habitSkips']);

    final progression = _map(userState['progression']);
    final wallet = _map(userState['wallet']);

    final xpTotal = ((progression['xp'] as num?) ?? 0).toInt();
    final level =
        ((progression['level'] as num?) ?? (1 + (xpTotal ~/ 100))).toInt();
    final xpInLevel = xpTotal % 100;
    final xpToNext = 100 - xpInLevel;
    final coins = ((wallet['coins'] as num?) ?? 0).toInt();

    final displayFromStore = (store.displayName ?? '').trim();
    final profileDisplay =
        (profile['displayName'] ?? profile['name'] ?? profile['username'] ?? '')
            .toString()
            .trim();
    final username = displayFromStore.isNotEmpty
        ? displayFromStore
        : (profileDisplay.isNotEmpty
            ? profileDisplay
            : l10n.monthlyDefaultUsername);

    final selectorHabits = visibleHabits;
    final selectedHabit = _resolveSelectedHabit(visibleHabits);

    final monthStats = selectedHabit == null
        ? const _MonthStats.empty()
        : _computeMonthStats(
            selectedHabit,
            _monthCursor,
            habitCompletions,
            habitCountValues,
            habitSkips,
          );

    final allHabitStats = selectedHabit == null
        ? const _HabitAllStats.empty()
        : _computeAllTimeStats(
            selectedHabit,
            habitCompletions,
            habitCountValues,
          );

    final selectedAccent = selectedHabit == null
        ? FamilyTheme.colorOf(FamilyTheme.fallbackId)
        : _habitColor(selectedHabit);

    final monthTitle = MonthUtils.monthLabel(context, _monthCursor);
    final monthSubtitle = _monthSubtitle(context, _monthCursor);

    return Stack(
      children: [
        const HomeBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          drawer: AppViewDrawer(
            selected: 'monthly',
            onGoDaily: () => _navReplace(context, const HomeScreen()),
            onGoWeekly: () => _navReplace(context, const HabitWeeklyScreen()),
            onGoMonthly: () => Navigator.of(context).pop(),
            onGoTodo: () => Navigator.pushNamed(context, '/todo'),
            onGoDiary: () => _navReplace(context, const DiaryScreen()),
            onGoArchived: () =>
                _navReplace(context, const ArchivedHabitsScreen()),
            onGoStats: () =>
                _navReplace(context, const HabitStatsOverviewHost()),
            onGoShop: () => _navReplace(context, const ShopScreen()),
            onGoProfile: () => _navReplace(context, const ProfileScreen()),
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // IOS-FIRST IMPROVEMENT START
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    IosSpacing.lg,
                    IosSpacing.xs,
                    IosSpacing.lg,
                    IosSpacing.sm,
                  ),
                  child: Builder(
                    builder: (ctx) => HomeStatsHeader(
                      username: username,
                      level: level,
                      xp: xpInLevel,
                      xpToNext: xpToNext,
                      coins: coins,
                      avatarUrl: store.avatarUrl,
                      onOpenMonthlyOverview: () =>
                          _navReplace(context, const ProfileScreen()),
                      onTapDrawer: () => Scaffold.of(ctx).openDrawer(),
                      cardBg: ColorPalette.cardBg,
                      primary: ColorPalette.primary,
                      primaryDark: ColorPalette.primaryDark,
                    ),
                  ),
                ),
                // IOS-FIRST IMPROVEMENT END
                Expanded(
                  child: ListView(
                    // IOS-FIRST IMPROVEMENT START
                    padding: const EdgeInsets.fromLTRB(
                      IosSpacing.lg,
                      IosSpacing.xs,
                      IosSpacing.lg,
                      120,
                    ),
                    // IOS-FIRST IMPROVEMENT END
                    children: [
                      MonthlyTitleSection(
                        title: monthTitle,
                        subtitle: monthSubtitle,
                        onPreviousMonth: () {
                          setState(() {
                            _monthCursor = DateTime(
                              _monthCursor.year,
                              _monthCursor.month - 1,
                              1,
                            );
                          });
                        },
                        onNextMonth: () {
                          setState(() {
                            _monthCursor = DateTime(
                              _monthCursor.year,
                              _monthCursor.month + 1,
                              1,
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      MonthlyStatsRow(
                        monthPercent: monthStats.percent,
                        currentStreak: allHabitStats.currentStreak,
                        habitsCount: selectorHabits.length,
                      ),
                      const SizedBox(height: 14),
                      MonthlyHabitSelector(
                        habits: selectorHabits,
                        selectedHabitId:
                            (selectedHabit?['id'] ?? '').toString(),
                        colorResolver: _habitColor,
                        onHabitSelected: (hid) {
                          setState(() {
                            _selectedHabitId = hid;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      if (selectedHabit == null)
                        _EmptyMonthlyCard(
                          message: l10n.monthlyEmptyFilteredMessage,
                        )
                      else
                        MonthlyCalendarCard(
                          monthCursor: _monthCursor,
                          habit: selectedHabit,
                          accentColor: selectedAccent,
                          habitCompletions: habitCompletions,
                          habitCountValues: habitCountValues,
                          habitSkips: habitSkips,
                          currentStreak: allHabitStats.currentStreak,
                          bestStreak: allHabitStats.bestStreak,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic>? _resolveSelectedHabit(
      List<Map<String, dynamic>> source) {
    if (source.isEmpty) return null;

    final preferredId = (_selectedHabitId ?? '').trim();
    if (preferredId.isNotEmpty) {
      for (final h in source) {
        if ((h['id'] ?? '').toString() == preferredId) {
          return h;
        }
      }
    }

    return source.first;
  }

  Color _habitColor(Map<String, dynamic> habit) {
    final familyId = (habit['familyId'] ?? '').toString();
    return FamilyTheme.colorOf(familyId);
  }

  _MonthStats _computeMonthStats(
    Map<String, dynamic> habit,
    DateTime month,
    Map<String, dynamic> habitCompletions,
    Map<String, dynamic> habitCountValues,
    Map<String, dynamic> habitSkips,
  ) {
    final habitId = (habit['id'] ?? '').toString();
    final habitType = (habit['type'] ?? 'check').toString();
    final target = ((habit['target'] as num?) ?? 1).toInt();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = MonthUtils.daysInMonth(month);

    final lastEvaluatedDay =
        (month.year == today.year && month.month == today.month)
            ? today.day
            : daysInMonth;

    if (lastEvaluatedDay <= 0) {
      return const _MonthStats.empty();
    }

    int scheduledDays = 0;
    int doneDays = 0;

    for (int day = 1; day <= lastEvaluatedDay; day++) {
      final date = DateTime(month.year, month.month, day);
      final dateKey = MonthUtils.dateKey(date);

      if (!MonthlyStateUtils.isScheduledForDate(
          habit, date, MonthUtils.dateKey)) {
        continue;
      }

      scheduledDays++;

      final doneMap = _map(habitCompletions[dateKey]);
      final valsMap = _map(habitCountValues[dateKey]);
      final skipsMap = _map(habitSkips[dateKey]);

      final skipped = skipsMap[habitId] == true;

      bool done;
      if (habitType == 'count') {
        final v = ((valsMap[habitId] as num?) ?? 0).toInt();
        done = !skipped && (v >= target || doneMap[habitId] == true);
      } else {
        done = !skipped && (doneMap[habitId] == true);
      }

      if (done) doneDays++;
    }

    final percent =
        scheduledDays == 0 ? 0 : ((doneDays / scheduledDays) * 100).round();
    return _MonthStats(
        percent: percent, scheduledDays: scheduledDays, doneDays: doneDays);
  }

  _HabitAllStats _computeAllTimeStats(
    Map<String, dynamic> habit,
    Map<String, dynamic> habitCompletions,
    Map<String, dynamic> habitCountValues,
  ) {
    final habitId = (habit['id'] ?? '').toString();
    final habitType = (habit['type'] ?? 'check').toString();
    final target = ((habit['target'] as num?) ?? 1).toInt();

    final doneDays = <DateTime>{};

    final dateKeys = <String>{
      ...habitCompletions.keys.map((e) => e.toString()),
      ...habitCountValues.keys.map((e) => e.toString()),
    };

    for (final key in dateKeys) {
      final d = _parseDateKey(key);
      if (d == null) continue;
      if (!MonthlyStateUtils.isScheduledForDate(habit, d, MonthUtils.dateKey)) {
        continue;
      }

      final doneMap = _map(habitCompletions[key]);
      final valsMap = _map(habitCountValues[key]);

      bool done;
      if (habitType == 'count') {
        final v = ((valsMap[habitId] as num?) ?? 0).toInt();
        done = v >= target || doneMap[habitId] == true;
      } else {
        done = doneMap[habitId] == true;
      }

      if (done) {
        doneDays.add(DateTime(d.year, d.month, d.day));
      }
    }

    final sorted = doneDays.toList()..sort();
    if (sorted.isEmpty) {
      return const _HabitAllStats.empty();
    }

    int best = 0;
    int currentRun = 0;
    DateTime? prev;

    for (final d in sorted) {
      if (prev == null) {
        currentRun = 1;
      } else {
        currentRun = d.difference(prev).inDays == 1 ? currentRun + 1 : 1;
      }
      if (currentRun > best) best = currentRun;
      prev = d;
    }

    int currentStreak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    final doneSet = doneDays;

    while (doneSet.contains(cursor)) {
      currentStreak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return _HabitAllStats(currentStreak: currentStreak, bestStreak: best);
  }

  String _monthSubtitle(BuildContext context, DateTime month) {
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final elapsed = isCurrentMonth ? now.day : MonthUtils.daysInMonth(month);
    final anchorDay = DateTime(month.year, month.month, elapsed);
    final week = _weekNumber(anchorDay);
    return context.l10n.monthlyElapsedDaysWeek(elapsed, week);
  }

  int _weekNumber(DateTime d) {
    final startOfYear = DateTime(d.year, 1, 1);
    final diff =
        DateTime(d.year, d.month, d.day).difference(startOfYear).inDays;
    return (diff ~/ 7) + 1;
  }
}

class _EmptyMonthlyCard extends StatelessWidget {
  final String message;

  const _EmptyMonthlyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.black.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

class _MonthStats {
  final int percent;
  final int scheduledDays;
  final int doneDays;

  const _MonthStats({
    required this.percent,
    required this.scheduledDays,
    required this.doneDays,
  });

  const _MonthStats.empty()
      : percent = 0,
        scheduledDays = 0,
        doneDays = 0;
}

class _HabitAllStats {
  final int currentStreak;
  final int bestStreak;

  const _HabitAllStats({required this.currentStreak, required this.bestStreak});

  const _HabitAllStats.empty()
      : currentStreak = 0,
        bestStreak = 0;
}

Map<String, dynamic> _map(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _listMap(dynamic v) {
  if (v is List) {
    return v
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }
  return <Map<String, dynamic>>[];
}

DateTime? _parseDateKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}
