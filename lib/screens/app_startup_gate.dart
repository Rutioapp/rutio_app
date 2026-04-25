import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/auth/auth_controller.dart';
import '../stores/user_state_store.dart';
import 'auth/sign_in_screen.dart';
import 'root_gate.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';

class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  bool _splashComplete = false;
  String? _lastDebugSnapshot;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('[startup] AppStartupGate started');
      debugPrint('[startup] startup decision: splash');
    }
  }

  void _handleSplashFinished() {
    if (_splashComplete || !mounted) return;
    setState(() => _splashComplete = true);
  }

  void _logSnapshot({
    required String decision,
    required bool hasSupabaseUser,
    required bool welcomeSeen,
  }) {
    if (!kDebugMode) return;

    final snapshot = '$decision|$hasSupabaseUser|$welcomeSeen';
    if (_lastDebugSnapshot == snapshot) return;
    _lastDebugSnapshot = snapshot;

    debugPrint(
      '[startup] Supabase currentUser exists: ${hasSupabaseUser ? 'yes' : 'no'}',
    );
    debugPrint('[startup] welcome seen flag: $welcomeSeen');
    debugPrint('[startup] startup decision: $decision');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthController, UserStateStore>(
      builder: (context, authController, store, _) {
        final hasSupabaseUser = authController.currentUser != null;
        final welcomeSeen = store.onboardingDone;
        final isCheckingStartup =
            authController.isCheckingSession || store.isLoading;

        if (!_splashComplete || isCheckingStartup) {
          _logSnapshot(
            decision: 'splash',
            hasSupabaseUser: hasSupabaseUser,
            welcomeSeen: welcomeSeen,
          );
          return SplashScreen(onFinished: _handleSplashFinished);
        }

        if (hasSupabaseUser) {
          _logSnapshot(
            decision: 'home',
            hasSupabaseUser: hasSupabaseUser,
            welcomeSeen: welcomeSeen,
          );
          return const RootGate();
        }

        if (!welcomeSeen) {
          _logSnapshot(
            decision: 'welcome',
            hasSupabaseUser: hasSupabaseUser,
            welcomeSeen: welcomeSeen,
          );
          return const WelcomeScreen();
        }

        _logSnapshot(
          decision: 'auth',
          hasSupabaseUser: hasSupabaseUser,
          welcomeSeen: welcomeSeen,
        );
        return const SignInScreen();
      },
    );
  }
}
