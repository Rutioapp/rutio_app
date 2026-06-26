import 'package:flutter/material.dart';

import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/edit_habit_tab/edit_habit_tab_constants.dart';

import 'habit_target_config_components.dart';

/// Resultado del configurador de hábito.
/// - type: 'check' o 'count'
/// - target: num? (solo si type == 'count')
/// - scheduleType: 'daily' | 'weekly' | 'once'
/// - weekdays: `List<int>?` (1..7) si scheduleType == 'weekly'
/// - scheduledDate: String? (YYYY-MM-DD) si scheduleType == 'once'
class HabitTargetConfigResult {
  const HabitTargetConfigResult({
    required this.type,
    this.target,
    required this.scheduleType,
    this.weekdays,
    this.scheduledDate,
  });

  final String type;
  final num? target;
  final String scheduleType;
  final List<int>? weekdays;
  final String? scheduledDate;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'target': target,
        'scheduleType': scheduleType,
        'weekdays': weekdays,
        'scheduledDate': scheduledDate,
      };
}

Future<HabitTargetConfigResult?> showHabitTargetConfigSheet({
  required BuildContext context,
  required Map<String, dynamic> habitDef,
}) {
    return showModalBottomSheet<HabitTargetConfigResult?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacitySafe(0.20),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => HabitTargetConfigSheet(habitDef: habitDef),
  );
}

class HabitTargetConfigSheet extends StatefulWidget {
  const HabitTargetConfigSheet({super.key, required this.habitDef});

  final Map<String, dynamic> habitDef;

  @override
  State<HabitTargetConfigSheet> createState() => _HabitTargetConfigSheetState();
}

class _HabitTargetConfigSheetState extends State<HabitTargetConfigSheet> {
  late final String _rawType;
  late String _mode;
  String _scheduleType = 'daily';
  final Set<int> _weekdays = <int>{1, 2, 3, 4, 5, 6, 7};
  DateTime? _onceDate;
  late num _target;

  @override
  void initState() {
    super.initState();

    _rawType = (widget.habitDef['type'] ?? 'check').toString().toLowerCase();
    _mode = (_rawType == 'count_or_check') ? 'count' : _rawType;

    final num? initialTarget = _readInitialTarget(widget.habitDef);
    _target = initialTarget ?? (_mode == 'check' ? 1 : 10);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name =
        (widget.habitDef['name'] ?? widget.habitDef['id'] ?? '').toString();
    final emoji = _readEmoji(widget.habitDef);
    final canChooseMode = _rawType == 'count_or_check';
    final unit = _readUnit(widget.habitDef);
    final unitLabel = context.l10n.habitUnitLabel((unit ?? '').trim());

    return HabitTargetConfigScaffold(
      bottomCta: HabitTargetConfigPrimaryButton(
        label: l10n.commonAdd,
        onPressed: () {
          final result = _buildResult();
          if (result == null) return;
          Navigator.of(context).pop(result);
        },
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: editHabitCamel.withOpacitySafe(0.24),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            HabitTargetConfigHeader(
              emoji: emoji,
              title: name,
              subtitle: l10n.createHabitHeaderSubtitle,
              onClose: () => Navigator.of(context).pop(null),
            ),
            const SizedBox(height: 16),
            if (canChooseMode) ...[
              HabitTargetConfigSection(
                label: l10n.habitConfigTypeSection,
                caption: _mode == 'check'
                    ? l10n.createHabitTrackingCheckSubtitle
                    : l10n.createHabitTrackingCountSubtitle,
                child: Row(
                  children: [
                    Expanded(
                      child: HabitTargetConfigOptionChip(
                        label: l10n.habitConfigCheckOption,
                        selected: _mode == 'check',
                        onTap: () => setState(() => _mode = 'check'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: HabitTargetConfigOptionChip(
                        label: l10n.habitConfigCounterOption,
                        selected: _mode == 'count',
                        onTap: () => setState(() => _mode = 'count'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_mode == 'count') ...[
              HabitTargetConfigSection(
                label: unitLabel.isEmpty
                    ? l10n.habitConfigGoalSection
                    : l10n.habitConfigGoalSectionWithUnit(unitLabel),
                caption: l10n.createHabitCounterGoalSubtitle,
                child: HabitTargetConfigStepper(
                  value: _formatNum(_target),
                  unitLabel: unitLabel.isEmpty ? 'TOTAL' : unitLabel,
                  onDecrement: () => setState(() {
                    final next = _target - _stepForUnit(unit);
                    _target = next <= 1 ? 1 : next;
                  }),
                  onIncrement: () => setState(
                    () => _target = _target + _stepForUnit(unit),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            HabitTargetConfigSection(
              label: l10n.habitConfigFrequencySection,
              caption: _frequencyCaption(l10n),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      HabitTargetConfigOptionChip(
                        label: l10n.habitConfigDailyOption,
                        selected: _scheduleType == 'daily',
                        onTap: () => setState(() => _scheduleType = 'daily'),
                      ),
                      HabitTargetConfigOptionChip(
                        label: l10n.habitConfigWeeklyOption,
                        selected: _scheduleType == 'weekly',
                        onTap: () => setState(() => _scheduleType = 'weekly'),
                      ),
                      HabitTargetConfigOptionChip(
                        label: l10n.habitConfigOnceOption,
                        selected: _scheduleType == 'once',
                        onTap: () => setState(() => _scheduleType = 'once'),
                      ),
                    ],
                  ),
                  if (_scheduleType == 'weekly') ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List<Widget>.generate(7, (int index) {
                        final day = index + 1;
                        final selected = _weekdays.contains(day);
                        return HabitTargetConfigWeekdayChip(
                          label: l10n.weekdayLetter(day),
                          selected: selected,
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _weekdays.remove(day);
                              } else {
                                _weekdays.add(day);
                              }
                            });
                          },
                        );
                      }),
                    ),
                  ],
                  if (_scheduleType == 'once') ...[
                    const SizedBox(height: 12),
                    HabitTargetConfigDateButton(
                      label: _onceDate == null
                          ? l10n.habitConfigChooseDate
                          : _formatDate(_onceDate!),
                      onPressed: _pickDate,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _onceDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _onceDate = picked);
    }
  }

  int _stepForUnit(String? unit) {
    final normalizedUnit = (unit ?? '').trim().toLowerCase();
    if (normalizedUnit == 'minutes' ||
        normalizedUnit == 'mins' ||
        normalizedUnit == 'min') {
      return 5;
    }
    return 1;
  }

  String _frequencyCaption(dynamic l10n) {
    switch (_scheduleType) {
      case 'weekly':
        return l10n.createHabitFrequencySpecificSubtitle;
      case 'once':
        return l10n.editHabitHeaderSubtitle;
      case 'daily':
      default:
        return l10n.createHabitFrequencyDailySubtitle;
    }
  }

  HabitTargetConfigResult? _buildResult() {
    num? target;
    if (_mode == 'count') {
      target = _target;
      if (target <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.habitConfigInvalidGoal)),
        );
        return null;
      }
    }

    String? scheduledDate;
    List<int>? weekdays;

    if (_scheduleType == 'weekly') {
      final list = _weekdays.toList()..sort();
      if (list.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.habitConfigSelectDay)),
        );
        return null;
      }
      weekdays = list;
    } else if (_scheduleType == 'once') {
      if (_onceDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.habitConfigSelectDate)),
        );
        return null;
      }
      scheduledDate = _formatDate(_onceDate!);
    }

    return HabitTargetConfigResult(
      type: _mode,
      target: target,
      scheduleType: _scheduleType,
      weekdays: weekdays,
      scheduledDate: scheduledDate,
    );
  }
}

num? _readInitialTarget(Map<String, dynamic> habitDef) {
  final t = habitDef['target'];
  final num? fromTarget =
      (t is num) ? t : (t is String ? num.tryParse(t) : null);
  if (fromTarget != null) return fromTarget;

  final metric = habitDef['metric'];
  if (metric is Map) {
    final d = metric['default'];
    final num? fromDefault =
        (d is num) ? d : (d is String ? num.tryParse(d) : null);
    if (fromDefault != null) return fromDefault;
  }
  return null;
}

String? _readUnit(Map<String, dynamic> habitDef) {
  final metric = habitDef['metric'];
  if (metric is Map) {
    final u = metric['unit'];
    if (u != null) return u.toString();
  }
  return null;
}

String _readEmoji(Map<String, dynamic> habitDef) {
  final raw = (habitDef['emoji'] ?? '').toString().trim();
  return raw.isEmpty ? '✦' : raw;
}

String _formatNum(num n) {
  if (n % 1 == 0) return n.toInt().toString();
  return n.toStringAsFixed(1);
}

String _formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
