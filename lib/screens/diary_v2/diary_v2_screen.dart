import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/screens/diary/models/diary_types.dart';
import 'package:rutio/screens/diary/widgets/diary_screen_background.dart';
import 'package:rutio/screens/habit_archived_screen.dart';
import 'package:rutio/screens/habit_monthly_screen.dart';
import 'package:rutio/screens/habit_weekly_screen.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:rutio/screens/profile/profile_screen.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/widgets/app_view_drawer.dart';

import 'diary_v2_day_entries_screen.dart';
import 'diary_v2_entry_editor_screen.dart';
import 'widgets/diary_v2_explore_grid.dart';
import 'widgets/diary_v2_header.dart';
import 'widgets/diary_v2_month_preview_card.dart';
import 'widgets/diary_v2_stats_summary_card.dart';
import 'widgets/diary_v2_styles.dart';
import 'widgets/diary_v2_today_entry_card.dart';
import 'widgets/diary_v2_week_strip.dart';
import 'widgets/diary_v2_write_button.dart';

void _navReplace(BuildContext context, Widget screen) {
  final scaffold = Scaffold.maybeOf(context);
  if (scaffold != null && scaffold.isDrawerOpen) {
    Navigator.of(context).pop();
  }
  Navigator.of(context).pushReplacement(
    CupertinoPageRoute(builder: (_) => screen),
  );
}

class DiaryV2Screen extends StatefulWidget {
  const DiaryV2Screen({super.key});

  static const route = '/diary-v2';

  @override
  State<DiaryV2Screen> createState() => _DiaryV2ScreenState();
}

class _DiaryV2ScreenState extends State<DiaryV2Screen> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateUtils.dateOnly(DateTime.now());
  }

  void _openComposer(BuildContext context) {
    openDiaryV2EntryEditor(
      context,
      initialDate: _selectedDay,
    );
  }

  Future<void> _openSelectedDayEntries(
    BuildContext context,
    _DiaryV2ViewData viewData,
  ) async {
    final locale = Localizations.localeOf(context);
    final isSpanish = locale.languageCode == 'es';
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => DiaryV2DayEntriesScreen(
          title: isSpanish ? 'Entradas del d\u00eda' : 'Day entries',
          dateLabel: viewData.selectedDayLabel,
          entries: viewData.selectedDayEntries,
          onCreateEntry: () => _openComposer(context),
          createLabel: isSpanish ? 'Nueva entrada' : 'New entry',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserStateStore>();
    final locale = Localizations.localeOf(context);
    final localeTag = locale.toLanguageTag();
    final isSpanish = locale.languageCode == 'es';
    final viewData = _DiaryV2ViewData.fromEntries(
      entries: store.diaryEntries,
      selectedDay: _selectedDay,
      localeTag: localeTag,
    );
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final subtitle = isSpanish
        ? 'Tu espacio para recordar el d\u00eda.'
        : 'Your space to remember the day.';

    return Scaffold(
      drawer: AppViewDrawer(
        selected: 'diary',
        onGoDaily: () => _navReplace(context, const HomeScreen()),
        onGoWeekly: () => _navReplace(context, const HabitWeeklyScreen()),
        onGoMonthly: () => _navReplace(context, const HabitMonthlyScreen()),
        onGoTodo: () => Navigator.pushNamed(context, '/todo'),
        onGoDiary: () {},
        onGoDiaryV2: () => Navigator.of(context).pushReplacementNamed('/diary'),
        onGoArchived: () => _navReplace(context, const ArchivedHabitsScreen()),
        onGoStats: () => Navigator.pushNamed(context, '/stats'),
        onGoProfile: () => _navReplace(context, const ProfileScreen()),
      ),
      backgroundColor: Colors.transparent,
      body: DiaryScreenBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              ListView(
                padding: EdgeInsets.fromLTRB(14, 10, 14, bottomInset + 114),
                children: [
                  Builder(
                    builder: (ctx) => DiaryV2Header(
                      title: context.l10n.diaryTitle,
                      subtitle: subtitle,
                      onMenuTap: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DiaryV2WeekStrip(
                    days: viewData.weekDays,
                    onDaySelected: (day) {
                      setState(() => _selectedDay = day.date);
                    },
                  ),
                  const SizedBox(height: 18),
                  DiaryV2TodayEntryCard(
                    title: viewData.previewTitle,
                    dateLabel: viewData.selectedDayLabel,
                    excerpt: viewData.todayExcerpt,
                    emptyTitle: viewData.emptyStateTitle,
                    emptyBody: viewData.emptyStateBody,
                    selectedMood: viewData.selectedMood,
                    metadataLabels: viewData.metadataLabels,
                    isEmpty: viewData.selectedEntry == null,
                    extraEntriesLabel: viewData.extraEntriesLabel,
                    onViewAllTap: viewData.selectedDayEntries.length > 1
                        ? () => _openSelectedDayEntries(context, viewData)
                        : null,
                  ),
                  const SizedBox(height: 14),
                  DiaryV2StatsSummaryCard(items: viewData.stats),
                  const SizedBox(height: 18),
                  Text(
                    isSpanish ? 'Explora tu diario' : 'Explore your diary',
                    style: DiaryV2Styles.sectionTitle(context),
                  ),
                  const SizedBox(height: 12),
                  const DiaryV2ExploreGrid(items: _exploreItems),
                  const SizedBox(height: 14),
                  DiaryV2MonthPreviewCard(
                    title: isSpanish ? 'Tu mes' : 'Your month',
                    summary: viewData.monthSummary,
                    moodLabel: viewData.monthMoodLabel,
                    dominantMood: viewData.monthDominantMood,
                    dots: viewData.monthDots,
                  ),
                ],
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14 + bottomInset,
                child: DiaryV2WriteButton(
                  label: isSpanish ? 'Escribir ahora' : 'Write now',
                  onPressed: () => _openComposer(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiaryV2ViewData {
  const _DiaryV2ViewData({
    required this.weekDays,
    required this.selectedDayLabel,
    required this.previewTitle,
    required this.todayExcerpt,
    required this.emptyStateTitle,
    required this.emptyStateBody,
    required this.selectedEntry,
    required this.selectedMood,
    required this.stats,
    required this.monthSummary,
    required this.monthMoodLabel,
    required this.monthDominantMood,
    required this.monthDots,
    required this.metadataLabels,
    required this.selectedDayEntries,
    required this.extraEntriesLabel,
  });

  final List<DiaryV2WeekDay> weekDays;
  final String selectedDayLabel;
  final String previewTitle;
  final String todayExcerpt;
  final String emptyStateTitle;
  final String emptyStateBody;
  final DiaryEntryUi? selectedEntry;
  final int? selectedMood;
  final List<DiaryV2StatItem> stats;
  final String monthSummary;
  final String monthMoodLabel;
  final int? monthDominantMood;
  final List<DiaryV2MonthDot> monthDots;
  final List<String> metadataLabels;
  final List<DiaryV2DayEntryItem> selectedDayEntries;
  final String? extraEntriesLabel;

  static _DiaryV2ViewData fromEntries({
    required List<DiaryEntry> entries,
    required DateTime selectedDay,
    required String localeTag,
  }) {
    final normalizedSelectedDay = DateUtils.dateOnly(selectedDay);
    final uiEntries = entries.map(_toUi).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final selectedEntry = uiEntries
        .where(
          (entry) => DateUtils.isSameDay(entry.createdAt, normalizedSelectedDay),
        )
        .cast<DiaryEntryUi?>()
        .firstWhere((entry) => entry != null, orElse: () => null);
    final selectedDayEntries = entries
        .map(
          (entry) => DiaryV2DayEntryItem(
            ui: _toUi(entry),
            isPinned: entry.isPinned,
          ),
        )
        .where(
          (entry) => DateUtils.isSameDay(
            entry.ui.createdAt,
            normalizedSelectedDay,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => b.ui.createdAt.compareTo(a.ui.createdAt));

    final monthEntries = uiEntries
        .where(
          (entry) =>
              entry.createdAt.year == normalizedSelectedDay.year &&
              entry.createdAt.month == normalizedSelectedDay.month,
        )
        .toList(growable: false);

    final pinnedCount = entries.where((entry) => entry.isPinned).length;
    final monthlyEntryDays = monthEntries
        .map((entry) => DateUtils.dateOnly(entry.createdAt))
        .toSet()
        .length;
    final isSpanish = localeTag.startsWith('es');
    final previewText = _splitPreviewText(selectedEntry?.text ?? '');
    final fallbackTitle = isSpanish ? 'Entrada de hoy' : 'Today entry';

    return _DiaryV2ViewData(
      weekDays: _buildWeekDays(normalizedSelectedDay, localeTag),
      selectedDayLabel: _formatLongDate(normalizedSelectedDay, localeTag),
      previewTitle: previewText.$1.isNotEmpty ? previewText.$1 : fallbackTitle,
      todayExcerpt: _excerptFor(previewText.$2),
      emptyStateTitle: isSpanish
          ? 'A\u00fan no has escrito hoy'
          : 'You have not written today yet',
      emptyStateBody: isSpanish
          ? 'Guarda un momento cuando quieras.'
          : 'Save a moment whenever you want.',
      selectedEntry: selectedEntry,
      selectedMood: selectedEntry?.mood,
      stats: [
        DiaryV2StatItem(
          icon: CupertinoIcons.flame,
          value: _currentStreak(uiEntries, normalizedSelectedDay).toString(),
          label: isSpanish ? 'Racha actual' : 'Current streak',
          detail: isSpanish ? 'd\u00edas' : 'days',
        ),
        DiaryV2StatItem(
          icon: CupertinoIcons.calendar,
          value: monthEntries.length.toString(),
          label: isSpanish ? 'Este mes' : 'This month',
          detail: isSpanish ? 'entradas' : 'entries',
        ),
        DiaryV2StatItem(
          icon: CupertinoIcons.bookmark,
          value: pinnedCount.toString(),
          label: isSpanish ? 'Momentos guardados' : 'Saved moments',
          detail: isSpanish ? 'favoritos' : 'favorites',
        ),
      ],
      monthSummary: isSpanish
          ? '$monthlyEntryDays d\u00edas escritos'
          : '$monthlyEntryDays written days',
      monthMoodLabel: _monthMoodLabel(monthEntries, localeTag),
      monthDominantMood: _dominantMood(monthEntries),
      monthDots: _buildMonthDots(monthEntries, normalizedSelectedDay),
      metadataLabels: _metadataLabels(selectedEntry, isSpanish),
      selectedDayEntries: selectedDayEntries,
      extraEntriesLabel: _extraEntriesLabel(
        count: selectedDayEntries.length,
        localeTag: localeTag,
        selectedDay: normalizedSelectedDay,
      ),
    );
  }
}

const _exploreItems = [
  DiaryV2ExploreItem(
    icon: CupertinoIcons.heart,
    title: 'Gratitud',
    subtitle: 'Enf\u00f3cate en lo que te suma',
  ),
  DiaryV2ExploreItem(
    icon: CupertinoIcons.chat_bubble_2,
    title: 'Reflexiones',
    subtitle: 'Explora tus ideas y emociones',
  ),
  DiaryV2ExploreItem(
    icon: CupertinoIcons.leaf_arrow_circlepath,
    title: 'Aprendizajes',
    subtitle: 'Lo que hoy te dej\u00f3 una ense\u00f1anza',
  ),
  DiaryV2ExploreItem(
    icon: CupertinoIcons.bookmark,
    title: 'Momentos guardados',
    subtitle: 'Tus recuerdos m\u00e1s valiosos',
  ),
];

DiaryEntryUi _toUi(DiaryEntry entry) {
  return DiaryEntryUi.fromModel(
    id: entry.id,
    createdAt: entry.createdAt,
    type: entry.habitId == null
        ? DiaryEntryType.personal
        : DiaryEntryType.habit,
    text: entry.text,
    mood: entry.mood,
    habitId: entry.habitId,
  );
}

List<DiaryV2WeekDay> _buildWeekDays(DateTime selectedDay, String localeTag) {
  final startOfWeek =
      selectedDay.subtract(Duration(days: selectedDay.weekday - 1));
  const weekdayLettersEs = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  const weekdayLettersEn = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final letters =
      localeTag.startsWith('es') ? weekdayLettersEs : weekdayLettersEn;

  return List.generate(7, (index) {
    final day = startOfWeek.add(Duration(days: index));
    return DiaryV2WeekDay(
      label: letters[index],
      dayNumber: day.day.toString(),
      date: day,
      isSelected: DateUtils.isSameDay(day, selectedDay),
    );
  });
}

String _formatLongDate(DateTime date, String localeTag) {
  if (localeTag.startsWith('es')) {
    return DateFormat("d 'de' MMMM, y", localeTag).format(date);
  }
  return DateFormat('MMMM d, y', localeTag).format(date);
}

String _excerptFor(String text) {
  final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.isEmpty) return compact;
  if (compact.length <= 165) return compact;
  return '${compact.substring(0, 162).trimRight()}...';
}

(String, String) _splitPreviewText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return ('', '');

  final parts = trimmed
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);

  if (parts.isEmpty) return ('', '');
  if (parts.length == 1) return (parts.first, '');

  return (parts.first, parts.skip(1).join(' '));
}

String? _extraEntriesLabel({
  required int count,
  required String localeTag,
  required DateTime selectedDay,
}) {
  if (count <= 1) return null;
  final isSpanish = localeTag.startsWith('es');
  final isToday = DateUtils.isSameDay(selectedDay, DateTime.now());
  if (isSpanish) {
    return isToday
        ? 'Ver $count entradas de hoy'
        : 'Ver $count entradas del d\u00eda';
  }
  return isToday
      ? 'View $count entries today'
      : 'View $count entries for this day';
}

int _currentStreak(List<DiaryEntryUi> entries, DateTime anchorDay) {
  final uniqueDays =
      entries.map((entry) => DateUtils.dateOnly(entry.createdAt)).toSet();
  var streak = 0;
  var cursor = anchorDay;
  while (uniqueDays.contains(cursor)) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

List<String> _metadataLabels(DiaryEntryUi? entry, bool isSpanish) {
  if (entry == null) return const [];

  final labels = <String>[];
  if (entry.type == DiaryEntryType.habit) {
    labels.add(isSpanish ? 'H\u00e1bito' : 'Habit');
  }

  return labels;
}

String _monthMoodLabel(List<DiaryEntryUi> monthEntries, String localeTag) {
  final moods = monthEntries
      .map((entry) => entry.mood)
      .whereType<int>()
      .toList(growable: false);
  if (moods.isEmpty) {
    return localeTag.startsWith('es')
        ? 'Estado m\u00e1s repetido: por definir'
        : 'Most common mood: to be defined';
  }

  final counts = <int, int>{};
  for (final mood in moods) {
    counts[mood] = (counts[mood] ?? 0) + 1;
  }
  final dominantMood =
      counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  return localeTag.startsWith('es')
      ? 'Estado m\u00e1s repetido: ${_moodWord(dominantMood, true)}'
      : 'Most common mood: ${_moodWord(dominantMood, false)}';
}

String _moodWord(int mood, bool spanish) {
  switch (mood) {
    case -2:
      return spanish ? 'agotado' : 'drained';
    case -1:
      return spanish ? 'sensible' : 'low';
    case 1:
      return spanish ? 'enfocado' : 'steady';
    case 2:
      return spanish ? 'inspirado' : 'uplifted';
    default:
      return spanish ? 'calma' : 'calm';
  }
}

List<DiaryV2MonthDot> _buildMonthDots(
  List<DiaryEntryUi> monthEntries,
  DateTime selectedDay,
) {
  final groupedByDay = <int, List<DiaryEntryUi>>{};
  for (final entry in monthEntries) {
    groupedByDay.putIfAbsent(entry.createdAt.day, () => []).add(entry);
  }

  final daysInMonth =
      DateUtils.getDaysInMonth(selectedDay.year, selectedDay.month);
  return List.generate(daysInMonth, (index) {
    final dayNumber = index + 1;
    final entriesForDay = groupedByDay[dayNumber] ?? const <DiaryEntryUi>[];
    // TODO(v2-diary): This month preview temporarily uses diary entry mood as a
    // proxy for the global day mood. Replace this with a first-class DailyMood
    // source later, and do not mix habit-specific mood data into that model.
    final mood = entriesForDay
        .map((entry) => entry.mood)
        .whereType<int>()
        .cast<int?>()
        .firstWhere((value) => value != null, orElse: () => null);
    return DiaryV2MonthDot(
      active: entriesForDay.isNotEmpty,
      moodValue: mood,
      highlighted: DateUtils.isSameDay(
        DateTime(selectedDay.year, selectedDay.month, dayNumber),
        selectedDay,
      ),
      tone: _toneForMood(mood),
    );
  });
}

DiaryV2MonthDotTone _toneForMood(int? mood) {
  if (mood == null) return DiaryV2MonthDotTone.neutral;
  return switch (mood) {
    <= -2 => DiaryV2MonthDotTone.red,
    -1 => DiaryV2MonthDotTone.orange,
    0 => DiaryV2MonthDotTone.camel,
    1 => DiaryV2MonthDotTone.greenSoft,
    _ => DiaryV2MonthDotTone.greenStrong,
  };
}

int? _dominantMood(List<DiaryEntryUi> monthEntries) {
  final moods = monthEntries
      .map((entry) => entry.mood)
      .whereType<int>()
      .toList(growable: false);
  if (moods.isEmpty) return null;

  final counts = <int, int>{};
  for (final mood in moods) {
    counts[mood] = (counts[mood] ?? 0) + 1;
  }
  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}
