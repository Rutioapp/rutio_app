import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/screens/diary/models/diary_types.dart';
import 'package:rutio/stores/user_state_store.dart';

import 'diary_v2_entry_editor_screen.dart';
import 'diary_v2_mood_visuals.dart';
import 'diary_v2_tags.dart';
import 'widgets/diary_v2_styles.dart';
import 'widgets/diary_v2_write_button.dart';

class DiaryV2DayEntriesScreen extends StatelessWidget {
  const DiaryV2DayEntriesScreen({
    super.key,
    required this.title,
    required this.dateLabel,
    required this.selectedDay,
    required this.entries,
    this.onCreateEntry,
    this.createLabel,
  });

  final String title;
  final String dateLabel;
  final DateTime selectedDay;
  final List<DiaryV2DayEntryItem> entries;
  final VoidCallback? onCreateEntry;
  final String? createLabel;

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<UserStateStore?>(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final showCreateAction =
        onCreateEntry != null && (createLabel?.isNotEmpty ?? false);
    final locale = Localizations.localeOf(context);
    final isSpanish = locale.languageCode == 'es';
    final effectiveEntries = store == null
        ? entries
        : diaryV2DayEntryItemsForDate(
            entries: store.diaryEntries,
            selectedDay: selectedDay,
          );

    return Scaffold(
      backgroundColor: const Color(0xFFE7F1FA),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(
                14,
                8,
                14,
                bottomInset + (showCreateAction ? 106 : 24),
              ),
              children: [
                _Header(
                  title: title,
                  dateLabel: dateLabel,
                ),
                const SizedBox(height: 18),
                _SummaryCard(
                  count: effectiveEntries.length,
                  isSpanish: isSpanish,
                ),
                const SizedBox(height: 16),
                if (effectiveEntries.isEmpty)
                  _EmptyCard(isSpanish: isSpanish)
                else
                  ...effectiveEntries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DayEntryCard(
                        entry: entry,
                        onTap: () => openDiaryV2EntryEditor(
                          context,
                          editing: entry.entry,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (showCreateAction)
              Positioned(
                left: 14,
                right: 14,
                bottom: 14 + bottomInset,
                child: DiaryV2WriteButton(
                  label: createLabel!,
                  onPressed: onCreateEntry!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.dateLabel,
  });

  final String title;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _CircleButton(
              icon: CupertinoIcons.xmark,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: DiaryV2Styles.title(context).copyWith(
            fontSize: 30,
            color: DiaryV2Styles.textStrong,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          dateLabel,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: DiaryV2Styles.mutedTextStrong,
                height: 1.2,
              ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.count,
    required this.isSpanish,
  });

  final int count;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: DiaryV2Styles.accentSoftMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              CupertinoIcons.book,
              color: DiaryV2Styles.accentDeep,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSpanish ? '$count entradas guardadas' : '$count saved entries',
                  style: DiaryV2Styles.title(context).copyWith(
                    fontSize: 17,
                    color: DiaryV2Styles.textStrong,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSpanish
                      ? 'Momentos registrados hoy'
                      : 'Moments recorded today',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DiaryV2Styles.mutedTextStrong,
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.isSpanish});

  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: DiaryV2Styles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSpanish ? 'No hay entradas para este día' : 'No entries for this day',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: DiaryV2Styles.textStrong,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isSpanish
                ? 'Cuando escribas, tus momentos aparecerán aquí.'
                : 'When you write, your moments will appear here.',
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
            width: 50,
            height: 50,
            child: Icon(
              icon,
              color: DiaryV2Styles.textStrong,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayEntryCard extends StatelessWidget {
  const _DayEntryCard({
    required this.entry,
    required this.onTap,
  });

  final DiaryV2DayEntryItem entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = entry.displayTitle;
    final body = entry.displayBody;
    final chips = entry.metadataChips(Localizations.localeOf(context));

    return Container(
      decoration: BoxDecoration(
        color: DiaryV2Styles.cream.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: DiaryV2Styles.border.withValues(alpha: 0.9)),
        boxShadow: const [
          BoxShadow(
            color: DiaryV2Styles.shadowWarm,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        entry.timeLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: DiaryV2Styles.textStrong,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (entry.mood != null) ...[
                      _MoodBadge(mood: entry.mood!),
                      const SizedBox(width: 10),
                    ],
                    _SavedBadge(isPinned: entry.isPinned),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DiaryV2Styles.title(context).copyWith(
                    fontSize: 17,
                    color: DiaryV2Styles.textStrong,
                  ),
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: DiaryV2Styles.textStrong,
                          height: 1.35,
                        ),
                  ),
                ],
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chips
                        .map((chip) => _MetadataChip(label: chip))
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

class _MoodBadge extends StatelessWidget {
  const _MoodBadge({required this.mood});

  final int mood;

  @override
  Widget build(BuildContext context) {
    final emoji = DiaryMoodVisuals.emojiFor(mood);
    final borderColor = DiaryMoodVisuals.borderColorFor(mood);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: DiaryMoodVisuals.fillColorFor(mood),
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor.withValues(alpha: 0.45),
        ),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: mood == 0 ? 19 : 16,
            height: 1,
            color: borderColor,
            fontWeight: mood == 0 ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SavedBadge extends StatelessWidget {
  const _SavedBadge({required this.isPinned});

  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isPinned
            ? DiaryV2Styles.accentSoftMuted
            : Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        isPinned ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
        color: isPinned ? DiaryV2Styles.accentDeep : DiaryV2Styles.textStrong,
        size: 20,
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final accented = label == 'Energía' || label == 'Energy';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accented
            ? DiaryV2Styles.accentSoftMuted
            : DiaryV2Styles.creamStrong.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: accented ? DiaryV2Styles.accentDeep : DiaryV2Styles.sage,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
      ),
    );
  }
}

class DiaryV2DayEntryItem {
  const DiaryV2DayEntryItem({
    required this.entry,
    required this.ui,
    required this.isPinned,
  });

  final DiaryEntry entry;
  final DiaryEntryUi ui;
  final bool isPinned;

  int? get mood => ui.mood;
  String get timeLabel => ui.timeLabel;
  String get text => ui.text;

  String get displayTitle {
    final explicitTitle = _compactText(ui.title ?? '');
    if (explicitTitle.isNotEmpty) {
      return explicitTitle.length <= 32
          ? explicitTitle
          : '${explicitTitle.substring(0, 29).trimRight()}...';
    }

    final sourceText = _compactText(ui.body ?? '');
    final compact = sourceText.isNotEmpty ? sourceText : _compactText(text);
    if (compact.isEmpty) return 'Entrada';
    final firstSentenceMatch = RegExp(r'^[^.!?\n]{1,40}').firstMatch(compact);
    final title = firstSentenceMatch?.group(0)?.trim() ?? compact;
    return title.length <= 32 ? title : '${title.substring(0, 29).trimRight()}...';
  }

  String get displayBody {
    final explicitBody = _compactText(ui.body ?? '');
    final explicitTitle = _compactText(ui.title ?? '');
    if (explicitBody.isNotEmpty) {
      if (explicitTitle.isNotEmpty) return explicitBody;

      final derivedTitle = displayTitle.replaceAll('...', '').trimRight();
      if (derivedTitle.isEmpty) return explicitBody;
      if (explicitBody == derivedTitle) return '';
      if (explicitBody.startsWith(derivedTitle)) {
        return explicitBody.substring(derivedTitle.length).trimLeft();
      }
      return explicitBody;
    }

    final compact = _compactText(text);
    if (compact.isEmpty) return '';
    if (compact == displayTitle) return '';
    if (compact.startsWith(displayTitle)) {
      final rest = compact.substring(displayTitle.length).trimLeft();
      return rest;
    }
    return compact;
  }

  List<String> metadataChips(Locale locale) {
    final chips = <String>[];
    chips.addAll(diaryTagLabels(entry.tags, locale, maxVisible: 2));
    if (mood != null) {
      chips.add(DiaryMoodVisuals.labelForLocale(mood!, locale));
    }
    if ((ui.familyName ?? '').trim().isNotEmpty) {
      chips.add(ui.familyName!.trim());
    } else if ((ui.habitName ?? '').trim().isNotEmpty) {
      chips.add(ui.habitName!.trim());
    }
    return chips.take(3).toList(growable: false);
  }

  static String _compactText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

List<DiaryV2DayEntryItem> diaryV2DayEntryItemsForDate({
  required List<DiaryEntry> entries,
  required DateTime selectedDay,
}) {
  return entries
      .where(
        (entry) => DateUtils.isSameDay(
          DateTime.fromMillisecondsSinceEpoch(entry.createdAt),
          selectedDay,
        ),
      )
      .map(
        (entry) => DiaryV2DayEntryItem(
          entry: entry,
          ui: _toUi(entry),
          isPinned: entry.isPinned,
        ),
      )
      .toList(growable: false)
    ..sort((a, b) => b.ui.createdAt.compareTo(a.ui.createdAt));
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
