import 'package:flutter/material.dart';

import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/widgets/app_header/app_header.dart';
import 'package:rutio/widgets/app_header/user_stats_card.dart';

/// Weekly header kept for backwards compatibility.
///
/// ✅ Uses the SAME layout as Home (`AppHeader` + `UserStatsCard`).
///
/// Mapping:
/// - `onMenuTap` -> hamburger (open drawer)
/// - `onAddTap`  -> tap on the user card (you can open monthly picker, stats, etc.)
class WeeklyUserHeader extends StatelessWidget {
  final Map<String, dynamic> userState;
  final VoidCallback onMenuTap;
  final VoidCallback onAddTap;

  const WeeklyUserHeader({
    super.key,
    required this.userState,
    required this.onMenuTap,
    required this.onAddTap,
  });

  static int _readInt(Map<String, dynamic> m, List<String> path,
      {int fallback = 0}) {
    dynamic cur = m;
    for (final k in path) {
      if (cur is Map && cur[k] != null) {
        cur = cur[k];
      } else {
        return fallback;
      }
    }
    if (cur is int) return cur;
    if (cur is num) return cur.toInt();
    return int.tryParse(cur.toString()) ?? fallback;
  }

  static String _readString(Map<String, dynamic> m, List<String> path,
      {String fallback = ''}) {
    dynamic cur = m;
    for (final k in path) {
      if (cur is Map && cur[k] != null) {
        cur = cur[k];
      } else {
        return fallback;
      }
    }
    final s = (cur ?? '').toString().trim();
    return s.isNotEmpty ? s : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final double w = MediaQuery.of(context).size.width;
    final bool compact = w < 380;

    final int xpTotal = _readInt(userState, ['progression', 'xp'], fallback: 0);
    final int level = _readInt(
      userState,
      ['progression', 'level'],
      fallback: 1 + (xpTotal ~/ 100),
    );
    final int xpInLevel = xpTotal % 100;
    final int xpToNext = 100 - xpInLevel;
    final int coins = _readInt(userState, ['wallet', 'coins'], fallback: 0);

    final String profileName =
        _readString(userState, ['profile', 'displayName'], fallback: '').trim();
    final String legacyName =
        _readString(userState, ['userName'], fallback: '').trim();
    final String legacyName2 =
        _readString(userState, ['name'], fallback: '').trim();

    final String name = profileName.isNotEmpty
        ? profileName
        : (legacyName.isNotEmpty
            ? legacyName
            : (legacyName2.isNotEmpty
                ? legacyName2
                : l10n.homeFallbackUsername));

    final double denom = (xpInLevel + xpToNext).toDouble();
    final double xpValue =
        (denom <= 0) ? 0.0 : (xpInLevel / denom).clamp(0.0, 1.0);

    final double cardWidth = compact ? 220 : 244;

    return AppHeader(
      height: compact ? 88 : 92,
      left: AppDrawerButton(
        onTap: onMenuTap,
      ),
      center: const SizedBox.shrink(),
      right: SizedBox(
        width: cardWidth,
        child: Align(
          alignment: Alignment.centerRight,
          child: UserStatsCard(
            username: name,
            level: level,
            xpValue: xpValue,
            coins: coins,
            onTap: onAddTap,
            primaryDark: const Color(0xFF4B2BFF),
            compact: compact,
          ),
        ),
      ),
    );
  }
}
