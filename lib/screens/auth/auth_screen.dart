import 'package:flutter/material.dart';

import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

/// Backwards-compatible entry point for older auth call sites.
///
/// The old local-only submit flow has intentionally been removed: all auth UI
/// now goes through the Supabase-backed SignIn/SignUp screens.
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key, required this.isLogin});

  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    return isLogin ? const SignInScreen() : const SignUpScreen();
  }
}
