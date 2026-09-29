import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_theme.dart';
import '../domain/premium_access_policy.dart';
import 'premium_navigation.dart';

class PremiumLockBadge extends StatelessWidget {
  const PremiumLockBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.premiumLockLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.earth.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 13, color: AppColors.earth),
            const SizedBox(width: 4),
            Text(
              context.l10n.premiumBadge,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.earth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumLockedFeatureView extends StatelessWidget {
  const PremiumLockedFeatureView({
    super.key,
    required this.feature,
    this.showBackButton = false,
  });

  final PremiumFeature feature;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: showBackButton
          ? AppBar(
              backgroundColor: AppColors.cream,
              elevation: 0,
              title: Text(l10n.premiumTitle),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline,
                    size: 38, color: AppColors.earth),
                const SizedBox(height: 14),
                Text(
                  l10n.premiumGateTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.premiumFeatureMessage(feature),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => openPremiumPaywall(
                    context,
                    source: _sourceFor(feature),
                  ),
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: Text(l10n.premiumViewAction),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PremiumUpgradeSource _sourceFor(PremiumFeature value) {
    switch (value) {
      case PremiumFeature.weeklyStatistics:
        return PremiumUpgradeSource.weeklyStatistics;
      case PremiumFeature.monthlyStatistics:
        return PremiumUpgradeSource.monthlyStatistics;
      case PremiumFeature.annualStatistics:
        return PremiumUpgradeSource.annualStatistics;
      case PremiumFeature.perHabitStatistics:
        return PremiumUpgradeSource.perHabitStatistics;
      case PremiumFeature.weeklyReport:
        return PremiumUpgradeSource.weeklyReport;
    }
  }
}
