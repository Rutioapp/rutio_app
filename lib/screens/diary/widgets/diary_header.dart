import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../models/diary_types.dart';

enum SearchScope { all, habits, personal }

class DiaryTopControls extends StatelessWidget {
  const DiaryTopControls({
    super.key,
    required this.period,
    required this.entriesCount,
    required this.onPeriodChanged,
  });

  final DiaryPeriod period;
  final int entriesCount;
  final ValueChanged<DiaryPeriod> onPeriodChanged;

  String _labelFor(DiaryPeriod p) {
    switch (p) {
      case DiaryPeriod.all:
        return 'all';
      case DiaryPeriod.today:
        return 'days';
      case DiaryPeriod.last7:
        return 'weeks';
      case DiaryPeriod.month:
        return 'months';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: DiaryPeriod.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = DiaryPeriod.values[index];
              final selected = item == period;
              return _DiaryFilterPill(
                label: switch (_labelFor(item)) {
                  'all' => l10n.diaryPeriodAll,
                  'days' => l10n.diaryPeriodDays,
                  'weeks' => l10n.diaryPeriodWeeks,
                  _ => l10n.diaryPeriodMonths,
                },
                selected: selected,
                onTap: () => onPeriodChanged(item),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 1,
          color: const Color(0xFFD7C8B3),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.diaryEntriesCount(entriesCount),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF9D8268),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
        ),
      ],
    );
  }
}

class _DiaryFilterPill extends StatelessWidget {
  const _DiaryFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: selected ? Colors.white : const Color(0xFF8A6E56),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFC98A47) : const Color(0xFFF6EFE3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? const Color(0xFFC98A47) : const Color(0xFFD3C2AA),
          width: 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFFC98A47).withValues(alpha: 0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            child: Text(label, style: textStyle),
          ),
        ),
      ),
    );
  }
}

class DiarySearchPanel extends StatelessWidget {
  const DiarySearchPanel({
    super.key,
    required this.controller,
    required this.scope,
    required this.onScopeChanged,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final SearchScope? scope;
  final ValueChanged<SearchScope> onScopeChanged;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                cursorColor: const Color(0xFFC98A47),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.diarySearchHint,
                  hintStyle: const TextStyle(color: Color(0xFF9B846F)),
                  prefixIcon: const Icon(CupertinoIcons.search, size: 20),
                  suffixIcon: IconButton(
                    tooltip: l10n.diaryClearTooltip,
                    onPressed: onClear,
                    icon: const Icon(CupertinoIcons.clear_circled_solid,
                        size: 18),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.58),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFD5B48E)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SearchPill(
                    label: l10n.diarySearchScopeAll,
                    selected: scope == SearchScope.all,
                    onTap: () => onScopeChanged(SearchScope.all),
                  ),
                  _SearchPill(
                    label: l10n.diarySearchScopeHabits,
                    selected: scope == SearchScope.habits,
                    onTap: () => onScopeChanged(SearchScope.habits),
                  ),
                  _SearchPill(
                    label: l10n.diarySearchScopePersonal,
                    selected: scope == SearchScope.personal,
                    onTap: () => onScopeChanged(SearchScope.personal),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE9D3B9)
              : Colors.white.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFDAAE7E) : const Color(0xFFDCC9B0),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF6E5440),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
