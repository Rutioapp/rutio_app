import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../application/auth/auth_controller.dart';
import '../stores/user_state_store.dart';
import '../widgets/backgrounds/rutio_sky_background.dart';
import 'welcome/widgets/welcome_content.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void> completeWelcomeAndGo(String route) async {
      await context.read<UserStateStore>().setOnboardingDone(true);
      if (!context.mounted) return;

      context.read<AuthController>().clearError();
      if (kDebugMode) {
        debugPrint('[startup] Welcome completed');
      }
      Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
    }

    void goLogin() => completeWelcomeAndGo('/auth');
    void goSignup() => completeWelcomeAndGo('/auth-signup');

    return Scaffold(
      body: Stack(
        children: [
          const RutioSkyBackground(showBottomFade: true),
          WelcomeContent(
            onLogin: goLogin,
            onSignup: goSignup,
          ),
        ],
      ),
    );
  }
}
