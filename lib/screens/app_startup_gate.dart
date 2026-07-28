import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/bootstrap/bootstrap_controller.dart';
import '../data/models/remote/remote_profile.dart';
import '../utils/app_theme.dart';
import 'auth/sign_in_screen.dart';
import 'onboarding/temporary_onboarding_screen.dart';
import 'root_gate.dart';
import 'welcome_screen.dart';

class AppStartupGate extends StatelessWidget {
  const AppStartupGate({
    super.key,
    this.authenticatedBuilder,
  });

  final WidgetBuilder? authenticatedBuilder;

  @override
  Widget build(BuildContext context) {
    return Consumer<BootstrapController>(
      builder: (context, controller, _) {
        final state = controller.state;
        if (state.isReady) {
          if (state.destination == BootstrapDestination.onboarding &&
              !_hasOnboardingProfile(state)) {
            return const BootstrapPreparationScreen();
          }
          return _buildDestination(context, state.destination!);
        }

        if (state.isFailed) {
          return BootstrapPreparationScreen(
            errorMessage: state.error?.message,
            onRetry: controller.retry,
          );
        }

        return const BootstrapPreparationScreen();
      },
    );
  }

  Widget _buildDestination(
    BuildContext context,
    BootstrapDestination destination,
  ) {
    switch (destination) {
      case BootstrapDestination.home:
        return authenticatedBuilder?.call(context) ?? const RootGate();
      case BootstrapDestination.welcome:
        return const WelcomeScreen();
      case BootstrapDestination.authentication:
        return const SignInScreen();
      case BootstrapDestination.onboarding:
        return const TemporaryOnboardingScreen();
    }
  }

  bool _hasOnboardingProfile(BootstrapState state) {
    final profile = state.remoteProfile;
    if (profile == null) return false;
    switch (profile.onboardingStatus) {
      case OnboardingStatus.pending:
      case OnboardingStatus.inProgress:
        return true;
      case OnboardingStatus.completed:
        return false;
    }
  }
}

class BootstrapPreparationScreen extends StatelessWidget {
  const BootstrapPreparationScreen({
    super.key,
    this.errorMessage,
    this.onRetry,
  });

  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final background = isDark ? AppColors.ink : AppColors.cream;
    final foreground = isDark ? AppColors.cream : AppColors.ink;
    final muted = foreground.withValues(alpha: 0.68);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(radius: 14),
                const SizedBox(height: 22),
                Text(
                  'Preparando tu espacio…',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.authTitle.copyWith(
                    color: foreground,
                    fontSize: 24,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.authSub.copyWith(
                      color: muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(8),
                    onPressed: onRetry,
                    child: const Text('Reintentar'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
