import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';

class ArchiveHabitTile extends StatelessWidget {
  final bool archived;
  final Future<void> Function(bool value) onChanged;

  const ArchiveHabitTile({
    super.key,
    required this.archived,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Icon(
            archived ? Icons.archive : Icons.archive_outlined,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            context.l10n.archiveHabitTileTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      subtitle: Text(
        archived
            ? context.l10n.archiveHabitTileArchivedSubtitle
            : context.l10n.archiveHabitTileActiveSubtitle,
      ),
      value: archived,
      activeThumbColor: Colors.orange,
      onChanged: (v) async {
        if (!archived && v == true) {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(context.l10n.archiveHabitTileConfirmTitle),
              content: Text(context.l10n.archiveHabitTileConfirmBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.l10n.commonCancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(context.l10n.archiveHabitTileConfirmAction),
                ),
              ],
            ),
          );
          if (ok != true) return;
        }

        await onChanged(v);
      },
    );
  }
}
