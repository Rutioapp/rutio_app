import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_theme.dart';
import '../application/premium_controller.dart';
import '../domain/premium_access.dart';

/// Rutio-owned status and fallback surface around the hosted RevenueCat UI.
///
/// This screen intentionally does not render plans or execute purchases. The
/// normal free-user purchase surface is RevenueCatUI; this screen is reserved
/// for active Premium status and a safe retry state when that UI cannot load.
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({
    super.key,
    this.fallback = false,
    this.onRetry,
    this.accessStateOverride,
  });

  final bool fallback;
  final VoidCallback? onRetry;
  final PremiumAccessState? accessStateOverride;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PremiumController?>();
    final l10n = context.l10n;
    final active = accessStateOverride?.isPremium ??
        controller?.accessState.isPremium ??
        false;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: Text(l10n.premiumTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(l10n.premiumSubtitle, style: AppTextStyles.welcomeSub),
            const SizedBox(height: 20),
            const _BenefitsCard(),
            const SizedBox(height: 18),
            if (active)
              _StatusCard(
                title: l10n.premiumActive,
                subtitle: l10n.premiumActiveSubtitle,
                icon: Icons.check_circle_outline,
              )
            else ...[
              _StatusCard(
                title: fallback
                    ? l10n.premiumUnavailable
                    : l10n.premiumSignInRequired,
                subtitle: fallback
                    ? l10n.premiumGenericError
                    : l10n.premiumSignInRequired,
                icon: Icons.lock_outline_rounded,
              ),
              if (fallback && onRetry != null) ...[
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: onRetry,
                  child: Text(l10n.premiumRetry),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final benefits = [
      l10n.premiumBenefitWeekly,
      l10n.premiumBenefitMonthly,
      l10n.premiumBenefitAnnual,
      l10n.premiumBenefitByHabit,
      l10n.premiumBenefitReport,
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.earth.withValues(alpha: .15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: benefits
            .map(
              (benefit) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: AppColors.sage,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(benefit)),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.earth.withValues(alpha: .15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.sage),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
