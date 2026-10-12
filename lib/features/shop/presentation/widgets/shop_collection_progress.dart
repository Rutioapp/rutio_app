import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

class ShopCollectionProgress extends StatelessWidget {
  const ShopCollectionProgress({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  double get progress => total <= 0 ? 0 : current.clamp(0, total) / total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              '$current / $total',
              style: ShopUiTextStyles.label,
            ),
            Text(
              _statusLabel(context.l10n),
              style: ShopUiTextStyles.labelSmall.copyWith(
                color: _statusColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: ShopUiTokens.radiusXlShape,
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress,
            backgroundColor: ShopUiTokens.backgroundAlt,
            valueColor: AlwaysStoppedAnimation<Color>(_statusColor()),
          ),
        ),
      ],
    );
  }

  String _statusLabel(AppLocalizations l10n) {
    if (total <= 0) {
      return l10n.shopCollectionStatusBlocked;
    }
    if (current <= 0) {
      return l10n.shopCollectionStatusNew;
    }
    if (current >= total) {
      return l10n.shopCollectionStatusCompleted;
    }
    return l10n.shopCollectionStatusStarted;
  }

  Color _statusColor() {
    if (current >= total && total > 0) {
      return ShopUiTokens.success;
    }
    if (current > 0) {
      return ShopUiTokens.accent;
    }
    return ShopUiTokens.textTertiary;
  }
}
