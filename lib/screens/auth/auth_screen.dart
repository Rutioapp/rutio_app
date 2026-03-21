import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../stores/user_state_store.dart';
import '../../utils/app_theme.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_social_buttons.dart';
import 'widgets/auth_switch_link.dart';
import 'widgets/rutio_backdrop.dart';

/// AuthScreen unificado: sirve para Login y SignUp (iOS-first).
/// - isLogin=true  -> Iniciar sesión
/// - isLogin=false -> Crear cuenta
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.isLogin});

  final bool isLogin;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late final AnimationController _ctrl;
  late final Animation<double> _slideY;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideY = Tween<double>(begin: 0.06, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Cubic(0.22, 1, 0.36, 1)),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Firebase Auth se conectara despues; por ahora persistimos nombre/email local.
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;

    final store = context.read<UserStateStore>();

    if (!widget.isLogin) {
      final name = _nameCtrl.text.trim();
      if (name.isNotEmpty) {
        await store.updateProfileFields(displayName: name);
      }
    }

    await store.setOnboardingDone(true, email: email);

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/root', (_) => false);
  }

  void _toggleMode() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, __, ___) => AuthScreen(isLogin: !widget.isLogin),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: anim, curve: const Cubic(0.22, 1, 0.36, 1)),
          ),
          child: child,
        ),
      ),
    );
  }

  void _google() {
    // ✅ UI preparado. Hook Firebase aquí más adelante.
    debugPrint('Google Sign-In tapped');
  }

  void _apple() {
    // ✅ UI preparado. Hook Firebase aquí más adelante.
    debugPrint('Apple Sign-In tapped');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isLogin = widget.isLogin;

    final headerSubtitle =
        isLogin ? l10n.loginHeaderSubtitle : l10n.signupHeaderSubtitle;
    final title = isLogin ? l10n.loginTitle : l10n.signupTitle;
    final sub = isLogin ? l10n.loginSubtitle : l10n.signupSubtitle;
    final buttonLabel = isLogin ? l10n.loginPrimaryCta : l10n.signupPrimaryCta;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.cream,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // ── Illustration header ──
            RutioBackdrop(
              isLogin: isLogin,
              subtitle: headerSubtitle,
            ),

            // ── Form body ──
            Expanded(
              child: AnimatedBuilder(
                animation: _ctrl,
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
                          // Separator
                          Container(
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
                          ),

                          Text(title, style: AppTextStyles.authTitle),
                          const SizedBox(height: 3),
                          Text(sub, style: AppTextStyles.authSub),
                          const SizedBox(height: 22),

                          if (!isLogin) ...[
                            AuthField(
                              label: l10n.signupNameLabel,
                              hint: l10n.signupNameHint,
                              controller: _nameCtrl,
                            ),
                            const SizedBox(height: 14),
                          ],

                          AuthField(
                            label: l10n.fieldEmailLabel,
                            hint: l10n.fieldEmailHint,
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailCtrl,
                          ),
                          const SizedBox(height: 14),

                          AuthField(
                            label: l10n.fieldPasswordLabel,
                            hint: isLogin
                                ? l10n.loginPasswordHint
                                : l10n.signupPasswordHint,
                            obscure: true,
                            controller: _passwordCtrl,
                          ),
                          const SizedBox(height: 6),

                          if (isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {},
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 6, bottom: 18),
                                  child: Text(l10n.loginForgotPassword,
                                      style: AppTextStyles.forgot),
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 18),

                          AuthPrimaryButton(
                            label: buttonLabel,
                            onTap: _submit,
                          ),

                          const SizedBox(height: 16),

                          AuthSocialButtons(
                            dividerLabel: l10n.authOrContinueWith,
                            appleLabel: l10n.authContinueWithApple,
                            googleLabel: l10n.authContinueWithGoogle,
                            onApple: _apple,
                            onGoogle: _google,
                          ),

                          const SizedBox(height: 16),

                          AuthSwitchLink(
                            prefix: isLogin
                                ? l10n.loginSwitchPrefix
                                : l10n.signupSwitchPrefix,
                            linkText: isLogin
                                ? l10n.loginSwitchLink
                                : l10n.signupSwitchLink,
                            onTap: _toggleMode,
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
