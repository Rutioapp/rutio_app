import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats/habit_stats_header.dart';

void main() {
  testWidgets(
      'header keeps metadata in one line with ellipsis on compact width',
      (tester) async {
    const subtitle =
        'Professional - Monday, Wednesday, Friday, Saturday, Sunday objective label';

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(320, 568)),
          child: Scaffold(
            body: HabitStatsHeader(
              title: 'A very long habit title for compact iPhone layout',
              familyAndObjective: subtitle,
              familyColor: Colors.blue,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final subtitleText = tester.widget<Text>(find.text(subtitle));
    expect(subtitleText.maxLines, 1);
    expect(subtitleText.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}
