import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/bootstrap/bootstrap_controller.dart';
import '../../application/auth/auth_controller.dart';
import '../../features/auth/application/password_recovery_controller.dart';
import '../../l10n/l10n.dart';
import '../../utils/app_theme.dart';
import '../../core/diagnostics/onboarding_runtime_trace.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_primary_button.dart';
import 'password_recovery_request_screen.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  String? _validationError;

  @override
  void initState() {
    super.initState();
    OnboardingRuntimeTrace.log(
      'PASSWORD_RECOVERY',
      'event=reset_screen_entered hasSession=true result=rendered',
    );
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!PasswordRecoveryController.isValidPassword(_password.text)) {
      setState(() => _validationError = l10n.passwordRecoveryPasswordTooShort);
      return;
    }
    if (_password.text != _confirmation.text) {
      setState(() => _validationError = l10n.passwordRecoveryMismatch);
      return;
    }
    setState(() => _validationError = null);
    final recovery = context.read<PasswordRecoveryController>();
    final success = await recovery.updatePassword(
      _password.text,
      _confirmation.text,
    );
    if (!mounted || !success) return;
    await context.read<BootstrapController>().retry();
    await recovery.clear();
  }

  Future<void> _cancel() async {
    final recovery = context.read<PasswordRecoveryController>();
    await recovery.cancelRecovery(
      signOut: () => context.read<AuthController>().signOut(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recovery = context.watch<PasswordRecoveryController>();
    final invalid = recovery.isInvalidLink;
    if (invalid) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(l10n.passwordRecoveryInvalidLink,
                    style: AppTextStyles.authTitle,
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                AuthPrimaryButton(
                  label: l10n.passwordRecoverySendAnother,
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const PasswordRecoveryRequestScreen(),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 56, 22, 32),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.passwordResetTitle, style: AppTextStyles.authTitle),
            const SizedBox(height: 8),
            Text(l10n.passwordResetBody, style: AppTextStyles.authSub),
            const SizedBox(height: 26),
            AuthField(
                label: l10n.passwordResetNew,
                hint: l10n.signupPasswordHint,
                obscure: true,
                controller: _password),
            const SizedBox(height: 14),
            AuthField(
                label: l10n.passwordResetConfirm,
                hint: l10n.signupPasswordHint,
                obscure: true,
                controller: _confirmation),
            if (_validationError != null || recovery.failure != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                    _validationError ?? l10n.passwordRecoveryUpdateFailed,
                    style: const TextStyle(color: AppColors.rust)),
              ),
            const SizedBox(height: 22),
            AuthPrimaryButton(
              label: l10n.passwordResetSave,
              isLoading: recovery.isLoading,
              onTap: _save,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                  onPressed: _cancel, child: Text(l10n.passwordResetCancel)),
            ),
          ]),
        ),
      ),
    );
  }
}
