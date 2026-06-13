import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/models/daily_mood.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/screens/diary/models/diary_types.dart';
import 'package:rutio/stores/user_state_store.dart';

import 'diary_v2_daily_mood_resolver.dart';
import 'diary_v2_entry_editor_screen.dart';
import 'widgets/diary_v2_styles.dart';

class DiaryV2AllEntriesScreen extends StatelessWidget {
  const DiaryV2AllEntriesScreen({
    super.key,
    required this.entries,
    required this.dailyMoods,
  });

  final List<DiaryEntry> entries;
  final List<DailyMood> dailyMoods;

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<UserStateStore?>(context);
    final locale = Localizations.localeOf(context);
    final localeTag = locale.toLanguageTag();
    final effectiveEntries = store?.diaryEntries ?? entries;
    final effectiveDailyMoods = store?.dailyMoods ?? dailyMoods;
    final groups = _groupEntries(
      entries: effectiveEntries,
      dailyMoods: effectiveDailyMoods,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F0E7),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
          children: [
            _AllEntriesHeader(title: context.l10n.diaryAllEntriesTitle),
            const SizedBox(height: 18),
            if (groups.isEmpty)
              _AllEntriesEmptyState(
                title: context.l10n.diaryAllEntriesEmptyTitle,
                body: context.l10n.diaryAllEntriesEmptyBody,
              )
            else
              ...groups.map(
                (group) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _AllEntriesGroup(
                    label: _formatGroupDate(group.day, localeTag),
                    items: group.items,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AllEntriesHeader extends StatelessWidget {
  const _AllEntriesHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _CircleButton(
              icon: CupertinoIcons.back,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: DiaryV2Styles.title(context).copyWith(
              fontSize: 30,
              color: DiaryV2Styles.textStrong,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllEntriesEmptyState extends StatelessWidget {
  const _AllEntriesEmptyState({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: DiaryV2Styles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: DiaryV2Styles.textStrong,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DiaryV2Styles.mutedTextStrong,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _AllEntriesGroup extends StatelessWidget {
  const _AllEntriesGroup({
    required this.label,
    required this.items,
  });

  final String label;
  final List<_AllEntriesItemVm> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: DiaryV2Styles.mutedTextStrong,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
          ),
        ),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AllEntriesCard(item: item),
          ),
        ),
      ],
    );
  }
}

class _AllEntriesCard extends StatelessWidget {
  const _AllEntriesCard({required this.item});

  final _AllEntriesItemVm item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DiaryV2Styles.compactCardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DiaryV2Styles.compactCardRadius),
          onTap: () => openDiaryV2EntryEditor(
            context,
            editing: item.entry,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.timeLabel,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: DiaryV2Styles.textStrong,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    if (item.mood != null) ...[
                      _MoodPill(mood: item.mood!),
                      const SizedBox(width: 8),
                    ],
                    _SavedPill(isPinned: item.isPinned),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DiaryV2Styles.title(context).copyWith(
                    fontSize: 17,
                    color: DiaryV2Styles.textStrong,
                  ),
                ),
                if (item.displayBody.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.displayBody,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DiaryV2Styles.textStrong,
                          height: 1.35,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodPill extends StatelessWidget {
  const _MoodPill({required this.mood});

  final int mood;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mood) {
      -2 => CupertinoIcons.cloud_rain,
      -1 => CupertinoIcons.moon,
      1 => CupertinoIcons.sun_max,
      2 => CupertinoIcons.heart,
      _ => CupertinoIcons.smiley,
    };

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 18,
        color: DiaryV2Styles.accentDeep,
      ),
    );
  }
}

class _SavedPill extends StatelessWidget {
  const _SavedPill({required this.isPinned});

  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isPinned
            ? DiaryV2Styles.accentSoftMuted
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isPinned ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
        size: 17,
        color: isPinned ? DiaryV2Styles.accentDeep : DiaryV2Styles.textStrong,
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DiaryV2Styles.softButtonDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              color: DiaryV2Styles.textStrong,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _AllEntriesGroupVm {
  const _AllEntriesGroupVm({
    required this.day,
    required this.items,
  });

  final DateTime day;
  final List<_AllEntriesItemVm> items;
}

class _AllEntriesItemVm {
  const _AllEntriesItemVm({
    required this.entry,
    required this.ui,
    required this.isPinned,
    required this.mood,
  });

  final DiaryEntry entry;
  final DiaryEntryUi ui;
  final bool isPinned;
  final int? mood;

  String get timeLabel => ui.timeLabel;

  String get displayTitle {
    final title = _compact(ui.title ?? '');
    if (title.isNotEmpty) return title;

    final body = _compact(ui.body ?? '');
    if (body.isNotEmpty) return _truncate(body, 32);

    final text = _compact(ui.text);
    return text.isEmpty ? 'Entry' : _truncate(text, 32);
  }

  String get displayBody {
    final body = _compact(ui.body ?? '');
    if (body.isNotEmpty) return body;

    final title = _compact(ui.title ?? '');
    final legacy = _compact(ui.text);
    if (legacy.isEmpty || legacy == title) return '';
    if (title.isNotEmpty && legacy.startsWith(title)) {
      return legacy.substring(title.length).trimLeft();
    }
    return legacy;
  }
}

List<_AllEntriesGroupVm> _groupEntries({
  required List<DiaryEntry> entries,
  required List<DailyMood> dailyMoods,
}) {
  final dailyMoodsByDate = dailyMoodMapByDate(dailyMoods);
  final sortedEntries = [...entries]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final groups = <DateTime, List<_AllEntriesItemVm>>{};

  for (final entry in sortedEntries) {
    final ui = _toUi(entry);
    final day = DateUtils.dateOnly(ui.createdAt);
    final mood = resolvePreferredMoodForDay(
      day: day,
      dailyMoodsByDate: dailyMoodsByDate,
      fallbackEntries: [entry],
    );

    groups.putIfAbsent(day, () => <_AllEntriesItemVm>[]).add(
          _AllEntriesItemVm(
            entry: entry,
            ui: ui,
            isPinned: entry.isPinned,
            mood: mood,
          ),
        );
  }

  final orderedDays = groups.keys.toList()..sort((a, b) => b.compareTo(a));
  return orderedDays
      .map(
        (day) => _AllEntriesGroupVm(
          day: day,
          items: groups[day]!,
        ),
      )
      .toList(growable: false);
}

DiaryEntryUi _toUi(DiaryEntry entry) {
  return DiaryEntryUi.fromModel(
    id: entry.id,
    createdAt: entry.createdAt,
    type:
        entry.habitId == null ? DiaryEntryType.personal : DiaryEntryType.habit,
    text: entry.legacyText,
    title: entry.textParts.title,
    body: entry.textParts.body,
    mood: entry.mood,
    habitId: entry.habitId,
  );
}

String _formatGroupDate(DateTime day, String localeTag) {
  if (localeTag.startsWith('es')) {
    return DateFormat("EEEE, d 'de' MMMM", localeTag).format(day);
  }
  return DateFormat('EEEE, MMMM d', localeTag).format(day);
}

String _compact(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _truncate(String value, int maxLength) {
  if (value.length <= maxLength) return value;
  return '${value.substring(0, maxLength - 3).trimRight()}...';
}
