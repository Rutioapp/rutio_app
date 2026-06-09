import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/screens/diary/diary_screen.dart';
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
import 'widgets/diary_v2_prompt_card.dart';
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
          title: isSpanish ? 'Entradas del día' : 'Day entries',
          dateLabel: viewData.selectedDayLabel,
          entries: viewData.selectedDayEntries,
          onCreateEntry: DateUtils.isSameDay(_selectedDay, DateTime.now())
              ? () => _openComposer(context)
              : () => _openComposer(context),
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
        ? 'Tu espacio para recordar el día.'
        : 'Your space to remember the day.';

    return Scaffold(
      drawer: AppViewDrawer(
        selected: 'diary_v2',
        onGoDaily: () => _navReplace(context, const HomeScreen()),
        onGoWeekly: () => _navReplace(context, const HabitWeeklyScreen()),
        onGoMonthly: () => _navReplace(context, const HabitMonthlyScreen()),
        onGoTodo: () => Navigator.pushNamed(context, '/todo'),
        onGoDiary: () => _navReplace(context, const DiaryScreen()),
        onGoDiaryV2: () {},
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
                    title: isSpanish ? 'Entrada de hoy' : 'Today entry',
                    dateLabel: viewData.selectedDayLabel,
                    excerpt: viewData.todayExcerpt,
                    emptyTitle: viewData.emptyStateTitle,
                    emptyBody: viewData.emptyStateBody,
                    moodPrompt: isSpanish
                        ? '¿Cómo te sientes hoy?'
                        : 'How do you feel today?',
                    chips: viewData.placeholderChips,
                    moods: viewData.moods,
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
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 390;
                      if (stacked) {
                        return Column(
                          children: [
                            DiaryV2MonthPreviewCard(
                              title: isSpanish ? 'Tu mes' : 'Your month',
                              summary: viewData.monthSummary,
                              moodLabel: viewData.monthMoodLabel,
                              dots: viewData.monthDots,
                            ),
                            const SizedBox(height: 10),
                            DiaryV2PromptCard(
                              title: isSpanish
                                  ? 'Prompt de hoy'
                                  : 'Today prompt',
                              prompt: viewData.promptText,
                              onTap: () => _openComposer(context),
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DiaryV2MonthPreviewCard(
                              title: isSpanish ? 'Tu mes' : 'Your month',
                              summary: viewData.monthSummary,
                              moodLabel: viewData.monthMoodLabel,
                              dots: viewData.monthDots,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DiaryV2PromptCard(
                              title: isSpanish
                                  ? 'Prompt de hoy'
                                  : 'Today prompt',
                              prompt: viewData.promptText,
                              onTap: () => _openComposer(context),
                            ),
                          ),
                        ],
                      );
                    },
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
    required this.todayExcerpt,
    required this.emptyStateTitle,
    required this.emptyStateBody,
    required this.selectedEntry,
    required this.moods,
    required this.stats,
    required this.monthSummary,
    required this.monthMoodLabel,
    required this.monthDots,
    required this.promptText,
    required this.placeholderChips,
    required this.selectedDayEntries,
    required this.extraEntriesLabel,
  });

  final List<DiaryV2WeekDay> weekDays;
  final String selectedDayLabel;
  final String todayExcerpt;
  final String emptyStateTitle;
  final String emptyStateBody;
  final DiaryEntryUi? selectedEntry;
  final List<DiaryV2MoodOption> moods;
  final List<DiaryV2StatItem> stats;
  final String monthSummary;
  final String monthMoodLabel;
  final List<DiaryV2MonthDot> monthDots;
  final String promptText;
  final List<String> placeholderChips;
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

    return _DiaryV2ViewData(
      weekDays: _buildWeekDays(normalizedSelectedDay, localeTag),
      selectedDayLabel: _formatLongDate(normalizedSelectedDay, localeTag),
      todayExcerpt: _excerptFor(selectedEntry?.text ?? ''),
      emptyStateTitle: isSpanish
          ? 'Aún no has escrito hoy'
          : 'You have not written today yet',
      emptyStateBody: isSpanish
          ? 'Cuando quieras, puedes capturar un momento, una emoción o una idea con el flujo actual del diario.'
          : 'When you are ready, you can capture a moment, feeling, or idea using the current diary flow.',
      selectedEntry: selectedEntry,
      moods: _buildMoods(selectedEntry?.mood),
      stats: [
        DiaryV2StatItem(
          icon: CupertinoIcons.flame,
          value: _currentStreak(uiEntries, normalizedSelectedDay).toString(),
          label: isSpanish ? 'Racha actual' : 'Current streak',
          detail: isSpanish ? 'días' : 'days',
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
          ? '$monthlyEntryDays días escritos'
          : '$monthlyEntryDays written days',
      monthMoodLabel: _monthMoodLabel(monthEntries, localeTag),
      monthDots: _buildMonthDots(monthEntries, normalizedSelectedDay),
      promptText: isSpanish
          ? '¿Qué pequeño momento te gustaría recordar hoy?'
          : 'What small moment would you like to remember today?',
      placeholderChips: isSpanish
          ? const ['Gratitud', 'Energía', 'Foco', 'Sueño']
          : const ['Gratitude', 'Energy', 'Focus', 'Sleep'],
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
    subtitle: 'Enfócate en lo que te suma',
  ),
  DiaryV2ExploreItem(
    icon: CupertinoIcons.chat_bubble_2,
    title: 'Reflexiones',
    subtitle: 'Explora tus ideas y emociones',
  ),
  DiaryV2ExploreItem(
    icon: CupertinoIcons.leaf_arrow_circlepath,
    title: 'Aprendizajes',
    subtitle: 'Lo que hoy te dejó una enseñanza',
  ),
  DiaryV2ExploreItem(
    icon: CupertinoIcons.bookmark,
    title: 'Momentos guardados',
    subtitle: 'Tus recuerdos más valiosos',
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
        : 'Ver $count entradas del día';
  }
  return isToday
      ? 'View $count entries today'
      : 'View $count entries for this day';
}

List<DiaryV2MoodOption> _buildMoods(int? selectedMood) {
  const moodScale = [-2, -1, 0, 1, 2];
  return moodScale
      .map(
        (value) => DiaryV2MoodOption(
          moodValue: value,
          isSelected: selectedMood == value,
        ),
      )
      .toList(growable: false);
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

String _monthMoodLabel(List<DiaryEntryUi> monthEntries, String localeTag) {
  final moods = monthEntries
      .map((entry) => entry.mood)
      .whereType<int>()
      .toList(growable: false);
  if (moods.isEmpty) {
    return localeTag.startsWith('es')
        ? 'Estado más repetido: por definir'
        : 'Most common mood: to be defined';
  }

  final counts = <int, int>{};
  for (final mood in moods) {
    counts[mood] = (counts[mood] ?? 0) + 1;
  }
  final dominantMood =
      counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  return localeTag.startsWith('es')
      ? 'Estado más repetido: ${_moodWord(dominantMood, true)}'
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
    final entries = groupedByDay[dayNumber] ?? const <DiaryEntryUi>[];
    // TODO(v2-diary): This month preview temporarily uses diary entry mood as a
    // proxy for the global day mood. Replace this with a first-class DailyMood
    // source later, and do not mix habit-specific mood data into that model.
    final mood = entries
        .map((entry) => entry.mood)
        .whereType<int>()
        .cast<int?>()
        .firstWhere((value) => value != null, orElse: () => null);
    return DiaryV2MonthDot(
      active: entries.isNotEmpty,
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
  if (mood >= 1) return DiaryV2MonthDotTone.warm;
  if (mood <= -1) return DiaryV2MonthDotTone.soft;
  return DiaryV2MonthDotTone.calm;
}
