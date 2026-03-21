import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../stores/user_state_store.dart';
import '../models/diary_types.dart' as dt;

part 'diary_entry_composer_sheet.logic.dart';
part 'diary_entry_composer_sheet.models.dart';
part 'diary_entry_composer_sheet.widgets.dart';

class DiaryEntryComposerSheet extends StatefulWidget {
  const DiaryEntryComposerSheet({
    super.key,
    this.editing,
    this.presetHabitId,
    this.presetHabitName,
    this.presetFamilyName,
    this.presetFamilyColor,
    this.lockHabit = false,
    required this.onSave,
  });

  final dt.DiaryEntryUi? editing;
  final String? presetHabitId;
  final String? presetHabitName;
  final String? presetFamilyName;
  final Color? presetFamilyColor;
  final bool lockHabit;
  final ValueChanged<DiaryEntryComposerDraft> onSave;

  @override
  State<DiaryEntryComposerSheet> createState() =>
      _DiaryEntryComposerSheetState();
}

class _DiaryEntryComposerSheetState extends State<DiaryEntryComposerSheet> {
  late dt.DiaryEntryType _type;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _reflectionCtrl;
  int? _mood;
  String? _habitId;
  String? _habitName;
  String? _familyName;
  Color? _familyColor;

  @override
  void initState() {
    super.initState();

    final initialValues = _DiaryComposerInitialValues.fromWidget(widget);
    _type = initialValues.type;
    _titleCtrl = TextEditingController(text: initialValues.title);
    _reflectionCtrl = TextEditingController(text: initialValues.reflection);
    _mood = initialValues.mood;
    _habitId = initialValues.habitId;
    _habitName = initialValues.habitName;
    _familyName = initialValues.familyName;
    _familyColor = initialValues.familyColor;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _reflectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleHabitPick() async {
    if (widget.lockHabit) return;

    final pick = await _showHabitPickerSheet(context);
    if (!mounted || pick == null) return;

    setState(() {
      _habitId = pick.id;
      _habitName = pick.name;
      _familyName = pick.familyName;
      _familyColor = pick.familyColor;
    });
  }

  void _handleTypeChanged(dt.DiaryEntryType value) {
    setState(() => _type = value);
  }

  void _handleMoodChanged(int? value) {
    setState(() => _mood = value);
  }

  void _save() {
    final draft = _buildDiaryDraft(
      context: context,
      type: _type,
      title: _titleCtrl.text,
      reflection: _reflectionCtrl.text,
      mood: _mood,
      habitId: _habitId,
      habitName: _habitName,
      familyName: _familyName,
      familyColor: _familyColor,
    );

    if (draft == null) return;
    widget.onSave(draft);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return _DiaryComposerContent(
      bottomInset: bottomInset,
      isEditing: widget.editing != null,
      formattedDate: context.l10n
          .diaryComposerDate(widget.editing?.createdAt ?? DateTime.now()),
      lockHabit: widget.lockHabit,
      type: _type,
      habitName: _habitName,
      familyName: _familyName,
      familyColor: _familyColor,
      mood: _mood,
      titleController: _titleCtrl,
      reflectionController: _reflectionCtrl,
      onCancel: () => Navigator.of(context).pop(),
      onTypeChanged: _handleTypeChanged,
      onPickHabit: _handleHabitPick,
      onMoodChanged: _handleMoodChanged,
      onSave: _save,
    );
  }
}
