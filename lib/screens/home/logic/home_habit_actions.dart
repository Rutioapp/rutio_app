part of 'package:rutio/screens/home/home_screen.dart';

/// Home habit actions.
///
/// Reune las acciones que modifican datos del usuario o del habito:
/// actualizar, crear, marcar check, reordenar y guardar contadores.
extension _HomeScreenHabitActions on _HomeScreenState {
  Future<void> _reorderHabitSection(
    BuildContext context, {
    required List<Map<String, dynamic>> sectionHabits,
    required List<Map<String, dynamic>> viewHabits,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (sectionHabits.length < 2) return;
    if (oldIndex < 0 || oldIndex >= sectionHabits.length) return;

    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }

    if (targetIndex < 0 || targetIndex >= sectionHabits.length) return;
    if (targetIndex == oldIndex) return;

    final reorderedSectionIds = sectionHabits
        .map((habit) => (habit['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList(growable: true);
    if (reorderedSectionIds.length != sectionHabits.length) return;

    final movedId = reorderedSectionIds.removeAt(oldIndex);
    reorderedSectionIds.insert(targetIndex, movedId);

    final sectionIdSet = reorderedSectionIds.toSet();
    var sectionCursor = 0;
    final reorderedVisibleIds = viewHabits
        .map((habit) => (habit['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .map((id) {
      if (!sectionIdSet.contains(id)) {
        return id;
      }

      final nextId = reorderedSectionIds[sectionCursor];
      sectionCursor += 1;
      return nextId;
    }).toList(growable: false);

    await context.read<UserStateStore>().reorderVisibleHabits(
          orderedVisibleIds: reorderedVisibleIds,
        );
  }

  Future<bool> _tryUpdateHabit(
    BuildContext context, {
    required String habitId,
    required Map<String, dynamic> updates,
  }) async {
    final dynamic store = context.read<UserStateStore>();
    final attempts = <Future<void> Function()>[
      () async =>
          store.updateHabitDetailsFromEdit(habitId: habitId, updates: updates),
      () async => store.updateHabitPlan(habitId: habitId, updates: updates),
      () async => store.updateHabit(habitId: habitId, updates: updates),
      () async => store.updateActiveHabit(habitId: habitId, updates: updates),
      () async => store.editHabit(habitId: habitId, updates: updates),
      () async => store.updateHabitById(habitId, updates),
      () async => store.updateHabit(habitId, updates),
    ];

    for (final fn in attempts) {
      try {
        await fn();
        return true;
      } catch (_) {
        // seguimos probando
      }
    }
    return false;
  }
}
