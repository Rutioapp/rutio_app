import 'package:flutter/foundation.dart';

import 'models/onboarding_recommendation.dart';
import 'models/onboarding_types.dart';
import 'onboarding_recommendation_catalog_validator.dart';

@immutable
class OnboardingRecommendationRankingRequest {
  const OnboardingRecommendationRankingRequest({
    required this.snapshot,
    required this.selectedGoalCodes,
    required this.pace,
    this.shownRecommendationIds = const <String>{},
    this.discardedRecommendationIds = const <String>{},
    this.requestedCount,
    this.includeDiscardedAsLastResort = true,
  });

  final OnboardingRecommendationCatalogSnapshot snapshot;
  final Set<String> selectedGoalCodes;
  final OnboardingPace pace;
  final Set<String> shownRecommendationIds;
  final Set<String> discardedRecommendationIds;
  final int? requestedCount;
  final bool includeDiscardedAsLastResort;
}

class OnboardingRecommendationRankingService {
  const OnboardingRecommendationRankingService();

  static const int goalPrimaryWeight = 100;
  static const int goalSecondaryWeight = 60;
  static const int paceIdealWeight = 30;
  static const int paceAdjacentWeight = 15;
  static const int paceNeutralWeight = 0;
  static const int paceUnsuitableWeight = -20;

  List<OnboardingRecommendation> rank(
    OnboardingRecommendationRankingRequest request,
  ) {
    final validation = OnboardingRecommendationCatalogValidator.validate(
      request.snapshot,
      expectedVersion: request.snapshot.version,
    );
    final eligible = validation.validRecommendations;
    final candidates = <_ScoredRecommendation>[];
    for (final recommendation in eligible) {
      candidates.add(_ScoredRecommendation(
        recommendation,
        _score(recommendation, request),
        _goalCoverage(recommendation, request),
      ));
    }

    candidates.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      final coverage = b.goalCoverage.compareTo(a.goalCoverage);
      if (coverage != 0) return coverage;
      return a.recommendation.id.compareTo(b.recommendation.id);
    });

    final target = request.requestedCount ??
        _targetCount(request.snapshot, request.selectedGoalCodes, eligible);
    final unseen = candidates
        .where((entry) =>
            !request.shownRecommendationIds.contains(entry.recommendation.id) &&
            !request.discardedRecommendationIds
                .contains(entry.recommendation.id))
        .toList();
    final shown = candidates
        .where((entry) =>
            request.shownRecommendationIds.contains(entry.recommendation.id) &&
            !request.discardedRecommendationIds
                .contains(entry.recommendation.id))
        .toList();
    final discarded = candidates
        .where((entry) => request.discardedRecommendationIds
            .contains(entry.recommendation.id))
        .toList();

    final selected = <_ScoredRecommendation>[];
    _selectDiverse(selected, unseen, target, request.selectedGoalCodes);
    if (selected.length < target) {
      _selectDiverse(selected, shown, target, request.selectedGoalCodes);
    }
    if (selected.length < target && request.includeDiscardedAsLastResort) {
      _selectDiverse(selected, discarded, target, request.selectedGoalCodes);
    }
    return selected
        .take(target)
        .map((entry) => entry.recommendation)
        .toList(growable: false);
  }

  int score(
    OnboardingRecommendation recommendation, {
    required Iterable<String> selectedGoalCodes,
    required OnboardingPace pace,
    required OnboardingRecommendationCatalogSnapshot snapshot,
  }) {
    return _score(
      recommendation,
      OnboardingRecommendationRankingRequest(
        snapshot: snapshot,
        selectedGoalCodes: selectedGoalCodes.toSet(),
        pace: pace,
      ),
    );
  }

  bool isRelevant(
    OnboardingRecommendation recommendation,
    Iterable<String> goalCodes,
  ) {
    return recommendation.goalCodes.intersection(goalCodes.toSet()).isNotEmpty;
  }

  int _score(
    OnboardingRecommendation recommendation,
    OnboardingRecommendationRankingRequest request,
  ) {
    var score = recommendation.editorialPriority;
    for (final goalCode in request.selectedGoalCodes) {
      if (!recommendation.goalCodes.contains(goalCode)) continue;
      final relation = request.snapshot.relationFor(goalCode);
      if (relation == null) continue;
      if (relation.primaryFamilyCodes
          .contains(recommendation.primaryFamilyCode)) {
        score += goalPrimaryWeight;
      } else if (relation.secondaryFamilyCodes
          .contains(recommendation.primaryFamilyCode)) {
        score += goalSecondaryWeight;
      } else if (recommendation.secondaryFamilyCodes
          .intersection(relation.primaryFamilyCodes)
          .isNotEmpty) {
        score += goalSecondaryWeight;
      }
    }
    score += _paceScore(recommendation, request.pace);
    return score;
  }

  int _paceScore(OnboardingRecommendation recommendation, OnboardingPace pace) {
    switch (recommendation.paceCompatibility[pace]) {
      case OnboardingPaceCompatibility.ideal:
        return paceIdealWeight;
      case OnboardingPaceCompatibility.adjacent:
        return paceAdjacentWeight;
      case OnboardingPaceCompatibility.unsuitable:
        return paceUnsuitableWeight;
      case OnboardingPaceCompatibility.neutral:
      case null:
        return paceNeutralWeight;
    }
  }

  int _goalCoverage(
    OnboardingRecommendation recommendation,
    OnboardingRecommendationRankingRequest request,
  ) {
    return request.selectedGoalCodes
        .where(recommendation.goalCodes.contains)
        .length;
  }

  int _targetCount(
    OnboardingRecommendationCatalogSnapshot snapshot,
    Set<String> goals,
    List<OnboardingRecommendation> eligible,
  ) {
    final families = <String>{};
    for (final goal in goals) {
      final relation = snapshot.relationFor(goal);
      if (relation == null) continue;
      families
        ..addAll(relation.primaryFamilyCodes)
        ..addAll(relation.secondaryFamilyCodes);
    }
    final relevant = eligible
        .where((recommendation) => isRelevant(recommendation, goals))
        .map((recommendation) =>
            recommendation.habitCatalogId ?? recommendation.id)
        .toSet();
    return families.length >= 3 && relevant.length >= 6 ? 6 : 4;
  }

  void _selectDiverse(
    List<_ScoredRecommendation> selected,
    List<_ScoredRecommendation> source,
    int target,
    Set<String> selectedGoalCodes,
  ) {
    final remaining = source.toList();
    final families =
        selected.map((entry) => entry.recommendation.primaryFamilyCode).toSet();
    while (selected.length < target && remaining.isNotEmpty) {
      _ScoredRecommendation? next;
      final coveredGoals = selected
          .expand((entry) => entry.recommendation.goalCodes)
          .toSet()
          .intersection(selectedGoalCodes);
      for (final candidate in remaining) {
        final duplicate = selected.any((item) =>
            candidate.recommendation.habitCatalogId != null &&
            candidate.recommendation.habitCatalogId ==
                item.recommendation.habitCatalogId);
        if (duplicate) continue;
        if (next == null) {
          next = candidate;
          continue;
        }
        final candidateAddsGoal = candidate.recommendation.goalCodes
            .intersection(selectedGoalCodes)
            .difference(coveredGoals)
            .isNotEmpty;
        final nextAddsGoal = next.recommendation.goalCodes
            .intersection(selectedGoalCodes)
            .difference(coveredGoals)
            .isNotEmpty;
        if (candidateAddsGoal && !nextAddsGoal) {
          next = candidate;
          continue;
        }
        final candidateAddsFamily =
            !families.contains(candidate.recommendation.primaryFamilyCode);
        final nextAddsFamily =
            !families.contains(next.recommendation.primaryFamilyCode);
        if (candidateAddsFamily && !nextAddsFamily) {
          next = candidate;
        }
      }
      if (next == null) break;
      selected.add(next);
      remaining.remove(next);
      families.add(next.recommendation.primaryFamilyCode);
    }
  }
}

class _ScoredRecommendation {
  const _ScoredRecommendation(
      this.recommendation, this.score, this.goalCoverage);

  final OnboardingRecommendation recommendation;
  final int score;
  final int goalCoverage;
}
