import '../domain/models/onboarding_recommendation.dart';

abstract interface class RecommendationCatalogRepository {
  Future<OnboardingRecommendationCatalogSnapshot> resolve({
    required int catalogVersion,
    required String locale,
  });
}

class RecommendationCatalogException implements Exception {
  const RecommendationCatalogException({
    required this.message,
    required this.catalogVersion,
    this.cause,
  });

  final String message;
  final int catalogVersion;
  final Object? cause;

  @override
  String toString() => 'RecommendationCatalogException: $message';
}
