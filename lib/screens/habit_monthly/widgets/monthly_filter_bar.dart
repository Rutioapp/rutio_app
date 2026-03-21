import 'package:flutter/material.dart';

import 'package:rutio/l10n/l10n.dart';

enum MonthlyFilterMode { all, family, habit }

class MonthlyFilterBar extends StatelessWidget {
  final MonthlyFilterMode mode;
  final List<String> familyOptions;
  final List<Map<String, dynamic>> habits;
  final String? selectedFamilyId;
  final String? selectedHabitId;
  final ValueChanged<MonthlyFilterMode> onModeChanged;
  final ValueChanged<String?> onFamilyChanged;
  final ValueChanged<String?> onHabitChanged;
  final VoidCallback onReset;

  const MonthlyFilterBar({
    super.key,
    required this.mode,
    required this.familyOptions,
    required this.habits,
    required this.selectedFamilyId,
    required this.selectedHabitId,
    required this.onModeChanged,
    required this.onFamilyChanged,
    required this.onHabitChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    String summary;
    if (mode == MonthlyFilterMode.family &&
        (selectedFamilyId ?? '').isNotEmpty) {
      summary = l10n.monthlyFilterSummaryFamily(
        l10n.familyName(selectedFamilyId!),
      );
    } else if (mode == MonthlyFilterMode.habit &&
        (selectedHabitId ?? '').isNotEmpty) {
      final h = habits.cast<Map<String, dynamic>>().firstWhere(
            (e) => (e['id'] ?? '').toString() == selectedHabitId,
            orElse: () => const {},
          );
      final name = (h['name'] ?? h['title'] ?? selectedHabitId).toString();
      summary = l10n.monthlyFilterSummaryHabit(name);
    } else {
      summary = l10n.monthlyFilterSummaryAll;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.black.withValues(alpha: 0.80),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.monthlyFiltersTooltip,
            onPressed: () => _openFiltersSheet(context),
            icon: Icon(Icons.tune_rounded, color: cs.primary),
          ),
          IconButton(
            tooltip: l10n.monthlyResetTooltip,
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Future<void> _openFiltersSheet(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    MonthlyFilterMode localMode = mode;
    String? localFamily = selectedFamilyId;
    String? localHabit = selectedHabitId;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            void setMode(MonthlyFilterMode m) {
              setState(() => localMode = m);
              onModeChanged(m);
              if (m == MonthlyFilterMode.all) {
                localFamily = null;
                localHabit = null;
                onFamilyChanged(null);
                onHabitChanged(null);
              } else if (m == MonthlyFilterMode.family) {
                localHabit = null;
                onHabitChanged(null);
              } else if (m == MonthlyFilterMode.habit) {
                localFamily = null;
                onFamilyChanged(null);
              }
            }

            void setFamily(String? fid) {
              setState(() => localFamily = fid);
              onFamilyChanged(fid);
            }

            void setHabit(String? hid) {
              setState(() => localHabit = hid);
              onHabitChanged(hid);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.monthlyFiltersTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          onReset();
                          Navigator.of(ctx).pop();
                        },
                        child: Text(l10n.monthlyResetAction),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ChoiceChip(
                        label: l10n.monthlyFilterModeAll,
                        selected: localMode == MonthlyFilterMode.all,
                        onTap: () => setMode(MonthlyFilterMode.all),
                      ),
                      _ChoiceChip(
                        label: l10n.monthlyFilterModeFamily,
                        selected: localMode == MonthlyFilterMode.family,
                        onTap: () => setMode(MonthlyFilterMode.family),
                      ),
                      _ChoiceChip(
                        label: l10n.monthlyFilterModeHabit,
                        selected: localMode == MonthlyFilterMode.habit,
                        onTap: () => setMode(MonthlyFilterMode.habit),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (localMode == MonthlyFilterMode.family) ...[
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: familyOptions.map((fid) {
                        final selected = (localFamily ?? '') == fid;
                        return _FamilyChip(
                          label: l10n.familyName(fid),
                          selected: selected,
                          onTap: () => setFamily(selected ? null : fid),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (localMode == MonthlyFilterMode.habit) ...[
                    _HabitDropdown(
                      habits: habits,
                      selectedHabitId: localHabit,
                      onChanged: setHabit,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(l10n.commonClose),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            l10n.monthlyApplyAction,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: selected ? cs.primary : Colors.black.withValues(alpha: 0.70),
          ),
        ),
      ),
    );
  }
}

class _FamilyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FamilyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.black.withValues(alpha: 0.80),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> habits;
  final String? selectedHabitId;
  final ValueChanged<String?> onChanged;

  const _HabitDropdown({
    required this.habits,
    required this.selectedHabitId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DropdownButtonFormField<String>(
      initialValue: (selectedHabitId != null && selectedHabitId!.isNotEmpty)
          ? selectedHabitId
          : null,
      decoration: InputDecoration(
        labelText: l10n.monthlySelectHabitLabel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: habits.map((h) {
        final id = (h['id'] ?? '').toString();
        final name = (h['name'] ?? h['title'] ?? id).toString();
        return DropdownMenuItem(
          value: id,
          child: Text(name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
