import 'package:flutter/cupertino.dart';

import '../../premium/domain/premium_access_policy.dart';
import '../../premium/presentation/premium_navigation.dart';
import 'screens/weekly_report_history_screen.dart';
import 'screens/weekly_report_screen.dart';

Future<void> openWeeklyReport(
  BuildContext context, {
  String? reportId,
  bool openedFromHistory = false,
}) async {
  if (!canAccessPremiumFeature(context, PremiumFeature.weeklyReport)) {
    logPremiumGateBlocked(context, PremiumFeature.weeklyReport);
    final unlocked = await openPremiumPaywall(
      context,
      source: PremiumUpgradeSource.weeklyReport,
    );
    if (!context.mounted || !unlocked) return;
  }

  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    CupertinoPageRoute<void>(
      builder: (_) => WeeklyReportScreen(
        reportId: reportId,
        openedFromHistory: openedFromHistory,
      ),
    ),
  );
}

Future<void> openWeeklyReportHistory(BuildContext context) async {
  if (!canAccessPremiumFeature(context, PremiumFeature.weeklyReport)) {
    logPremiumGateBlocked(context, PremiumFeature.weeklyReport);
    final unlocked = await openPremiumPaywall(
      context,
      source: PremiumUpgradeSource.weeklyReport,
    );
    if (!context.mounted || !unlocked) return;
  }

  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    CupertinoPageRoute<void>(
      builder: (_) => const WeeklyReportHistoryScreen(),
    ),
  );
}
