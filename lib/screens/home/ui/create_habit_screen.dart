import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rutio/services/notification_service.dart';
import 'package:rutio/services/notification_preferences.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/utils/app_theme.dart';
import 'package:rutio/utils/family_theme.dart';
import 'package:rutio/widgets/emoji_picker_bottom_sheet.dart';
import 'package:rutio/screens/habit_detail/widgets/editor/habit_editor_header.dart';
import 'package:rutio/screens/habit_detail/widgets/editor/habit_editor_utils.dart';
import 'package:rutio/screens/habit_detail/widgets/editor/habit_form_visuals.dart';

class CreateHabitScreen extends StatefulWidget {
  const CreateHabitScreen({
    super.key,
    required this.initialFamilyId,
  });

  final String initialFamilyId;

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  static const Color _cream = Color(0xFFF5EDE0);
  static const Color _camel = Color(0xFFB8895A);
  static const Color _dark = Color(0xFF3D2010);
  static const Color _sage = Color(0xFF7A9E7E);

  late final TextEditingController _titleController;
  late final TextEditingController _unitController;
  late final FocusNode _titleFocusNode;

  late String _familyId;
  late String _emoji;
  bool _emojiManuallyEdited = false;
  String _title = '';
  String _trackingType = 'check';
  int _target = 1;
  String _unit = '';
  String _frequencyMode = 'daily';
  final Set<int> _selectedDays = <int>{1, 2, 3, 4, 5, 6, 7};
  bool _reminderEnabled = false;
  late DateTime _reminderTime;
  bool _isSaving = false;
  bool _saveSuccess = false;
  bool _showTitleError = false;
  int _timesPerWeekTarget = 3;

  @override
  void initState() {
    super.initState();

    final List<String> families = _availableFamilies;
    final String fallbackFamilyId =
        families.isNotEmpty ? families.first : FamilyTheme.fallbackId;

    _familyId = families.contains(widget.initialFamilyId)
        ? widget.initialFamilyId
        : fallbackFamilyId;
    _emoji = FamilyTheme.emojiOf(_familyId);
    _reminderTime = DateTime(
      2000,
      1,
      1,
      TimeOfDay.now().hour,
      TimeOfDay.now().minute,
    );

    _titleController = TextEditingController();
    _unitController = TextEditingController();
    _titleFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _unitController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  List<String> get _availableFamilies {
    final dynamic families = _readFamilyThemeFamilies();
    if (families is List) {
      return families.whereType<String>().toList(growable: false);
    }
    return FamilyTheme.order;
  }

  dynamic _readFamilyThemeFamilies() {
    try {
      return (FamilyTheme as dynamic).families;
    } catch (_) {
      return null;
    }
  }

  Color get _familyColor => FamilyTheme.colorOf(_familyId);

  List<String> _suggestedUnits(BuildContext context) =>
      context.l10n.editHabitSuggestedUnits;

  bool get _showsCountTargetSection => _trackingType == 'count';

  bool get _showsWeeklyCheckTargetSection =>
      _trackingType == 'check' && _frequencyMode == 'timesPerWeek';

  Future<void> _pickEmoji() async {
    final String? emoji = await showEmojiPickerBottomSheet(
      context,
      currentEmoji: _emoji,
      accentColor: _familyColor,
    );

    if (!mounted || emoji == null || emoji.trim().isEmpty) {
      return;
    }

    setState(() {
      _emoji = emoji;
      _emojiManuallyEdited = true;
    });
  }

  void _selectFamily(String familyId) {
    setState(() {
      _familyId = familyId;
      if (!_emojiManuallyEdited) {
        _emoji = FamilyTheme.emojiOf(familyId);
      }
    });
  }

  void _setUnit(String value) {
    setState(() {
      _unit = value;
      _unitController.text = value;
    });
  }

  Future<void> _showUnitBottomSheet() async {
    final TextEditingController customController = TextEditingController(
      text: _unit.trim(),
    );
    final l10n = context.l10n;

    final String? selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _camel.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.editHabitUnitPickerTitle,
                style: AppTextStyles.welcomeTitle.copyWith(
                  fontSize: 28,
                  color: _dark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.editHabitUnitPickerSubtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _dark.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedUnits(context).map((String unit) {
                  final bool isSelected = _unit.trim() == unit;
                  return GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(unit),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _camel.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? _camel
                              : _camel.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        unit,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _dark,
                        ),
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: customController,
                autofocus: false,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _dark,
                ),
                decoration: InputDecoration(
                  hintText: l10n.editHabitUnitHint,
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _dark.withValues(alpha: 0.35),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: _camel.withValues(alpha: 0.30)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: _camel.withValues(alpha: 0.80)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: _dark,
                  borderRadius: BorderRadius.circular(16),
                  onPressed: () => Navigator.of(sheetContext)
                      .pop(customController.text.trim()),
                  child: Text(
                    l10n.editHabitUnitPickerAction,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _cream,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    customController.dispose();

    if (!mounted || selected == null) {
      return;
    }

    _setUnit(selected.trim());
  }

  List<int> _resolvedRoutineDaysForSave() {
    if (_frequencyMode != 'specificDays') {
      return <int>[];
    }

    final List<int> ordered = _selectedDays.toList()..sort();
    return ordered;
  }

  int _parsePositiveInt(String raw, {required int fallback}) {
    final int? parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed < 1) {
      return fallback;
    }
    return parsed;
  }

  Future<void> _showNumberInputDialog({
    required String title,
    required int initialValue,
    required ValueChanged<int> onSubmitted,
    String? subtitle,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: initialValue.toString(),
    );
    final l10n = context.l10n;

    await showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _dark,
            ),
          ),
          content: Column(
            children: [
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _dark.withValues(alpha: 0.68),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              CupertinoTextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: _dark,
                ),
                decoration: BoxDecoration(
                  color: _cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _camel.withValues(alpha: 0.24)),
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                l10n.commonCancel,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final int value =
                    _parsePositiveInt(controller.text, fallback: initialValue);
                onSubmitted(value);
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                l10n.commonSave,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> _syncReminderNotification(String _) async {
    final store = context.read<UserStateStore>();
    try {
      if (_reminderEnabled) {
        final result = await NotificationService.instance.requestPermissionFlow();
        if (!result.isAuthorized) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.notificationPermissionMessage(result.status),
              ),
              action: result.shouldOpenSettings
                  ? SnackBarAction(
                      label: context.l10n.commonOpenSettings,
                      onPressed: NotificationService.instance.openSettings,
                    )
                  : null,
            ),
          );
          return;
        }

        final preferences = NotificationPreferences(store);
        final snapshot = preferences.snapshot;
        if (!snapshot.notificationsEnabled) {
          await preferences.setMasterEnabled(true);
        }
        if (!snapshot.habitRemindersEnabled) {
          await preferences.setHabitRemindersEnabled(true);
        }
      }

      await NotificationService.instance.syncPhaseOne(store: store);
    } catch (error) {
      debugPrint('Notification sync error: $error');
    }
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    if (_title.trim().isEmpty) {
      setState(() {
        _showTitleError = true;
      });
      _titleFocusNode.requestFocus();
      return;
    }

    setState(() {
      _showTitleError = false;
      _isSaving = true;
    });

    final List<int> routineDays = _resolvedRoutineDaysForSave();
    final bool isWeeklyCheckGoal = _showsWeeklyCheckTargetSection;
    final String habitId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final String reminderTime = formatHabitTimeForSave(
      TimeOfDay(hour: _reminderTime.hour, minute: _reminderTime.minute),
    );

    final Map<String, dynamic> habit = <String, dynamic>{
      'id': habitId,
      'name': _title.trim(),
      'emoji': _emoji,
      'familyId': _familyId,
      'type': _trackingType,
      'target': _trackingType == 'count' ? _target : 1,
      'unit': _trackingType == 'count' && _unit.trim().isNotEmpty
          ? _unit.trim()
          : null,
      'isCustom': true,
      'reminderEnabled': _reminderEnabled,
      'remindersEnabled': _reminderEnabled,
      'reminderTime': reminderTime,
      if (routineDays.isNotEmpty) 'routineDays': routineDays,
      if (isWeeklyCheckGoal) 'goal': _timesPerWeekTarget,
      if (isWeeklyCheckGoal) 'targetCount': _timesPerWeekTarget,
      if (isWeeklyCheckGoal) 'timesPerWeekTarget': _timesPerWeekTarget,
      if (isWeeklyCheckGoal) 'frequencyMode': _frequencyMode,
    };

    try {
      await context.read<UserStateStore>().addCustomHabit(habit);
      await _syncReminderNotification(habitId);

      if (!mounted) {
        return;
      }

      setState(() {
        _saveSuccess = true;
        _isSaving = false;
      });

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _saveSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String liveTitle = _title.trim().isEmpty
        ? context.l10n.createHabitNewHabitTitle
        : _title.trim();

    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          HabitFormBackground(familyColor: _familyColor),
          SafeArea(
            child: Column(
              children: [
                HabitEditorHeader(
                  title: liveTitle,
                  familyColor: _familyColor,
                  onBack: () => Navigator.maybePop(context),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 1,
                  color: _camel.withValues(alpha: 0.18),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HabitFormSectionLabel(
                            text: context.l10n.editHabitSectionIdentity),
                        _buildIdentitySection(),
                        const SizedBox(height: 28),
                        HabitFormSectionLabel(
                            text: context.l10n.editHabitSectionCategory),
                        _buildCategorySection(),
                        const SizedBox(height: 28),
                        HabitFormSectionLabel(
                            text: context.l10n.editHabitSectionTracking),
                        _buildTrackingTypeSection(),
                        const SizedBox(height: 28),
                        _buildCountSection(),
                        const SizedBox(height: 28),
                        HabitFormSectionLabel(
                            text: context.l10n.editHabitSectionFrequency),
                        _buildFrequencySection(),
                        const SizedBox(height: 28),
                        HabitFormSectionLabel(
                            text: context.l10n.editHabitSectionReminder),
                        _buildReminderSection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomCta(),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    final l10n = context.l10n;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickEmoji,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _camel.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _camel.withValues(alpha: 0.35)),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Text(
                    _emoji,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: _camel,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 9,
                      color: _cream,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                maxLength: 40,
                onChanged: (String value) {
                  setState(() {
                    _title = value;
                    if (_showTitleError && value.trim().isNotEmpty) {
                      _showTitleError = false;
                    }
                  });
                },
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: _dark,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: l10n.editHabitTitleHint,
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: _dark.withValues(alpha: 0.28),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: _showTitleError
                          ? _camel
                          : _camel.withValues(alpha: 0.30),
                      width: _showTitleError ? 1.4 : 1,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: _showTitleError
                          ? _camel
                          : _camel.withValues(alpha: 0.80),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_title.characters.length} / 40',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: _dark.withValues(alpha: 0.28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    final List<String> families = _availableFamilies;
    final l10n = context.l10n;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: families.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 74 / 60,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (BuildContext context, int index) {
        final String familyId = families[index];
        final bool isSelected = familyId == _familyId;
        final Color color = FamilyTheme.colorOf(familyId);

        return GestureDetector(
          onTap: () => _selectFamily(familyId),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.11)
                  : Colors.white.withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? color : _camel.withValues(alpha: 0.12),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    FamilyTheme.emojiOf(familyId),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.familyName(familyId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _dark,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackingTypeSection() {
    final l10n = context.l10n;

    return SizedBox(
      height: 112,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: HabitFormTypeCard(
              title: l10n.editHabitTrackingCheckTitle,
              description: l10n.editHabitTrackingCheckSubtitle,
              icon: Icons.check_rounded,
              accentColor: _sage,
              isSelected: _trackingType == 'check',
              onTap: () => setState(() => _trackingType = 'check'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: HabitFormTypeCard(
              title: l10n.editHabitTrackingCountTitle,
              description: l10n.editHabitTrackingCountSubtitle,
              icon: Icons.loop_rounded,
              accentColor: _camel,
              isSelected: _trackingType == 'count',
              onTap: () => setState(() => _trackingType = 'count'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountSection() {
    final l10n = context.l10n;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: _showsCountTargetSection ? 1 : 0,
        child: _showsCountTargetSection
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HabitFormSectionLabel(text: l10n.editHabitDailyGoalSection),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _camel.withValues(alpha: 0.14)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.editHabitRepetitionsTitle,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _dark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.editHabitRepetitionsSubtitle,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: _dark.withValues(alpha: 0.38),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                HabitFormStepperButton(
                                  icon: Icons.remove_rounded,
                                  onTap: () {
                                    if (_target > 1) {
                                      setState(() => _target -= 1);
                                    }
                                  },
                                ),
                                const SizedBox(width: 10),
                                HabitFormEditableTargetValue(
                                  value: _target,
                                  onTap: () => _showNumberInputDialog(
                                    title: l10n.editHabitDailyGoalDialogTitle,
                                    subtitle:
                                        l10n.editHabitDailyGoalDialogSubtitle,
                                    initialValue: _target,
                                    onSubmitted: (int value) {
                                      if (!mounted) return;
                                      setState(() => _target = value);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                HabitFormStepperButton(
                                  icon: Icons.add_rounded,
                                  onTap: () => setState(() => _target += 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        GestureDetector(
                          onTap: _showUnitBottomSheet,
                          child: AbsorbPointer(
                            child: SizedBox(
                              height: 44,
                              child: TextField(
                                controller: _unitController,
                                readOnly: true,
                                minLines: 1,
                                maxLines: 1,
                                textAlignVertical: TextAlignVertical.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _dark,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: l10n.editHabitUnitHint,
                                  hintStyle: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: _dark.withValues(alpha: 0.28),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  suffixIconConstraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                  suffixIcon: Icon(
                                    Icons.expand_more_rounded,
                                    color: _camel.withValues(alpha: 0.90),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _camel.withValues(alpha: 0.30),
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _camel.withValues(alpha: 0.80),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildFrequencySection() {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            HabitFormFrequencyChip(
              label: l10n.editHabitFrequencyDaily,
              isSelected: _frequencyMode == 'daily',
              onTap: () => setState(() => _frequencyMode = 'daily'),
            ),
            HabitFormFrequencyChip(
              label: l10n.editHabitFrequencySpecificDays,
              isSelected: _frequencyMode == 'specificDays',
              onTap: () => setState(() => _frequencyMode = 'specificDays'),
            ),
            HabitFormFrequencyChip(
              label: l10n.editHabitFrequencyTimesPerWeek,
              isSelected: _frequencyMode == 'timesPerWeek',
              onTap: () => setState(() => _frequencyMode = 'timesPerWeek'),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _frequencyMode == 'specificDays'
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List<Widget>.generate(7, (int index) {
                      final int day = index + 1;
                      final bool isSelected = _selectedDays.contains(day);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected && _selectedDays.length > 1) {
                              _selectedDays.remove(day);
                            } else if (!isSelected) {
                              _selectedDays.add(day);
                            }
                          });
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _camel
                                : Colors.white.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? _camel
                                  : _camel.withValues(alpha: 0.20),
                            ),
                          ),
                          child: Text(
                            l10n.weekdayLetter(day),
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? _cream
                                  : _dark.withValues(alpha: 0.38),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _showsWeeklyCheckTargetSection
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _camel.withValues(alpha: 0.14)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.editHabitWeeklyGoalTitle,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _dark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.editHabitWeeklyGoalSubtitle,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: _dark.withValues(alpha: 0.38),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            HabitFormStepperButton(
                              icon: Icons.remove_rounded,
                              onTap: () {
                                if (_timesPerWeekTarget > 1) {
                                  setState(() => _timesPerWeekTarget -= 1);
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            HabitFormEditableTargetValue(
                              value: _timesPerWeekTarget,
                              onTap: () => _showNumberInputDialog(
                                title: l10n.editHabitTimesPerWeekDialogTitle,
                                subtitle:
                                    l10n.editHabitTimesPerWeekDialogSubtitle,
                                initialValue: _timesPerWeekTarget,
                                onSubmitted: (int value) {
                                  if (!mounted) return;
                                  setState(() => _timesPerWeekTarget = value);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            HabitFormStepperButton(
                              icon: Icons.add_rounded,
                              onTap: () =>
                                  setState(() => _timesPerWeekTarget += 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildReminderSection() {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _camel.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _camel.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  CupertinoIcons.bell_fill,
                  size: 18,
                  color: _camel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.editHabitReminderDailyTitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _dark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.editHabitReminderDailySubtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: _dark.withValues(alpha: 0.42),
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: _reminderEnabled,
                activeTrackColor: _camel,
                onChanged: (bool value) {
                  setState(() => _reminderEnabled = value);
                },
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: _reminderEnabled
              ? Container(
                  margin: const EdgeInsets.only(top: 12),
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _camel.withValues(alpha: 0.14)),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: _reminderTime,
                    use24hFormat: true,
                    onDateTimeChanged: (DateTime value) {
                      setState(() => _reminderTime = value);
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildBottomCta() {
    final bool disabled = _isSaving;
    final Color backgroundColor = _saveSuccess ? _sage : _dark;
    final String label = _saveSuccess
        ? context.l10n.createHabitSaved
        : _isSaving
            ? context.l10n.editHabitSaving
            : context.l10n.createHabitSaveHabit;

    return HabitFormBottomCta(
      label: label,
      onPressed: _save,
      isDisabled: disabled,
      backgroundColor: backgroundColor,
      foregroundColor: _cream,
      baseColor: _cream,
    );
  }
}
