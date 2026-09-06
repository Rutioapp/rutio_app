import '../data/shared_preferences_onboarding_draft_store.dart';
import '../domain/models/onboarding_draft.dart';
import '../domain/models/onboarding_types.dart';
import '../domain/onboarding_draft_store.dart';

/// Minimal application operations needed by the future coordinator.
/// Navigation, auth and remote completion deliberately remain outside this
/// service in Phase 1.
class OnboardingDraftService {
  OnboardingDraftService({
    required OnboardingDraftStore store,
    DateTime Function()? now,
    String Function()? uuidGenerator,
  })  : _store = store,
        _now = now ?? DateTime.now,
        _uuidGenerator = uuidGenerator;

  factory OnboardingDraftService.sharedPreferences({
    DateTime Function()? now,
    String Function()? uuidGenerator,
  }) {
    return OnboardingDraftService(
      store: SharedPreferencesOnboardingDraftStore(now: now),
      now: now,
      uuidGenerator: uuidGenerator,
    );
  }

  final OnboardingDraftStore _store;
  final DateTime Function() _now;
  final String Function()? _uuidGenerator;

  Future<OnboardingDraft> createNew() async {
    final draft = OnboardingDraft.create(
      now: _now,
      uuidGenerator: _uuidGenerator,
    );
    await _store.saveAnonymousDraft(draft);
    return draft;
  }

  /// Deletes the current anonymous draft and creates a fresh one with new
  /// identities and timestamps.
  Future<OnboardingDraft> restart() async {
    await _store.deleteAnonymousDraft();
    return createNew();
  }

  Future<OnboardingDraft?> loadAnonymousDraft() => _store.loadAnonymousDraft();

  Future<OnboardingDraftLoadResult> loadAnonymousDraftResult() =>
      _store.loadAnonymousDraftResult();

  Future<bool> hasAnonymousDraft() => _store.hasAnonymousDraft();

  Future<void> saveAnonymousDraft(OnboardingDraft draft) async {
    await _store.saveAnonymousDraft(draft.copyWith(updatedAt: _now()));
  }

  /// Explicitly binds an anonymous draft to one account. The anonymous copy
  /// is removed only after the user-scoped copy has been persisted.
  Future<OnboardingDraft> bindToUser(
    OnboardingDraft draft,
    String userId,
  ) async {
    final bound = draft.bindToUser(userId);
    await _store.saveForUser(userId, bound.copyWith(updatedAt: _now()));
    await _store.deleteAnonymousDraft();
    return bound;
  }

  OnboardingStep get initialStep => OnboardingStep.name;

  OnboardingCompletionState get initialCompletionState =>
      OnboardingCompletionState.draft;
}
