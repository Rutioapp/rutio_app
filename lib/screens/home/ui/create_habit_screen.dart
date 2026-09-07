import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rutio/features/notifications/application/notification_permission_controller.dart';
import 'package:rutio/features/notifications/domain/notification_permission_status.dart';
import 'package:rutio/features/notifications/presentation/notification_permission_recovery_sheet.dart';
import 'package:rutio/services/notification_service.dart';
import 'package:rutio/services/notification_preferences.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/utils/app_theme.dart';
import 'package:rutio/utils/family_theme.dart';
import 'package:rutio/widgets/emoji_picker_bottom_sheet.dart';
import 'package:rutio/screens/habit_detail/widgets/editor/habit_editor_utils.dart';
import 'package:rutio/screens/habit_detail/widgets/editor/habit_form_visuals.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/edit_habit_tab/edit_habit_tab_sections.dart';

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
  int _counterStep = 1;
  String _frequencyMode = 'daily';
  final Set<int> _selectedDays = <int>{1, 2, 3, 4, 5, 6, 7};
  bool _reminderEnabled = false;
  late DateTime _reminderTime;
  bool _isSaving = false;
  bool _saveSuccess = false;
  bool _showTitleError = false;
  int _timesPerWeekTarget = 3;

  static const int _defaultWeekStartsOn = 1;

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

  void _selectTrackingType(String trackingType) {
    setState(() {
      _trackingType = trackingType;
      if (_trackingType == 'count' && _frequencyMode == 'timesPerWeek') {
        _frequencyMode = 'daily';
      }
    });
  }

  Future<void> _pickEmoji() async {
    final String? emoji = await showEmojiPickerBottomSheet(
      context,
      currentEmoji: _emoji,
      currentHabitName: _titleController.text,
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

  Future<void> _editTarget() async {
    await _showNumberInputDialog(
      title: context.l10n.createHabitCounterTargetAmountLabel,
      initialValue: _target,
      onSubmitted: (int value) => setState(() => _target = value),
    );
  }

  Future<void> _openUnitSelector() => _showUnitBottomSheet();

  void _selectQuickUnit(String value) => _setUnit(value);

  Future<void> _editStep() async {
    await _showNumberInputDialog(
      title: context.l10n.editHabitCounterStepDialogTitle,
      subtitle: context.l10n.editHabitCounterStepDialogSubtitle,
      initialValue: _counterStep,
      onSubmitted: (int value) => setState(() => _counterStep = value),
    );
  }

  Future<void> _showUnitBottomSheet() async {
    String customValue = _unit.trim();
    final l10n = context.l10n;

    final String? selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) {
        final double keyboardInset =
            MediaQuery.of(sheetContext).viewInsets.bottom;

        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
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
                  TextFormField(
                    autofocus: true,
                    initialValue: customValue,
                    onChanged: (String value) => customValue = value,
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
                      onPressed: () =>
                          Navigator.of(sheetContext).pop(customValue.trim()),
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
            ),
          ),
        );
      },
    );

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
        final permissionController = NotificationPermissionController();
        await permissionController.markPostLoginPromptShown();
        final canSchedule =
            await permissionController.ensureCanScheduleFromReminderFlow();
        if (!canSchedule) {
          final effectiveStatus =
              await permissionController.getEffectiveStatus();
          final shouldShowPermissionSnack = effectiveStatus ==
                  NotificationPermissionStatus.denied ||
              effectiveStatus == NotificationPermissionStatus.permanentlyDenied;
          if (!shouldShowPermissionSnack || !mounted) {
            return;
          }

          final result =
              await NotificationService.instance.checkPermissionStatus();
          if (!mounted) return;
          await showNotificationPermissionRecoverySheet(
            context,
            controller: permissionController,
            permissionResult: result,
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
    final Map<String, dynamic> schedule = isWeeklyCheckGoal
        ? <String, dynamic>{
            'type': 'timesPerWeek',
            'timesPerWeek': _timesPerWeekTarget,
            'weekStartsOn': _defaultWeekStartsOn,
          }
        : routineDays.isEmpty || routineDays.length == 7
            ? <String, dynamic>{'type': 'daily'}
            : <String, dynamic>{
                'type': 'weekly',
                'weekdays': routineDays,
              };
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
      'schedule': schedule,
      if (routineDays.isNotEmpty) 'routineDays': routineDays,
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
    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          HabitFormBackground(familyColor: _familyColor),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildIdentitySection(),
                  const SizedBox(height: 14),
                  _buildCategorySection(),
                  const SizedBox(height: 14),
                  _buildTrackingTypeSection(),
                  const SizedBox(height: 14),
                  _buildCountSection(),
                  if (_showsCountTargetSection) ...[
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 14),
                  _buildFrequencySection(),
                  const SizedBox(height: 12),
                  _buildRoutineSection(),
                  const SizedBox(height: 12),
                  _buildReminderSection(),
                ],
              ),
            ),
          ),
          _buildBottomCta(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = context.l10n;

    return Row(
      children: [
        _HeaderRoundButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.maybePop(context),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.createHabitNewHabitTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.authTitle.copyWith(
                  fontSize: 42,
                  height: 0.9,
                  color: _dark,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                l10n.createHabitHeaderSubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  color: _dark.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        const _HeaderRoundButton(
          icon: CupertinoIcons.ellipsis,
          onTap: null,
        ),
      ],
    );
  }

  Widget _buildIdentitySection() {
    return EditHabitIdentitySection(
      titleController: _titleController,
      titleFocusNode: _titleFocusNode,
      emoji: _emoji,
      showTitleError: _showTitleError,
      onPickEmoji: _pickEmoji,
      onTitleChanged: (String value) {
        setState(() {
          _title = value;
          if (_showTitleError && value.trim().isNotEmpty) {
            _showTitleError = false;
          }
        });
      },
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HabitFormSectionLabel(text: context.l10n.createHabitSectionCategory),
        EditHabitCategorySection(
          families: _availableFamilies,
          selectedFamilyId: _familyId,
          onSelectFamily: _selectFamily,
        ),
      ],
    );
  }

  Widget _buildTrackingTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HabitFormSectionLabel(text: context.l10n.createHabitSectionTracking),
        EditHabitTrackingTypeSection(
          trackingType: _trackingType,
          onSelectCheck: () => _selectTrackingType('check'),
          onSelectCount: () => _selectTrackingType('count'),
        ),
      ],
    );
  }

  Widget _buildCountSection() {
    return EditHabitCountSection(
      isVisible: _showsCountTargetSection,
      targetCount: _target,
      unitController: _unitController,
      counterStep: _counterStep,
      onDecrementTarget: () {
        setState(() {
          _target = (_target - _counterStep).clamp(1, 999999);
        });
      },
      onIncrementTarget: () {
        setState(() => _target += _counterStep);
      },
      onEditTarget: _editTarget,
      onOpenUnitSelector: _openUnitSelector,
      onSelectQuickUnit: _selectQuickUnit,
      onDecrementStep: () {
        setState(() {
          _counterStep = (_counterStep - 1).clamp(1, 999999);
        });
      },
      onIncrementStep: () {
        setState(() => _counterStep += 1);
      },
      onEditStep: _editStep,
    );
  }

  Widget _buildFrequencySection() {
    return EditHabitFrequencySection(
      trackingType: _trackingType,
      frequencyMode: _frequencyMode,
      selectedDays: _selectedDays,
      timesPerWeekTarget: _timesPerWeekTarget,
      showsWeeklyCheckTargetSection: _showsWeeklyCheckTargetSection,
      onSelectFrequencyMode: (String id) {
        setState(() => _frequencyMode = id);
      },
      onToggleSelectedDay: (int day) {
        setState(() {
          if (_selectedDays.contains(day)) {
            if (_selectedDays.length > 1) {
              _selectedDays.remove(day);
            }
          } else {
            _selectedDays.add(day);
          }
        });
      },
      onDecrementTimesPerWeek: () {
        if (_timesPerWeekTarget > 1) {
          setState(() => _timesPerWeekTarget -= 1);
        }
      },
      onIncrementTimesPerWeek: () {
        setState(() => _timesPerWeekTarget += 1);
      },
      onEditTimesPerWeek: () {
        final l10n = context.l10n;
        _showNumberInputDialog(
          title: l10n.editHabitTimesPerWeekDialogTitle,
          subtitle: l10n.editHabitTimesPerWeekDialogSubtitle,
          initialValue: _timesPerWeekTarget,
          onSubmitted: (int value) {
            if (!mounted) return;
            setState(() => _timesPerWeekTarget = value);
          },
        );
      },
    );
  }

  Widget _buildRoutineSection() {
    final l10n = context.l10n;

    return GestureDetector(
      onTap: _showRoutineSheet,
      child: _SurfaceCard(
        borderColor: _camel.withValues(alpha: 0.25),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _camel.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.briefcase_fill,
                size: 17,
                color: _camel.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l10n.createHabitRoutineTitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _dark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(999),
                          border:
                              Border.all(color: _camel.withValues(alpha: 0.22)),
                        ),
                        child: Text(
                          l10n.createHabitOptionalPill,
                          style: GoogleFonts.dmSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: _dark.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.createHabitRoutineSubtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _dark.withValues(alpha: 0.52),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _camel.withValues(alpha: 0.40),
                  style: BorderStyle.solid,
                ),
              ),
              child: Text(
                l10n.createHabitComingSoon,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _camel.withValues(alpha: 0.95),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: _dark.withValues(alpha: 0.42),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSection() {
    final l10n = context.l10n;
    final String timeText = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: _reminderTime.hour, minute: _reminderTime.minute),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat ||
          Localizations.localeOf(context).languageCode == 'es',
    );

    return GestureDetector(
      onTap: _showReminderTimeSheet,
      child: _SurfaceCard(
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _camel.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.bell_fill,
                size: 17,
                color: _camel.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.createHabitReminderTitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _reminderEnabled
                        ? l10n.createHabitReminderEnabledSubtitle
                        : l10n.createHabitReminderDisabledSubtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _dark.withValues(alpha: 0.55),
                    ),
                  ),
                  if (_reminderEnabled) ...[
                    const SizedBox(height: 2),
                    Text(
                      timeText,
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: _dark.withValues(alpha: 0.90),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            CupertinoSwitch(
              value: _reminderEnabled,
              activeTrackColor: _sage,
              onChanged: (bool value) {
                setState(() => _reminderEnabled = value);
                if (value) {
                  _showReminderTimeSheet();
                }
              },
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: _dark.withValues(alpha: 0.42),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReminderTimeSheet() async {
    if (!_reminderEnabled) {
      return;
    }
    final l10n = context.l10n;
    DateTime selected = _reminderTime;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        final double safeBottom = MediaQuery.of(sheetContext).padding.bottom;

        return Container(
          decoration: const BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 292 + (safeBottom > 10 ? 10 : safeBottom),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Container(
                    width: 34,
                    height: 3,
                    decoration: BoxDecoration(
                      color: _camel.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: Text(
                            l10n.commonCancel,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _sage,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            l10n.createHabitReminderTimeTitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: _dark,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          onPressed: () {
                            setState(() => _reminderTime = selected);
                            Navigator.of(sheetContext).pop();
                          },
                          child: Text(
                            l10n.createHabitDone,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _sage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 0.9,
                    color: _camel.withValues(alpha: 0.14),
                  ),
                  Expanded(
                    child: Transform.scale(
                      scale: 1.07,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        itemExtent: 36,
                        initialDateTime: _reminderTime,
                        use24hFormat:
                            MediaQuery.of(context).alwaysUse24HourFormat ||
                                Localizations.localeOf(context).languageCode ==
                                    'es',
                        onDateTimeChanged: (DateTime value) {
                          selected = value;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRoutineSheet() async {
    final l10n = context.l10n;
    final List<_RoutinePreviewOption> options = <_RoutinePreviewOption>[
      _RoutinePreviewOption(
        emoji: '??',
        title: l10n.createHabitRoutineMorningTitle,
        subtitle: l10n.createHabitRoutineMorningSubtitle,
      ),
      _RoutinePreviewOption(
        emoji: '??',
        title: l10n.createHabitRoutineDeepFocusTitle,
        subtitle: l10n.createHabitRoutineDeepFocusSubtitle,
      ),
      _RoutinePreviewOption(
        emoji: '??',
        title: l10n.createHabitRoutineEveningTitle,
        subtitle: l10n.createHabitRoutineEveningSubtitle,
      ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _camel.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.createHabitRoutineTitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.createHabitRoutineSheetSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: _dark.withValues(alpha: 0.56),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...options.map(
                    (_RoutinePreviewOption option) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => Navigator.of(sheetContext).pop(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.62),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _camel.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _camel.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  option.emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.title,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _dark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      option.subtitle,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w400,
                                        color: _dark.withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: _camel.withValues(alpha: 0.26),
                                  ),
                                ),
                                child: Text(
                                  l10n.createHabitRoutineSoon,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: _camel.withValues(alpha: 0.95),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _camel.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: _camel.withValues(alpha: 0.95),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.createHabitRoutineCreateNew,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _dark.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  CupertinoButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(
                      l10n.createHabitRoutineNotNow,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _dark.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _cream.withValues(alpha: 0),
                  _cream,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(16),
                color: backgroundColor,
                onPressed: disabled ? null : _save,
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _cream,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.borderColor,
  });

  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor ?? const Color(0xFFB8895A).withValues(alpha: 0.16),
        ),
      ),
      child: child,
    );
  }
}

class _HeaderRoundButton extends StatelessWidget {
  const _HeaderRoundButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.56),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFB8895A).withValues(alpha: 0.24),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF3D2010)
                  .withValues(alpha: onTap == null ? 0.35 : 0.85),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutinePreviewOption {
  const _RoutinePreviewOption({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;
}
