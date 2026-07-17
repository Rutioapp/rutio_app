import 'models/active_utility_effect.dart';

abstract interface class ActiveUtilityEffectsRepository {
  Future<List<ActiveUtilityEffect>> loadEffects(String userScope);

  Future<void> saveEffects(
    String userScope,
    List<ActiveUtilityEffect> effects,
  );
}
