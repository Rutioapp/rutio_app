import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../stores/user_state_store.dart';
import '../components/diary_entry_swipe_action_background.dart';
import '../models/diary_types.dart';
import '../widgets/diary_day_header.dart';
import '../widgets/diary_entry_card.dart';

class DiaryEntriesSection extends StatelessWidget {
  const DiaryEntriesSection({
    super.key,
    required this.store,
    required this.sortedDays,
    required this.groupedEntries,
    required this.onEntryTap,
    required this.onEntryEdit,
    required this.onEntryDelete,
    required this.onEntryPin,
    required this.onEntryDismiss,
  });

  final UserStateStore store;
  final List<DateTime> sortedDays;
  final Map<DateTime, List<DiaryEntryUi>> groupedEntries;
  final ValueChanged<DiaryEntryUi> onEntryTap;
  final ValueChanged<DiaryEntryUi> onEntryEdit;
  final ValueChanged<DiaryEntryUi> onEntryDelete;
  final VoidCallback onEntryPin;
  final Future<bool> Function(
    DiaryEntryUi entry,
    DismissDirection direction,
  ) onEntryDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (sortedDays.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final day in sortedDays) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DiaryDayHeader(date: day),
          ),
          const SizedBox(height: 10),
          for (final entry in groupedEntries[day]!) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Dismissible(
                key: ValueKey('diary_${entry.id}'),
                direction: DismissDirection.horizontal,
                background: DiaryEntrySwipeActionBackground(
                  alignment: Alignment.centerLeft,
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded),
                      SizedBox(width: 8),
                      Text(l10n.diaryActionEdit),
                    ],
                  ),
                ),
                secondaryBackground: DiaryEntrySwipeActionBackground(
                  alignment: Alignment.centerRight,
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.diaryActionDelete),
                      SizedBox(width: 8),
                      Icon(Icons.delete_outline_rounded),
                    ],
                  ),
                ),
                confirmDismiss: (direction) => onEntryDismiss(entry, direction),
                child: DiaryEntryCard(
                  store: store,
                  entry: entry,
                  onTap: () => onEntryTap(entry),
                  onEdit: () => onEntryEdit(entry),
                  onDelete: () => onEntryDelete(entry),
                  onPin: onEntryPin,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}
