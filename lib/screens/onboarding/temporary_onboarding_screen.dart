import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/bootstrap/bootstrap_controller.dart';
import '../../utils/app_theme.dart';

class TemporaryOnboardingScreen extends StatefulWidget {
  const TemporaryOnboardingScreen({super.key});

  @override
  State<TemporaryOnboardingScreen> createState() =>
      _TemporaryOnboardingScreenState();
}

class _TemporaryOnboardingScreenState extends State<TemporaryOnboardingScreen> {
  bool _isCompleting = false;
  String? _errorMessage;

  Future<void> _continue() async {
    if (_isCompleting) return;
    setState(() {
      _isCompleting = true;
      _errorMessage = null;
    });

    final controller = context.read<BootstrapController>();
    await controller.completeTemporaryOnboarding();
    if (!mounted) return;

    final state = controller.state;
    if (!state.isReady || state.destination != BootstrapDestination.home) {
      setState(() {
        _isCompleting = false;
        _errorMessage =
            state.error?.message ?? 'No hemos podido continuar. Reintenta.';
      });
    }
  }

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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tu espacio está listo',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.welcomeTitle.copyWith(
                      color: foreground,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'El onboarding personalizado se añadirá próximamente.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.welcomeSub.copyWith(
                      color: muted,
                      fontSize: 14,
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.authSub.copyWith(
                        color: AppColors.rust,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(8),
                      onPressed: _isCompleting ? null : _continue,
                      child: _isCompleting
                          ? const CupertinoActivityIndicator()
                          : const Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
