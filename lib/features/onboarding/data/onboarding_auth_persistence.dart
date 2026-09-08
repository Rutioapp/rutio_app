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
  Future<void> clear(OnboardingDraft draft) async {
    // AUTH-3 owns draft clearing. Keeping this no-op prevents an AUTH-2
    // success/session event from deleting the user's recoverable draft.
  }
}
