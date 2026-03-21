import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../stores/user_state_store.dart';

import '../widgets/stats/stats_period_tabs.dart';
import '../widgets/stats/streak_hero_card.dart';
import '../widgets/stats/stats_metrics_grid.dart';
import '../widgets/stats/stats_weekly_bar_chart_card.dart';
import '../widgets/stats/stats_month_heatmap.dart';
import '../widgets/stats/weekly_comparison_card.dart';
import '../widgets/stats/stats_best_time_of_day_card.dart';
import '../widgets/stats/stats_motivational_tip_card.dart';

import 'package:rutio/widgets/app_header/app_header.dart';
import 'package:rutio/widgets/app_view_drawer.dart';
import 'package:rutio/widgets/backgrounds/home_landscape_background.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:rutio/screens/habit_weekly_screen.dart';
import 'package:rutio/screens/habit_archived_screen.dart';
import 'package:rutio/screens/diary/diary_screen.dart';
import 'package:rutio/screens/shop_screen.dart';
import 'package:rutio/screens/profile/profile_screen.dart';
import 'package:rutio/screens/habit_monthly_screen.dart';

void _navReplace(BuildContext context, Widget screen) {
  final st = Scaffold.maybeOf(context);
  if (st != null && st.isDrawerOpen) {
    Navigator.of(context).pop(); // close drawer
  }
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => screen),
  );
}

/// Host sin parámetros para poder navegar desde el Drawer.
/// Lee los hábitos desde UserStateStore y delega en HabitStatsOverviewScreen.
class HabitStatsOverviewHost extends StatelessWidget {
  const HabitStatsOverviewHost({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserStateStore>();
    final habits = store.activeHabits; // ✅ fuente correcta
    return HabitStatsOverviewScreen(habits: habits);
  }
}

/// Pantalla global de estadísticas
/// - Selector de período (tabs)
/// - Selector de hábito (dropdown)
/// - Streak hero + grid métricas + bar chart
/// - Resto de stats (HabitStatsTab) integrado abajo (scroll unificado)
class HabitStatsOverviewScreen extends StatefulWidget {
  final List<dynamic> habits;

  /// Devuelve el color de la familia del hábito (si no lo pasas, usa un morado por defecto).
  final Color Function(dynamic habit)? familyColorResolver;

  /// Devuelve el título del hábito (si no lo pasas, intenta detectarlo con claves típicas).
  final String Function(dynamic habit)? titleResolver;

  /// Hábito seleccionado inicialmente (por id o por referencia)
  final dynamic initialHabit;

  const HabitStatsOverviewScreen({
    super.key,
    required this.habits,
    this.familyColorResolver,
    this.titleResolver,
    this.initialHabit,
  });

  @override
  State<HabitStatsOverviewScreen> createState() =>
      _HabitStatsOverviewScreenState();
}

class _HabitStatsOverviewScreenState extends State<HabitStatsOverviewScreen> {
  StatsPeriod _period = StatsPeriod.week;
  String? _selectedHabitId;

  @override
  void initState() {
    super.initState();
    final init = widget.initialHabit;
    _selectedHabitId = _habitId(init);
    _selectedHabitId ??=
        widget.habits.isNotEmpty ? _habitId(widget.habits.first) : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = context
        .watch<UserStateStore>(); // 🔁 se actualiza con cambios de estado
    final habits = widget.habits;

    // Drawer común (mismo comportamiento que el resto de pantallas)
    final drawer = AppViewDrawer(
      selected: 'stats',
      onGoDaily: () => _navReplace(context, const HomeScreen()),
      onGoWeekly: () => _navReplace(context, const HabitWeeklyScreen()),
      onGoMonthly: () => _navReplace(context, const HabitMonthlyScreen()),
      onGoTodo: () => Navigator.pushNamed(context, '/todo'),
      onGoDiary: () => _navReplace(context, const DiaryScreen()),
      onGoArchived: () => _navReplace(context, const ArchivedHabitsScreen()),
      onGoStats: () => _navReplace(context, const HabitStatsOverviewHost()),
      onGoShop: () => _navReplace(context, const ShopScreen()),
      onGoProfile: () => _navReplace(context, const ProfileScreen()),
    );

    if (habits.isEmpty) {
      return Stack(
        children: [
          const HomeBackground(),
          Scaffold(
            backgroundColor: Colors.transparent,
            drawer: drawer,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leadingWidth: AppDrawerAppBarLeading.leadingWidth,
              title: Text(l10n.habitStatsTitle),
              leading: Builder(
                builder: (ctx) => AppDrawerAppBarLeading(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            ),
            body: Center(child: Text(l10n.habitStatsEmpty)),
          ),
        ],
      );
    }

    // Selección robusta por id
    final selected = _findById(habits, _selectedHabitId) ?? habits.first;
    final selectedId = _habitId(selected) ?? '';
    final familyColor =
        (widget.familyColorResolver?.call(selected)) ?? const Color(0xFF6C5CE7);
    final title = _habitTitle(
      selected,
      resolver: widget.titleResolver,
      fallback: l10n.habitStatsHabitFallbackTitle,
    );

    final computed = _computeStats(
      store: store,
      habit: selected,
      habitId: selectedId,
      period: _period,
      weekdayLabelBuilder: (DateTime date) => l10n.weekdayLetter(date.weekday),
      weekShortBuilder: (int weekNumber) =>
          l10n.habitStatsWeekShort(weekNumber),
    );

    final weeklyPair =
        _weeklyDoneDaysPair(store: store, habit: selected, habitId: selectedId);
    final thisWeekDays = weeklyPair[0];
    final lastWeekDays = weeklyPair[1];

    // Mejor momento del día (para card de franjas + consejo motivacional)
    final timeOfDayPercents = _computeBestTimeOfDayPercents(
      store: store,
      habitId: selectedId,
      period: _period,
    );
    final bestTimeLabel = _bestTimeLabelFromPercents(timeOfDayPercents);

    // Acentos del grid (pedido)
    const green = Color(0xFF22C55E);
    const indigo = Color(0xFF4F46E5);
    const plum = Color(0xFF7C3AED);
    const terracotta = Color(0xFFB45309);

    final metrics = <StatsMetric>[
      StatsMetric(
        labelUpper: l10n.habitStatsMetricCompleted,
        value: '${computed.completionPct}%',
        description: l10n.habitStatsMetricCompletionDescription(
          computed.doneDays,
          computed.totalDays,
        ),
        icon: Icons.check_circle_rounded,
        accent: green,
      ),
      StatsMetric(
        labelUpper: l10n.habitStatsMetricConsistency,
        value: '${computed.consistencyPct}%',
        description: l10n.habitStatsMetricConsistencyDescription(
          computed.consistencyWindow,
        ),
        icon: Icons.auto_graph_rounded,
        accent: indigo,
      ),
      StatsMetric(
        labelUpper: l10n.habitStatsMetricBestStreak,
        value: '${computed.bestStreak}',
        description: l10n.habitStatsMetricPersonalBest,
        icon: Icons.emoji_events_rounded,
        accent: plum,
      ),
      StatsMetric(
        labelUpper: l10n.habitStatsMetricTotalDone,
        value: '${computed.totalDone}',
        description: l10n.habitStatsMetricHistoricRecords,
        icon: Icons.layers_rounded,
        accent: terracotta,
      ),
    ];

    final chart = StatsWeeklyBarChartCard(
      title: _period == StatsPeriod.week
          ? l10n.habitStatsChartWeekTitle
          : l10n.habitStatsChartLastFourWeeksTitle,
      subtitle: _period == StatsPeriod.week
          ? l10n.habitStatsChartWeekSubtitle
          : l10n.habitStatsChartWeeksSubtitle,
      points: computed.bars,
      accent: familyColor,
    );

    return Stack(
      children: [
        const HomeBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          drawer: drawer,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leadingWidth: AppDrawerAppBarLeading.leadingWidth,
            title: Text(l10n.habitStatsTitle),
            centerTitle: true,
            leading: Builder(
              builder: (ctx) => AppDrawerAppBarLeading(
                onTap: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              // 1) Period tabs
              StatsPeriodTabs(
                value: _period,
                onChanged: (p) => setState(() => _period = p),
              ),
              const SizedBox(height: 12),

              // 2) Selector hábito
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: familyColor.withValues(alpha: 0.25)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, color: familyColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedId,
                          icon: Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.black.withValues(alpha: 0.7)),
                          items: habits.map((h) {
                            final id = _habitId(h) ?? '';
                            final t = _habitTitle(
                              h,
                              resolver: widget.titleResolver,
                              fallback: l10n.habitStatsHabitFallbackTitle,
                            );
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(
                                t,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                            );
                          }).toList(),
                          onChanged: (id) =>
                              setState(() => _selectedHabitId = id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Título
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // 3) Streak hero
              StreakHeroCard(
                streakDays: computed.currentStreak,
                nextMilestoneDays: computed.nextMilestone,
                milestoneLabel: l10n.habitStatsNextMilestone,
              ),
              const SizedBox(height: 12),

              // 4) Grid 2x2 métricas
              StatsMetricsGrid(metrics: metrics),
              const SizedBox(height: 12),

              // 5) Bar chart
              chart,
              const SizedBox(height: 12),

              // 5.1) Comparación semanal
              WeeklyComparisonCard(
                thisWeekDays: thisWeekDays,
                lastWeekDays: lastWeekDays,
                accentColor: familyColor,
                title: l10n.habitStatsWeeklyComparisonTitle,
                subtitle: l10n.habitStatsWeeklyComparisonSubtitle,
              ),
              const SizedBox(height: 12),
// 5.5) Mejor momento del día (franja horaria)
              _StatsSectionCard(
                icon: Icons.schedule_rounded,
                iconBg: familyColor.withValues(alpha: 0.12),
                title: l10n.habitStatsBestTimeSectionTitle,
                subtitle: l10n.habitStatsBestTimeSectionSubtitle,
                child: StatsBestTimeOfDayCard(
                  accent: familyColor,
                  morningPct: timeOfDayPercents['morning'] ?? 0,
                  afternoonPct: timeOfDayPercents['afternoon'] ?? 0,
                  eveningPct: timeOfDayPercents['evening'] ?? 0,
                  nightPct: timeOfDayPercents['night'] ?? 0,
                ),
              ),
              const SizedBox(height: 12),

              // 6) Calendario del mes (solo pestaña Mes)
              if (_period == StatsPeriod.month) ...[
                _StatsSectionCard(
                  icon: Icons.calendar_month_rounded,
                  iconBg: familyColor.withValues(alpha: 0.12),
                  title: l10n.habitStatsMonthCalendarTitle,
                  child: StatsMonthHeatmap(
                    month:
                        DateTime(DateTime.now().year, DateTime.now().month, 1),
                    accent: familyColor,
                    intensityByDay: _monthIntensityByDay(
                      store: store,
                      habit: selected,
                      habitId: selectedId,
                      month: DateTime(
                          DateTime.now().year, DateTime.now().month, 1),
                    ),
                  ),
                ),
              ],

              // 7) Consejo motivacional (último widget)
              StatsMotivationalTipCard(
                habitTitle: title,
                streakDays: computed.currentStreak,
                thisWeekDoneDays: thisWeekDays,
                lastWeekDoneDays: lastWeekDays,
                bestTimeLabel: bestTimeLabel,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================
  // Data computation
  // =====================

  _ComputedStats _computeStats({
    required UserStateStore store,
    required dynamic habit,
    required String habitId,
    required StatsPeriod period,
    required String Function(DateTime date) weekdayLabelBuilder,
    required String Function(int weekNumber) weekShortBuilder,
  }) {
    final today = _dateOnly(DateTime.now());

    final range =
        _periodRange(period, today: today, store: store, habitId: habitId);
    final days = range.days;

    int scheduled = 0;
    int done = 0;

    // Valores (para chart y totals)
    final valuesByDay = <DateTime, int>{};

    for (final d in days) {
      if (!_isScheduledForDate(habit, d)) continue;
      scheduled++;

      final v = _doneValueForDay(
          store: store, habit: habit, habitId: habitId, date: d);
      valuesByDay[d] = v;
      if (v > 0) done++;
    }

    final completionPct =
        scheduled == 0 ? 0 : ((done / scheduled) * 100).round();

    // Consistencia: últimos 14 días
    const consistencyWindow = 14;
    final lastN = List.generate(
      consistencyWindow,
      (i) => today.subtract(Duration(days: (consistencyWindow - 1) - i)),
    );
    int scheduledN = 0;
    int doneN = 0;
    for (final d in lastN) {
      if (!_isScheduledForDate(habit, d)) continue;
      scheduledN++;
      final v = _doneValueForDay(
          store: store, habit: habit, habitId: habitId, date: d);
      if (v > 0) doneN++;
    }
    final consistencyPct =
        scheduledN == 0 ? 0 : ((doneN / scheduledN) * 100).round();

    // Streak actual y best streak (desde history, no solo rango)
    final allCounts = _extractCountsByDayFromStore(
        store: store, habit: habit, habitId: habitId);
    final currentStreak = _currentStreak(allCounts, today);
    final bestStreak = _bestStreak(allCounts);

    // TotalDone histórico
    final totalDone =
        allCounts.values.fold<int>(0, (a, b) => a + (b > 0 ? 1 : 0));

    // Next milestone
    final milestones = <int>[3, 7, 14, 21, 30, 45, 60, 90, 120, 180, 365];
    int nextMilestone = milestones.firstWhere(
      (m) => m > currentStreak,
      orElse: () => currentStreak + 30,
    );

    // Bars: week => 7 days, else => 4 weeks
    final bars = <StatsBarPoint>[];
    if (period == StatsPeriod.week) {
      final last7 =
          List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
      for (final d in last7) {
        final v = _doneValueForDay(
            store: store, habit: habit, habitId: habitId, date: d);
        bars.add(StatsBarPoint(
          label: weekdayLabelBuilder(d),
          value: v.toDouble(),
          isActive: _sameDate(d, today),
        ));
      }
    } else {
      // 4 semanas (cada una 7 días) terminando esta semana
      final start = today.subtract(const Duration(days: 27));
      for (int w = 0; w < 4; w++) {
        final ws = start.add(Duration(days: w * 7));
        final we = ws.add(const Duration(days: 6));
        double sum = 0;
        for (int i = 0; i < 7; i++) {
          final d = ws.add(Duration(days: i));
          final v = _doneValueForDay(
              store: store, habit: habit, habitId: habitId, date: d);
          sum += (v > 0 ? 1 : 0).toDouble();
        }
        bars.add(StatsBarPoint(
          label: weekShortBuilder(w + 1),
          value: sum,
          isActive: today.isAfter(ws.subtract(const Duration(days: 1))) &&
              today.isBefore(we.add(const Duration(days: 1))),
        ));
      }
    }

    return _ComputedStats(
      totalDays: scheduled,
      doneDays: done,
      completionPct: completionPct,
      consistencyPct: consistencyPct,
      consistencyWindow: consistencyWindow,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      totalDone: totalDone,
      nextMilestone: nextMilestone,
      bars: bars,
    );
  }

  Map<String, int> _computeBestTimeOfDayPercents({
    required UserStateStore store,
    required String habitId,
    required StatsPeriod period,
  }) {
    // Guardamos el acceso a mapas con null-safety total (store.state puede ser null).
    final rootMap = (store.state ?? <String, dynamic>{});

    final userState = (rootMap['userState'] is Map)
        ? Map<String, dynamic>.from(rootMap['userState'] as Map)
        : <String, dynamic>{};

    final history = (userState['history'] is Map)
        ? Map<String, dynamic>.from(userState['history'] as Map)
        : <String, dynamic>{};

    final timesRoot = (history['habitCompletionTimes'] is Map)
        ? Map<String, dynamic>.from(history['habitCompletionTimes'] as Map)
        : <String, dynamic>{};

    final range = _periodRange(period,
        today: DateTime.now(), store: store, habitId: habitId);

    int morning = 0, afternoon = 0, evening = 0, night = 0;
    int total = 0;

    for (final d in range.days) {
      final dayKey = _dateKey(d);
      final dayMapDyn = timesRoot[dayKey];
      if (dayMapDyn is! Map) continue;

      final dayMap = Map<String, dynamic>.from(dayMapDyn);
      final v = dayMap[habitId];
      if (v is! num) continue;

      final ms = v.toInt();
      if (ms <= 0) continue;

      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      final h = dt.hour;

      if (h >= 6 && h <= 11) {
        morning++;
      } else if (h >= 12 && h <= 17) {
        afternoon++;
      } else if (h >= 18 && h <= 23) {
        evening++;
      } else {
        night++;
      }
      total++;
    }

    int pct(int n) => total == 0 ? 0 : ((n * 100) / total).round();

    return {
      'morning': pct(morning),
      'afternoon': pct(afternoon),
      'evening': pct(evening),
      'night': pct(night),
      'total': total,
    };
  }

  String _bestTimeLabelFromPercents(Map<String, int> pcts) {
    // Elegimos el tramo con mayor porcentaje. En caso de empate, priorizamos evening.
    final entries = <String, int>{
      'morning': pcts['morning'] ?? 0,
      'afternoon': pcts['afternoon'] ?? 0,
      'evening': pcts['evening'] ?? 0,
      'night': pcts['night'] ?? 0,
    };

    final best = entries.entries.reduce((a, b) {
      if (b.value > a.value) return b;
      if (b.value < a.value) return a;
      if (a.key == 'evening') return a;
      if (b.key == 'evening') return b;
      return a;
    });

    return best.value <= 0 ? '' : best.key;
  }

  _PeriodRange _periodRange(StatsPeriod period,
      {required DateTime today,
      required UserStateStore store,
      required String habitId}) {
    switch (period) {
      case StatsPeriod.week:
        return _PeriodRange.lastDays(today, 7);
      case StatsPeriod.month:
        return _PeriodRange.lastDays(today, 30);
      case StatsPeriod.threeMonths:
        return _PeriodRange.lastDays(today, 90);
      case StatsPeriod.all:
        final min = _minDateForHabit(store: store, habitId: habitId) ??
            today.subtract(const Duration(days: 365));
        return _PeriodRange(min, today);
    }
  }

  DateTime? _minDateForHabit(
      {required UserStateStore store, required String habitId}) {
    final root = store.state;
    if (root is! Map) return null;
    final rootMap = Map<String, dynamic>.from(root as Map);
    final userState = (rootMap['userState'] is Map)
        ? Map<String, dynamic>.from(rootMap['userState'] as Map)
        : null;
    if (userState == null) return null;
    final history = (userState['history'] is Map)
        ? Map<String, dynamic>.from(userState['history'] as Map)
        : null;
    if (history == null) return null;

    final completions = history['habitCompletions'];
    if (completions is! Map) return null;

    DateTime? min;
    for (final k in completions.keys) {
      final dayKey = k.toString();
      final dayMap = completions[dayKey];
      if (dayMap is! Map) continue;
      if (dayMap[habitId] == true) {
        final d = _parseDateKey(dayKey);
        if (d == null) continue;
        if (min == null || d.isBefore(min)) min = d;
      }
    }
    return min;
  }

  Map<DateTime, int> _extractCountsByDayFromStore({
    required UserStateStore store,
    required dynamic habit,
    required String habitId,
  }) {
    final out = <DateTime, int>{};
    final root = store.state;
    if (root is! Map) return out;

    final rootMap = Map<String, dynamic>.from(root as Map);

    final Map<String, dynamic>? userState = (rootMap['userState'] is Map)
        ? Map<String, dynamic>.from(rootMap['userState'] as Map)
        : null;
    final Map<String, dynamic>? history = (userState?['history'] is Map)
        ? Map<String, dynamic>.from(userState?['history'] as Map)
        : null;

    final Map<String, dynamic> completions =
        (history?['habitCompletions'] is Map)
            ? Map<String, dynamic>.from(history?['habitCompletions'] as Map)
            : <String, dynamic>{};
    final Map<String, dynamic> countValues =
        (history?['habitCountValues'] is Map)
            ? Map<String, dynamic>.from(history?['habitCountValues'] as Map)
            : <String, dynamic>{};

    // Recorremos días con registros (completions + countValues)
    final keys = <String>{};
    for (final k in completions.keys) {
      keys.add(k.toString());
    }
    for (final k in countValues.keys) {
      keys.add(k.toString());
    }

    for (final dayKey in keys) {
      final d = _parseDateKey(dayKey);
      if (d == null) continue;
      if (!_isScheduledForDate(habit, d)) continue;

      final v = _doneValueForDay(
          store: store, habit: habit, habitId: habitId, date: d);
      out[_dateOnly(d)] = v;
    }

    return out;
  }

  int _doneValueForDay({
    required UserStateStore store,
    required dynamic habit,
    required String habitId,
    required DateTime date,
  }) {
    final root = store.state;
    if (root is! Map) return 0;

    final rootMap = Map<String, dynamic>.from(root as Map);

    final Map<String, dynamic>? userState = (rootMap['userState'] is Map)
        ? Map<String, dynamic>.from(rootMap['userState'] as Map)
        : null;
    final Map<String, dynamic>? history = (userState?['history'] is Map)
        ? Map<String, dynamic>.from(userState?['history'] as Map)
        : null;

    final Map<String, dynamic> completions =
        (history?['habitCompletions'] is Map)
            ? Map<String, dynamic>.from(history?['habitCompletions'] as Map)
            : <String, dynamic>{};
    final Map<String, dynamic> countValues =
        (history?['habitCountValues'] is Map)
            ? Map<String, dynamic>.from(history?['habitCountValues'] as Map)
            : <String, dynamic>{};

    final dayKey = _dateKey(date);

    final Map<String, dynamic> dayDoneMap = (completions[dayKey] is Map)
        ? Map<String, dynamic>.from(completions[dayKey] as Map)
        : <String, dynamic>{};
    final Map<String, dynamic> dayValsMap = (countValues[dayKey] is Map)
        ? Map<String, dynamic>.from(countValues[dayKey] as Map)
        : <String, dynamic>{};

    final type = _habitType(habit);
    if (type == 'count') {
      final v = (dayValsMap[habitId] as num?)?.toInt() ?? 0;
      final target = _habitTarget(habit);
      // Para estadísticas: barra basada en progreso (cap al target)
      return v.clamp(0, target);
    }

    final done = (dayDoneMap[habitId] == true);
    return done ? 1 : 0;
  }

  // =====================
  // Streak helpers
  // =====================

  int _currentStreak(Map<DateTime, int> countsByDay, DateTime today) {
    int streak = 0;
    DateTime d = _dateOnly(today);

    while (true) {
      final v = countsByDay[d] ?? 0;
      if (v > 0) {
        streak++;
        d = d.subtract(const Duration(days: 1));
        continue;
      }
      break;
    }
    return streak;
  }

  int _bestStreak(Map<DateTime, int> countsByDay) {
    if (countsByDay.isEmpty) return 0;

    final days = countsByDay.keys.toList()..sort();
    int best = 0;
    int current = 0;
    DateTime? prev;

    for (final d in days) {
      final v = countsByDay[d] ?? 0;
      if (v <= 0) {
        current = 0;
        prev = d;
        continue;
      }

      if (prev == null) {
        current = 1;
      } else {
        final diff = d.difference(prev).inDays;
        if (diff == 1) {
          current += 1;
        } else {
          current = 1;
        }
      }
      if (current > best) best = current;
      prev = d;
    }
    return best;
  }

  // =====================
  // Habit helpers
  // =====================

  static String? _habitId(dynamic habit) {
    if (habit == null) return null;
    if (habit is Map) {
      final v = habit['id'] ?? habit['habitId'];
      if (v != null) return v.toString();
    }
    try {
      // ignore: avoid_dynamic_calls
      final d = habit as dynamic;
      // ignore: avoid_dynamic_calls
      final v = d.id ?? d.habitId;
      if (v != null) return v.toString();
    } catch (_) {}
    return null;
  }

  dynamic _findById(List<dynamic> habits, String? id) {
    if (id == null || id.isEmpty) return null;
    for (final h in habits) {
      if (_habitId(h) == id) return h;
    }
    return null;
  }

  static String _habitType(dynamic habit) {
    if (habit is Map) return (habit['type'] ?? 'check').toString();
    try {
      // ignore: avoid_dynamic_calls
      final d = habit as dynamic;
      // ignore: avoid_dynamic_calls
      return (d.type ?? 'check').toString();
    } catch (_) {}
    return 'check';
  }

  static int _habitTarget(dynamic habit) {
    if (habit is Map) return ((habit['target'] as num?) ?? 1).toInt();
    try {
      // ignore: avoid_dynamic_calls
      final d = habit as dynamic;
      // ignore: avoid_dynamic_calls
      return ((d.target as num?) ?? 1).toInt();
    } catch (_) {}
    return 1;
  }

  static bool _isScheduledForDate(dynamic habit, DateTime date) {
    // schedule:
    //  - { type: "daily" }
    //  - { type: "once", date: "YYYY-MM-DD" }
    //  - { type: "weekly", weekdays: [1..7] }  // Mon=1..Sun=7
    Map<String, dynamic> schedule = const {};
    if (habit is Map) {
      final s = habit['schedule'];
      if (s is Map) schedule = Map<String, dynamic>.from(s);
    } else {
      try {
        // ignore: avoid_dynamic_calls
        final d = habit as dynamic;
        // ignore: avoid_dynamic_calls
        final s = d.schedule;
        if (s is Map) schedule = Map<String, dynamic>.from(s);
      } catch (_) {}
    }

    final type = (schedule['type'] ?? 'daily').toString();
    if (type == 'daily') return true;

    if (type == 'once') {
      final key = (schedule['date'] ?? '').toString();
      return key == _dateKey(date);
    }

    if (type == 'weekly') {
      final w = schedule['weekdays'];
      if (w is List) {
        final weekdays =
            w.map((e) => (e as num?)?.toInt()).whereType<int>().toSet();
        return weekdays.contains(date.weekday);
      }
      return true; // fallback
    }

    return true;
  }

  static String _habitTitle(dynamic habit,
      {String Function(dynamic h)? resolver, required String fallback}) {
    if (resolver != null) return resolver(habit);

    if (habit is Map) {
      final v = habit['title'] ??
          habit['name'] ??
          habit['habitName'] ??
          habit['label'];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }

    try {
      // ignore: avoid_dynamic_calls
      final d = habit as dynamic;
      // ignore: avoid_dynamic_calls
      final v = d.title ?? d.name ?? d.habitName ?? d.label;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}

    return fallback;
  }

  // =====================
  // Date helpers
  // =====================

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parseDateKey(String key) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
    if (m == null) return null;
    final y = int.tryParse(m.group(1)!) ?? 0;
    final mo = int.tryParse(m.group(2)!) ?? 1;
    final da = int.tryParse(m.group(3)!) ?? 1;
    return DateTime(y, mo, da);
  }

  // ===============================
  // HEATMAP HELPERS
  // ===============================

  Map<int, double> _monthIntensityByDay({
    required UserStateStore store,
    required dynamic habit,
    required String habitId,
    required DateTime month,
  }) {
    final out = <int, double>{};
    final daysInMonth = _daysInMonth(month);
    final type = _habitType(habit);
    final target = _habitTarget(habit);

    for (int day = 1; day <= daysInMonth; day++) {
      final d = _dateOnly(DateTime(month.year, month.month, day));

      if (!_isScheduledForDate(habit, d)) {
        out[day] = 0.0;
        continue;
      }

      final v = _doneValueForDay(
        store: store,
        habit: habit,
        habitId: habitId,
        date: d,
      );

      if (type == 'count') {
        final denom = target <= 0 ? 1 : target;
        out[day] = (v / denom).clamp(0.0, 1.0);
      } else {
        out[day] = v > 0 ? 1.0 : 0.0;
      }
    }

    return out;
  }

  int _daysInMonth(DateTime d) {
    final firstNextMonth = DateTime(d.year, d.month + 1, 1);
    final lastThisMonth = firstNextMonth.subtract(const Duration(days: 1));
    return lastThisMonth.day;
  }

  /// Returns [thisWeekDoneDays, lastWeekDoneDays] for the given habit.
  ///
  /// Uses the SAME completion logic as the rest of this screen:
  /// `_doneValueForDay(...) > 0` (so it works for check + count habits).
  /// Counts only scheduled days for the habit.
  List<int> _weeklyDoneDaysPair({
    required UserStateStore store,
    required dynamic habit,
    required String habitId,
  }) {
    final today = _dateOnly(DateTime.now());

    int countDoneInRange(DateTime startInclusive, DateTime endInclusive) {
      int c = 0;
      for (DateTime d = startInclusive;
          !d.isAfter(endInclusive);
          d = d.add(const Duration(days: 1))) {
        // Only count days where the habit is scheduled
        if (!_isScheduledForDate(habit, d)) continue;

        final v = _doneValueForDay(
          store: store,
          habit: habit,
          habitId: habitId,
          date: d,
        );
        if (v > 0) c++;
      }
      return c;
    }

    // Define "this week" as last 7 days including today (same as your weekly chart)
    final thisWeekStart = today.subtract(const Duration(days: 6));
    final thisWeekEnd = today;

    final lastWeekStart = today.subtract(const Duration(days: 13));
    final lastWeekEnd = today.subtract(const Duration(days: 7));

    final thisWeekDone = countDoneInRange(thisWeekStart, thisWeekEnd);
    final lastWeekDone = countDoneInRange(lastWeekStart, lastWeekEnd);

    return <int>[thisWeekDone, lastWeekDone];
  }
}

class _StatsSectionCard extends StatelessWidget {
  const _StatsSectionCard({
    required this.icon,
    required this.iconBg,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 6),
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    size: 18, color: Colors.black.withValues(alpha: 0.75)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PeriodRange {
  final DateTime start;
  final DateTime end; // inclusive

  _PeriodRange(this.start, this.end);

  factory _PeriodRange.lastDays(DateTime end, int n) {
    final e = DateTime(end.year, end.month, end.day);
    final s = e.subtract(Duration(days: n - 1));
    return _PeriodRange(s, e);
  }

  List<DateTime> get days {
    final out = <DateTime>[];
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    for (int i = 0; i <= e.difference(s).inDays; i++) {
      out.add(s.add(Duration(days: i)));
    }
    return out;
  }
}

class _ComputedStats {
  final int totalDays;
  final int doneDays;
  final int completionPct;

  final int consistencyPct;
  final int consistencyWindow;

  final int currentStreak;
  final int bestStreak;

  final int totalDone;

  final int nextMilestone;

  final List<StatsBarPoint> bars;

  const _ComputedStats({
    required this.totalDays,
    required this.doneDays,
    required this.completionPct,
    required this.consistencyPct,
    required this.consistencyWindow,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalDone,
    required this.nextMilestone,
    required this.bars,
  });
}
