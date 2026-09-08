import '../application/onboarding_draft_service.dart';
import '../domain/auth/onboarding_auth_contracts.dart';
import '../domain/models/onboarding_draft.dart';

class DraftOnboardingAuthPersistence implements OnboardingAuthDraftPersistence {
  const DraftOnboardingAuthPersistence(this._service);

  final OnboardingDraftService _service;

  @override
  Future<void> save(OnboardingDraft draft) async {
    final boundUserId = draft.boundUserId;
    if (boundUserId == null) {
      await _service.saveAnonymousDraft(draft);
    } else {
      await _service.bindToUser(draft, boundUserId);
    }
  }

  @override
  Future<void> clear(OnboardingDraft draft) =>
      _service.clearAfterCompletion(draft);
}
