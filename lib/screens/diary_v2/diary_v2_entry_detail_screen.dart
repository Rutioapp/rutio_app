import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/screens/diary/widgets/diary_screen_background.dart';
import 'package:rutio/stores/user_state_store.dart';

import 'diary_v2_entry_editor_screen.dart';
import 'diary_v2_mood_visuals.dart';
import 'diary_v2_tags.dart';
import 'widgets/diary_v2_styles.dart';

Future<void> openDiaryV2EntryDetail(
  BuildContext context, {
  required DiaryEntry entry,
}) {
  return Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) => DiaryV2EntryDetailScreen(entry: entry),
    ),
  );
}

class DiaryV2EntryDetailScreen extends StatefulWidget {
  const DiaryV2EntryDetailScreen({
    super.key,
    required this.entry,
  });

  final DiaryEntry entry;

  @override
  State<DiaryV2EntryDetailScreen> createState() =>
      _DiaryV2EntryDetailScreenState();
}

class _DiaryV2EntryDetailScreenState extends State<DiaryV2EntryDetailScreen> {
  bool _didSchedulePop = false;

  Future<void> _openEditor(DiaryEntry entry) async {
    await openDiaryV2EntryEditor(
      context,
      editing: entry,
    );
  }

  void _popIfDeleted() {
    if (_didSchedulePop || !mounted) return;
    _didSchedulePop = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final store = context.watch<UserStateStore?>();
    final currentEntry = store == null
        ? widget.entry
        : store.diaryEntries
            .where((entry) => entry.id == widget.entry.id)
            .cast<DiaryEntry?>()
            .firstWhere((entry) => entry != null, orElse: () => null);

    if (currentEntry == null) {
      _popIfDeleted();
      return const SizedBox.shrink();
    }

    final copy = _DiaryV2EntryDetailCopy.from(locale);
    final title = _displayTitle(currentEntry, copy.fallbackTitle);
    final body = _displayBody(currentEntry);
    final dateLabel = _formatDateTimeLabel(
      DateTime.fromMillisecondsSinceEpoch(currentEntry.createdAt),
      locale.toLanguageTag(),
    );
    final tagLabels = diaryTagLabels(currentEntry.tags, locale);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DiaryScreenBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(14, 10, 14, bottomPadding + 28),
            children: [
              _DetailHeader(
                editLabel: context.l10n.diaryActionEdit,
                onClose: () => Navigator.of(context).maybePop(),
                onEdit: () => _openEditor(currentEntry),
              ),
              const SizedBox(height: 18),
              _MetaStrip(dateLabel: dateLabel),
              const SizedBox(height: 12),
              _TitleCard(title: title),
              const SizedBox(height: 12),
              _SignalsCard(
                mood: currentEntry.mood,
                moodLabel:
                    currentEntry.mood == null
                        ? null
                        : DiaryMoodVisuals.labelForLocale(
                            currentEntry.mood!,
                            locale,
                          ),
                tags: tagLabels,
                isPinned: currentEntry.isPinned,
              ),
              const SizedBox(height: 12),
              _BodyCard(
                title: copy.bodySectionTitle,
                body: body.isEmpty ? copy.emptyBody : body,
                isPlaceholder: body.isEmpty,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiaryV2EntryDetailCopy {
  const _DiaryV2EntryDetailCopy({
    required this.fallbackTitle,
    required this.emptyBody,
    required this.bodySectionTitle,
    required this.savedLabel,
  });

  factory _DiaryV2EntryDetailCopy.from(Locale locale) {
    final isSpanish = locale.languageCode == 'es';
    return _DiaryV2EntryDetailCopy(
      fallbackTitle: isSpanish ? 'Entrada' : 'Entry',
      emptyBody: isSpanish ? 'Sin contenido' : 'No content',
      bodySectionTitle: isSpanish ? 'Tu entrada' : 'Your entry',
      savedLabel: isSpanish ? 'Guardada' : 'Saved',
    );
  }

  final String fallbackTitle;
  final String emptyBody;
  final String bodySectionTitle;
  final String savedLabel;
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.editLabel,
    required this.onClose,
    required this.onEdit,
  });

  final String editLabel;
  final VoidCallback onClose;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          _CircleButton(
            icon: CupertinoIcons.back,
            onTap: onClose,
          ),
          const Spacer(),
          _EditPill(
            label: editLabel,
            onTap: onEdit,
          ),
        ],
      ),
    );
  }
}

class _MetaStrip extends StatelessWidget {
  const _MetaStrip({required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: DiaryV2Styles.compactCardDecoration(),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.time,
            size: 16,
            color: DiaryV2Styles.accentDeep,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dateLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DiaryV2Styles.textStrong,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.2,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleCard extends StatelessWidget {
  const _TitleCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: DiaryV2Styles.cardDecoration(),
      child: Text(
        title,
        style: DiaryV2Styles.title(context).copyWith(
          fontSize: 23,
          fontWeight: FontWeight.w600,
          color: DiaryV2Styles.textStrong,
          height: 1.16,
        ),
      ),
    );
  }
}

class _SignalsCard extends StatelessWidget {
  const _SignalsCard({
    required this.mood,
    required this.moodLabel,
    required this.tags,
    required this.isPinned,
  });

  final int? mood;
  final String? moodLabel;
  final List<String> tags;
  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    if (mood == null && tags.isEmpty && !isPinned) {
      return const SizedBox.shrink();
    }

    final copy = _DiaryV2EntryDetailCopy.from(Localizations.localeOf(context));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: DiaryV2Styles.compactCardDecoration(),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (mood != null && moodLabel != null)
            _Badge(
              label: moodLabel!,
              emoji: DiaryMoodVisuals.emojiFor(mood!),
              fillColor: DiaryMoodVisuals.fillColorFor(mood!),
              borderColor: DiaryMoodVisuals.borderColorFor(mood!),
              textColor: DiaryV2Styles.textStrong,
            ),
          for (final tag in tags)
            _Badge(
              label: tag,
              fillColor: DiaryV2Styles.creamStrong.withValues(alpha: 0.96),
              borderColor: DiaryV2Styles.border.withValues(alpha: 0.88),
              textColor: DiaryV2Styles.mutedTextStrong,
            ),
          if (isPinned)
            _Badge(
              label: copy.savedLabel,
              icon: CupertinoIcons.bookmark_fill,
              fillColor: DiaryV2Styles.accentSoftMuted,
              borderColor: DiaryV2Styles.accent.withValues(alpha: 0.2),
              textColor: DiaryV2Styles.accentDeep,
            ),
        ],
      ),
    );
  }
}

class _BodyCard extends StatelessWidget {
  const _BodyCard({
    required this.title,
    required this.body,
    required this.isPlaceholder,
  });

  final String title;
  final String body;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: DiaryV2Styles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: DiaryV2Styles.mutedTextStrong,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  fontSize: 13,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isPlaceholder
                      ? DiaryV2Styles.mutedTextStrong
                      : DiaryV2Styles.textStrong,
                  fontSize: 15,
                  height: 1.7,
                ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
    this.emoji,
    this.icon,
  });

  final String label;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final String? emoji;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(
              emoji!,
              style: const TextStyle(fontSize: 13, height: 1),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.15,
                ),
          ),
        ],
      ),
    );
  }
}

class _EditPill extends StatelessWidget {
  const _EditPill({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DiaryV2Styles.accentDeep,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
          ),
        ),
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

String _displayTitle(DiaryEntry entry, String fallbackTitle) {
  final title = _compact(entry.textParts.title);
  if (title.isNotEmpty) return title;

  final body = _compact(entry.textParts.body);
  if (body.isNotEmpty) return _truncate(body, 48);

  final text = _compact(entry.legacyText);
  return text.isEmpty ? fallbackTitle : _truncate(text, 48);
}

String _displayBody(DiaryEntry entry) {
  final body = _compactPreservingParagraphs(entry.textParts.body);
  if (body.isNotEmpty) return body;

  final title = _compact(entry.textParts.title);
  final legacy = _compactPreservingParagraphs(entry.legacyText);
  if (legacy.isEmpty || legacy == title) return '';
  if (title.isNotEmpty && legacy.startsWith(title)) {
    return legacy.substring(title.length).trimLeft();
  }
  return legacy;
}

String _formatDateTimeLabel(DateTime date, String localeTag) {
  final pattern = localeTag.startsWith('es')
      ? "EEEE, d 'de' MMMM · HH:mm"
      : 'EEEE, MMMM d · HH:mm';
  final formatted = DateFormat(pattern, localeTag).format(date);
  if (formatted.isEmpty) return formatted;
  return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
}

String _compact(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _compactPreservingParagraphs(String value) {
  final paragraphs = value
      .split(RegExp(r'\n\s*\n'))
      .map((paragraph) => paragraph.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
      .where((paragraph) => paragraph.isNotEmpty)
      .toList(growable: false);
  return paragraphs.join('\n\n').trim();
}

String _truncate(String value, int maxLength) {
  if (value.length <= maxLength) return value;
  return '${value.substring(0, maxLength - 3).trimRight()}...';
}
