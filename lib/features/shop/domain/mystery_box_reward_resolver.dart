import 'models/mystery_box_reward_definition.dart';
import 'random_source.dart';

class MysteryBoxRewardResolver {
  const MysteryBoxRewardResolver();

  MysteryBoxRewardDefinition resolve({
    required List<MysteryBoxRewardDefinition> catalog,
    required RandomSource randomSource,
  }) {
    final validationErrors = validateCatalog(catalog);
    if (validationErrors.isNotEmpty) {
      throw StateError(
        'Invalid mystery box catalog: ${validationErrors.join('; ')}',
      );
    }

    final totalWeight = catalog.fold<int>(0, (sum, reward) => sum + reward.weight);
    final roll = randomSource.nextInt(totalWeight);
    return resolveByRoll(catalog: catalog, roll: roll);
  }

  MysteryBoxRewardDefinition resolveByRoll({
    required List<MysteryBoxRewardDefinition> catalog,
    required int roll,
  }) {
    final validationErrors = validateCatalog(catalog);
    if (validationErrors.isNotEmpty) {
      throw StateError(
        'Invalid mystery box catalog: ${validationErrors.join('; ')}',
      );
    }

    if (roll < 0 || roll >= 100) {
      throw RangeError.range(roll, 0, 99, 'roll');
    }

    var cumulative = 0;
    for (final reward in catalog) {
      cumulative += reward.weight;
      if (roll < cumulative) {
        return reward;
      }
    }

    throw StateError('No reward matched roll $roll.');
  }

  List<String> validateCatalog(
    List<MysteryBoxRewardDefinition> catalog, {
    Set<String>? validUtilityIds,
  }) {
    final errors = <String>[];
    if (catalog.isEmpty) {
      errors.add('catalog is empty');
      return errors;
    }

    final ids = <String>{};
    var totalWeight = 0;
    for (final reward in catalog) {
      final id = reward.id.trim();
      if (id.isEmpty) {
        errors.add('reward has empty id');
      } else if (!ids.add(id)) {
        errors.add('duplicate reward id "$id"');
      }

      if (reward.weight <= 0) {
        errors.add('reward "$id" has invalid weight ${reward.weight}');
      }
      if (reward.coins < 0) {
        errors.add('reward "$id" has negative coins');
      }
      if (reward.xp < 0) {
        errors.add('reward "$id" has negative xp');
      }
      if (reward.isEmpty) {
        errors.add('reward "$id" is empty');
      }

      final utilityEntries = reward.utilityRewards.entries.toList(growable: false);
      final utilityIdsSeen = <String>{};
      for (final entry in utilityEntries) {
        final utilityId = entry.key.trim();
        final quantity = entry.value;
        if (utilityId.isEmpty) {
          errors.add('reward "$id" has empty utility id');
          continue;
        }
        if (!utilityIdsSeen.add(utilityId)) {
          errors.add('reward "$id" repeats utility "$utilityId"');
        }
        if (quantity <= 0) {
          errors.add('reward "$id" has invalid utility quantity for "$utilityId"');
        }
        final allowedIds = validUtilityIds;
        if (allowedIds != null && !allowedIds.contains(utilityId)) {
          errors.add('reward "$id" references unknown utility "$utilityId"');
        }
      }

      totalWeight += reward.weight;
    }

    if (totalWeight != 100) {
      errors.add('total weight is $totalWeight instead of 100');
    }

    return errors;
  }
}
