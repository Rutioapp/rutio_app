import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/home/home_screen.dart';

void main() {
  group('Home view data clock', () {
    test('uses the simulated calendar day as today', () {
      final calendarNow = DateTime(2026, 7, 26, 10);
      final root = <String, dynamic>{
        'userState': <String, dynamic>{
          'history': <String, dynamic>{
            'habitCompletions': <String, dynamic>{},
            'habitCountValues': <String, dynamic>{},
            'habitSkips': <String, dynamic>{},
          },
          'activeHabits': <Map<String, dynamic>>[],
          'progression': <String, dynamic>{'xp': 0},
          'wallet': <String, dynamic>{'coins': 0},
          'profile': <String, dynamic>{},
        },
      };

      final viewData = buildHomeViewData(root, calendarNow, calendarNow);

      expect(viewData.dayLabel, 'Hoy');
      expect(viewData.totalCount, 0);
      expect(viewData.doneCount, 0);
    });
  });
}
