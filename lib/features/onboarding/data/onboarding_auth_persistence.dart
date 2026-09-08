import '../application/onboarding_draft_service.dart';
import '../domain/auth/onboarding_auth_contracts.dart';
import '../domain/models/onboarding_draft.dart';

class DraftOnboardingAuthPersistence implements OnboardingAuthDraftPersistence {
  const DraftOnboardingAuthPersistence(this._service);

  final OnboardingDraftService _service;

  @override
  Future<void> save(OnboardingDraft draft) =>
      _service.saveAnonymousDraft(draft);

  @override
  Future<void> clear(OnboardingDraft draft) =>
      _service.clearAfterCompletion(draft);
}
