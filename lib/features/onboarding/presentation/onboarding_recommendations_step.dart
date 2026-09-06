import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_theme.dart';
import '../domain/models/onboarding_recommendation.dart';

class OnboardingRecommendationsStep extends StatelessWidget {
  const OnboardingRecommendationsStep({
    super.key,
    required this.recommendations,
    required this.selectedRecommendationId,
    required this.isLoading,
    required this.isRefreshing,
    required this.onSelect,
    required this.onRefresh,
    required this.onCreateFromScratch,
    required this.onRetry,
  });

  final List<OnboardingRecommendation>? recommendations;
  final String? selectedRecommendationId;
  final bool isLoading;
  final bool isRefreshing;
  final ValueChanged<String> onSelect;
  final VoidCallback onRefresh;
  final VoidCallback onCreateFromScratch;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final items = recommendations ?? const <OnboardingRecommendation>[];
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (isLoading && items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 42),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.onboardingRecommendationsEmpty,
            style: AppTextStyles.welcomeSub,
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: isRefreshing ? null : onRetry,
            child: Text(context.l10n.onboardingRetry),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.onboardingStepRecommendations,
          style: AppTextStyles.authSub.copyWith(
            color: AppColors.ink.withValues(alpha: 0.56),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
            context.l10n.onboardingRecommendationsUpdated,
            style: AppTextStyles.welcomeSub.copyWith(
              color: AppColors.ink.withValues(alpha: 0.68),
            ),
          ),
        ),
        const SizedBox(height: 18),
        ...items.map(
          (recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RecommendationCard(
              recommendation: recommendation,
              locale: locale,
              selected: recommendation.id == selectedRecommendationId,
              enabled: !isRefreshing,
              onTap: () => onSelect(recommendation.id),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isRefreshing ? null : onRefresh,
            icon: isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(context.l10n.onboardingRecommendationsRefresh),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: isRefreshing ? null : onCreateFromScratch,
            child: Text(context.l10n.onboardingRecommendationsCreateCustom),
          ),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.locale,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final OnboardingRecommendation recommendation;
  final String locale;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = recommendation.nameFor(locale);
    return Semantics(
      button: true,
      selected: selected,
      label: selected
          ? '$name, ${context.l10n.onboardingRecommendationSelected}'
          : name,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: AppColors.cream2.withValues(alpha: 0.78),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected
                ? AppColors.rust
                : AppColors.ink.withValues(alpha: 0.10),
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
            child: Row(
              children: [
                Text(recommendation.emoji,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    name,
                    style: AppTextStyles.authTitle.copyWith(fontSize: 18),
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.chevron_right,
                  color: selected
                      ? AppColors.rust
                      : AppColors.ink.withValues(alpha: 0.48),
                  semanticLabel: selected
                      ? context.l10n.onboardingRecommendationSelected
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
