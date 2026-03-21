import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';

/// Resultado del configurador de hÃ¡bito.
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

  /// 'check' o 'count'
  final String type;

  /// Solo aplica si type == 'count'
  final num? target;

  /// 'daily' | 'weekly' | 'once'
  final String scheduleType;

  /// 1..7 (Lun..Dom) si scheduleType == 'weekly'
  final List<int>? weekdays;

  /// YYYY-MM-DD si scheduleType == 'once'
  final String? scheduledDate;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'target': target,
        'scheduleType': scheduleType,
        'weekdays': weekdays,
        'scheduledDate': scheduledDate,
      };
}

/// Abre un bottom sheet minimalista para configurar hÃ¡bitos de tipo contador/tiempo.
/// Devuelve null si el usuario cancela.
Future<HabitTargetConfigResult?> showHabitTargetConfigSheet({
  required BuildContext context,
  required Map<String, dynamic> habitDef,
}) {
  return showModalBottomSheet<HabitTargetConfigResult?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
  late final String _rawType; // check / count / count_or_check
  late String _mode; // check / count
  String _scheduleType = 'daily'; // daily / weekly / once

  // weekly
  final Set<int> _weekdays = <int>{1, 2, 3, 4, 5, 6, 7};

  // once
  DateTime? _onceDate;

  // target
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
    final name =
        (widget.habitDef['name'] ?? widget.habitDef['id'] ?? '').toString();
    final canChooseMode = _rawType == 'count_or_check';

    final unit = _readUnit(widget.habitDef);
    final unitLabel = context.l10n.habitUnitLabel(unit);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 14 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handle(context),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                tooltip: context.l10n.commonClose,
                onPressed: () => Navigator.of(context).pop(null),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (canChooseMode) ...[
            const SizedBox(height: 10),
            _sectionTitle(context, context.l10n.habitConfigTypeSection),
            const SizedBox(height: 8),
            _segmentedRow(
              children: [
                _pillChoice(
                  label: context.l10n.habitConfigCheckOption,
                  selected: _mode == 'check',
                  onTap: () => setState(() => _mode = 'check'),
                ),
                _pillChoice(
                  label: context.l10n.habitConfigCounterOption,
                  selected: _mode == 'count',
                  onTap: () => setState(() => _mode = 'count'),
                ),
              ],
            ),
          ],
          if (_mode == 'count') ...[
            const SizedBox(height: 14),
            _sectionTitle(
                context,
                unitLabel.isEmpty
                    ? context.l10n.habitConfigGoalSection
                    : context.l10n.habitConfigGoalSectionWithUnit(unitLabel)),
            const SizedBox(height: 8),
            _targetStepper(context, unitLabel: unitLabel, unit: unit),
          ],
          const SizedBox(height: 14),
          _sectionTitle(context, context.l10n.habitConfigFrequencySection),
          const SizedBox(height: 8),
          _segmentedRow(
            children: [
              _pillChoice(
                label: context.l10n.habitConfigDailyOption,
                selected: _scheduleType == 'daily',
                onTap: () => setState(() => _scheduleType = 'daily'),
              ),
              _pillChoice(
                label: context.l10n.habitConfigWeeklyOption,
                selected: _scheduleType == 'weekly',
                onTap: () => setState(() => _scheduleType = 'weekly'),
              ),
              _pillChoice(
                label: context.l10n.habitConfigOnceOption,
                selected: _scheduleType == 'once',
                onTap: () => setState(() => _scheduleType = 'once'),
              ),
            ],
          ),
          if (_scheduleType == 'weekly') ...[
            const SizedBox(height: 12),
            _sectionTitle(context, context.l10n.habitConfigDaysSection),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _weekdayChip(1, context.l10n.weekdayLetter(1)),
                _weekdayChip(2, context.l10n.weekdayLetter(2)),
                _weekdayChip(3, context.l10n.weekdayLetter(3)),
                _weekdayChip(4, context.l10n.weekdayLetter(4)),
                _weekdayChip(5, context.l10n.weekdayLetter(5)),
                _weekdayChip(6, context.l10n.weekdayLetter(6)),
                _weekdayChip(7, context.l10n.weekdayLetter(7)),
              ],
            ),
          ],
          if (_scheduleType == 'once') ...[
            const SizedBox(height: 12),
            _sectionTitle(context, context.l10n.habitConfigDateSection),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.event),
                label: Text(_onceDate == null
                    ? context.l10n.habitConfigChooseDate
                    : _formatDate(_onceDate!)),
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _onceDate ?? now,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 5),
                  );
                  if (picked != null) setState(() => _onceDate = picked);
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final res = _buildResult();
                if (res == null) return;
                Navigator.of(context).pop(res);
              },
              child: Text(context.l10n.commonAdd),
            ),
          ),
        ],
      ),
    );
  }

  Widget _handle(BuildContext context) {
    return Container(
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _segmentedRow({required List<Widget> children}) {
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1) const SizedBox(width: 8),
        ]
      ],
    );
  }

  Widget _pillChoice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected
        ? scheme.primary.withValues(alpha: 0.14)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final fg =
        selected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.75);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? scheme.primary.withValues(alpha: 0.35)
                : scheme.outline.withValues(alpha: 0.20),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }

  Widget _targetStepper(BuildContext context,
      {required String unitLabel, String? unit}) {
    final scheme = Theme.of(context).colorScheme;

    // step: si minutos, subimos de 5; si "times" u otro, de 1.
    final normalizedUnit = (unit ?? '').trim().toLowerCase();
    final step = (normalizedUnit == 'minutes' ||
            normalizedUnit == 'mins' ||
            normalizedUnit == 'min')
        ? 5
        : 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          _roundIconButton(
            icon: Icons.remove,
            onTap: () => setState(() {
              final next = _target - step;
              _target = (next <= 1) ? 1 : next;
            }),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Center(
              child: Text(
                _formatNum(_target),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _roundIconButton(
            icon: Icons.add,
            onTap: () => setState(() => _target = _target + step),
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.20)),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _weekdayChip(int day, String label) {
    final selected = _weekdays.contains(day);
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        setState(() {
          if (selected) {
            _weekdays.remove(day);
          } else {
            _weekdays.add(day);
          }
        });
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.14)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? scheme.primary.withValues(alpha: 0.35)
                : scheme.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.75),
                ),
          ),
        ),
      ),
    );
  }

  HabitTargetConfigResult? _buildResult() {
    // Si el usuario elige check, no necesitamos target.
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

    String scheduleType = _scheduleType;
    String? scheduledDate;
    List<int>? weekdays;

    if (scheduleType == 'weekly') {
      final list = _weekdays.toList()..sort();
      if (list.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.habitConfigSelectDay)),
        );
        return null;
      }
      weekdays = list;
    } else if (scheduleType == 'once') {
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
      scheduleType: scheduleType,
      weekdays: weekdays,
      scheduledDate: scheduledDate,
    );
  }
}

num? _readInitialTarget(Map<String, dynamic> habitDef) {
  // prioridad: habitDef['target'], luego metric.default (si existe)
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
