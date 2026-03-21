import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../utils/app_theme.dart';

class WelcomeContent extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onSignup;

  const WelcomeContent({
    super.key,
    required this.onLogin,
    required this.onSignup,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),

            /// RUTIO
            Text(
              l10n.welcomeBrand, // "RUTIO"
              style: TextStyle(
                letterSpacing: 3,
                fontSize: 12,
                color: AppColors.ink.withValues(alpha: 0.35),
              ),
            ),

            const SizedBox(height: 12),

            /// TITLE
            RichText(
              text: TextSpan(
                style: AppTextStyles.welcomeTitle,
                children: [
                  TextSpan(text: l10n.welcomeTitleLine1), // "Tu camino\n"
                  TextSpan(
                    text: l10n.welcomeTitleLine2, // "empieza hoy."
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            /// SUBTITLE
            Text(
              l10n.welcomeSubtitle,
              style: AppTextStyles.welcomeSubtitle,
            ),

            const SizedBox(height: 36),

            /// LOGIN BUTTON (FIX: force foreground/text color)
            SizedBox(
              height: 64,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor:
                      AppColors.cream, // ✅ aquí estaba el problema típico
                  shape: const StadiumBorder(),
                  textStyle: AppTextStyles.buttonPrimary,
                ),
                child: Text(l10n.welcomeLoginButton),
              ),
            ),

            const SizedBox(height: 16),

            /// SIGNUP BUTTON
            SizedBox(
              height: 60,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSignup,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  shape: const StadiumBorder(),
                  textStyle: AppTextStyles.buttonOutline,
                  side: BorderSide(
                    color: AppColors.ink.withValues(alpha: 0.22),
                    width: 1.2,
                  ),
                ),
                child: Text(l10n.welcomeSignupButton),
              ),
            ),

            SizedBox(height: 20 + bottomPad),
          ],
        ),
      ),
    );
  }
}
