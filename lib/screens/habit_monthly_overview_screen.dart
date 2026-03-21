
import 'package:flutter/material.dart';
import 'package:rutio/screens/habit_monthly_screen.dart';

/// Backwards-compatible wrapper.
/// If some menus still navigate to HabitMonthlyOverviewScreen, this now shows the unified Monthly screen.
class HabitMonthlyOverviewScreen extends StatelessWidget {
  const HabitMonthlyOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HabitMonthlyScreen();
  }
}

