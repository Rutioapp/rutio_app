import 'package:flutter/material.dart';

import 'package:rutio/application/sync/pending_sync_status.dart';
import 'package:rutio/constants/color_palette.dart';
import 'package:rutio/l10n/l10n.dart';

class HomeSyncStatusIndicator extends StatelessWidget {
  const HomeSyncStatusIndicator({
    super.key,
    required this.status,
  });

  final SyncStatusSnapshot status;

  @override
  Widget build(BuildContext context) {
    if (!status.isVisible) return const SizedBox.shrink();

    final attention = status.needsAttention;
    final label = attention
        ? context.l10n.syncStatusNeedsAttention
        : context.l10n.syncStatusPending;
    final color = attention
        ? ColorPalette.accent.withValues(alpha: 0.88)
        : ColorPalette.textSecondary.withValues(alpha: 0.82);
    final icon = attention ? Icons.cloud_off_outlined : Icons.cloud_queue;

    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: Tooltip(
        message: label,
        child: SizedBox(
          width: 36,
          height: 44,
          child: Center(
            child: Icon(icon, size: 19, color: color),
          ),
        ),
      ),
    );
  }
}
