import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:provider/provider.dart';

import '../application/premium_controller.dart';
import '../domain/premium_access.dart';
import '../domain/premium_access_policy.dart';
import 'premium_screen.dart';

enum PremiumUpgradeSource {
  weeklyStatistics,
  monthlyStatistics,
  annualStatistics,
  perHabitStatistics,
  weeklyReport,
  settings,
}

typedef PremiumPaywallPresenter = Future<PaywallResult> Function();

PremiumAccessState premiumAccessStateOf(BuildContext context) {
  return context.read<PremiumController?>()?.accessState ??
      const PremiumAccessState.unknown();
}

bool canAccessPremiumFeature(
  BuildContext context,
  PremiumFeature feature,
) {
  return PremiumAccessPolicy.canAccess(feature, premiumAccessStateOf(context));
}

void logPremiumGateBlocked(PremiumFeature feature) {
  if (kDebugMode) {
    debugPrint('[premium_gate] blocked feature=${feature.name}');
  }
}

class RevenueCatPaywallPresenter {
  const RevenueCatPaywallPresenter();

  Future<PaywallResult> present() {
    return RevenueCatUI.presentPaywall(displayCloseButton: true);
  }
}

Future<void>? _paywallPresentationInFlight;

Future<void> openPremiumPaywall(
  BuildContext context, {
  required PremiumUpgradeSource source,
  PremiumPaywallPresenter? presenter,
}) async {
  final existingPresentation = _paywallPresentationInFlight;
  if (existingPresentation != null) {
    await existingPresentation;
    return;
  }

  final future = _presentPremiumPaywall(
    context,
    source: source,
    presenter: presenter ?? const RevenueCatPaywallPresenter().present,
  );
  _paywallPresentationInFlight = future;
  try {
    await future;
  } finally {
    if (identical(_paywallPresentationInFlight, future)) {
      _paywallPresentationInFlight = null;
    }
  }
}

Future<void> _presentPremiumPaywall(
  BuildContext context, {
  required PremiumUpgradeSource source,
  required PremiumPaywallPresenter presenter,
}) async {
  final controller = context.read<PremiumController>();

  if (!controller.isAuthenticated || !controller.identityReady) {
    await _pushStatusScreen(context);
    return;
  }

  if (controller.accessState.isPremium) {
    await _pushStatusScreen(context);
    return;
  }

  try {
    final result = await presenter();
    if (context.mounted &&
        (result == PaywallResult.error ||
            result == PaywallResult.notPresented)) {
      _debugPaywallFailure('RevenueCatUI returned $result');
      await _pushFallbackScreen(context, source: source);
    }
  } catch (error, stackTrace) {
    _debugPaywallFailure(
      'RevenueCatUI presentation threw an exception: $error',
      stackTrace,
    );
    if (context.mounted) {
      await _pushFallbackScreen(context, source: source);
    }
  }
}

void _debugPaywallFailure(String message, [StackTrace? stackTrace]) {
  if (!kDebugMode) return;
  debugPrint('[premium] $message');
  if (stackTrace != null) debugPrint('$stackTrace');
}

Future<void> _pushStatusScreen(BuildContext context) {
  return Navigator.of(context).push<void>(
    CupertinoPageRoute<void>(builder: (_) => const PremiumScreen()),
  );
}

Future<void> _pushFallbackScreen(
  BuildContext context, {
  required PremiumUpgradeSource source,
}) {
  return Navigator.of(context).push<void>(
    CupertinoPageRoute<void>(
      builder: (_) => PremiumScreen(
        fallback: true,
        onRetry: () async {
          Navigator.of(context).pop();
          await openPremiumPaywall(context, source: source);
        },
      ),
    ),
  );
}
