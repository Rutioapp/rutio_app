import 'models/onboarding_draft.dart';

enum OnboardingDraftLoadStatus {
  missing,
  valid,
  migrated,
  corrupt,
  unsupportedFutureSchema,
  recoverableError,
}

class OnboardingDraftLoadResult {
  const OnboardingDraftLoadResult({
    required this.status,
    this.draft,
    this.message,
  });

  const OnboardingDraftLoadResult.missing()
      : status = OnboardingDraftLoadStatus.missing,
        draft = null,
        message = null;

  final OnboardingDraftLoadStatus status;
  final OnboardingDraft? draft;
  final String? message;

  bool get hasDraft => draft != null;
  bool get isRecoverable =>
      status == OnboardingDraftLoadStatus.recoverableError ||
      status == OnboardingDraftLoadStatus.unsupportedFutureSchema;
}

abstract interface class OnboardingDraftStore {
  Future<OnboardingDraft?> loadAnonymousDraft();

  Future<OnboardingDraftLoadResult> loadAnonymousDraftResult();

  Future<void> saveAnonymousDraft(OnboardingDraft draft);

  Future<void> deleteAnonymousDraft();

  Future<bool> hasAnonymousDraft();

  Future<OnboardingDraft?> loadForUser(String userId);

  Future<void> saveForUser(String userId, OnboardingDraft draft);

  Future<void> deleteForUser(String userId);
}
