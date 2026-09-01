import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/mappers/habit_log_remote_mapper.dart';

void main() {
  test('maps skip explicitly and gives it precedence over completion', () {
    final log = HabitLogRemoteMapper.toRemoteHabitLog(
      localHabit: <String, dynamic>{
        'remoteId': '550e8400-e29b-41d4-a716-446655440000',
        'type': 'count',
        'target': 10,
        'progress': 12,
      },
      userId: 'user-1',
      date: DateTime(2026, 9, 1),
      isCompleted: true,
      isSkipped: true,
      countValue: 12,
    );

    expect(log, isNotNull);
    expect(log!.isSkipped, isTrue);
    expect(log.isCompleted, isFalse);
    expect(log.value, 0);
  });
}
