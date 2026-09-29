import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/observability/analytics_events.dart';
import '../../../core/observability/analytics_service.dart';
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

void logPremiumGateBlocked(BuildContext context, PremiumFeature feature) {
  final access = premiumAccessStateOf(context);
  if (access.status != PremiumAccessStatus.unknown && !access.isPremium) {
    final analytics = context.read<AnalyticsService?>();
    if (analytics != null)
      unawaited(analytics.track(
        ProductAnalyticsEvents.premiumFeatureBlocked,
        properties: <String, Object?>{
          'premium_feature': analyticsPremiumFeature(feature),
          'upgrade_source': analyticsUpgradeSource(_sourceFor(feature)),
        },
      ));
  }
  if (kDebugMode) {
    debugPrint('[premium_gate] blocked feature=${feature.name}');
  }
}

PremiumUpgradeSource _sourceFor(PremiumFeature feature) => switch (feature) {
      PremiumFeature.weeklyStatistics => PremiumUpgradeSource.weeklyStatistics,
      PremiumFeature.monthlyStatistics =>
        PremiumUpgradeSource.monthlyStatistics,
      PremiumFeature.annualStatistics => PremiumUpgradeSource.annualStatistics,
      PremiumFeature.perHabitStatistics =>
        PremiumUpgradeSource.perHabitStatistics,
      PremiumFeature.weeklyReport => PremiumUpgradeSource.weeklyReport,
    };

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
    final analytics = context.read<AnalyticsService?>();
    if (result != PaywallResult.error && result != PaywallResult.notPresented) {
      if (analytics != null)
        unawaited(analytics.track(
          ProductAnalyticsEvents.paywallViewed,
          properties: <String, Object?>{
            'upgrade_source': analyticsUpgradeSource(source),
          },
        ));
    }
    switch (result) {
      case PaywallResult.purchased:
        // Hosted Paywall owns the transaction. Refresh once after it closes so
        // the app state does not depend solely on listener delivery timing.
        await controller.refresh();
        if (analytics != null)
          unawaited(analytics.track(
            ProductAnalyticsEvents.purchaseCompleted,
            properties: <String, Object?>{
              'upgrade_source': analyticsUpgradeSource(source),
            },
          ));
      case PaywallResult.cancelled:
        if (analytics != null)
          unawaited(analytics.track(
            ProductAnalyticsEvents.paywallDismissed,
            properties: <String, Object?>{
              'upgrade_source': analyticsUpgradeSource(source),
            },
          ));
        if (analytics != null)
          unawaited(analytics.track(
            ProductAnalyticsEvents.purchaseCancelled,
            properties: <String, Object?>{
              'upgrade_source': analyticsUpgradeSource(source),
            },
          ));
      case PaywallResult.restored:
        await controller.refresh();
        if (analytics != null)
          unawaited(analytics.track(
            ProductAnalyticsEvents.restoreCompleted,
            properties: <String, Object?>{
              'upgrade_source': analyticsUpgradeSource(source),
            },
          ));
      case PaywallResult.error:
      case PaywallResult.notPresented:
        break;
    }
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
