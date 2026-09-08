import 'package:flutter/foundation.dart';

/// Runtime-only correlation for the post-completion handoff investigation.
/// It intentionally carries no product state or navigation behavior.
class OnboardingRuntimeTrace {
  OnboardingRuntimeTrace._();

  static int _nextHandoffRunId = 0;
  static int? _activeHandoffRunId;

  static int beginHandoff({
    required String operationId,
    required String? userId,
    required String? currentStep,
    required bool draftPresent,
  }) {
    _activeHandoffRunId = ++_nextHandoffRunId;
    log(
      'ONBOARDING_HANDOFF',
      'event=final_cta_tapped operationId=${short(operationId)} '
          'userId=${short(userId)} mounted=true currentStep=${currentStep ?? 'none'} '
          'draftPresent=$draftPresent',
    );
    return _activeHandoffRunId!;
  }

  static int? get activeHandoffRunId => _activeHandoffRunId;

  static void log(String channel, String message, {int? handoffRunId}) {
    if (!kDebugMode) return;
    final id = handoffRunId ?? _activeHandoffRunId;
    debugPrint('[$channel] ${id == null ? '' : 'handoffRunId=$id '}$message');
  }

  static String short(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'none';
    return normalized.length <= 8 ? normalized : normalized.substring(0, 8);
  }
}
