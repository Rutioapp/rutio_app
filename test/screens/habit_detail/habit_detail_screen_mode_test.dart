import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/habit_detail/habit_detail_screen.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/edit_habit_tab.dart';
import 'package:rutio/screens/habit_detail/widgets/tabs/habit_stats_tab.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, appChild) {
      final data = MediaQuery.of(context);
      return MediaQuery(
        data: data.copyWith(textScaler: const TextScaler.linear(0.2)),
        child: appChild ?? const SizedBox.shrink(),
      );
    },
    home: child,
  );
}

void main() {
  final habit = <String, dynamic>{
    'title': 'Resolver un problema lógico',
  };

  testWidgets('normal mode shows edit and stats tabs', (tester) async {
    await tester.pumpWidget(
      _testApp(
        HabitDetailScreen(
          habit: habit,
          familyColor: Colors.blue,
          mode: HabitDetailScreenMode.normal,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HabitDetailScreen)),
    );

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text(l10n.habitDetailEditTab), findsOneWidget);
    expect(find.text(l10n.habitDetailStatsTab), findsOneWidget);
    expect(find.byType(EditHabitTab), findsOneWidget);
    expect(find.byType(HabitStatsTab), findsNothing);
  });

  testWidgets('statsOnly mode hides tab selector and edit tab', (tester) async {
    await tester.pumpWidget(
      _testApp(
        HabitDetailScreen(
          habit: habit,
          familyColor: Colors.blue,
          mode: HabitDetailScreenMode.statsOnly,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HabitDetailScreen)),
    );

    expect(find.byType(TabBar), findsNothing);
    expect(find.text(l10n.habitDetailEditTab), findsNothing);
    expect(find.text(l10n.habitDetailStatsTab), findsNothing);
    expect(find.byType(EditHabitTab), findsNothing);
    expect(find.byType(HabitStatsTab), findsOneWidget);
  });

  testWidgets(
      'editOnly mode hides tab selector and old habit-title app bar',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        HabitDetailScreen(
          habit: habit,
          familyColor: Colors.blue,
          mode: HabitDetailScreenMode.editOnly,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(HabitDetailScreen)),
    );

    expect(find.byType(TabBar), findsNothing);
    expect(find.text(l10n.habitDetailStatsTab), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text(l10n.editHabitHeaderTitle), findsOneWidget);
    expect(find.byType(EditHabitTab), findsOneWidget);
    expect(find.byType(HabitStatsTab), findsNothing);
  });
}
