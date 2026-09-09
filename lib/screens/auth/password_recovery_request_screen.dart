import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/application/password_recovery_controller.dart';
import '../../l10n/l10n.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../utils/app_theme.dart';
import '../../core/diagnostics/onboarding_runtime_trace.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_switch_link.dart';
import 'widgets/rutio_backdrop.dart';

class PasswordRecoveryRequestScreen extends StatefulWidget {
  const PasswordRecoveryRequestScreen({super.key});

  @override
  State<PasswordRecoveryRequestScreen> createState() =>
      _PasswordRecoveryRequestScreenState();
}

class _PasswordRecoveryRequestScreenState
    extends State<PasswordRecoveryRequestScreen> {
  final _emailController = TextEditingController();
  bool _staleRoutesCleared = false;

  @override
  void initState() {
    super.initState();
    OnboardingRuntimeTrace.log(
      'ROUTE_WIDGET',
      'widget=PasswordRecoveryRequestScreen event=mounted',
    );
  }

  @override
  void dispose() {
    OnboardingRuntimeTrace.log(
      'ROUTE_WIDGET',
      'widget=PasswordRecoveryRequestScreen event=disposed',
    );
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await context.read<PasswordRecoveryController>().requestReset(
          _emailController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<PasswordRecoveryController>();
    if (controller.hasActiveRecovery && !_staleRoutesCleared) {
      _staleRoutesCleared = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final navigator = Navigator.of(context);
        if (!ModalRoute.of(context)!.isCurrent) return;
        OnboardingRuntimeTrace.log(
          'AUTH_NAV_BOUNDARY',
          'event=clear_stale_recovery_routes result=state_driven',
        );
        // Remove request/login routes only. AppStartupGate remains the first
        // route and derives PasswordResetScreen from recovery state.
        navigator.popUntil((route) => route.isFirst);
      });
    }
    final sent = controller.phase == PasswordRecoveryPhase.resetEmailSent;
    final error = controller.failure;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          RutioBackdrop(isLogin: true, subtitle: l10n.loginHeaderSubtitle),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.passwordRecoveryTitle,
                        style: AppTextStyles.authTitle),
                    const SizedBox(height: 8),
                    Text(l10n.passwordRecoveryBody,
                        style: AppTextStyles.authSub),
                    const SizedBox(height: 24),
                    AuthField(
                      label: l10n.fieldEmailLabel,
                      hint: l10n.fieldEmailHint,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                    ),
                    if (sent)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(l10n.passwordRecoverySent,
                            style: const TextStyle(color: AppColors.sage)),
                      ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(_errorCopy(l10n, error),
                            style: const TextStyle(color: AppColors.rust)),
                      ),
                    const SizedBox(height: 20),
                    AuthPrimaryButton(
                      label: sent
                          ? l10n.passwordRecoveryResend
                          : l10n.passwordRecoverySend,
                      isLoading: controller.isLoading,
                      onTap: controller.canRequestAgain ? _submit : null,
                    ),
                    const SizedBox(height: 20),
                    AuthSwitchLink(
                      prefix: '',
                      linkText: l10n.passwordRecoveryBackToLogin,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _errorCopy(AppLocalizations l10n, PasswordRecoveryFailure error) {
    switch (error.type) {
      case PasswordRecoveryFailureType.invalidEmail:
        return l10n.passwordRecoveryInvalidEmail;
      case PasswordRecoveryFailureType.rateLimit:
        return l10n.passwordRecoveryRateLimited;
      case PasswordRecoveryFailureType.network:
      case PasswordRecoveryFailureType.unexpected:
      case PasswordRecoveryFailureType.recoveryLinkInvalid:
      case PasswordRecoveryFailureType.updatePasswordFailed:
        return l10n.passwordRecoveryTryAgain;
    }
  }
}
