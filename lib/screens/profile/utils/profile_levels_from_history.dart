import 'package:rutio/features/habits/domain/count_habit_progress.dart';

import '../models/family_level.dart';
import 'profile_families.dart';
import 'profile_xp.dart';

// Calculates XP/level by family using `history`, following UserStateStore
// completion rules.
List<FamilyLevel> buildFamilyLevelsFromHistory({
  required Map<String, dynamic> userState,
  required List<Map<String, dynamic>> activeHabits,
  required String Function(String familyId) familyTitleResolver,
  List<String> extraFamilyIds = const [],
}) {
  final history = _map(userState['history']);
  final habitCompletions = _map(history['habitCompletions']);
  final habitCountValues = _map(history['habitCountValues']);
  final habitSkips = _map(history['habitSkips']);

  final byId = <String, Map<String, dynamic>>{};
  for (final h in activeHabits) {
    final id = (h['id'] ?? '').toString();
    if (id.isNotEmpty) byId[id] = h;
  }

  final xpByFamily = <String, int>{};

  final dayKeys = <String>{
    ...habitCompletions.keys.map((key) => key.toString()),
    ...habitCountValues.keys.map((key) => key.toString()),
    ...habitSkips.keys.map((key) => key.toString()),
  };

  for (final dayKey in dayKeys) {
    final dayDone = _map(habitCompletions[dayKey]);
    final dayVals = _map(habitCountValues[dayKey]);
    final daySkips = _map(habitSkips[dayKey]);
    final dayHabitIds = <String>{
      ...dayDone.keys.map((key) => key.toString()),
      ...dayVals.keys.map((key) => key.toString()),
      ...daySkips.keys.map((key) => key.toString()),
    };

    for (final habitId in dayHabitIds) {
      final done = dayDone[habitId] == true;
      final skipped = daySkips[habitId] == true;

      final habit = byId[habitId];
      if (habit == null) continue;

      final type = (habit['type'] ?? 'check').toString();
      final familyId = normalizeFamilyId(habitFamilyId(habit));
      if (familyId.isEmpty) continue;

      int gain = 0;

      if (type == 'count') {
        final progress = CountHabitProgress.fromHabitMap(
          habit,
          currentValue: dayVals[habitId],
          skipped: skipped,
        );
        if (progress.isCompleted) {
          gain = xpForCountCompletion(progress.effectiveTarget);
        }
      } else if (!skipped && done) {
        gain = xpForCheckCompletion();
      }

      if (gain > 0) {
        xpByFamily[familyId] = (xpByFamily[familyId] ?? 0) + gain;
      }
    }
  }

  final order = resolveFamilyOrder(
    activeHabits,
    extraFamilyIds: extraFamilyIds,
  );

  return order.map((fid) {
    final id = normalizeFamilyId(fid);
    final name = familyTitleResolver(id);
    final xp = xpByFamily[id] ?? 0;
    final ld = levelFromXp(xp);
    return FamilyLevel(
      id: id,
      name: name,
      level: ld.level,
      xp: xp,
      xpToNext: ld.xpToNext,
    );
  }).toList();
}

Map<String, dynamic> _map(dynamic v) =>
    (v is Map) ? v.cast<String, dynamic>() : <String, dynamic>{};
