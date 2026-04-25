import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../stores/user_state_store.dart';
import '../screens/achievements_screen.dart';
import '../sheets/achievement_unlock_sheet.dart';
import '../../application/achievement_catalog.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/unlocked_achievement_record.dart';

class AchievementUnlockOverlayHost extends StatefulWidget {
  const AchievementUnlockOverlayHost({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AchievementUnlockOverlayHost> createState() =>
      _AchievementUnlockOverlayHostState();
}

class _AchievementUnlockOverlayHostState
    extends State<AchievementUnlockOverlayHost> {
  bool _pumpScheduled = false;
  bool _isPresentingSheet = false;

  @override
  Widget build(BuildContext context) {
    final pendingCount = context.select<UserStateStore, int>(
      (store) => store.pendingAchievementUnlockCount,
    );

    if (!_isPresentingSheet && pendingCount > 0 && !_pumpScheduled) {
      _pumpScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _pumpScheduled = false;
        await _showNextPending();
      });
    }

    return widget.child;
  }

  Future<void> _showNextPending() async {
    if (!mounted || _isPresentingSheet) return;
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _showNextPending();
      });
      return;
    }

    final store = context.read<UserStateStore>();
    final next = store.consumeNextPendingAchievementUnlock();
    if (next == null) return;

    final achievement = _unlockSheetAchievement(
      next,
      unlockedRecords: store.unlockedAchievementRecords,
    );

    _isPresentingSheet = true;
    await showAchievementUnlockSheet<void>(
      navigatorContext,
      achievement: achievement,
      onViewAchievements: () {
        widget.navigatorKey.currentState?.pushNamed(AchievementsScreen.route);
      },
      onContinue: () {},
    );
    _isPresentingSheet = false;

    if (!mounted) return;
    if (context.read<UserStateStore>().pendingAchievementUnlockCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _showNextPending();
      });
    }
  }

  Achievement _unlockSheetAchievement(
    UnlockedAchievementRecord record, {
    required List<UnlockedAchievementRecord> unlockedRecords,
  }) {
    return AchievementCatalog.achievementForUnlockSheetRecord(
      record,
      unlockedRecords: unlockedRecords,
    );
  }
}
