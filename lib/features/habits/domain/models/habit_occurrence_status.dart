enum HabitOccurrenceStatus {
  pending,
  notScheduled,
  completed,
  missed,
  protected,
}

extension HabitOccurrenceStatusX on HabitOccurrenceStatus {
  String get key {
    switch (this) {
      case HabitOccurrenceStatus.pending:
        return 'pending';
      case HabitOccurrenceStatus.notScheduled:
        return 'notScheduled';
      case HabitOccurrenceStatus.completed:
        return 'completed';
      case HabitOccurrenceStatus.missed:
        return 'missed';
      case HabitOccurrenceStatus.protected:
        return 'protected';
    }
  }

  static HabitOccurrenceStatus? fromKey(String? key) {
    switch ((key ?? '').trim()) {
      case 'pending':
        return HabitOccurrenceStatus.pending;
      case 'notScheduled':
        return HabitOccurrenceStatus.notScheduled;
      case 'completed':
        return HabitOccurrenceStatus.completed;
      case 'missed':
        return HabitOccurrenceStatus.missed;
      case 'protected':
        return HabitOccurrenceStatus.protected;
      default:
        return null;
    }
  }
}
