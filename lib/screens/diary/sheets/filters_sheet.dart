import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class DiaryFiltersSheet extends StatelessWidget {
  const DiaryFiltersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final familyIds = const [
      'body',
      'mind',
      'spirit',
      'social',
      'discipline',
      'professional',
      'emotional',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.diaryFiltersTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Text(l10n.diaryFiltersType,
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilterChip(
                label: Text(l10n.diaryComposerTypeHabit),
                selected: true,
                onSelected: null,
              ),
              FilterChip(
                label: Text(l10n.diaryComposerTypePersonal),
                selected: true,
                onSelected: null,
              ),
              FilterChip(
                label: Text(l10n.diaryFiltersPinnedOnly),
                selected: false,
                onSelected: null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.diaryFiltersFamily,
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final familyId in familyIds)
                FilterChip(
                  label: Text(l10n.familyName(familyId)),
                  selected: false,
                  onSelected: null,
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.diaryFiltersApply),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draft from composer -> map this to your real DiaryEntry model later.
