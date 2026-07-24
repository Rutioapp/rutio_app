import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/local_active_utility_effects_repository.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalActiveUtilityEffectsRepository', () {
    test('persists effects after rebuilding the repository', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final repo = LocalActiveUtilityEffectsRepository();
      final effect = _effect(
        id: 'xp-boost',
        utilityId: 'utility_xp_boost_1d',
        type: ActiveUtilityEffectType.xpBoost,
        remainingUses: 7,
      );

      await repo.saveEffects('user-a', <ActiveUtilityEffect>[effect]);

      final reloaded = LocalActiveUtilityEffectsRepository();
      final loaded = await reloaded.loadEffects('user-a');

      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'xp-boost');
      expect(loaded.single.remainingUses, 7);
      expect(loaded.single.totalUses, 10);
      expect(loaded.single.isActive, isTrue);
    });

    test('keeps active effects separated by user scope', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final repo = LocalActiveUtilityEffectsRepository();
      await repo.saveEffects(
        'user-a',
        <ActiveUtilityEffect>[
          _effect(
            id: 'xp-a',
            utilityId: 'utility_xp_boost_1d',
            type: ActiveUtilityEffectType.xpBoost,
            remainingUses: 6,
          ),
        ],
      );
      await repo.saveEffects(
        'user-b',
        <ActiveUtilityEffect>[
          _effect(
            id: 'coin-b',
            utilityId: 'utility_coin_boost_1d',
            type: ActiveUtilityEffectType.coinBoost,
            remainingUses: 4,
          ),
        ],
      );

      expect((await repo.loadEffects('user-a')).single.id, 'xp-a');
      expect((await repo.loadEffects('user-b')).single.id, 'coin-b');
    });

    test('drops stale streak shield effects on load', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      var now = DateTime(2026, 7, 24, 10);
      final staleShieldActivatedAtMillis =
          DateTime(2026, 7, 23, 10).millisecondsSinceEpoch;
      final repo = LocalActiveUtilityEffectsRepository(
        nowProvider: () => now,
      );
      await repo.saveEffects(
        'user-a',
        <ActiveUtilityEffect>[
          ActiveUtilityEffect(
            id: 'shield-old',
            utilityId: 'utility_streak_shield_1',
            type: ActiveUtilityEffectType.streakShield,
            activatedAtMillis: staleShieldActivatedAtMillis,
            remainingUses: 1,
            totalUses: 1,
          ),
        ],
      );

      now = DateTime(2026, 7, 24, 10);
      final loaded = await repo.loadEffects('user-a');

      expect(loaded, isEmpty);
    });

    test('drops exhausted or invalid remaining uses on load', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final repo = LocalActiveUtilityEffectsRepository();
      await repo.saveEffects(
        'user-a',
        <ActiveUtilityEffect>[
          _effect(
            id: 'xp-zero',
            utilityId: 'utility_xp_boost_1d',
            type: ActiveUtilityEffectType.xpBoost,
            remainingUses: 0,
          ),
          _effect(
            id: 'coin-negative',
            utilityId: 'utility_coin_boost_1d',
            type: ActiveUtilityEffectType.coinBoost,
            remainingUses: -3,
          ),
        ],
      );

      expect(await repo.loadEffects('user-a'), isEmpty);
    });
  });
}

ActiveUtilityEffect _effect({
  required String id,
  required String utilityId,
  required ActiveUtilityEffectType type,
  required int remainingUses,
}) {
  return ActiveUtilityEffect(
    id: id,
    utilityId: utilityId,
    type: type,
    activatedAtMillis: 1,
    remainingUses: remainingUses,
    totalUses: 10,
  );
}
