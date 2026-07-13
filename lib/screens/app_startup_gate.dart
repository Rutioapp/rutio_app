import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/auth/auth_controller.dart';
import '../application/bootstrap/async_bootstrap_gate.dart';
import '../application/bootstrap/home_background_bootstrapper.dart';
import '../devtools/rutio_runtime_profile.dart';
import '../features/shop/application/shop_cosmetics_controller.dart';
import '../stores/user_state_store.dart';
import 'auth/sign_in_screen.dart';
import 'root_gate.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';

const Duration kMinimumStartupSplashDuration = Duration(milliseconds: 900);

enum _StartupDestination {
  home,
  welcome,
  auth,
}

@immutable
class _StartupGateResult {
  const _StartupGateResult({
    required this.destination,
    required this.usedWallpaperFallback,
  });

  final _StartupDestination destination;
  final bool usedWallpaperFallback;
}

class AppStartupGate extends StatelessWidget {
  const AppStartupGate({super.key});

  @override
  Widget build(BuildContext context) {
    return AsyncBootstrapGate<_StartupGateResult>(
      minimumInitializationDuration: kMinimumStartupSplashDuration,
      initializer: _initializeStartup,
      initializingBuilder: (_) => const SplashScreen(
        showTapHint: false,
      ),
      readyBuilder: (context, result) => _buildDestination(context, result),
      failedBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          debugPrint('[startup] bootstrap failed: $error');
          debugPrintStack(
            label: '[startup]',
            stackTrace: stackTrace,
          );
        }
        return _buildDestination(
          context,
          _fallbackResultForCurrentState(
            authController: context.read<AuthController>(),
            userStateStore: context.read<UserStateStore>(),
          ),
        );
      },
    );
  }

  static Future<_StartupGateResult> _initializeStartup(
    BuildContext context,
  ) async {
    final authController = context.read<AuthController>();
    final userStateStore = context.read<UserStateStore>();
    final cosmeticsController = context.read<ShopCosmeticsController>();

    if (kDebugMode) {
      debugPrint('[startup] bootstrap started');
    }

    await _ensureLocalStateReady(userStateStore);
    await _waitForAuthSessionCheck(authController);

    final shouldOpenHome =
        authController.currentUser != null || RutioRuntimeProfile.isDemo;
    final destination = shouldOpenHome
        ? _StartupDestination.home
        : userStateStore.onboardingDone
            ? _StartupDestination.auth
            : _StartupDestination.welcome;

    if (!shouldOpenHome) {
      if (kDebugMode) {
        debugPrint('[startup] bootstrap ready without home background preload');
      }
      return _StartupGateResult(
        destination: destination,
        usedWallpaperFallback: false,
      );
    }

    if (!context.mounted) {
      return _StartupGateResult(
        destination: destination,
        usedWallpaperFallback: true,
      );
    }

    final bootstrapper = HomeBackgroundBootstrapper(
      controller: cosmeticsController,
    );
    final backgroundResult = await bootstrapper.prepare(context);

    if (kDebugMode) {
      debugPrint(
        '[startup] bootstrap ready destination=${destination.name} '
        'usedWallpaperFallback=${backgroundResult.usedFallback} '
        'didPrecacheCustomWallpaper=${backgroundResult.didPrecacheCustomWallpaper} '
        'wallpaperAssetPath=${backgroundResult.wallpaperAsset?.assetPath}',
      );
    }

    return _StartupGateResult(
      destination: destination,
      usedWallpaperFallback: backgroundResult.usedFallback,
    );
  }

  static Future<void> _ensureLocalStateReady(UserStateStore store) async {
    if (store.state == null && !store.isLoading) {
      await store.load();
    }

    while (store.isLoading) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  static Future<void> _waitForAuthSessionCheck(
      AuthController authController) async {
    while (authController.isCheckingSession) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  static Widget _buildDestination(
    BuildContext context,
    _StartupGateResult result,
  ) {
    switch (result.destination) {
      case _StartupDestination.home:
        return const RootGate();
      case _StartupDestination.welcome:
        return const WelcomeScreen();
      case _StartupDestination.auth:
        return const SignInScreen();
    }
  }

  static _StartupGateResult _fallbackResultForCurrentState({
    required AuthController authController,
    required UserStateStore userStateStore,
  }) {
    final shouldOpenHome =
        authController.currentUser != null || RutioRuntimeProfile.isDemo;
    final destination = shouldOpenHome
        ? _StartupDestination.home
        : userStateStore.onboardingDone
            ? _StartupDestination.auth
            : _StartupDestination.welcome;
    return _StartupGateResult(
      destination: destination,
      usedWallpaperFallback: true,
    );
  }
}
