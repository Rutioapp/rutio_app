import 'package:flutter/material.dart';

import '../widgets/backgrounds/rutio_sky_background.dart';
import 'welcome/widgets/welcome_content.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void goLogin() => Navigator.of(context).pushNamed('/auth');
    void goSignup() => Navigator.of(context).pushNamed('/auth-signup');

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