import 'models/onboarding_draft.dart';

class OnboardingDraftRetentionPolicy {
  const OnboardingDraftRetentionPolicy({
    this.completedRetention = const Duration(hours: 24),
  });

  final Duration completedRetention;

  bool isReanudable(OnboardingDraft draft, {required DateTime now}) {
    if (draft.isCompleted) return false;
    return draft.isResumableAt(now);
  }

  bool isResumable(OnboardingDraft draft, {required DateTime now}) =>
      isReanudable(draft, now: now);

  bool shouldRetain(OnboardingDraft draft, {required DateTime now}) {
    if (!draft.isCompleted) return true;
    return draft.shouldRetainCompletedAt(
      now,
      retention: completedRetention,
    );
  }
}
