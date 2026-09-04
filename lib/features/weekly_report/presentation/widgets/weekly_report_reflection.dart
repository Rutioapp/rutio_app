import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../models/diary_entry.dart';
import '../../../../screens/diary_v2/diary_v2_mood_visuals.dart';
import '../../../../screens/diary/helpers/diary_screen_actions.dart';
import '../../../../stores/user_state_store.dart';
import '../weekly_report_visuals.dart';

class WeeklyReportReflection extends StatefulWidget {
  const WeeklyReportReflection(
      {super.key, required this.reportId, required this.weekEnd});
  final String reportId;
  final DateTime weekEnd;

  @override
  State<WeeklyReportReflection> createState() => _WeeklyReportReflectionState();
}

class _WeeklyReportReflectionState extends State<WeeklyReportReflection> {
  final _textController = TextEditingController();
  int? _mood;
  bool _editing = false;
  bool _saving = false;
  String? _loadedSignature;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserStateStore>();
    final entry = store.diaryEntries
        .where((e) =>
            e.weeklyReportId == widget.reportId &&
            e.entryType == DiaryEntryContentType.reflection)
        .firstOrNull;
    final signature =
        entry == null ? null : '${entry.id}|${entry.mood}|${entry.legacyText}';
    if (_loadedSignature != signature) {
      _loadedSignature = signature;
      _mood = entry?.mood;
      _textController.text = entry?.legacyText ?? '';
      _editing = entry == null;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: WeeklyReportVisuals.cardDecoration(
          color: WeeklyReportVisuals.reflection,
          borderColor: WeeklyReportVisuals.reflectionBorder),
      child: _editing || entry == null
          ? _Composer(
              mood: _mood,
              controller: _textController,
              saving: _saving,
              onMood: (value) => setState(() => _mood = value),
              onSave: () => _save(context, entry))
          : _Saved(entry: entry, onEdit: () => setState(() => _editing = true)),
    );
  }

  Future<void> _save(BuildContext context, DiaryEntry? existing) async {
    if (_saving) return;
    final store = context.read<UserStateStore>();
    final user = store.activeLocalScopeUserId ?? store.userId;
    final epoch = store.scopeEpoch;
    setState(() => _saving = true);
    final createdAt = DateTime(
            widget.weekEnd.year, widget.weekEnd.month, widget.weekEnd.day, 12)
        .millisecondsSinceEpoch;
    final normalizedText = _textController.text.trim();
    // copyWith treats null as preserve; an empty reflection must clear any
    // legacy title/body values explicitly.
    final entry = existing == null
        ? DiaryEntry(
            id: newDiaryEntryId(),
            createdAt: createdAt,
            text: normalizedText,
            // Diary V2's canonical content field is text. Do not mirror it
            // into body, otherwise legacy/presentation paths can show it twice.
            body: null,
            mood: _mood,
            entryType: DiaryEntryContentType.reflection,
            weeklyReportId: widget.reportId,
          )
        : DiaryEntry(
            id: existing.id,
            createdAt: existing.createdAt,
            dateKey: existing.dateKey,
            text: normalizedText,
            body: null,
            remoteId: existing.remoteId,
            habitId: existing.habitId,
            familyId: existing.familyId,
            mood: _mood,
            entryType: DiaryEntryContentType.reflection,
            weeklyReportId: existing.weeklyReportId,
            tags: existing.tags,
            isPinned: existing.isPinned,
          );
    if ((store.activeLocalScopeUserId ?? store.userId) == user &&
        store.scopeEpoch == epoch) {
      if (existing == null) {
        await store.addDiaryEntry(entry);
      } else {
        await store.updateDiaryEntry(entry);
      }
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editing = false;
    });
  }
}

class _Composer extends StatelessWidget {
  const _Composer(
      {required this.mood,
      required this.controller,
      required this.saving,
      required this.onMood,
      required this.onSave});
  final int? mood;
  final TextEditingController controller;
  final bool saving;
  final ValueChanged<int> onMood;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .56),
              shape: BoxShape.circle),
          child: const Icon(Icons.favorite_border_rounded,
              size: 16, color: Color(0xFF75649B)),
        ),
        const SizedBox(width: 6),
        Text(l10n.weeklyReflectionTitle,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF584477))),
      ]),
      const SizedBox(height: 4),
      Text(l10n.weeklyReflectionQuestion,
          style: const TextStyle(color: WeeklyReportVisuals.mutedText)),
      const SizedBox(height: 4),
      Row(children: [
        for (final value in const [-2, -1, 0, 1, 2])
          Expanded(
              child: Semantics(
                  label: l10n.weeklyReflectionMoodLabel(value),
                  button: true,
                  selected: mood == value,
                  child: InkWell(
                      onTap: () => onMood(value),
                      borderRadius: BorderRadius.circular(22),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: CircleAvatar(
                            radius: 16,
                            backgroundColor: mood == value
                                ? const Color(0xFFE3DCF1)
                                : Colors.white.withValues(alpha: .62),
                            child: Text(DiaryMoodVisuals.emojiFor(value),
                                style: const TextStyle(fontSize: 16))),
                      ))))
      ]),
      const SizedBox(height: 4),
      TextField(
          controller: controller,
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(
              labelText: l10n.weeklyReflectionHint,
              filled: true,
              fillColor: Colors.white.withValues(alpha: .58),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDCD3E9))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDCD3E9))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF9B8ABF))))),
      const SizedBox(height: 4),
      SizedBox(
          height: 44,
          child: FilledButton(
              onPressed: saving ? null : onSave,
              child: Text(saving
                  ? l10n.weeklyReflectionSaving
                  : l10n.weeklyReflectionSave))),
    ]);
  }
}

class _Saved extends StatelessWidget {
  const _Saved({required this.entry, required this.onEdit});
  final DiaryEntry entry;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.favorite_rounded,
              size: 18, color: Color(0xFF75649B)),
          const SizedBox(width: 5),
          Expanded(
              child: Text(context.l10n.weeklyReflectionTitle,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF584477)))),
          TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  visualDensity: VisualDensity.compact),
              child: Text(context.l10n.weeklyReflectionEdit))
        ]),
        if (entry.mood != null)
          Text(DiaryMoodVisuals.emojiFor(entry.mood!),
              style: const TextStyle(fontSize: 20)),
        if (entry.legacyText.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(entry.legacyText)
        ],
      ]);
}
