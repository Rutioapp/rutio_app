import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/screens/diary/helpers/diary_screen_actions.dart';
import 'package:rutio/screens/diary/widgets/diary_screen_background.dart';
import 'package:rutio/stores/user_state_store.dart';

import 'widgets/diary_v2_editor_header.dart';
import 'widgets/diary_v2_editor_mood_selector.dart';
import 'widgets/diary_v2_editor_write_card.dart';
import 'widgets/diary_v2_styles.dart';
import 'widgets/diary_v2_write_button.dart';

Future<void> openDiaryV2EntryEditor(
  BuildContext context, {
  DiaryEntry? editing,
  DateTime? initialDate,
}) {
  return Navigator.of(context).push(
    CupertinoPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => DiaryV2EntryEditorScreen(
        editing: editing,
        initialDate: initialDate,
      ),
    ),
  );
}

class DiaryV2EntryEditorScreen extends StatefulWidget {
  const DiaryV2EntryEditorScreen({
    super.key,
    this.editing,
    this.initialDate,
  });

  final DiaryEntry? editing;
  final DateTime? initialDate;

  @override
  State<DiaryV2EntryEditorScreen> createState() =>
      _DiaryV2EntryEditorScreenState();
}

class _DiaryV2EntryEditorScreenState extends State<DiaryV2EntryEditorScreen> {
  static const _maxCharacters = 5000;

  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final ScrollController _scrollController;
  late final FocusNode _titleFocusNode;
  late final FocusNode _bodyFocusNode;
  late final DateTime _entryDate;
  final GlobalKey _titleFieldKey = GlobalKey();
  final GlobalKey _writeCardKey = GlobalKey();
  int? _selectedMood;
  final Set<String> _selectedTags = <String>{};

  @override
  void initState() {
    super.initState();
    final initialText = widget.editing?.text.trim() ?? '';
    final splitText = _splitInitialText(initialText);
    _scrollController = ScrollController();
    _titleFocusNode = FocusNode()
      ..addListener(() => _handleFocusChanged(_titleFocusNode, _titleFieldKey));
    _bodyFocusNode = FocusNode()
      ..addListener(() => _handleFocusChanged(_bodyFocusNode, _writeCardKey));
    _titleController = TextEditingController(text: splitText.$1)
      ..addListener(_handleTextChanged);
    _bodyController = TextEditingController(text: splitText.$2)
      ..addListener(_handleTextChanged);
    _selectedMood = widget.editing?.mood;
    _entryDate = DateUtils.dateOnly(
      widget.initialDate ??
          (widget.editing != null
              ? DateTime.fromMillisecondsSinceEpoch(widget.editing!.createdAt)
              : DateTime.now()),
    );
  }

  @override
  void dispose() {
    _titleFocusNode.dispose();
    _bodyFocusNode.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _handleFocusChanged(FocusNode focusNode, GlobalKey targetKey) {
    if (!focusNode.hasFocus || !mounted) return;
    _scrollFocusedFieldIntoView(targetKey);
  }

  void _scrollFocusedFieldIntoView(GlobalKey targetKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final targetContext = targetKey.currentContext;
      if (targetContext == null) return;

      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.12,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _handleTextChanged() {
    if (!mounted) return;
    final body = _bodyController.text;
    if (body.characters.length <= _maxCharacters) {
      setState(() {});
      return;
    }

    final truncated = body.characters.take(_maxCharacters).toString();
    _bodyController.value = TextEditingValue(
      text: truncated,
      selection: TextSelection.collapsed(offset: truncated.length),
    );
    setState(() {});
  }

  Future<void> _save() async {
    final text = _composeDiaryText(
      title: _titleController.text,
      body: _bodyController.text,
    );
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_copy(context).writeSomethingError)),
      );
      return;
    }

    final store = context.read<UserStateStore>();
    final existing = widget.editing;
    final sourceDate = existing != null
        ? DateTime.fromMillisecondsSinceEpoch(existing.createdAt)
        : _entryDate;
    final createdAt = DateTime(
      sourceDate.year,
      sourceDate.month,
      sourceDate.day,
      existing != null ? sourceDate.hour : DateTime.now().hour,
      existing != null ? sourceDate.minute : DateTime.now().minute,
      existing != null ? sourceDate.second : DateTime.now().second,
      existing != null
          ? sourceDate.millisecond
          : DateTime.now().millisecond,
    );

    final entry = DiaryEntry(
      id: existing?.id ?? newDiaryEntryId(),
      createdAt: createdAt.millisecondsSinceEpoch,
      text: text,
      remoteId: existing?.remoteId,
      habitId: existing?.habitId,
      familyId: existing?.familyId,
      mood: _selectedMood,
      isPinned: existing?.isPinned ?? false,
    );

    if (existing == null) {
      await store.addDiaryEntry(entry);
    } else {
      await store.updateDiaryEntry(entry);
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text(_copy(context).savedMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = _copy(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final bodyCount = _bodyController.text.characters.length;
    final contentBottomPadding = bottomInset > 0
        ? bottomInset + 24
        : bottomPadding + 28;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: DiaryScreenBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(14, 10, 14, contentBottomPadding),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DiaryV2EditorHeader(
                        title: copy.screenTitle,
                        saveLabel: copy.topSaveLabel,
                        onClose: () => Navigator.of(context).maybePop(),
                        onSave: _save,
                      ),
                      const SizedBox(height: 16),
                      _DateStatusCard(
                        dateLabel: _formatDateLabel(_entryDate, copy.localeTag),
                        statusLabel: copy.autoSaveLabel,
                      ),
                      const SizedBox(height: 12),
                      DiaryV2EditorMoodSelector(
                        title: copy.moodTitle,
                        selectedMood: _selectedMood,
                        onMoodSelected: (value) {
                          setState(() => _selectedMood = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _TitleField(
                        key: _titleFieldKey,
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        hintText: copy.titleHint,
                      ),
                      const SizedBox(height: 12),
                      DiaryV2EditorWriteCard(
                        key: _writeCardKey,
                        title: copy.promptTitle,
                        controller: _bodyController,
                        focusNode: _bodyFocusNode,
                        currentLength: bodyCount,
                        maxLength: _maxCharacters,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        copy.tagsLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: DiaryV2Styles.textStrong,
                              fontWeight: FontWeight.w500,
                              fontSize: 17,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: copy.tags
                            .map(
                              (tag) => _SelectableTagChip(
                                label: tag,
                                selected: _selectedTags.contains(tag),
                                onTap: () {
                                  setState(() {
                                    if (_selectedTags.contains(tag)) {
                                      _selectedTags.remove(tag);
                                    } else {
                                      _selectedTags.add(tag);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(growable: false),
                      ),
                      SizedBox(height: bodyCount > 0 ? 22 : 18),
                      Center(
                        child: DiaryV2WriteButton(
                          label: copy.bottomSaveLabel,
                          onPressed: _save,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DateStatusCard extends StatelessWidget {
  const _DateStatusCard({
    required this.dateLabel,
    required this.statusLabel,
  });

  final String dateLabel;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      decoration: DiaryV2Styles.compactCardDecoration(),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.calendar,
            color: DiaryV2Styles.accentDeep,
            size: 16,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              dateLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: DiaryV2Styles.textStrong,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    height: 1.15,
                  ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.check_mark_circled,
                  color: DiaryV2Styles.mutedTextStrong,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    statusLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DiaryV2Styles.mutedTextStrong
                              .withValues(alpha: 0.78),
                          fontSize: 11.5,
                          height: 1.15,
                        ),
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

class _TitleField extends StatelessWidget {
  const _TitleField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DiaryV2Styles.compactCardDecoration(),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        scrollPadding: const EdgeInsets.fromLTRB(0, 24, 0, 120),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: DiaryV2Styles.textStrong,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: DiaryV2Styles.mutedText,
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        ),
      ),
    );
  }
}

class _SelectableTagChip extends StatelessWidget {
  const _SelectableTagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? DiaryV2Styles.accentSoftMuted
                : Colors.white.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? DiaryV2Styles.accent.withValues(alpha: 0.4)
                  : DiaryV2Styles.border.withValues(alpha: 0.72),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected
                      ? DiaryV2Styles.accentDeep
                      : DiaryV2Styles.mutedTextStrong,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
          ),
        ),
      ),
    );
  }
}

class _DiaryV2EditorCopy {
  const _DiaryV2EditorCopy.spanish()
      : localeTag = 'es',
        screenTitle = 'Nueva entrada',
        topSaveLabel = 'Guardar',
        autoSaveLabel = 'Guardado autom\u00e1tico',
        moodTitle = '\u00bfC\u00f3mo te sientes hoy?',
        titleHint = 'T\u00edtulo opcional',
        promptTitle = '\u00bfQu\u00e9 quieres recordar de hoy?',
        tagsLabel = 'Etiquetas (opcional)',
        tags = const ['Gratitud', 'Energ\u00eda', 'Foco', 'Sue\u00f1o', 'Ideas'],
        bottomSaveLabel = 'Guardar entrada',
        savedMessage = 'Entrada guardada',
        writeSomethingError = 'Escribe algo antes de guardar.';

  const _DiaryV2EditorCopy.english()
      : localeTag = 'en',
        screenTitle = 'New entry',
        topSaveLabel = 'Save',
        autoSaveLabel = 'Autosaved',
        moodTitle = 'How do you feel today?',
        titleHint = 'Optional title',
        promptTitle = 'What would you like to remember today?',
        tagsLabel = 'Tags (optional)',
        tags = const ['Gratitude', 'Energy', 'Focus', 'Sleep', 'Ideas'],
        bottomSaveLabel = 'Save entry',
        savedMessage = 'Entry saved',
        writeSomethingError = 'Write something before saving.';

  final String localeTag;
  final String screenTitle;
  final String topSaveLabel;
  final String autoSaveLabel;
  final String moodTitle;
  final String titleHint;
  final String promptTitle;
  final String tagsLabel;
  final List<String> tags;
  final String bottomSaveLabel;
  final String savedMessage;
  final String writeSomethingError;
}

_DiaryV2EditorCopy _copy(BuildContext context) {
  final locale = Localizations.localeOf(context);
  return locale.languageCode == 'es'
      ? const _DiaryV2EditorCopy.spanish()
      : const _DiaryV2EditorCopy.english();
}

(String, String) _splitInitialText(String value) {
  if (value.isEmpty) return ('', '');

  final parts = value.split(RegExp(r'\n\s*\n'));
  if (parts.length >= 2) {
    return (parts.first.trim(), parts.sublist(1).join('\n\n').trim());
  }

  return ('', value);
}

String _composeDiaryText({
  required String title,
  required String body,
}) {
  final trimmedTitle = title.trim();
  final trimmedBody = body.trim();

  return [
    if (trimmedTitle.isNotEmpty) trimmedTitle,
    if (trimmedBody.isNotEmpty) trimmedBody,
  ].join('\n\n').trim();
}

String _formatDateLabel(DateTime date, String localeTag) {
  final pattern = localeTag.startsWith('es')
      ? "EEEE, d 'de' MMMM"
      : 'EEEE, MMMM d';
  final formatted = DateFormat(pattern, localeTag).format(date);
  if (formatted.isEmpty) return formatted;
  return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
}
