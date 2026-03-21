import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../stores/user_state_store.dart';

class UserStatsCard extends StatelessWidget {
  final String username;
  final int level;
  final double xpValue; // 0..1
  final int coins;
  final VoidCallback onTap;
  final Color primaryDark;
  final bool compact;

  const UserStatsCard({
    super.key,
    required this.username,
    required this.level,
    required this.xpValue,
    required this.coins,
    required this.onTap,
    required this.primaryDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Reactive read from store: updates automatically after onboarding/profile edits.
    final storeDisplayName =
        context.select<UserStateStore, String?>((s) => s.displayName);

    final fallbackFromProp = username.trim();
    final fromStore = (storeDisplayName ?? '').trim();
    final displayUsername = fromStore.isNotEmpty
        ? fromStore
        : (fallbackFromProp.isNotEmpty
            ? fallbackFromProp
            : context.l10n.homeFallbackUsername);

    final textTheme = Theme.of(context).textTheme;

    final double padding = compact ? 6 : 10;
    final double titleFont = compact ? 12 : 14;
    final double progressHeight = compact ? 4 : 6;
    final double cardWidth = compact ? 190 : 220;
    final double? cardHeight = compact ? 56 : null;
    final double vGap = compact ? 4 : 6;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: cardHeight,
        child: Container(
          width: cardWidth,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _LevelPill(
                level: level,
                compact: compact,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayUsername,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (textTheme.titleMedium ?? const TextStyle()).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: titleFont,
                      ),
                    ),
                    SizedBox(height: vGap),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: xpValue.clamp(0.0, 1.0),
                        minHeight: progressHeight,
                        backgroundColor: Colors.black.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(primaryDark),
                      ),
                    ),
                    SizedBox(height: vGap),
                    Row(
                      children: [
                        Text(
                          '\$',
                          style: (textTheme.labelMedium ?? const TextStyle())
                              .copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: compact ? 11 : 12,
                            color: primaryDark,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          coins.toString(),
                          style: (textTheme.labelMedium ?? const TextStyle())
                              .copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: compact ? 11 : 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  final int level;
  final bool compact;

  const _LevelPill({
    required this.level,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: compact ? 44 : 50,
      padding: EdgeInsets.symmetric(
        vertical: compact ? 4 : 8,
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.userLevelLabel,
            style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            level.toString(),
            style: (textTheme.titleSmall ?? const TextStyle()).copyWith(
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
