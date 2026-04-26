import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../stores/user_state_store.dart';

/// TAB: Estadísticas de un hábito - VERSIÓN MEJORADA
///
/// Mejoras visuales:
/// - Animaciones en métricas
/// - Gradientes sutiles
/// - Indicadores de progreso circular
/// - Badges de logros
/// - Tendencias y comparaciones
/// - Mini calendario mensual
class HabitStatsTab extends StatefulWidget {
  final dynamic habit;
  final Color familyColor;
  final bool scrollable;

  const HabitStatsTab({
    super.key,
    required this.habit,
    required this.familyColor,
    this.scrollable = true,
  });

  @override
  State<HabitStatsTab> createState() => _HabitStatsTabState();
}

class _HabitStatsTabState extends State<HabitStatsTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = _dateOnly(DateTime.now());
    // 1) Try to extract from the habit object itself (works when the habit
    //    contains its own completion history).
    // 2) If empty, fall back to the global store history (this is the common
    //    case when navigating from Weekly, where activeHabits are "light" and
    //    completions live under userState.history.habitCompletions).
    final countsByDay =
        _extractCountsByDayWithStoreFallback(context, widget.habit);

    final totalDone = countsByDay.values.fold<int>(0, (a, b) => a + b);
    final currentStreak = _currentStreak(countsByDay, today);
    final bestStreak = _bestStreak(countsByDay);

    final last30 =
        List.generate(30, (i) => today.subtract(Duration(days: 29 - i)));
    final doneDays30 =
        last30.where((d) => (countsByDay[_dateOnly(d)] ?? 0) > 0).length;
    final rate30 = doneDays30 / 30.0;

    // Semana anterior para comparación
    final prev7Start = today.subtract(const Duration(days: 13));
    // ignore: unused_local_variable
    final prev7End = today.subtract(const Duration(days: 7));
    final prev7Days =
        List.generate(7, (i) => prev7Start.add(Duration(days: i)));
    final donePrev7 =
        prev7Days.where((d) => (countsByDay[_dateOnly(d)] ?? 0) > 0).length;

    final last7 =
        List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final doneLast7 = last7.map((d) => countsByDay[_dateOnly(d)] ?? 0).toList();
    final doneThisWeek = doneLast7.where((c) => c > 0).length;
    final max7 = doneLast7.isEmpty
        ? 1
        : doneLast7.reduce((a, b) => a > b ? a : b).clamp(1, 999);

    final weekTrendIcon = doneThisWeek > donePrev7
        ? Icons.trending_up_rounded
        : doneThisWeek < donePrev7
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;

    final border = widget.familyColor.withValues(alpha: 0.20);
    final bg = widget.familyColor.withValues(alpha: 0.08);

    // Logros desbloqueados
    final achievements =
        _getAchievements(context, totalDone, currentStreak, bestStreak, rate30);

    final content = AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logros destacados
          if (achievements.isNotEmpty) ...[
            _AchievementsBanner(
              achievements: achievements,
              familyColor: widget.familyColor,
              scrollable: false,
            ),
            const SizedBox(height: 16),
          ],

          // Métricas principales
          _SectionCard(
            title: l10n.habitStatsTabSummaryTitle,
            icon: Icons.analytics_rounded,
            iconColor: widget.familyColor,
            border: border,
            bg: Colors.white,
            child: _MetricsGrid(
              familyColor: widget.familyColor,
              bg: bg,
              border: border,
              currentStreak: currentStreak,
              bestStreak: bestStreak,
              totalDone: totalDone,
              rate30: rate30,
              doneDays30: doneDays30,
              scrollable: false,
            ),
          ),

          const SizedBox(height: 16),

          // Gráfico de barras con tendencia
          _SectionCard(
            title: l10n.habitStatsTabLastDaysTitle(7),
            icon: Icons.bar_chart_rounded,
            iconColor: widget.familyColor,
            border: border,
            bg: Colors.white,
            child: _WeeklyBars(
              familyColor: widget.familyColor,
              today: today,
              days: last7,
              counts: doneLast7,
              maxCount: max7,
              weekTrendIcon: weekTrendIcon,
              doneThisWeek: doneThisWeek,
              donePrev7: donePrev7,
              hintText: _hintTextFromExtraction(context, widget.habit),
              scrollable: false,
            ),
          ),

          const SizedBox(height: 16),

          // Mini calendario mensual
          _SectionCard(
            title: l10n.habitStatsMonthCalendarTitle,
            icon: Icons.calendar_today_rounded,
            iconColor: widget.familyColor,
            border: border,
            bg: Colors.white,
            child: _MonthlyCalendar(
              familyColor: widget.familyColor,
              countsByDay: countsByDay,
              today: today,
              scrollable: false,
            ),
          ),
        ],
      ),
    );
    if (widget.scrollable) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: content,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: content,
    );
  }

  // Detectar logros
  List<Achievement> _getAchievements(
      BuildContext context, int total, int streak, int best, double rate) {
    final l10n = context.l10n;
    final achievements = <Achievement>[];

    if (streak >= 7) {
      achievements.add(Achievement(
        icon: 'ðŸ”¥',
        title: l10n.habitStatsTabFireStreakTitle,
        description: l10n.habitStatsTabStreakInARow(streak),
      ));
    }

    if (total >= 100) {
      achievements.add(Achievement(
        icon: 'ðŸ’¯',
        title: l10n.habitStatsTabCentennialTitle,
        description: l10n.habitStatsTabCompletedCount(total),
      ));
    } else if (total >= 50) {
      achievements.add(Achievement(
        icon: '⭐',
        title: l10n.habitStatsTabHalfCenturyTitle,
        description: l10n.habitStatsTabCompletedCount(total),
      ));
    }

    if (rate >= 0.9) {
      achievements.add(Achievement(
        icon: 'ðŸ†',
        title: l10n.habitStatsTabMaxConsistencyTitle,
        description: l10n.habitStatsTabLast30DaysPercent((rate * 100).round()),
      ));
    }

    if (best >= 30) {
      achievements.add(Achievement(
        icon: 'ðŸ‘‘',
        title: l10n.habitStatsTabLegendaryRecordTitle,
        description: l10n.habitStatsTabRecordStreak(best),
      ));
    }

    return achievements;
  }

  // ---------------- Stats logic (igual que antes) ----------------

  /// Extracts completion counts from the habit object.
  ///
  /// When navigating from the Weekly view, `activeHabits` are often "light"
  /// objects without embedded history. In that case, completion history lives
  /// in `userState.history.habitCompletions` inside [UserStateStore].
  ///
  /// This helper makes the tab work consistently regardless of entry point.
  static Map<DateTime, int> _extractCountsByDayWithStoreFallback(
    BuildContext context,
    dynamic habit,
  ) {
    final fromHabit = _extractCountsByDay(habit);
    if (fromHabit.isNotEmpty) return fromHabit;

    final habitId = _habitIdFromAny(habit);
    if (habitId == null || habitId.isEmpty) return fromHabit;

    try {
      final store = context.read<UserStateStore>();
      final root = _toMap(store.state);
      final userState = _toMap(root['userState']);
      final history = _toMap(userState['history']);

      // Common layout: history.habitCompletions[habitId] -> {"2026-02-09": 1, ...}
      final habitCompletions = _toMap(history['habitCompletions']);

      final out = <DateTime, int>{};
      void addDate(DateTime dt, [int inc = 1]) {
        final d = _dateOnly(dt);
        out[d] = (out[d] ?? 0) + inc;
      }

      // Case A: per-habit bucket
      dynamic perHabit =
          habitCompletions[habitId] ?? habitCompletions[habitId.toString()];
      if (perHabit != null) {
        _consumeAnyHistoryValue(perHabit, addDate);
        if (out.isNotEmpty) return out;
      }

      // Case B: by-day bucket: habitCompletions["YYYY-MM-DD"] -> {habitId: true/int}
      if (habitCompletions.isNotEmpty) {
        for (final entry in habitCompletions.entries) {
          final day = _tryParseDate(entry.key);
          if (day == null) continue;
          final v = entry.value;
          if (v is Map) {
            final map = Map<String, dynamic>.from(
                v.map((k, val) => MapEntry(k.toString(), val)));
            final vv = map[habitId] ?? map[habitId.toString()];
            if (vv == true) {
              addDate(day, 1);
            } else if (vv is int && vv > 0) {
              addDate(day, vv);
            } else if (vv is num && vv > 0) {
              addDate(day, vv.round());
            }
          }
        }
        if (out.isNotEmpty) return out;
      }

      // Case C: other possible keys
      for (final k in [
        'completions',
        'checkins',
        'checkIns',
        'records',
        'calendar'
      ]) {
        final v = history[k];
        if (v == null) continue;
        _consumeAnyHistoryValue(v, addDate);
        if (out.isNotEmpty) return out;
      }
    } catch (_) {
      // ignore and fall back
    }

    return fromHabit;
  }

  static String? _habitIdFromAny(dynamic h) {
    if (h == null) return null;
    if (h is Map) {
      final v = h['id'] ?? h['habitId'] ?? h['uuid'] ?? h['key'];
      return v?.toString();
    }
    try {
      final dyn = h as dynamic;
      final v = dyn.id ?? dyn.habitId ?? dyn.uuid ?? dyn.key;
      return v?.toString();
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _toMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  static int _currentStreak(Map<DateTime, int> countsByDay, DateTime today) {
    var streak = 0;
    var d = today;
    while ((countsByDay[_dateOnly(d)] ?? 0) > 0) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int _bestStreak(Map<DateTime, int> countsByDay) {
    final doneDays = countsByDay.keys.toList()..sort();
    var best = 0;
    var current = 0;

    DateTime? prev;
    for (final d in doneDays) {
      if ((countsByDay[d] ?? 0) <= 0) continue;

      if (prev == null) {
        current = 1;
      } else {
        final diff = d.difference(prev).inDays;
        current = (diff == 1) ? (current + 1) : 1;
      }
      if (current > best) best = current;
      prev = d;
    }
    return best;
  }

  static Map<DateTime, int> _extractCountsByDay(dynamic habit) {
    final out = <DateTime, int>{};

    void addDate(DateTime dt, [int inc = 1]) {
      final d = _dateOnly(dt);
      out[d] = (out[d] ?? 0) + inc;
    }

    final candidates = <dynamic>[];

    dynamic readKey(Map m, String k) => m.containsKey(k) ? m[k] : null;

    if (habit is Map) {
      const keys = [
        'history',
        'log',
        'doneDates',
        'completedDates',
        'completionDates',
        'checkins',
        'checkIns',
        'completions',
        'records',
        'calendar',
      ];
      for (final k in keys) {
        final v = readKey(habit, k);
        if (v != null) candidates.add(v);
      }
    } else {
      try {
        final m = (habit as dynamic).toJson?.call();
        if (m is Map) {
          const keys = [
            'history',
            'log',
            'doneDates',
            'completedDates',
            'completionDates',
            'checkins',
            'checkIns',
            'completions',
            'records',
            'calendar',
          ];
          for (final k in keys) {
            if (m[k] != null) candidates.add(m[k]);
          }
        }
      } catch (_) {}

      for (final prop in [
        'history',
        'log',
        'doneDates',
        'completedDates',
        'checkins',
        'completions',
        'records'
      ]) {
        final dyn = _readDynamicProp(habit, prop);
        if (dyn != null) candidates.add(dyn);
      }
    }

    for (final c in candidates) {
      _consumeAnyHistoryValue(c, addDate);
    }

    DateTime? lastDone;
    if (habit is Map) {
      lastDone = _tryParseDate(habit['lastDoneAt'] ?? habit['lastCompletedAt']);
    } else {
      lastDone = _tryParseDate(_readDynamicProp(habit, 'lastDoneAt') ??
          _readDynamicProp(habit, 'lastCompletedAt'));
    }
    if (lastDone != null) addDate(lastDone);

    return out;
  }

  static void _consumeAnyHistoryValue(
      dynamic value, void Function(DateTime dt, [int inc]) addDate) {
    if (value == null) return;

    if (value is List) {
      for (final e in value) {
        if (e is DateTime) {
          addDate(e);
        } else if (e is String || e is int || e is num) {
          final dt = _tryParseDate(e);
          if (dt != null) addDate(dt);
        } else if (e is Map) {
          final done = (e['done'] ?? e['completed'] ?? e['isDone']);
          if (done == false) continue;

          final count = (e['count'] is int) ? (e['count'] as int) : 1;
          final dt = _tryParseDate(e['date'] ??
              e['day'] ??
              e['ts'] ??
              e['time'] ??
              e['completedAt']);
          if (dt != null) addDate(dt, count);
        }
      }
      return;
    }

    if (value is Map) {
      value.forEach((k, v) {
        final dt = _tryParseDate(k);
        if (dt == null) return;

        if (v == true) addDate(dt, 1);
        if (v is int && v > 0) addDate(dt, v);
        if (v is num && v > 0) addDate(dt, v.round());
      });
      return;
    }

    if (value is DateTime) {
      addDate(value);
      return;
    }
    final dt = _tryParseDate(value);
    if (dt != null) addDate(dt);
  }

  static dynamic _readDynamicProp(dynamic obj, String prop) {
    try {
      final d = (obj as dynamic);
      switch (prop) {
        case 'history':
          return d.history;
        case 'log':
          return d.log;
        case 'doneDates':
          return d.doneDates;
        case 'completedDates':
          return d.completedDates;
        case 'checkins':
          return d.checkins;
        case 'completions':
          return d.completions;
        case 'records':
          return d.records;
        case 'lastDoneAt':
          return d.lastDoneAt;
        case 'lastCompletedAt':
          return d.lastCompletedAt;
      }
    } catch (_) {}
    return null;
  }

  static DateTime? _tryParseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;

    if (v is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(v);
      } catch (_) {}
      try {
        return DateTime.fromMillisecondsSinceEpoch(v * 1000);
      } catch (_) {}
      return null;
    }

    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {}
    }

    return null;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _hintTextFromExtraction(BuildContext context, dynamic habit) {
    if (habit is Map) {
      final type = habit['type'] ?? habit['habitType'] ?? '';
      if (type.toString().toLowerCase() == 'counter') {
        return context.l10n.habitStatsTabCounterHint;
      }
    }
    return context.l10n.habitStatsTabCheckHint;
  }
}

// ============================================================================
// WIDGETS MEJORADOS
// ============================================================================

class Achievement {
  final String icon;
  final String title;
  final String description;

  Achievement({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _AchievementsBanner extends StatelessWidget {
  final List<Achievement> achievements;
  final Color familyColor;
  final bool scrollable;

  const _AchievementsBanner({
    required this.achievements,
    required this.familyColor,
    required this.scrollable,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            familyColor.withValues(alpha: 0.15),
            familyColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: familyColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: familyColor, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.habitStatsTabAchievementsUnlocked,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: achievements
                .map((a) => _AchievementChip(
                      achievement: a,
                      color: familyColor,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  final Achievement achievement;
  final Color color;

  const _AchievementChip({
    required this.achievement,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            achievement.icon,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                achievement.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final Color familyColor;
  final bool scrollable;
  final Color bg;
  final Color border;
  final int currentStreak;
  final int bestStreak;
  final int totalDone;
  final double rate30;
  final int doneDays30;

  const _MetricsGrid({
    required this.familyColor,
    required this.bg,
    required this.border,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalDone,
    required this.rate30,
    required this.doneDays30,
    required this.scrollable,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        final cards = [
          _MetricCard(
            title: l10n.habitStatsTabCurrentStreakTitle,
            value: '$currentStreak',
            subtitle: l10n.habitStatsTabDayUnit(currentStreak),
            bg: bg,
            border: border,
            accent: familyColor,
            icon: Icons.local_fire_department_rounded,
            gradient: true,
          ),
          _MetricCard(
            title: l10n.habitStatsMetricBestStreak,
            value: '$bestStreak',
            subtitle: l10n.habitStatsMetricPersonalBest,
            bg: bg,
            border: border,
            accent: familyColor,
            icon: Icons.emoji_events_rounded,
          ),
          _MetricCard(
            title: l10n.habitStatsMetricCompleted,
            value: '$totalDone',
            subtitle: l10n.habitStatsTabTotalLabel,
            bg: bg,
            border: border,
            accent: familyColor,
            icon: Icons.check_circle_rounded,
          ),
          _MetricCardWithProgress(
            title: l10n.habitStatsTabLastDaysTitle(30),
            value: '${(rate30 * 100).round()}%',
            subtitle: l10n.habitStatsTabCompletionWindow(doneDays30, 30),
            progress: rate30,
            bg: bg,
            border: border,
            accent: familyColor,
            icon: Icons.calendar_month_rounded,
          ),
        ];

        if (!isWide) {
          return Column(
            children: [
              Row(children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1])
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 12),
                Expanded(child: cards[3])
              ]),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color bg;
  final Color border;
  final Color accent;
  final IconData icon;
  final bool gradient;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.bg,
    required this.border,
    required this.accent,
    required this.icon,
    this.gradient = false,
  });

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradient
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.bg,
                      widget.accent.withValues(alpha: 0.12),
                    ],
                  )
                : null,
            color: widget.gradient ? null : widget.bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: widget.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, size: 18, color: widget.accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: int.tryParse(widget.value) ?? 0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Text(
                    int.tryParse(widget.value) != null
                        ? '$value'
                        : widget.value,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: widget.gradient ? widget.accent : Colors.black,
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCardWithProgress extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final double progress;
  final Color bg;
  final Color border;
  final Color accent;
  final IconData icon;

  const _MetricCardWithProgress({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.progress,
    required this.bg,
    required this.border,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return SizedBox(
                    width: 50,
                    height: 50,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 4,
                            backgroundColor: accent.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation(accent),
                          ),
                        ),
                        Text(
                          '${(value * 100).round()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  final Color familyColor;
  final bool scrollable;
  final DateTime today;
  final List<DateTime> days;
  final List<int> counts;
  final int maxCount;
  final IconData weekTrendIcon;
  final int doneThisWeek;
  final int donePrev7;
  final String hintText;

  const _WeeklyBars({
    required this.familyColor,
    required this.today,
    required this.days,
    required this.counts,
    required this.maxCount,
    required this.weekTrendIcon,
    required this.doneThisWeek,
    required this.donePrev7,
    required this.hintText,
    required this.scrollable,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final comparison = doneThisWeek - donePrev7;
    final comparisonText = l10n.habitStatsTabWeeklyDelta(comparison);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                l10n.habitStatsChartWeekSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withValues(alpha: 0.70),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: familyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        weekTrendIcon,
                        size: 14,
                        color: familyColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          comparisonText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: familyColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Reservamos espacio para: número (arriba) + separaciones + etiqueta del día (abajo)
              const topAndBottom = 44.0;
              final maxBar =
                  math.max(0.0, constraints.maxHeight - topAndBottom);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(days.length, (i) {
                  final d = days[i];
                  final count = counts[i];
                  final isToday = _dateOnly(d) == today;
                  final h = maxCount <= 0 ? 0.0 : (count / maxCount) * maxBar;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            count == 0 ? '' : '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: familyColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: h),
                            duration: Duration(milliseconds: 400 + (i * 50)),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Container(
                                height: value,
                                decoration: BoxDecoration(
                                  gradient: count == 0
                                      ? null
                                      : LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            familyColor.withValues(alpha: 0.95),
                                            familyColor.withValues(alpha: 0.7),
                                          ],
                                        ),
                                  color: count == 0
                                      ? Colors.black.withValues(alpha: 0.08)
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: count > 0 && isToday
                                      ? [
                                          BoxShadow(
                                            color: familyColor.withValues(
                                                alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _dowShort(context, d),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  isToday ? FontWeight.w900 : FontWeight.w600,
                              color: isToday
                                  ? familyColor
                                  : Colors.black.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          hintText,
          style: TextStyle(
              fontSize: 11, color: Colors.black.withValues(alpha: 0.50)),
        ),
      ],
    );
  }
}

class _MonthlyCalendar extends StatelessWidget {
  final Color familyColor;
  final bool scrollable;
  final Map<DateTime, int> countsByDay;
  final DateTime today;

  const _MonthlyCalendar({
    required this.familyColor,
    required this.countsByDay,
    required this.today,
    required this.scrollable,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final firstDayOfMonth = DateTime(today.year, today.month, 1);
    final lastDayOfMonth = DateTime(today.year, today.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday;

    return Column(
      children: [
        // Header de días de la semana
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) => index + 1)
              .map((weekday) => SizedBox(
                    width: 32,
                    child: Text(
                      l10n.weekdayLetter(weekday),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // Grid de días
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: startWeekday - 1 + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startWeekday - 1) {
              return const SizedBox();
            }

            final day = index - (startWeekday - 2);
            final date = DateTime(today.year, today.month, day);
            final dateOnly = _dateOnly(date);
            final count = countsByDay[dateOnly] ?? 0;
            final isToday = dateOnly == _dateOnly(today);
            final isFuture = dateOnly.isAfter(today);

            return Container(
              decoration: BoxDecoration(
                color: isFuture
                    ? Colors.black.withValues(alpha: 0.03)
                    : count > 0
                        ? familyColor.withValues(alpha: 0.85)
                        : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border:
                    isToday ? Border.all(color: familyColor, width: 2) : null,
              ),
              alignment: Alignment.center,
              child: count > 0
                  ? Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 14,
                    )
                  : Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                        color: isFuture
                            ? Colors.black.withValues(alpha: 0.3)
                            : isToday
                                ? familyColor
                                : Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
            );
          },
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final Color border;
  final Color bg;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
    required this.border,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers (library-level)
// NOTE: Algunos widgets auxiliares (fuera de la clase State) necesitan estas
// funciones. Por eso están aquí a nivel de archivo.
// ─────────────────────────────────────────────────────────────────────────────
DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _dowShort(BuildContext context, DateTime d) {
  return context.l10n.weekdayShort(d.weekday);
}
