import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/achievements/domain/models/achievement.dart';
import 'package:rutio/features/achievements/domain/models/unlocked_achievement_record.dart';
import 'package:rutio/features/achievements/presentation/widgets/achievement_unlock_overlay_host.dart';
import 'package:rutio/features/gamification/domain/level_event.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'achievement and level-up overlays are queued in order without visual overlap',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = _FakeOverlayQueueStore();
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        ChangeNotifierProvider<UserStateStore>.value(
          value: store,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AchievementUnlockOverlayHost(
              navigatorKey: navigatorKey,
              child: const Scaffold(body: SizedBox.shrink()),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Ver mis logros'), findsNothing);
      expect(
        store.callLog.where((entry) => entry == 'consumeAchievement'),
        isEmpty,
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Ver mis logros'), findsOneWidget);
      expect(
        store.callLog.indexOf('markLevel:2') <
            store.callLog.indexOf('consumeAchievement'),
        isTrue,
      );

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(store.pendingLevelCelebrationCount, 0);
      expect(store.pendingAchievementUnlockCount, 0);
    },
  );

  testWidgets(
    'does not present level-up sheet when gamification overlays are suppressed',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = _FakeOverlayQueueStore()..allowGamificationOverlays = false;
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        ChangeNotifierProvider<UserStateStore>.value(
          value: store,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AchievementUnlockOverlayHost(
              navigatorKey: navigatorKey,
              child: const Scaffold(body: SizedBox.shrink()),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsNothing);
      expect(store.callLog.where((entry) => entry.startsWith('markLevel')), isEmpty);
      expect(
        store.callLog.where((entry) => entry == 'consumeAchievement'),
        isEmpty,
      );
    },
  );

  testWidgets(
    'skips invalid pending level celebration with level <= 1',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = _FakeOverlayQueueStore(
        levelEvents: const <LevelEvent>[
          LevelEvent(level: 1, type: LevelEventType.normalLevelUp),
        ],
        achievementEvents: const <UnlockedAchievementRecord>[],
      );
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        ChangeNotifierProvider<UserStateStore>.value(
          value: store,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AchievementUnlockOverlayHost(
              navigatorKey: navigatorKey,
              child: const Scaffold(body: SizedBox.shrink()),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(store.callLog.where((entry) => entry == 'consumeLevel').length, 1);
      expect(store.callLog.where((entry) => entry.startsWith('markLevel')), isEmpty);
      expect(store.pendingLevelCelebrationCount, 0);
      expect(find.text('Ver mis logros'), findsNothing);
    },
  );
}

class _FakeOverlayQueueStore extends UserStateStore {
  _FakeOverlayQueueStore({
    List<LevelEvent>? levelEvents,
    List<UnlockedAchievementRecord>? achievementEvents,
  })  : _levelEvents = List<LevelEvent>.from(
          levelEvents ??
              const <LevelEvent>[
                LevelEvent(
                  level: 2,
                  type: LevelEventType.normalLevelUp,
                ),
              ],
        ),
        _achievementEvents = List<UnlockedAchievementRecord>.from(
          achievementEvents ??
              <UnlockedAchievementRecord>[
                UnlockedAchievementRecord(
                  id: 'special:flash',
                  type: AchievementType.special,
                  tier: AchievementTier.bronze,
                  unlockedAt: DateTime(2026, 1, 1),
                  habitId: 'habit_1',
                  habitName: 'Habit 1',
                  familyId: 'special',
                  targetValue: 5,
                ),
              ],
        ),
        super(
          UserStateRepository(storage: UserStateStorage())
            ..setActiveUserScope('user_123'),
          journalEntrySyncService: JournalEntrySyncService(),
        );

  final List<LevelEvent> _levelEvents;
  final List<UnlockedAchievementRecord> _achievementEvents;

  final List<String> callLog = <String>[];
  bool allowGamificationOverlays = true;

  @override
  int get pendingLevelCelebrationCount => _levelEvents.length;

  @override
  int get pendingAchievementUnlockCount => _achievementEvents.length;

  @override
  bool get shouldShowGamificationOverlays => allowGamificationOverlays;

  @override
  LevelEvent? peekNextPendingLevelCelebration() {
    callLog.add('peekLevel');
    if (_levelEvents.isEmpty) return null;
    return _levelEvents.first;
  }

  @override
  Future<void> markLevelCelebrationAsCelebrated({required int level}) async {
    callLog.add('markLevel:$level');
    if (_levelEvents.isNotEmpty && _levelEvents.first.level <= level) {
      _levelEvents.removeAt(0);
    }
    notifyListeners();
  }

  @override
  LevelEvent? consumeNextPendingLevelCelebration() {
    callLog.add('consumeLevel');
    if (_levelEvents.isEmpty) return null;
    final next = _levelEvents.removeAt(0);
    notifyListeners();
    return next;
  }

  @override
  UnlockedAchievementRecord? consumeNextPendingAchievementUnlock() {
    callLog.add('consumeAchievement');
    if (_achievementEvents.isEmpty) return null;
    final next = _achievementEvents.removeAt(0);
    notifyListeners();
    return next;
  }

  @override
  List<UnlockedAchievementRecord> get unlockedAchievementRecords =>
      _achievementEvents;
}
