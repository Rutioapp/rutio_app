import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'onboarding_types.dart';

class OnboardingDraftBindingException implements Exception {
  const OnboardingDraftBindingException(this.message);

  final String message;

  @override
  String toString() => 'OnboardingDraftBindingException: $message';
}

/// The habit payload uses Rutio's existing local `activeHabits` map contract.
/// It intentionally has no parallel HabitDraft model. Unknown future keys are
/// retained by the codec so the real habit contract can grow in a later phase.
@immutable
class OnboardingDraft {
  OnboardingDraft({
    required this.draftId,
    required this.onboardingOperationId,
    required this.draftSchemaVersion,
    required this.onboardingVersion,
    required this.catalogVersion,
    required DateTime createdAt,
    required DateTime updatedAt,
    required this.currentStep,
    String? firstName,
    Set<String>? goalCodes,
    this.pace,
    Map<String, dynamic>? habit,
    Map<String, dynamic>? reminder,
    Set<String>? shownRecommendationIds,
    Set<String>? discardedRecommendationIds,
    this.selectedRecommendationId,
    this.authIntent,
    this.authEmail,
    this.completionState = OnboardingCompletionState.draft,
    this.completionAccountResolutionCode,
    this.completionPreparedHabitDecisionCode,
    this.boundUserId,
    DateTime? completedAt,
  })  : createdAt = createdAt.toUtc(),
        updatedAt = updatedAt.toUtc(),
        firstName = _normalizeOptionalString(firstName),
        goalCodes = Set.unmodifiable(goalCodes ?? const <String>{}),
        habit = _immutableJsonMap(habit),
        reminder = _immutableJsonMap(reminder),
        shownRecommendationIds =
            Set.unmodifiable(shownRecommendationIds ?? const <String>{}),
        discardedRecommendationIds = Set.unmodifiable(
          discardedRecommendationIds ?? const <String>{},
        ),
        completedAt = completedAt?.toUtc();

  factory OnboardingDraft.create({
    DateTime Function()? now,
    String Function()? uuidGenerator,
  }) {
    final timestamp = (now ?? DateTime.now)().toUtc();
    final generateId = uuidGenerator ?? const Uuid().v4;
    final draftId = generateId();
    var operationId = generateId();
    if (operationId == draftId) operationId = const Uuid().v4();
    if (operationId == draftId) {
      throw StateError('Could not generate distinct onboarding IDs.');
    }

    return OnboardingDraft(
      draftId: draftId,
      onboardingOperationId: operationId,
      draftSchemaVersion: OnboardingVersions.draftSchemaVersion,
      onboardingVersion: OnboardingVersions.onboardingVersion,
      catalogVersion: OnboardingVersions.catalogVersion,
      createdAt: timestamp,
      updatedAt: timestamp,
      currentStep: OnboardingStep.name,
    );
  }

  final String draftId;
  final String onboardingOperationId;
  final int draftSchemaVersion;
  final int onboardingVersion;
  final int catalogVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final OnboardingStep currentStep;
  final String? firstName;
  final Set<String> goalCodes;
  final OnboardingPace? pace;
  final Map<String, dynamic>? habit;
  final Map<String, dynamic>? reminder;
  final Set<String> shownRecommendationIds;
  final Set<String> discardedRecommendationIds;
  final String? selectedRecommendationId;
  final AuthIntent? authIntent;
  final String? authEmail;
  final OnboardingCompletionState completionState;
  final String? completionAccountResolutionCode;
  final String? completionPreparedHabitDecisionCode;
  final String? boundUserId;
  final DateTime? completedAt;

  bool get isCompleted =>
      completionState == OnboardingCompletionState.completed;

  bool get isResumable =>
      !isCompleted &&
      !(completionState == OnboardingCompletionState.recoverableError &&
          currentStep == OnboardingStep.finalizing);

  bool isResumableAt(DateTime now) => isResumable;

  bool shouldRetainCompletedAt(
    DateTime now, {
    Duration retention = const Duration(hours: 24),
  }) {
    if (!isCompleted) return false;
    final reference = completedAt ?? updatedAt;
    return !now.toUtc().isAfter(reference.add(retention));
  }

  OnboardingDraft bindToUser(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      throw const OnboardingDraftBindingException('userId must not be empty.');
    }
    if (boundUserId != null && boundUserId != normalized) {
      throw OnboardingDraftBindingException(
        'Draft is already bound to another user.',
      );
    }
    if (boundUserId == normalized) return this;
    return copyWith(boundUserId: normalized);
  }

  OnboardingDraft copyWith({
    String? draftId,
    String? onboardingOperationId,
    int? draftSchemaVersion,
    int? onboardingVersion,
    int? catalogVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
    OnboardingStep? currentStep,
    Object? firstName = _unset,
    Set<String>? goalCodes,
    Object? pace = _unset,
    Object? habit = _unset,
    Object? reminder = _unset,
    Set<String>? shownRecommendationIds,
    Set<String>? discardedRecommendationIds,
    Object? selectedRecommendationId = _unset,
    Object? authIntent = _unset,
    Object? authEmail = _unset,
    OnboardingCompletionState? completionState,
    Object? completionAccountResolutionCode = _unset,
    Object? completionPreparedHabitDecisionCode = _unset,
    Object? boundUserId = _unset,
    Object? completedAt = _unset,
  }) {
    return OnboardingDraft(
      draftId: draftId ?? this.draftId,
      onboardingOperationId:
          onboardingOperationId ?? this.onboardingOperationId,
      draftSchemaVersion: draftSchemaVersion ?? this.draftSchemaVersion,
      onboardingVersion: onboardingVersion ?? this.onboardingVersion,
      catalogVersion: catalogVersion ?? this.catalogVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentStep: currentStep ?? this.currentStep,
      firstName:
          identical(firstName, _unset) ? this.firstName : firstName as String?,
      goalCodes: goalCodes ?? this.goalCodes,
      pace: identical(pace, _unset) ? this.pace : pace as OnboardingPace?,
      habit: identical(habit, _unset)
          ? this.habit
          : habit as Map<String, dynamic>?,
      reminder: identical(reminder, _unset)
          ? this.reminder
          : reminder as Map<String, dynamic>?,
      shownRecommendationIds:
          shownRecommendationIds ?? this.shownRecommendationIds,
      discardedRecommendationIds:
          discardedRecommendationIds ?? this.discardedRecommendationIds,
      selectedRecommendationId: identical(selectedRecommendationId, _unset)
          ? this.selectedRecommendationId
          : selectedRecommendationId as String?,
      authIntent: identical(authIntent, _unset)
          ? this.authIntent
          : authIntent as AuthIntent?,
      authEmail:
          identical(authEmail, _unset) ? this.authEmail : authEmail as String?,
      completionState: completionState ?? this.completionState,
      completionAccountResolutionCode: identical(
        completionAccountResolutionCode,
        _unset,
      )
          ? this.completionAccountResolutionCode
          : completionAccountResolutionCode as String?,
      completionPreparedHabitDecisionCode: identical(
        completionPreparedHabitDecisionCode,
        _unset,
      )
          ? this.completionPreparedHabitDecisionCode
          : completionPreparedHabitDecisionCode as String?,
      boundUserId: identical(boundUserId, _unset)
          ? this.boundUserId
          : boundUserId as String?,
      completedAt: identical(completedAt, _unset)
          ? this.completedAt
          : completedAt as DateTime?,
    );
  }

  static const Object _unset = Object();

  static String? _normalizeOptionalString(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static Map<String, dynamic>? _immutableJsonMap(Map<String, dynamic>? value) {
    if (value == null) return null;
    return Map.unmodifiable(_copyJsonMap(value));
  }

  static Map<String, dynamic> _copyJsonMap(Map<String, dynamic> value) {
    return value.map((key, value) => MapEntry(key, _copyJsonValue(value)));
  }

  static dynamic _copyJsonValue(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), _copyJsonValue(value)),
      );
    }
    if (value is List) return value.map(_copyJsonValue).toList(growable: false);
    return value;
  }
}
