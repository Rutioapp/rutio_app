import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/screens/diary/models/diary_types.dart';
import 'package:rutio/stores/user_state_store.dart';

import 'diary_v2_entry_editor_screen.dart';
import 'diary_v2_mood_visuals.dart';
import 'diary_v2_tags.dart';
import 'widgets/diary_v2_styles.dart';

class DiaryV2AllEntriesScreen extends StatefulWidget {
  const DiaryV2AllEntriesScreen({
    super.key,
    required this.entries,
    this.now,
  });

  final List<DiaryEntry> entries;
  final DateTime? now;

  @override
  State<DiaryV2AllEntriesScreen> createState() =>
      _DiaryV2AllEntriesScreenState();
}

class _DiaryV2AllEntriesScreenState extends State<DiaryV2AllEntriesScreen> {
  static const String _allFilter = 'all';

  _AllEntriesDateFilter _selectedDateFilter = _AllEntriesDateFilter.all;
  String _selectedTag = _allFilter;
  int? _selectedEntryMood;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEntryEditor(DiaryEntry entry) async {
    final didChange = await openDiaryV2EntryEditor(
      context,
      editing: entry,
    );
    if (didChange == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<UserStateStore?>(context);
    final locale = Localizations.localeOf(context);
    final localeTag = locale.toLanguageTag();
    final effectiveEntries = store?.diaryEntries ?? widget.entries;
    final filteredEntries = _filterEntries(
      entries: effectiveEntries,
      selectedDateFilter: _selectedDateFilter,
      selectedTag: _selectedTag,
      selectedEntryMood: _selectedEntryMood,
      searchQuery: _searchQuery,
      now: widget.now ?? DateTime.now(),
    );
    final groups = _groupEntries(entries: filteredEntries);
    final isDateFiltered = _selectedDateFilter != _AllEntriesDateFilter.all;
    final isTagFiltered = _selectedTag != _allFilter;
    final isMoodFiltered = _selectedEntryMood != null;
    final hasSearchQuery = _normalizedSearchQuery(_searchQuery).isNotEmpty;
    final hasAnyEntries = effectiveEntries.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F0E7),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
          children: [
            _AllEntriesHeader(title: context.l10n.diaryAllEntriesTitle),
            const SizedBox(height: 14),
            _AllEntriesSearchField(
              controller: _searchController,
              placeholder: context.l10n.diaryAllEntriesSearchPlaceholder,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 12),
            _DateFilterRow(
              selectedFilter: _selectedDateFilter,
              onFilterSelected: (filter) =>
                  setState(() => _selectedDateFilter = filter),
            ),
            const SizedBox(height: 10),
            _TagFilterRow(
              selectedTag: _selectedTag,
              onTagSelected: (tag) => setState(() => _selectedTag = tag),
            ),
            const SizedBox(height: 10),
            _EntryMoodFilterRow(
              selectedMood: _selectedEntryMood,
              onMoodSelected: (mood) =>
                  setState(() => _selectedEntryMood = mood),
            ),
            const SizedBox(height: 16),
            if (groups.isEmpty)
              _AllEntriesEmptyState(
                title: !hasAnyEntries
                    ? context.l10n.diaryAllEntriesEmptyTitle
                    : hasSearchQuery
                        ? context.l10n.diaryAllEntriesNoResultsTitle
                        : isDateFiltered || isTagFiltered || isMoodFiltered
                            ? _filterEmptyTitle(locale)
                            : context.l10n.diaryAllEntriesEmptyTitle,
                body: !hasAnyEntries
                    ? context.l10n.diaryAllEntriesEmptyBody
                    : hasSearchQuery
                        ? context.l10n.diaryAllEntriesNoResultsBody
                        : isDateFiltered || isTagFiltered || isMoodFiltered
                            ? _filterEmptyBody(locale)
                            : context.l10n.diaryAllEntriesEmptyBody,
              )
            else
              ...groups.map(
                (group) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _AllEntriesGroup(
                    label: _formatGroupDate(group.day, localeTag),
                    items: group.items,
                    onEntryTap: _openEntryEditor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AllEntriesSearchField extends StatelessWidget {
  const _AllEntriesSearchField({
    required this.controller,
    required this.placeholder,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: DiaryV2Styles.compactCardDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: CupertinoSearchTextField(
          key: const ValueKey<String>('diary-all-entries-search-field'),
          controller: controller,
          onChanged: onChanged,
          placeholder: placeholder,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          backgroundColor: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DiaryV2Styles.textStrong,
              ),
          placeholderStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DiaryV2Styles.mutedTextStrong,
              ),
        ),
      ),
    );
  }
}

enum _AllEntriesDateFilter { all, week, month, last30Days }

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

class _TagFilterRow extends StatelessWidget {
  const _TagFilterRow({
    required this.selectedTag,
    required this.onTagSelected,
  });

  final String selectedTag;
  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final filters = <String>[
      _DiaryV2AllEntriesScreenState._allFilter,
      ...diaryV2PredefinedTags,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: filters
            .map(
              (tag) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChipButton(
                  key: ValueKey<String>('diary-all-entries-filter-$tag'),
                  label: _filterLabel(
                    tag: tag,
                    locale: locale,
                    context: context,
                  ),
                  isSelected: selectedTag == tag,
                  onTap: () => onTagSelected(tag),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _DateFilterRow extends StatelessWidget {
  const _DateFilterRow({
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final _AllEntriesDateFilter selectedFilter;
  final ValueChanged<_AllEntriesDateFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: _AllEntriesDateFilter.values
            .map(
              (filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChipButton(
                  key: ValueKey<String>(
                    'diary-all-entries-date-filter-${filter.name}',
                  ),
                  label: _dateFilterLabel(filter, locale),
                  isSelected: selectedFilter == filter,
                  onTap: () => onFilterSelected(filter),
                ),
              ),
            )
            .toList(growable: false),
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

class _EntryMoodFilterRow extends StatelessWidget {
  const _EntryMoodFilterRow({
    required this.selectedMood,
    required this.onMoodSelected,
  });

  final int? selectedMood;
  final ValueChanged<int?> onMoodSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            _entryMoodFilterLabel(locale),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: DiaryV2Styles.mutedTextStrong,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.15,
                ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChipButton(
                  key: const ValueKey<String>(
                      'diary-all-entries-mood-filter-all'),
                  label: _allMoodFilterLabel(locale),
                  isSelected: selectedMood == null,
                  onTap: () => onMoodSelected(null),
                ),
              ),
              ...DiaryMoodVisuals.values.map(
                (mood) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _MoodFilterChipButton(
                    mood: mood,
                    isSelected: selectedMood == mood,
                    onTap: () => onMoodSelected(mood),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AllEntriesGroup extends StatelessWidget {
  const _AllEntriesGroup({
    required this.label,
    required this.items,
    required this.onEntryTap,
  });

  final String label;
  final List<_AllEntriesItemVm> items;
  final ValueChanged<DiaryEntry> onEntryTap;

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
            child: _AllEntriesCard(
              item: item,
              onTap: () => onEntryTap(item.entry),
            ),
          ),
        ),
      ],
    );
  }
}

class _AllEntriesCard extends StatelessWidget {
  const _AllEntriesCard({
    required this.item,
    required this.onTap,
  });

  final _AllEntriesItemVm item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DiaryV2Styles.compactCardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DiaryV2Styles.compactCardRadius),
          onTap: onTap,
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
                if (item
                    .tagLabels(Localizations.localeOf(context))
                    .isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item
                        .tagLabels(Localizations.localeOf(context))
                        .map((label) => _EntryChip(label: label))
                        .toList(growable: false),
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
    final emoji = DiaryMoodVisuals.emojiFor(mood);
    final borderColor = DiaryMoodVisuals.borderColorFor(mood);

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: DiaryMoodVisuals.fillColorFor(mood),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.34)),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: mood == 0 ? 18 : 15,
            height: 1,
            color: borderColor,
            fontWeight: mood == 0 ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
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

  List<String> tagLabels(Locale locale) {
    return diaryTagLabels(entry.tags, locale, maxVisible: 3);
  }
}

List<_AllEntriesGroupVm> _groupEntries({
  required List<DiaryEntry> entries,
}) {
  final sortedEntries = [...entries]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final groups = <DateTime, List<_AllEntriesItemVm>>{};

  for (final entry in sortedEntries) {
    final ui = _toUi(entry);
    final day = DateUtils.dateOnly(ui.createdAt);

    groups.putIfAbsent(day, () => <_AllEntriesItemVm>[]).add(
          _AllEntriesItemVm(
            entry: entry,
            ui: ui,
            isPinned: entry.isPinned,
            mood: entry.mood,
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
    tags: entry.tags,
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

List<DiaryEntry> _filterEntries({
  required List<DiaryEntry> entries,
  required _AllEntriesDateFilter selectedDateFilter,
  required String selectedTag,
  required int? selectedEntryMood,
  required String searchQuery,
  required DateTime now,
}) {
  final normalizedQuery = _normalizedSearchQuery(searchQuery);
  final normalizedNow = DateUtils.dateOnly(now);

  return entries.where((entry) {
    final matchesDate = _matchesDateFilter(
      entry: entry,
      selectedDateFilter: selectedDateFilter,
      now: normalizedNow,
    );
    if (!matchesDate) return false;
    final matchesTag = selectedTag == _DiaryV2AllEntriesScreenState._allFilter
        ? true
        : entry.tags.contains(selectedTag);
    if (!matchesTag) return false;
    final matchesMood =
        selectedEntryMood == null ? true : entry.mood == selectedEntryMood;
    if (!matchesMood) return false;
    if (normalizedQuery.isEmpty) return true;
    return _entryMatchesSearch(entry, normalizedQuery);
  }).toList(growable: false);
}

String _normalizedSearchQuery(String value) => value.trim().toLowerCase();

bool _entryMatchesSearch(DiaryEntry entry, String normalizedQuery) {
  final ui = _toUi(entry);
  final searchHaystacks = <String>[
    ui.title ?? '',
    ui.body ?? '',
    ui.text,
    ...entry.tags,
  ];

  return searchHaystacks.any(
    (value) => value.trim().toLowerCase().contains(normalizedQuery),
  );
}

bool _matchesDateFilter({
  required DiaryEntry entry,
  required _AllEntriesDateFilter selectedDateFilter,
  required DateTime now,
}) {
  if (selectedDateFilter == _AllEntriesDateFilter.all) return true;

  final entryDay = DateUtils.dateOnly(_toUi(entry).createdAt);
  switch (selectedDateFilter) {
    case _AllEntriesDateFilter.all:
      return true;
    case _AllEntriesDateFilter.week:
      final startOfWeek =
          now.subtract(Duration(days: now.weekday - DateTime.monday));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return !_isBeforeDay(entryDay, startOfWeek) &&
          !_isAfterDay(entryDay, endOfWeek);
    case _AllEntriesDateFilter.month:
      return entryDay.year == now.year && entryDay.month == now.month;
    case _AllEntriesDateFilter.last30Days:
      final start = now.subtract(const Duration(days: 29));
      return !_isBeforeDay(entryDay, start) && !_isAfterDay(entryDay, now);
  }
}

bool _isBeforeDay(DateTime value, DateTime other) => value.compareTo(other) < 0;

bool _isAfterDay(DateTime value, DateTime other) => value.compareTo(other) > 0;

String _filterLabel({
  required String tag,
  required Locale locale,
  required BuildContext context,
}) {
  if (tag == _DiaryV2AllEntriesScreenState._allFilter) {
    return context.l10n.todoFilterAll;
  }
  return diaryTagLabel(tag, locale);
}

String _dateFilterLabel(_AllEntriesDateFilter filter, Locale locale) {
  final isSpanish = locale.languageCode == 'es';
  switch (filter) {
    case _AllEntriesDateFilter.all:
      return isSpanish ? 'Todo' : 'All';
    case _AllEntriesDateFilter.week:
      return isSpanish ? 'Semana' : 'Week';
    case _AllEntriesDateFilter.month:
      return isSpanish ? 'Mes' : 'Month';
    case _AllEntriesDateFilter.last30Days:
      return isSpanish ? '30 días' : '30 days';
  }
}

String _entryMoodFilterLabel(Locale locale) {
  return locale.languageCode == 'es' ? 'Mood de entrada' : 'Entry mood';
}

String _allMoodFilterLabel(Locale locale) {
  return locale.languageCode == 'es' ? 'Todos' : 'All';
}

String _filterEmptyTitle(Locale locale) {
  return locale.languageCode == 'es'
      ? 'No hay entradas con estos filtros'
      : 'No entries with these filters';
}

String _filterEmptyBody(Locale locale) {
  return locale.languageCode == 'es'
      ? 'Prueba con otro periodo, mood o etiqueta.'
      : 'Try another period, mood or tag.';
}

class _EntryChip extends StatelessWidget {
  const _EntryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DiaryV2Styles.creamStrong.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DiaryV2Styles.border.withValues(alpha: 0.82)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DiaryV2Styles.mutedTextStrong,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? DiaryV2Styles.accentSoftMuted
        : Colors.white.withValues(alpha: 0.62);
    final borderColor = isSelected
        ? DiaryV2Styles.accent.withValues(alpha: 0.3)
        : DiaryV2Styles.border.withValues(alpha: 0.72);
    final textColor =
        isSelected ? DiaryV2Styles.textStrong : DiaryV2Styles.mutedTextStrong;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
          ),
        ),
      ),
    );
  }
}

class _MoodFilterChipButton extends StatelessWidget {
  const _MoodFilterChipButton({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  final int mood;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fillColor = DiaryMoodVisuals.fillColorFor(mood);
    final borderColor = DiaryMoodVisuals.borderColorFor(mood);
    final locale = Localizations.localeOf(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: DiaryMoodVisuals.semanticLabelForLocale(mood, locale),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey<String>('diary-all-entries-mood-filter-$mood'),
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? fillColor.withValues(alpha: 0.95)
                  : fillColor.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected
                    ? borderColor.withValues(alpha: 0.42)
                    : borderColor.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DiaryMoodVisuals.emojiFor(mood),
                  style: TextStyle(
                    fontSize: mood == 0 ? 16 : 14,
                    height: 1,
                    color: borderColor,
                    fontWeight: mood == 0 ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  DiaryMoodVisuals.labelForLocale(mood, locale),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? DiaryV2Styles.textStrong
                            : DiaryV2Styles.mutedTextStrong,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
