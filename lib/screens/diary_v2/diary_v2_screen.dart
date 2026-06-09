import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/diary/diary_screen.dart';
import 'package:rutio/screens/diary/widgets/diary_screen_background.dart';
import 'package:rutio/screens/habit_archived_screen.dart';
import 'package:rutio/screens/habit_monthly_screen.dart';
import 'package:rutio/screens/habit_weekly_screen.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:rutio/screens/profile/profile_screen.dart';
import 'package:rutio/widgets/app_view_drawer.dart';

import 'widgets/diary_v2_explore_grid.dart';
import 'widgets/diary_v2_header.dart';
import 'widgets/diary_v2_month_preview_card.dart';
import 'widgets/diary_v2_prompt_card.dart';
import 'widgets/diary_v2_stats_summary_card.dart';
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

class DiaryV2Screen extends StatelessWidget {
  const DiaryV2Screen({super.key});

  static const route = '/diary-v2';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final subtitle = Localizations.localeOf(context).languageCode == 'es'
        ? 'Tu espacio para recordar el dia.'
        : 'Your space to remember the day.';

    const todayDate = '15 de mayo, 2025';
    const todayEntry =
        'Hoy me siento agradecido por los pequenos momentos que me dieron paz. '
        'Elegi enfocarme en lo que puedo controlar y eso me dio claridad.';

    const weekDays = [
      DiaryV2WeekDay(label: 'L', dayNumber: '12'),
      DiaryV2WeekDay(label: 'M', dayNumber: '13'),
      DiaryV2WeekDay(label: 'X', dayNumber: '14'),
      DiaryV2WeekDay(label: 'J', dayNumber: '15', isSelected: true),
      DiaryV2WeekDay(label: 'V', dayNumber: '16'),
      DiaryV2WeekDay(label: 'S', dayNumber: '17'),
      DiaryV2WeekDay(label: 'D', dayNumber: '18'),
    ];

    const moods = [
      DiaryV2MoodOption(icon: CupertinoIcons.smiley, isSelected: false),
      DiaryV2MoodOption(icon: CupertinoIcons.smiley_fill, isSelected: false),
      DiaryV2MoodOption(icon: CupertinoIcons.smiley_fill, isSelected: true),
      DiaryV2MoodOption(icon: CupertinoIcons.smiley, isSelected: false),
      DiaryV2MoodOption(icon: CupertinoIcons.smiley, isSelected: false),
    ];

    const stats = [
      DiaryV2StatItem(
        icon: CupertinoIcons.flame,
        value: '28',
        label: 'Racha actual',
        detail: 'dias',
      ),
      DiaryV2StatItem(
        icon: CupertinoIcons.calendar,
        value: '18',
        label: 'Este mes',
        detail: 'entradas',
      ),
      DiaryV2StatItem(
        icon: CupertinoIcons.bookmark,
        value: '42',
        label: 'Momentos',
        detail: 'guardados',
      ),
    ];

    const exploreItems = [
      DiaryV2ExploreItem(
        icon: CupertinoIcons.heart,
        title: 'Gratitud',
        subtitle: 'Enfocate en lo que te suma',
      ),
      DiaryV2ExploreItem(
        icon: CupertinoIcons.chat_bubble,
        title: 'Reflexiones',
        subtitle: 'Explora ideas y emociones',
      ),
      DiaryV2ExploreItem(
        icon: CupertinoIcons.leaf_arrow_circlepath,
        title: 'Aprendizajes',
        subtitle: 'Lo que hoy te dejo una ensenanza',
      ),
      DiaryV2ExploreItem(
        icon: CupertinoIcons.bookmark,
        title: 'Momentos guardados',
        subtitle: 'Tus recuerdos mas valiosos',
      ),
    ];

    const monthDots = [
      DiaryV2MonthDot(active: true),
      DiaryV2MonthDot(active: true),
      DiaryV2MonthDot(active: true),
      DiaryV2MonthDot(active: true),
      DiaryV2MonthDot(active: true),
      DiaryV2MonthDot(active: true, highlighted: true),
      DiaryV2MonthDot(active: true),
      DiaryV2MonthDot(active: true),
      DiaryV2MonthDot(active: true),
      DiaryV2MonthDot(active: true, highlighted: true),
      DiaryV2MonthDot(active: true),
      DiaryV2MonthDot(active: true, highlighted: true),
      DiaryV2MonthDot(active: true),
      DiaryV2MonthDot(active: false),
    ];

    return Scaffold(
      drawer: AppViewDrawer(
        selected: 'diary',
        onGoDaily: () => _navReplace(context, const HomeScreen()),
        onGoWeekly: () => _navReplace(context, const HabitWeeklyScreen()),
        onGoMonthly: () => _navReplace(context, const HabitMonthlyScreen()),
        onGoTodo: () => Navigator.pushNamed(context, '/todo'),
        onGoDiary: () => _navReplace(context, const DiaryScreen()),
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
                padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 124),
                children: [
                  Builder(
                    builder: (ctx) => DiaryV2Header(
                      title: context.l10n.diaryTitle,
                      subtitle: subtitle,
                      onMenuTap: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const DiaryV2WeekStrip(days: weekDays),
                  const SizedBox(height: 20),
                  const DiaryV2TodayEntryCard(
                    dateLabel: todayDate,
                    body: todayEntry,
                    chips: ['Gratitud', 'Energia', 'Foco', 'Sueno'],
                    moods: moods,
                  ),
                  const SizedBox(height: 16),
                  const DiaryV2StatsSummaryCard(items: stats),
                  const SizedBox(height: 20),
                  Text(
                    Localizations.localeOf(context).languageCode == 'es'
                        ? 'Explora tu diario'
                        : 'Explore your diary',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF5B3A25),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const DiaryV2ExploreGrid(items: exploreItems),
                  const SizedBox(height: 14),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DiaryV2MonthPreviewCard(
                          title: 'Tu mes',
                          summary: '12 dias escritos',
                          moodLabel: 'Estado mas repetido: calma',
                          dots: monthDots,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: DiaryV2PromptCard(
                          title: 'Prompt de hoy',
                          prompt:
                              'Que pequeno momento te gustaria recordar hoy?',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16 + bottomInset,
                child: DiaryV2WriteButton(
                  label: Localizations.localeOf(context).languageCode == 'es'
                      ? 'Escribir ahora'
                      : 'Write now',
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
