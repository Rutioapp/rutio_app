import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../stores/user_state_store.dart';
import 'package:rutio/constants/color_palette.dart';
import 'package:rutio/screens/habit_monthly/widgets/monthly_filter_bar.dart';
import 'package:rutio/screens/habit_stats_overview_screen.dart';
import 'package:rutio/screens/home/ui/header/home_stats_header.dart';
import 'package:rutio/screens/home_screen.dart' show HomeScreen;
import 'package:rutio/ui/behaviours/ios_feedback.dart';
import 'package:rutio/ui/foundations/ios_foundations.dart';
import 'package:rutio/widgets/app_view_drawer.dart';
import 'package:rutio/widgets/backgrounds/home_landscape_background.dart';
import 'habit_monthly_screen.dart';
import 'weekly/weekly_helpers.dart';
import 'weekly/widgets/week_navigator.dart';
import 'weekly/widgets/weekly_habit_list.dart';

class HabitWeeklyScreen extends StatefulWidget {
  const HabitWeeklyScreen({super.key});

  @override
  State<HabitWeeklyScreen> createState() => _HabitWeeklyScreenState();
}

class _HabitWeeklyScreenState extends State<HabitWeeklyScreen>
    with SingleTickerProviderStateMixin {
  DateTime _weekStart = AppDateUtils.startOfWeek(DateTime.now());
  late final AnimationController _navigationController;
  static const _emptyRoot = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _navigationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _navigationController.dispose();
    super.dispose();
  }

  // IOS-FIRST IMPROVEMENT START
  String _rangeLabelForDays(BuildContext context, List<DateTime> days) {
    final localizations = MaterialLocalizations.of(context);
    final start = localizations.formatShortMonthDay(days.first);
    final end = localizations.formatShortMonthDay(days.last);
    return '$start - $end';
  }
  // IOS-FIRST IMPROVEMENT END

  int get _weekNumber {
    final startOfYear = DateTime(_weekStart.year, 1, 1);
    final diff = _weekStart.difference(startOfYear).inDays;
    return (diff ~/ 7) + 1;
  }

  void _navigateToWeek(int weekOffset) {
    IosFeedback.selection();
    _navigationController.forward(from: 0.0);
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * weekOffset));
    });
  }

  void _replaceWith(Widget screen) {
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _replaceNamed(String routeName) async {
    try {
      Navigator.of(context).pushReplacementNamed(routeName);
    } catch (_) {
      _showSnackBar(context.l10n.weeklyScreenUnavailableSoon);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserStateStore>();
    final root = store.state ?? _emptyRoot;
    final isLoading = store.isLoading || store.state == null;
    final daysOfWeek =
        List<DateTime>.generate(7, (i) => _weekStart.add(Duration(days: i)));

    final userState = DataHelpers.toMap(root['userState']);
    final activeHabits = DataHelpers.toListMap(userState['activeHabits']);
    final history = DataHelpers.toMap(userState['history']);
    final habitCompletions = DataHelpers.toMap(
      DataHelpers.toMap(history['habitCompletions']),
    );
    final habitSkips = DataHelpers.toMap(
      DataHelpers.toMap(history['habitSkips']),
    );
    final habitCountValues = DataHelpers.toMap(
      DataHelpers.toMap(history['habitCountValues']),
    );

    final xpTotal =
        _readInt(root, ['userState', 'progression', 'xp'], fallback: 0);
    final level = _readInt(
      root,
      ['userState', 'progression', 'level'],
      fallback: 1 + (xpTotal ~/ 100),
    );
    final xpInLevel = xpTotal % 100;
    final xpToNext = 100 - xpInLevel;
    final coins = _readInt(root, ['userState', 'wallet', 'coins'], fallback: 0);
    final display = (store.displayName ?? '').trim();
    final fallbackName = _readString(
      root,
      ['userState', 'profile', 'displayName'],
      fallback: context.l10n.homeFallbackUsername,
    );
    final name = display.isNotEmpty ? display : fallbackName;

    final body = isLoading
        ? const _WeeklyStatusScaffold(
            child: CupertinoActivityIndicator(radius: 16),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  IosSpacing.lg,
                  IosSpacing.xs,
                  IosSpacing.lg,
                  IosSpacing.sm,
                ),
                child: _WeeklyHeroHeader(
                  statsHeader: Builder(
                    builder: (headerContext) => HomeStatsHeader(
                      username: name,
                      level: level,
                      xp: xpInLevel,
                      xpToNext: xpToNext,
                      coins: coins,
                      avatarUrl: store.avatarUrl,
                      onOpenMonthlyOverview: () => _replaceWith(
                        const HabitMonthlyScreen(
                          initialMode: MonthlyFilterMode.all,
                        ),
                      ),
                      onTapDrawer: () =>
                          Scaffold.maybeOf(headerContext)?.openDrawer(),
                      cardBg: ColorPalette.cardBg,
                      primary: ColorPalette.primary,
                      primaryDark: ColorPalette.primaryDark,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  IosSpacing.lg,
                  0,
                  IosSpacing.lg,
                  IosSpacing.sm,
                ),
                child: WeekNavigator(
                  weekNumber: _weekNumber,
                  rangeLabel: _rangeLabelForDays(context, daysOfWeek),
                  onPreviousWeek: () => _navigateToWeek(-1),
                  onNextWeek: () => _navigateToWeek(1),
                  animation: _navigationController,
                ),
              ),
              Expanded(
                child: ClipRect(
                  // IOS-FIRST IMPROVEMENT START
                  child: WeeklyHabitList(
                    habits: activeHabits,
                    days: daysOfWeek,
                    habitCompletions: habitCompletions,
                    habitSkips: habitSkips,
                    habitCountValues: habitCountValues,
                    userState: userState,
                    root: root,
                    onOpenDailyView: () => _replaceWith(const HomeScreen()),
                  ),
                  // IOS-FIRST IMPROVEMENT END
                ),
              ),
            ],
          );

    return Stack(
      children: [
        const HomeBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          drawer: AppViewDrawer(
            selected: 'weekly',
            onGoDaily: () => _replaceWith(const HomeScreen()),
            onGoWeekly: () {},
            onGoMonthly: () => _replaceWith(
              const HabitMonthlyScreen(initialMode: MonthlyFilterMode.all),
            ),
            onGoTodo: () => Navigator.pushNamed(context, '/todo'),
            onGoDiary: () => _replaceNamedAny(const ['/diary']),
            onGoArchived: () => _replaceNamedAny(const ['/archived']),
            onGoStats: () => _replaceWith(const HabitStatsOverviewHost()),
            onGoShop: () => _replaceNamed('/shop'),
            onGoProfile: () => _replaceNamed('/profile'),
          ),
          body: SafeArea(
            bottom: false,
            child: body,
          ),
        ),
      ],
    );
  }

  Future<void> _replaceNamedAny(List<String> routeNames) async {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }

    for (final name in routeNames) {
      try {
        await Navigator.of(context).pushReplacementNamed(name);
        return;
      } catch (_) {}
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.weeklyScreenUnavailable)),
    );
  }
}

// IOS-FIRST IMPROVEMENT START
class _WeeklyHeroHeader extends StatelessWidget {
  final Widget statsHeader;

  const _WeeklyHeroHeader({
    required this.statsHeader,
  });

  @override
  Widget build(BuildContext context) {
    // IOS-FIRST IMPROVEMENT START
    return statsHeader;
    // IOS-FIRST IMPROVEMENT END
  }
}

class _WeeklyStatusScaffold extends StatelessWidget {
  final Widget child;

  const _WeeklyStatusScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: IosSpacing.lg),
        child: IosFrostedCard(
          elevated: true,
          child: child,
        ),
      ),
    );
  }
}
// IOS-FIRST IMPROVEMENT END

dynamic _readPath(dynamic root, List<String> path) {
  dynamic cur = root;
  for (final key in path) {
    if (cur is Map) {
      cur = cur[key];
    } else {
      return null;
    }
  }
  return cur;
}

int _readInt(Map<String, dynamic> root, List<String> path, {int fallback = 0}) {
  final v = _readPath(root, path);
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String _readString(
  Map<String, dynamic> root,
  List<String> path, {
  String fallback = '',
}) {
  final v = _readPath(root, path);
  final s = v?.toString().trim() ?? '';
  return s.isEmpty ? fallback : s;
}
