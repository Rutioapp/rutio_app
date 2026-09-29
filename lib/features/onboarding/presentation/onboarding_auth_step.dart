import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:provider/provider.dart';

import '../application/auth/onboarding_auth_state_machine.dart';
import '../application/onboarding_draft_service.dart';
import '../data/onboarding_auth_persistence.dart';
import '../data/onboarding_completion_reconciler.dart';
import '../domain/auth/onboarding_auth_contracts.dart';
import '../domain/models/onboarding_draft.dart';
import '../domain/models/onboarding_types.dart';
import '../../../application/auth/auth_controller.dart';
import '../../../core/observability/analytics_service.dart';
import '../../../application/bootstrap/bootstrap_controller.dart';
import '../../../stores/user_state_store.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../utils/app_theme.dart';
import '../../../screens/auth/widgets/auth_field.dart';
import '../../../screens/auth/widgets/auth_primary_button.dart';
import '../../../screens/auth/widgets/google_auth_button.dart';
import '../../../screens/auth/widgets/apple_auth_button.dart';
import 'dart:io';

@visibleForTesting
bool onboardingAuthRecoveryGateVisible({
  required bool hasAuthenticatedSession,
  required OnboardingCompletionState completionState,
}) {
  return hasAuthenticatedSession &&
      completionState == OnboardingCompletionState.remoteInProgress;
}

class OnboardingAuthStep extends StatefulWidget {
  const OnboardingAuthStep({
    required this.draft,
    this.onCompletionHandoff,
    super.key,
  });

  final OnboardingDraft draft;
  final Future<void> Function({
    required String operationId,
    required bool habitPresent,
  })? onCompletionHandoff;

  @override
  State<OnboardingAuthStep> createState() => _OnboardingAuthStepState();
}

class _OnboardingAuthStepState extends State<OnboardingAuthStep> {
  late final OnboardingAuthStateMachine _machine;
  late final String _ownershipOperationId;
  BootstrapController? _bootstrapController;
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final TextEditingController _name;
  bool _showManualForm = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.draft.firstName ?? '');
    _email.text = widget.draft.authEmail ?? '';
    _ownershipOperationId = widget.draft.onboardingOperationId;
    try {
      _bootstrapController = context.read<BootstrapController>();
      _bootstrapController
          ?.acquireOnboardingAuthOwnership(_ownershipOperationId);
    } catch (_) {
      // Isolated onboarding widget tests may omit the production bootstrap.
    }
    _machine = OnboardingAuthStateMachine(
      draft: widget.draft,
      auth: context.read<OnboardingAuthPort>(),
      accountResolution: OnboardingAccountResolutionService(
        context.read<OnboardingAccountResolver>(),
      ),
      completion: context.read<OnboardingCompletionPort>(),
      reconciler: LocalOnboardingCompletionReconciler(
        userStateStore: context.read<UserStateStore>(),
      ),
      draftPersistence: DraftOnboardingAuthPersistence(
        context.read<OnboardingDraftService>(),
      ),
      autoCompleteAfterAccountResolution: true,
      onCompletionHandoff: widget.onCompletionHandoff,
      analyticsService: context.read<AnalyticsService?>(),
    )..addListener(_onMachineChanged);
    if (kDebugMode) {
      debugPrint(
        '[ONBOARDING_AUTH] event=machine_created '
        'op=${_shortId(widget.draft.onboardingOperationId)} '
        'draftStep=${widget.draft.currentStep.name}',
      );
    }
    context.read<AuthController>().addListener(_onAuthControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthController>().currentUser?.id;
      if (userId != null) {
        _machine.onAuthenticatedSessionAvailable(
          AuthenticatedOnboardingSession(userId: userId),
        );
      }
    });
  }

  void _onMachineChanged() {
    if (mounted) setState(() {});
  }

  void _onAuthControllerChanged() {
    final userId = context.read<AuthController>().currentUser?.id;
    if (userId == null || !mounted) return;
    final phase = _machine.state.phase;
    if (phase == OnboardingAuthPhase.authenticating ||
        phase == OnboardingAuthPhase.resolvingAccount ||
        phase == OnboardingAuthPhase.readyToComplete ||
        phase == OnboardingAuthPhase.awaitingPreparedHabitDecision ||
        phase == OnboardingAuthPhase.completed) {
      return;
    }
    _machine.onAuthenticatedSessionAvailable(
      AuthenticatedOnboardingSession(userId: userId),
    );
  }

  @override
  void dispose() {
    _bootstrapController?.releaseOnboardingAuthOwnership(_ownershipOperationId);
    if (kDebugMode) {
      debugPrint(
        '[ONBOARDING_AUTH] event=machine_disposed '
        'op=${_shortId(_machine.state.draft.onboardingOperationId)} '
        'phase=${_machine.state.phase.name}',
      );
    }
    context.read<AuthController>().removeListener(_onAuthControllerChanged);
    _machine.removeListener(_onMachineChanged);
    _machine.dispose();
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  static String _shortId(String value) =>
      value.length <= 8 ? value : value.substring(0, 8);

  Future<void> _submit() async {
    if (_isAuthenticatedFrozenRecovery) return;
    FocusScope.of(context).unfocus();
    await _machine.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      email: _email.text,
      password: _password.text,
    );
    _password.clear();
  }

  Future<void> _submitGoogle() async {
    if (_isAuthenticatedFrozenRecovery) return;
    FocusScope.of(context).unfocus();
    await _machine.updateName(_name.text);
    await _machine.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      method: OnboardingAuthMethod.google,
      email: _email.text,
    );
  }

  Future<void> _submitApple() async {
    if (_isAuthenticatedFrozenRecovery) return;
    FocusScope.of(context).unfocus();
    await _machine.updateName(_name.text);
    await _machine.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      method: OnboardingAuthMethod.apple,
      email: _email.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = _machine.state;
    final waiting =
        state.phase == OnboardingAuthPhase.awaitingEmailConfirmation;
    final resolving = state.phase == OnboardingAuthPhase.resolvingAccount;
    final ready = state.phase == OnboardingAuthPhase.readyToComplete ||
        state.phase == OnboardingAuthPhase.awaitingPreparedHabitDecision;
    final completionFailure = state.phase == OnboardingAuthPhase.failure &&
        state.failureStage == OnboardingAuthFailureStage.completion &&
        state.authenticatedUserId != null &&
        state.resolution != null;
    final completionRetryable =
        state.error?.code == OnboardingAuthErrorCode.completionRetryable;
    final recovering = _isAuthenticatedFrozenRecovery &&
        state.phase != OnboardingAuthPhase.completed &&
        !completionFailure;
    if (waiting) {
      return _ConfirmationView(
        email: _email.text,
        isChecking: _machine.manualCheckInFlight,
        isResending: _machine.resendInFlight,
        error: state.error == null ? null : _errorCopy(l10n, state.error!.code),
        onCheck: _machine.checkEmailConfirmation,
        onResend: _machine.resendConfirmation,
      );
    }
    if (completionFailure) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No se pudo finalizar el onboarding. Tu sesión y tus datos siguen guardados.',
              textAlign: TextAlign.center,
              style: AppTextStyles.authSub,
            ),
            if (completionRetryable) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _machine.complete,
                child: const Text('Reintentar finalización'),
              ),
            ],
          ],
        ),
      );
    }
    if (recovering) {
      return const _RecoveryView();
    }
    if (resolving || ready) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              resolving
                  ? l10n.onboardingAuthResolving
                  : l10n.onboardingAuthReady,
              textAlign: TextAlign.center,
              style: AppTextStyles.authSub,
            ),
            if (state.phase ==
                OnboardingAuthPhase.awaitingPreparedHabitDecision) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _machine.choosePreparedHabit(
                  PreparedHabitDecision.discard,
                ),
                child: const Text('Descartar hábito preparado'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _machine.choosePreparedHabit(
                  PreparedHabitDecision.keep,
                ),
                child: const Text('Conservar hábito preparado'),
              ),
            ],
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingAuthCreateTitle,
            style: AppTextStyles.welcomeTitle.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 14),
          Text(l10n.onboardingAuthSubtitle, style: AppTextStyles.authSub),
          const SizedBox(height: 24),
          if (_showManualForm)
            _ManualSignupForm(
              l10n: l10n,
              state: state,
              nameController: _name,
              emailController: _email,
              passwordController: _password,
              onSubmit: () async {
                await _machine.updateName(_name.text);
                await _submit();
              },
              errorCopy: state.error == null
                  ? null
                  : _errorCopy(l10n, state.error!.code),
            )
          else ...[
            AuthPrimaryButton(
              label: l10n.onboardingAuthCreateCta,
              isLoading: state.phase == OnboardingAuthPhase.authenticating,
              onTap: () => setState(() => _showManualForm = true),
            ),
            const SizedBox(height: 12),
            GoogleAuthButton(
              label: l10n.onboardingAuthGoogleCta,
              isLoading: state.phase == OnboardingAuthPhase.authenticating,
              onTap: _submitGoogle,
            ),
            if (Platform.isIOS) ...[
              const SizedBox(height: 12),
              AppleAuthButton(
                label: l10n.onboardingAuthAppleCta,
                isLoading: state.phase == OnboardingAuthPhase.authenticating,
                onTap: _submitApple,
              ),
            ],
          ],
        ],
      ),
    );
  }

  bool get _isAuthenticatedFrozenRecovery => onboardingAuthRecoveryGateVisible(
        hasAuthenticatedSession:
            context.read<AuthController>().currentUser != null ||
                _machine.state.authenticatedUserId != null,
        completionState: _machine.state.draft.completionState,
      );

  String _errorCopy(AppLocalizations l10n, OnboardingAuthErrorCode code) {
    switch (code) {
      case OnboardingAuthErrorCode.emailAlreadyRegistered:
        return l10n.onboardingAuthEmailExists;
      case OnboardingAuthErrorCode.invalidCredentials:
        return l10n.onboardingAuthInvalidCredentials;
      case OnboardingAuthErrorCode.weakPassword:
        return l10n.onboardingAuthWeakPassword;
      case OnboardingAuthErrorCode.network:
        return l10n.onboardingAuthNetwork;
      case OnboardingAuthErrorCode.confirmationNotDetected:
        return l10n.onboardingAuthConfirmationNotDetected;
      case OnboardingAuthErrorCode.resendRateLimited:
        return l10n.onboardingAuthResendRateLimited;
      case OnboardingAuthErrorCode.invalidEmail:
        return l10n.onboardingAuthInvalidEmail;
      default:
        return l10n.onboardingAuthGenericError;
    }
  }
}

class _ManualSignupForm extends StatelessWidget {
  const _ManualSignupForm({
    required this.l10n,
    required this.state,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    required this.errorCopy,
  });

  final AppLocalizations l10n;
  final OnboardingAuthState state;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final String? errorCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthField(
          label: l10n.signupNameLabel,
          hint: l10n.signupNameHint,
          controller: nameController,
        ),
        const SizedBox(height: 14),
        AuthField(
          label: l10n.fieldEmailLabel,
          hint: l10n.fieldEmailHint,
          keyboardType: TextInputType.emailAddress,
          controller: emailController,
        ),
        const SizedBox(height: 14),
        AuthField(
          label: l10n.fieldPasswordLabel,
          hint: l10n.signupPasswordHint,
          obscure: true,
          controller: passwordController,
        ),
        if (errorCopy != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              errorCopy!,
              style: TextStyle(color: AppColors.rust.withValues(alpha: .94)),
            ),
          ),
        const SizedBox(height: 18),
        AuthPrimaryButton(
          label: l10n.onboardingAuthCreateCta,
          isLoading: state.phase == OnboardingAuthPhase.authenticating,
          onTap: onSubmit,
        ),
      ],
    );
  }
}

class _ConfirmationView extends StatelessWidget {
  const _ConfirmationView({
    required this.email,
    required this.isChecking,
    required this.isResending,
    required this.onCheck,
    required this.onResend,
    this.error,
  });

  final String email;
  final bool isChecking;
  final bool isResending;
  final String? error;
  final Future<bool> Function() onCheck;
  final Future<bool> Function() onResend;

  @override
  Widget build(BuildContext context) {
    return _ConfirmationContent(
      email: email,
      isChecking: isChecking,
      isResending: isResending,
      error: error,
      onCheck: onCheck,
      onResend: onResend,
    );
  }
}

class _ConfirmationContent extends StatefulWidget {
  const _ConfirmationContent({
    required this.email,
    required this.isChecking,
    required this.isResending,
    required this.onCheck,
    required this.onResend,
    this.error,
  });
  final String email;
  final bool isChecking;
  final bool isResending;
  final String? error;
  final Future<bool> Function() onCheck;
  final Future<bool> Function() onResend;

  @override
  State<_ConfirmationContent> createState() => _ConfirmationContentState();
}

class _ConfirmationContentState extends State<_ConfirmationContent> {
  Timer? _timer;
  DateTime? _cooldownUntil;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    if (widget.isResending || _cooldownRemaining > 0) return;
    final ok = await widget.onResend();
    if (!mounted || !ok) return;
    setState(
        () => _cooldownUntil = DateTime.now().add(const Duration(seconds: 60)));
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  int get _cooldownRemaining {
    final until = _cooldownUntil;
    if (until == null) return 0;
    final remaining = until.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _timer?.cancel();
      return 0;
    }
    return remaining;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final remaining = _cooldownRemaining;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.onboardingAuthConfirmationTitle,
                style: AppTextStyles.authTitle, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              l10n.onboardingAuthConfirmationBody(widget.email),
              style: AppTextStyles.authSub,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            AuthPrimaryButton(
              label: l10n.onboardingAuthConfirmedCta,
              isLoading: widget.isChecking,
              onTap: () {
                widget.onCheck();
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: widget.isResending || remaining > 0 ? null : _resend,
              child: Text(remaining > 0
                  ? l10n.onboardingAuthResendCooldown(remaining)
                  : l10n.onboardingAuthResendCta),
            ),
            if (widget.error != null) ...[
              const SizedBox(height: 8),
              Text(widget.error!,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: AppColors.rust.withValues(alpha: .94))),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecoveryView extends StatelessWidget {
  const _RecoveryView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
            Text(
              'Recuperando tu onboarding…',
              textAlign: TextAlign.center,
              style: AppTextStyles.authSub,
            ),
            const SizedBox(height: 8),
            Text(
              'No necesitas volver a registrarte.',
              textAlign: TextAlign.center,
              style: AppTextStyles.authSub,
            ),
          ],
        ),
      ),
    );
  }
}
