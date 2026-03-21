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

  final byId = <String, Map<String, dynamic>>{};
  for (final h in activeHabits) {
    final id = (h['id'] ?? '').toString();
    if (id.isNotEmpty) byId[id] = h;
  }

  final xpByFamily = <String, int>{};

  for (final e in habitCompletions.entries) {
    final dayKey = e.key.toString();
    final dayDone = _map(e.value);
    final dayVals = _map(habitCountValues[dayKey]);

    for (final hd in dayDone.entries) {
      final habitId = hd.key.toString();
      final done = hd.value == true;

      final habit = byId[habitId];
      if (habit == null) continue;

      final type = (habit['type'] ?? 'check').toString();
      final familyId = normalizeFamilyId(habitFamilyId(habit));
      if (familyId.isEmpty) continue;

      int gain = 0;

      if (type == 'count') {
        final target = (habit['target'] as num?) ?? 1;
        final inferredDone =
            done || (((dayVals[habitId] as num?) ?? 0) >= target);
        if (inferredDone) gain = xpForCountCompletion(target);
      } else if (done) {
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
