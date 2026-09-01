import '../../../services/phase1_notification_timing_registry.dart';

class Phase1SpacingPolicy {
  const Phase1SpacingPolicy({
    this.spacing = const Duration(minutes: 30),
  });

  static const Duration personalizedPhase1Spacing = Duration(minutes: 30);

  final Duration spacing;

  bool conflictsWithPhase1({
    required DateTime personalizedAt,
    required List<Phase1NotificationScheduleIntent> phase1Schedules,
  }) {
    return phase1Schedules.any((intent) {
      final distance = personalizedAt.difference(intent.scheduledFor).abs();
      return distance < spacing;
    });
  }
}
