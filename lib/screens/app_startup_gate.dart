import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/auth/auth_controller.dart';
import '../application/bootstrap/bootstrap_controller.dart';
import '../data/models/remote/remote_profile.dart';
import '../utils/app_theme.dart';
import 'auth/sign_in_screen.dart';
import 'onboarding/temporary_onboarding_screen.dart';
import 'root_gate.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';

class AppStartupGate extends StatefulWidget {
  const AppStartupGate({
    super.key,
    this.authenticatedBuilder,
  });

  final WidgetBuilder? authenticatedBuilder;

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  static const Duration _minimumSplashDuration = Duration(milliseconds: 2000);

  Timer? _minimumSplashTimer;
  bool _minimumSplashElapsed = false;

  @override
  void initState() {
    super.initState();
    _minimumSplashTimer = Timer(_minimumSplashDuration, () {
      if (!mounted) return;
      setState(() {
        _minimumSplashElapsed = true;
      });
    });
  }

  @override
  void dispose() {
    _minimumSplashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BootstrapController>(
      builder: (context, controller, _) {
        final state = controller.state;
        final isColdStart = state.mode == BootstrapRunMode.coldStart;
        final routeName = ModalRoute.of(context)?.settings.name;
        final shouldHoldReadySplash = isColdStart &&
            !_minimumSplashElapsed &&
            (routeName == null || routeName == '/' || routeName == '/home');
        if (state.isReady) {
          if (shouldHoldReadySplash) {
            controller.logColdStartSplashShown();
            return const SplashScreen(
              autoAdvanceDuration: null,
              enableTapToContinue: false,
              showTapHint: false,
            );
          }
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

        if (isColdStart) {
          controller.logColdStartSplashShown();
          return const SplashScreen(
            autoAdvanceDuration: null,
            enableTapToContinue: false,
            showTapHint: false,
          );
        }

        controller.logPreparingScreenShown();
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
        return widget.authenticatedBuilder?.call(context) ?? const RootGate();
      case BootstrapDestination.welcome:
        return const WelcomeScreen();
      case BootstrapDestination.authentication:
        return const SignInScreen();
      case BootstrapDestination.onboarding:
        return const TemporaryOnboardingScreen();
      case BootstrapDestination.profileUninitialized:
      case BootstrapDestination.profileDeleted:
      case BootstrapDestination.accountSuspended:
      case BootstrapDestination.accountPendingDeletion:
      case BootstrapDestination.invalidProfile:
        return BootstrapAuthorityStateScreen(destination: destination);
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

class BootstrapAuthorityStateScreen extends StatefulWidget {
  const BootstrapAuthorityStateScreen({
    super.key,
    required this.destination,
  });

  final BootstrapDestination destination;

  @override
  State<BootstrapAuthorityStateScreen> createState() =>
      _BootstrapAuthorityStateScreenState();
}

class _BootstrapAuthorityStateScreenState
    extends State<BootstrapAuthorityStateScreen> {
  bool _isProcessingAction = false;

  Future<void> _runAction(Future<void> Function() action) async {
    if (_isProcessingAction) return;
    setState(() {
      _isProcessingAction = true;
    });
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final background = isDark ? AppColors.ink : AppColors.cream;
    final foreground = isDark ? AppColors.cream : AppColors.ink;
    final muted = foreground.withValues(alpha: 0.72);
    final accent = AppColors.rust;
    final presentation = _bootstrapAuthorityPresentation(widget.destination);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.inkSoft.withValues(alpha: 0.34)
                      : AppColors.cream2.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.exclamationmark_shield_fill,
                        size: 28,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      presentation.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.welcomeTitle.copyWith(
                        color: foreground,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      presentation.body,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.welcomeSub.copyWith(
                        color: muted,
                        fontSize: 14,
                      ),
                    ),
                    if (presentation.note != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        presentation.note!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.authSub.copyWith(
                          color: muted.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                    if (presentation.showActions) ...[
                      const SizedBox(height: 24),
                      if (presentation.canRetry) ...[
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton.filled(
                            borderRadius: BorderRadius.circular(10),
                            onPressed: _isProcessingAction
                                ? null
                                : () => _runAction(() => context
                                    .read<BootstrapController>()
                                    .retry()),
                            child: Text(
                              _isProcessingAction
                                  ? 'Reintentando...'
                                  : 'Reintentar',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (presentation.canLogout)
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton(
                            color: isDark
                                ? AppColors.inkSoft.withValues(alpha: 0.26)
                                : AppColors.cream2.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(10),
                            onPressed: _isProcessingAction
                                ? null
                                : () => _runAction(
                                      () => context
                                          .read<AuthController>()
                                          .signOut(),
                                    ),
                            child: Text(
                              _isProcessingAction
                                  ? 'Cerrando...'
                                  : 'Cerrar sesion',
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

_BootstrapAuthorityPresentation _bootstrapAuthorityPresentation(
  BootstrapDestination destination,
) {
  switch (destination) {
    case BootstrapDestination.profileUninitialized:
      return const _BootstrapAuthorityPresentation(
        title: 'Perfil no inicializado',
        body:
            'La cuenta existe, pero todavia no tiene un perfil listo para entrar.',
        note: 'No avanzamos para mantener el flujo fail-closed.',
        canRetry: true,
        canLogout: true,
      );
    case BootstrapDestination.profileDeleted:
      return const _BootstrapAuthorityPresentation(
        title: 'Perfil eliminado',
        body: 'Este usuario ya no tiene un perfil activo en Rutio.',
        note: 'Solo puedes cerrar la sesion.',
        canLogout: true,
      );
    case BootstrapDestination.accountSuspended:
      return const _BootstrapAuthorityPresentation(
        title: 'Cuenta suspendida',
        body:
            'El acceso esta bloqueado temporalmente por una decision de cuenta.',
        note: 'Solo puedes cerrar la sesion.',
        canLogout: true,
      );
    case BootstrapDestination.accountPendingDeletion:
      return const _BootstrapAuthorityPresentation(
        title: 'Cuenta en borrado',
        body: 'La cuenta esta marcada para eliminacion y no puede continuar.',
        note: 'Solo puedes cerrar la sesion.',
        canLogout: true,
      );
    case BootstrapDestination.invalidProfile:
      return const _BootstrapAuthorityPresentation(
        title: 'Perfil incoherente',
        body:
            'Hemos detectado un estado que no cumple el contrato autoritativo.',
        note: 'No se avanza para conservar la semantica fail-closed.',
        canRetry: true,
        canLogout: true,
      );
    case BootstrapDestination.welcome:
    case BootstrapDestination.authentication:
    case BootstrapDestination.onboarding:
    case BootstrapDestination.home:
      return const _BootstrapAuthorityPresentation(
        title: 'Estado no aplicable',
        body: 'Este destino no corresponde a una pantalla autoritativa.',
      );
  }
}

class _BootstrapAuthorityPresentation {
  const _BootstrapAuthorityPresentation({
    required this.title,
    required this.body,
    this.note,
    this.canRetry = false,
    this.canLogout = false,
  });

  final String title;
  final String body;
  final String? note;
  final bool canRetry;
  final bool canLogout;

  bool get showActions => canRetry || canLogout;
}
