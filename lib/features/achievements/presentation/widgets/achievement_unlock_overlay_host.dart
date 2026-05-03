import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/gamification/presentation/level_up_sheet.dart';
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
    final overlayQueueSnapshot = context.select<UserStateStore, ({int pendingCount, bool canShow})>(
      (store) => (
        pendingCount:
            store.pendingAchievementUnlockCount +
                store.pendingLevelCelebrationCount,
        canShow: store.shouldShowGamificationOverlays,
      ),
    );
    final pendingCount = overlayQueueSnapshot.pendingCount;
    final canShowOverlays = overlayQueueSnapshot.canShow;

    if (!_isPresentingSheet &&
        canShowOverlays &&
        pendingCount > 0 &&
        !_pumpScheduled) {
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
    if (!store.shouldShowGamificationOverlays) return;

    final pendingLevelEvent = store.peekNextPendingLevelCelebration();
    if (pendingLevelEvent != null) {
      if (!store.shouldShowGamificationOverlays) return;
      _isPresentingSheet = true;
      try {
        await showLevelUpSheet<void>(
          navigatorContext,
          event: pendingLevelEvent,
        );
        if (!mounted) return;
        if (!store.shouldShowGamificationOverlays) return;
        await store.markLevelCelebrationAsCelebrated(
          level: pendingLevelEvent.level,
        );
      } finally {
        _isPresentingSheet = false;
      }

      if (!mounted) return;
      final stillPending =
          context.read<UserStateStore>().pendingAchievementUnlockCount > 0 ||
              context.read<UserStateStore>().pendingLevelCelebrationCount > 0;
      if (stillPending) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _showNextPending();
        });
      }
      return;
    }

    if (!store.shouldShowGamificationOverlays) return;
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
    final stillPending =
        context.read<UserStateStore>().pendingAchievementUnlockCount > 0 ||
            context.read<UserStateStore>().pendingLevelCelebrationCount > 0;
    if (stillPending) {
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
