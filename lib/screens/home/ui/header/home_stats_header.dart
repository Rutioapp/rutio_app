import 'package:flutter/material.dart';

import 'package:rutio/ui/behaviours/ios_feedback.dart';
import 'package:rutio/ui/foundations/ios_foundations.dart';
import 'package:rutio/widgets/app_header/app_header.dart';
import 'package:rutio/widgets/home/user_identity_row.dart';

/// Unified header wrapper used by Weekly / Monthly.
/// - Reuses the same user identity row as Home.
/// - Keeps the caller-owned tap behavior intact.
class HomeStatsHeader extends StatelessWidget {
  final String username;
  final int level;
  final int xp;
  final int xpToNext;
  final int coins;
  final String? avatarUrl;

  final VoidCallback onOpenMonthlyOverview;
  final VoidCallback onTapDrawer;

  final Color cardBg;
  final Color primary;
  final Color primaryDark;

  const HomeStatsHeader({
    super.key,
    required this.username,
    required this.level,
    required this.xp,
    required this.xpToNext,
    required this.coins,
    required this.avatarUrl,
    required this.onOpenMonthlyOverview,
    required this.onTapDrawer,
    required this.cardBg,
    required this.primary,
    required this.primaryDark,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool compact = width < 390;
    final double denom = (xp + xpToNext).toDouble();
    final double xpValue = (denom <= 0) ? 0.0 : (xp / denom).clamp(0.0, 1.0);

    // IOS-FIRST IMPROVEMENT START
    return AppHeader(
      height: compact ? 56 : 60,
      padding: EdgeInsets.zero,
      left: AppDrawerButton(
        onTap: onTapDrawer,
      ),
      center: const SizedBox.shrink(),
      right: SizedBox(
        width: compact ? 222 : 248,
        child: Align(
          alignment: Alignment.centerRight,
          child: IosFrostedCard(
            padding: const EdgeInsets.symmetric(
              horizontal: IosSpacing.sm,
              vertical: IosSpacing.xxs,
            ),
            borderRadius: BorderRadius.circular(20),
            child: UserIdentityRow(
              username: username,
              level: level,
              coins: coins,
              xpProgress: xpValue,
              avatarUrl: avatarUrl,
              onTap: () async {
                await IosFeedback.lightImpact();
                if (!context.mounted) return;
                onOpenMonthlyOverview();
              },
            ),
          ),
        ),
      ),
    );
    // IOS-FIRST IMPROVEMENT END
  }
}
