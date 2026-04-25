import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../application/auth/auth_controller.dart';
import '../../utils/app_theme.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.authenticatedBuilder,
  });

  static const String route = '/auth/supabase/gate';

  final WidgetBuilder? authenticatedBuilder;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastDecision;

  void _logDecision(String decision) {
    if (!kDebugMode || _lastDecision == decision) return;
    _lastDecision = decision;
    debugPrint('[auth] AuthGate decision: $decision');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        if (authController.isCheckingSession) {
          _logDecision('checking session');
          return const Scaffold(
            backgroundColor: AppColors.cream,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authController.isLoading && authController.currentUser == null) {
          _logDecision('showing auth loading');
          return const Scaffold(
            backgroundColor: AppColors.cream,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authController.isAuthenticated) {
          _logDecision('showing app');
          return widget.authenticatedBuilder?.call(context) ??
              const Scaffold(
                backgroundColor: AppColors.cream,
                body: Center(
                  child: Text(
                    'Authenticated session ready.',
                    style: TextStyle(color: AppColors.inkSoft),
                  ),
                ),
              );
        }

        _logDecision('showing auth');
        return const SignInScreen();
      },
    );
  }
}
