import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/auth/onboarding_auth_state_machine.dart';
import '../application/onboarding_draft_service.dart';
import '../data/onboarding_auth_persistence.dart';
import '../domain/auth/onboarding_auth_contracts.dart';
import '../domain/models/onboarding_draft.dart';
import '../domain/models/onboarding_types.dart';
import '../../../application/auth/auth_controller.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../utils/app_theme.dart';
import '../../../screens/auth/widgets/auth_field.dart';
import '../../../screens/auth/widgets/auth_primary_button.dart';

class OnboardingAuthStep extends StatefulWidget {
  const OnboardingAuthStep({required this.draft, super.key});

  final OnboardingDraft draft;

  @override
  State<OnboardingAuthStep> createState() => _OnboardingAuthStepState();
}

class _OnboardingAuthStepState extends State<OnboardingAuthStep> {
  late final OnboardingAuthStateMachine _machine;
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignUp = true;

  @override
  void initState() {
    super.initState();
    _email.text = widget.draft.authEmail ?? '';
    _isSignUp = widget.draft.authIntent != AuthIntent.signIn;
    _machine = OnboardingAuthStateMachine(
      draft: widget.draft,
      auth: context.read<OnboardingAuthPort>(),
      accountResolution: OnboardingAccountResolutionService(
        context.read<OnboardingAccountResolver>(),
      ),
      completion: const _Auth2CompletionPort(),
      draftPersistence: DraftOnboardingAuthPersistence(
        context.read<OnboardingDraftService>(),
      ),
    )..addListener(_onMachineChanged);
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
    context.read<AuthController>().removeListener(_onAuthControllerChanged);
    _machine.removeListener(_onMachineChanged);
    _machine.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await _machine.authenticate(
      command: _isSignUp
          ? OnboardingAuthCommand.signUpWithEmail
          : OnboardingAuthCommand.signInWithEmail,
      email: _email.text,
      password: _password.text,
    );
    _password.clear();
  }

  void _switchMode(bool signUp) {
    if (_machine.state.phase == OnboardingAuthPhase.authenticating) return;
    setState(() {
      _isSignUp = signUp;
      _password.clear();
    });
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
    if (waiting) {
      return _ConfirmationView(
        email: _email.text,
        onLogin: () => setState(() {
          _isSignUp = false;
          _password.clear();
        }),
      );
    }
    if (resolving || ready) {
      return Center(
        child: Text(
          resolving ? l10n.onboardingAuthResolving : l10n.onboardingAuthReady,
          textAlign: TextAlign.center,
          style: AppTextStyles.authSub,
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSignUp
                ? l10n.onboardingAuthCreateTitle
                : l10n.onboardingAuthLoginTitle,
            style: AppTextStyles.authTitle,
          ),
          const SizedBox(height: 6),
          Text(l10n.onboardingAuthSubtitle, style: AppTextStyles.authSub),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _switchMode(true),
                  child: Text(l10n.onboardingAuthCreateMode),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _switchMode(false),
                  child: Text(l10n.onboardingAuthLoginMode),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AuthField(
            label: l10n.fieldEmailLabel,
            hint: l10n.fieldEmailHint,
            keyboardType: TextInputType.emailAddress,
            controller: _email,
          ),
          const SizedBox(height: 14),
          AuthField(
            label: l10n.fieldPasswordLabel,
            hint: l10n.signupPasswordHint,
            obscure: true,
            controller: _password,
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _errorCopy(l10n, state.error!.code),
                style: TextStyle(color: AppColors.rust.withValues(alpha: .94)),
              ),
            ),
          if (state.error?.code ==
              OnboardingAuthErrorCode.emailAlreadyRegistered)
            TextButton(
              onPressed: () => _switchMode(false),
              child: Text(l10n.onboardingAuthLoginMode),
            ),
          const SizedBox(height: 18),
          AuthPrimaryButton(
            label: _isSignUp
                ? l10n.onboardingAuthCreateCta
                : l10n.onboardingAuthLoginCta,
            isLoading: state.phase == OnboardingAuthPhase.authenticating,
            onTap: _submit,
          ),
        ],
      ),
    );
  }

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
      default:
        return l10n.onboardingAuthGenericError;
    }
  }
}

class _ConfirmationView extends StatelessWidget {
  const _ConfirmationView({required this.email, required this.onLogin});

  final String email;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
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
              context.l10n.onboardingAuthConfirmationBody(email),
              style: AppTextStyles.authSub,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            AuthPrimaryButton(
              label: context.l10n.onboardingAuthConfirmedCta,
              onTap: onLogin,
            ),
          ],
        ),
      ),
    );
  }
}

class _Auth2CompletionPort implements OnboardingCompletionPort {
  const _Auth2CompletionPort();

  @override
  Future<OnboardingCompletionResult> completeOnboarding(
    OnboardingCompletionIntent intent,
  ) async {
    return OnboardingCompletionResult(
      kind: OnboardingCompletionResultKind.terminalFailure,
      operationId: intent.operationId,
      userId: intent.authenticatedUserId,
      error:
          const OnboardingAuthError(OnboardingAuthErrorCode.completionFailed),
    );
  }
}
