import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/auth/auth_controller.dart';
import '../../l10n/l10n.dart';
import '../../stores/user_state_store.dart';
import '../../utils/app_theme.dart';
import 'sign_in_screen.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_switch_link.dart';
import 'widgets/rutio_backdrop.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  static const String route = '/auth/supabase/sign-up';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final AnimationController _animationController;
  late final Animation<double> _slideY;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideY = Tween<double>(begin: 0.06, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Cubic(0.22, 1, 0.36, 1),
      ),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authController = context.read<AuthController>();
    final response = await authController.signUpWithEmailPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _displayNameController.text.trim(),
    );
    if (!mounted) return;

    final hasAuthenticatedUser =
        authController.isAuthenticated || response?.session?.user != null;
    if (!hasAuthenticatedUser) return;

    final store = context.read<UserStateStore>();
    final displayName = _displayNameController.text.trim();
    if (displayName.isNotEmpty) {
      await store.updateProfileFields(displayName: displayName);
    }
    await store.setOnboardingDone(
      true,
      email: _emailController.text.trim(),
    );
    if (!mounted) return;

    // Auth screens can be pushed above /root from the welcome flow. After a
    // real Supabase session exists, reset to /root so AuthGate can reveal app.
    Navigator.of(context).pushNamedAndRemoveUntil('/root', (_) => false);
  }

  void _openSignIn() {
    context.read<AuthController>().clearError();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, __, ___) => const SignInScreen(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.22, 1, 0.36, 1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final authController = context.watch<AuthController>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.cream,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            RutioBackdrop(
              isLogin: false,
              subtitle: l10n.signupHeaderSubtitle,
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (_, child) => Opacity(
                  opacity: _opacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideY.value * 60),
                    child: child,
                  ),
                ),
                child: Container(
                  color: AppColors.cream,
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _AuthSeparator(),
                          Text(l10n.signupTitle,
                              style: AppTextStyles.authTitle),
                          const SizedBox(height: 3),
                          Text(l10n.signupSubtitle,
                              style: AppTextStyles.authSub),
                          const SizedBox(height: 22),
                          AuthField(
                            label: l10n.signupNameLabel,
                            hint: l10n.signupNameHint,
                            controller: _displayNameController,
                          ),
                          const SizedBox(height: 14),
                          AuthField(
                            label: l10n.fieldEmailLabel,
                            hint: l10n.fieldEmailHint,
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                          ),
                          const SizedBox(height: 14),
                          AuthField(
                            label: l10n.fieldPasswordLabel,
                            hint: l10n.signupPasswordHint,
                            obscure: true,
                            controller: _passwordController,
                          ),
                          _AuthMessage(controller: authController),
                          const SizedBox(height: 18),
                          AuthPrimaryButton(
                            label: l10n.signupPrimaryCta,
                            isLoading: authController.isLoading,
                            onTap: _submit,
                          ),
                          const SizedBox(height: 22),
                          AuthSwitchLink(
                            prefix: l10n.signupSwitchPrefix,
                            linkText: l10n.signupSwitchLink,
                            onTap: _openSignIn,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthSeparator extends StatelessWidget {
  const _AuthSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.ink.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final error = controller.errorMessage;
    final notice = controller.noticeMessage;
    final message = error ?? notice;
    if (message == null || message.isEmpty) return const SizedBox.shrink();

    final color = error != null
        ? AppColors.rust.withValues(alpha: 0.94)
        : AppColors.sage.withValues(alpha: 0.92);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(
        message,
        style: TextStyle(
          color: color,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}
