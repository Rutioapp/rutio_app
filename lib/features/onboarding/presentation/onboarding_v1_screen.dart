import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/auth/auth_controller.dart';
import '../../../l10n/l10n.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/backgrounds/rutio_sky_background.dart';
import '../application/onboarding_coordinator.dart';
import '../domain/models/onboarding_types.dart';
import '../domain/onboarding_goals.dart';
import '../domain/onboarding_validation.dart';
import 'onboarding_shell.dart';
import 'onboarding_goals_step.dart';
import 'onboarding_name_step.dart';
import 'onboarding_pace_step.dart';
import '../../../screens/welcome/widgets/welcome_content.dart';

/// V1 coordinator-backed entry point. The seven step presenters are
/// intentionally temporary and can be replaced without changing navigation
/// or persistence ownership.
class OnboardingV1Screen extends StatefulWidget {
  const OnboardingV1Screen({super.key});

  @override
  State<OnboardingV1Screen> createState() => _OnboardingV1ScreenState();
}

class _OnboardingV1ScreenState extends State<OnboardingV1Screen> {
  bool _resumeRequested = false;
  final GlobalKey<OnboardingNameStepState> _nameStepKey =
      GlobalKey<OnboardingNameStepState>();
  final GlobalKey<OnboardingGoalsStepState> _goalsStepKey =
      GlobalKey<OnboardingGoalsStepState>();
  final GlobalKey<OnboardingPaceStepState> _paceStepKey =
      GlobalKey<OnboardingPaceStepState>();
  bool _goalsCanSubmit = false;
  bool _paceCanSubmit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resumeRequested) return;
    _resumeRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<OnboardingCoordinator>().resume());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingCoordinator>(
      builder: (context, coordinator, _) {
        final state = coordinator.state;
        if (state.isLoading && state.draft == null) {
          return _LoadingView();
        }
        if (state.isAtWelcome || state.draft == null) {
          return _buildWelcome(context, coordinator, state);
        }
        final step = state.effectiveStep ?? OnboardingStep.name;
        final isGoals = step == OnboardingStep.goals;
        final isPace = step == OnboardingStep.pace;
        return AnimatedSwitcher(
          duration: MediaQuery.maybeOf(context)?.disableAnimations == true
              ? Duration.zero
              : const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: OnboardingShell(
            key: ValueKey<OnboardingStep>(step),
            step: step,
            progress: state.progress,
            canGoBack: state.canGoBack,
            isBusy: state.isPersisting,
            showStepHeader: step != OnboardingStep.name,
            content: step == OnboardingStep.name
                ? OnboardingNameStep(
                    key: _nameStepKey,
                    initialValue: state.draft?.firstName ?? '',
                    errorMessage: _nameErrorMessage(context, state),
                    onSubmit: (value) =>
                        unawaited(coordinator.submitName(value)),
                  )
                : isGoals
                    ? OnboardingGoalsStep(
                        key: _goalsStepKey,
                        initialGoalCodes:
                            state.draft?.goalCodes ?? const <String>{},
                        errorMessage: _goalsErrorMessage(context, state),
                        onSelectionChanged: _onGoalsSelectionChanged,
                        onSubmit: (values) =>
                            unawaited(coordinator.submitGoals(values)),
                      )
                    : isPace
                        ? OnboardingPaceStep(
                            key: _paceStepKey,
                            initialPace: state.draft?.pace,
                            errorMessage: _paceErrorMessage(context, state),
                            onSelectionChanged: _onPaceSelectionChanged,
                            onSubmit: (pace) =>
                                unawaited(coordinator.submitPace(pace)),
                          )
                        : null,
            continueEnabled:
                (!isGoals || _goalsCanSubmit) && (!isPace || _paceCanSubmit),
            errorMessage: state.isRecoverableError
                ? context.l10n.onboardingRecoverableError
                : null,
            onBack: () => unawaited(coordinator.goBack()),
            onContinue: state.canAdvance
                ? step == OnboardingStep.name
                    ? () => _nameStepKey.currentState?.submit()
                    : isGoals
                        ? () => _goalsStepKey.currentState?.submit()
                        : isPace
                            ? () => _paceStepKey.currentState?.submit()
                            : () =>
                                unawaited(coordinator.submitPlaceholderStep())
                : null,
          ),
        );
      },
    );
  }

  String? _nameErrorMessage(
    BuildContext context,
    OnboardingCoordinatorState state,
  ) {
    final issue = state.validation?.issues.firstOrNull;
    if (issue == null) return null;
    switch (issue.code) {
      case OnboardingValidationCode.required:
        return context.l10n.onboardingNameRequired;
      case OnboardingValidationCode.tooLong:
        return context.l10n.onboardingNameTooLong;
      case OnboardingValidationCode.invalidUnicode:
      case OnboardingValidationCode.minimum:
      case OnboardingValidationCode.maximum:
      case OnboardingValidationCode.duplicate:
      case OnboardingValidationCode.missing:
      case OnboardingValidationCode.unknown:
        return context.l10n.onboardingNameInvalid;
    }
  }

  String? _paceErrorMessage(
    BuildContext context,
    OnboardingCoordinatorState state,
  ) {
    final issue = state.validation?.issues.firstOrNull;
    if (issue == null) return null;
    return context.l10n.onboardingPaceRequired;
  }

  String? _goalsErrorMessage(
    BuildContext context,
    OnboardingCoordinatorState state,
  ) {
    final issue = state.validation?.issues.firstOrNull;
    if (issue == null) return null;
    switch (issue.code) {
      case OnboardingValidationCode.minimum:
      case OnboardingValidationCode.required:
        return context.l10n.onboardingGoalsMinimum;
      case OnboardingValidationCode.maximum:
        return context.l10n.onboardingGoalsMaximum;
      case OnboardingValidationCode.unknown:
      case OnboardingValidationCode.duplicate:
      case OnboardingValidationCode.invalidUnicode:
      case OnboardingValidationCode.tooLong:
      case OnboardingValidationCode.missing:
        return context.l10n.onboardingGoalsInvalid;
    }
  }

  void _onGoalsSelectionChanged(Set<String> values) {
    final canSubmit = OnboardingGoalCatalog.isValidSelection(values);
    if (!mounted || canSubmit == _goalsCanSubmit) return;
    setState(() => _goalsCanSubmit = canSubmit);
  }

  void _onPaceSelectionChanged(OnboardingPace? pace) {
    final canSubmit = pace != null;
    if (!mounted || canSubmit == _paceCanSubmit) return;
    setState(() => _paceCanSubmit = canSubmit);
  }

  Widget _buildWelcome(
    BuildContext context,
    OnboardingCoordinator coordinator,
    OnboardingCoordinatorState state,
  ) {
    final hasResume = state.draft != null && !state.draft!.isCompleted;
    return Stack(
      children: [
        const RutioSkyBackground(showBottomFade: true),
        WelcomeContent(
          onPrepare: () => unawaited(coordinator.startNew()),
          onResume: hasResume ? coordinator.continueDraft : null,
          onRestart:
              hasResume ? () => _confirmRestart(context, coordinator) : null,
          resumeStep: hasResume
              ? _stepLabel(context, state.effectiveStep ?? OnboardingStep.name)
              : null,
          errorMessage: state.isRecoverableError
              ? context.l10n.onboardingRecoverableError
              : null,
          isBusy: state.isPersisting || state.isLoading,
          onLogin: () {
            context.read<AuthController>().clearError();
            Navigator.of(context).pushNamed('/auth');
          },
          onSignup: () {
            context.read<AuthController>().clearError();
            Navigator.of(context).pushNamed('/auth-signup');
          },
        ),
      ],
    );
  }

  Future<void> _confirmRestart(
    BuildContext context,
    OnboardingCoordinator coordinator,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.onboardingRestartTitle),
        content: Text(context.l10n.onboardingRestartBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.onboardingRestartConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await coordinator.restart();
    }
  }

  String _stepLabel(BuildContext context, OnboardingStep step) {
    final l10n = context.l10n;
    switch (step) {
      case OnboardingStep.name:
        return l10n.onboardingStepName;
      case OnboardingStep.goals:
        return l10n.onboardingStepGoals;
      case OnboardingStep.pace:
        return l10n.onboardingStepPace;
      case OnboardingStep.recommendations:
        return l10n.onboardingStepRecommendations;
      case OnboardingStep.habit:
        return l10n.onboardingStepHabit;
      case OnboardingStep.reminder:
        return l10n.onboardingStepReminder;
      case OnboardingStep.preview:
        return l10n.onboardingStepPreview;
      case OnboardingStep.auth:
      case OnboardingStep.emailConfirmation:
      case OnboardingStep.resolvingAccount:
      case OnboardingStep.finalizing:
        return step.code;
    }
  }
}

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(height: 18),
              Text(context.l10n.onboardingLoading),
            ],
          ),
        ),
      ),
    );
  }
}
