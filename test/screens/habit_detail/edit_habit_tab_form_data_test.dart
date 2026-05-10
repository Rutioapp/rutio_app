import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/edit_habit_tab/edit_habit_tab_form_data.dart';

void main() {
  group('EditHabitTabFormData timesPerWeek handling', () {
    test('hydrates canonical timesPerWeek schedule for check habit', () {
      final formData = EditHabitTabFormData.fromHabit({
        'id': 'h-1',
        'name': 'Habit',
        'type': 'check',
        'schedule': {
          'type': 'timesPerWeek',
          'timesPerWeek': 4,
          'weekStartsOn': 1,
        },
      });

      expect(formData.frequencyMode, 'timesPerWeek');
      expect(formData.timesPerWeekTarget, 4);
      expect(formData.showsWeeklyCheckTargetSection, isTrue);
    });

    test('buildScheduleForSave writes canonical timesPerWeek schedule', () {
      final formData = EditHabitTabFormData.fromHabit({
        'id': 'h-2',
        'name': 'Habit',
        'type': 'check',
      });
      formData.frequencyMode = 'timesPerWeek';
      formData.timesPerWeekTarget = 3;

      expect(
        formData.buildScheduleForSave(),
        {
          'type': 'timesPerWeek',
          'timesPerWeek': 3,
          'weekStartsOn': 1,
        },
      );
    });

    test('count habits never save timesPerWeek schedule', () {
      final formData = EditHabitTabFormData.fromHabit({
        'id': 'h-3',
        'name': 'Habit',
        'type': 'check',
      });
      formData.frequencyMode = 'timesPerWeek';
      formData.setTrackingTypeToCount();

      expect(formData.frequencyMode, 'daily');
      expect(formData.buildScheduleForSave(), {'type': 'daily'});
    });
  });
}
