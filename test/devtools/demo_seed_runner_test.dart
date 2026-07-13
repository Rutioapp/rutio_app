import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/devtools/demo_seed/demo_seed_data.dart';
import 'package:rutio/devtools/demo_seed/demo_seed_models.dart';
import 'package:rutio/devtools/demo_seed/demo_seed_runner.dart';
import 'package:rutio/devtools/rutio_runtime_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DemoSeedRunner', () {
    test('does not seed when runtime profile is not demo', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final storage = UserStateStorage();
      final repository = UserStateRepository(storage: storage);
      final runner = DemoSeedRunner(
        repository: repository,
        storage: storage,
        runtimeProfile: RutioRuntimeProfile.parse(profileValue: 'default'),
        nowProvider: () => DateTime(2026, 5, 20, 8, 0),
      );

      await runner.prepare();

      final demoState = await storage.read(userId: DemoSeedScope.userId);
      expect(demoState, isNull);
    });

    test('seeds once and avoids duplicate habits on repeated prepare',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final storage = UserStateStorage();
      final repository = UserStateRepository(storage: storage);
      final profile = RutioRuntimeProfile.parse(profileValue: 'demo');
      final runner = DemoSeedRunner(
        repository: repository,
        storage: storage,
        runtimeProfile: profile,
        nowProvider: () => DateTime(2026, 5, 20, 8, 0),
      );

      await runner.prepare();
      await runner.prepare();

      final demoState = await storage.read(userId: DemoSeedScope.userId);
      expect(demoState, isNotNull);
      final habits = (((demoState!['userState']
              as Map<String, dynamic>)['activeHabits'] as List)
          .cast<Map<String, dynamic>>());
      final ids = habits.map((habit) => habit['id'].toString()).toList();

      expect(habits.length, inInclusiveRange(10, 14));
      expect(ids.toSet().length, equals(ids.length));

      final profileState = ((demoState['userState']
          as Map<String, dynamic>)['profile'] as Map<String, dynamic>);
      final wallet = ((demoState['userState'] as Map<String, dynamic>)['wallet']
          as Map<String, dynamic>);
      final achievements = profileState['achievements'] as Map<String, dynamic>;
      final unlockedIds = (achievements['unlocked'] as List)
          .cast<Map<String, dynamic>>()
          .map((entry) => entry['id'].toString())
          .toList();
      final rewardAppliedIds =
          (achievements['rewardAppliedAchievementIds'] as List)
              .map((entry) => entry.toString())
              .toList();

      expect(unlockedIds.toSet().length, equals(unlockedIds.length));
      expect(rewardAppliedIds.toSet().length, equals(rewardAppliedIds.length));
      expect(rewardAppliedIds.toSet(), equals(unlockedIds.toSet()));
      expect(wallet['coins'], equals(DemoSeedData.initialDemoCoins));
    });

    test(
        'existing demo state keeps its current coin balance on repeated prepare',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final storage = UserStateStorage();
      final repository = UserStateRepository(storage: storage);
      final profile = RutioRuntimeProfile.parse(profileValue: 'demo');
      final runner = DemoSeedRunner(
        repository: repository,
        storage: storage,
        runtimeProfile: profile,
        nowProvider: () => DateTime(2026, 5, 20, 8, 0),
      );

      await runner.prepare();
      final initialState = await storage.read(userId: DemoSeedScope.userId);
      expect(initialState, isNotNull);

      final mutatedState = Map<String, dynamic>.from(initialState!);
      final userState = Map<String, dynamic>.from(
        mutatedState['userState'] as Map<String, dynamic>,
      );
      final wallet = Map<String, dynamic>.from(
        userState['wallet'] as Map<String, dynamic>,
      );
      wallet['coins'] = DemoSeedData.initialDemoCoins - 321;
      userState['wallet'] = wallet;
      mutatedState['userState'] = userState;
      await storage.write(mutatedState, userId: DemoSeedScope.userId);

      await runner.prepare();

      final persisted = await storage.read(userId: DemoSeedScope.userId);
      final persistedWallet = ((persisted!['userState']
          as Map<String, dynamic>)['wallet'] as Map<String, dynamic>);
      expect(
        persistedWallet['coins'],
        equals(DemoSeedData.initialDemoCoins - 321),
      );
    });

    test('reset mode clears and reseeds deterministic demo state', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final storage = UserStateStorage();
      final repository = UserStateRepository(storage: storage);
      final seedNow = DateTime(2026, 5, 20, 8, 0);

      final initialRunner = DemoSeedRunner(
        repository: repository,
        storage: storage,
        runtimeProfile: RutioRuntimeProfile.parse(profileValue: 'demo'),
        nowProvider: () => seedNow,
      );
      await initialRunner.prepare();
      final beforeReset = await storage.read(userId: DemoSeedScope.userId);

      final resetRunner = DemoSeedRunner(
        repository: repository,
        storage: storage,
        runtimeProfile: RutioRuntimeProfile.parse(
          profileValue: 'demo',
          resetDemoValue: 'true',
        ),
        nowProvider: () => seedNow,
      );
      await resetRunner.prepare();
      final afterReset = await storage.read(userId: DemoSeedScope.userId);

      expect(beforeReset, isNotNull);
      expect(afterReset, isNotNull);
      expect(afterReset, equals(beforeReset));
    });

    test('uses RUTIO_DEMO_NOW when provided in runtime profile', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final storage = UserStateStorage();
      final repository = UserStateRepository(storage: storage);
      final runner = DemoSeedRunner(
        repository: repository,
        storage: storage,
        runtimeProfile: RutioRuntimeProfile.parse(
          profileValue: 'demo',
          demoNowValue: '2026-05-20',
        ),
        nowProvider: () => DateTime(2030, 1, 1, 9, 0),
      );

      await runner.prepare();

      final demoState = await storage.read(userId: DemoSeedScope.userId);
      expect(demoState, isNotNull);

      final userState = (demoState!['userState'] as Map<String, dynamic>);
      final daily = userState['daily'] as Map<String, dynamic>;
      final meta = userState['meta'] as Map<String, dynamic>;
      final wallet = userState['wallet'] as Map<String, dynamic>;

      expect(daily['lastResetDate'], equals('2026-05-20'));
      expect(meta['activeViewDateKey'], equals('2026-05-20'));
      expect(wallet['coins'], equals(DemoSeedData.initialDemoCoins));
    });
  });
}
