import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import '../../domain/premium_purchase.dart';

typedef RevenueCatCustomerInfoListener = void Function(
    RevenueCatCustomerInfoSnapshot customerInfo);

class RevenueCatClientException implements Exception {
  const RevenueCatClientException({required this.operation, this.cause});

  final String operation;
  final Object? cause;

  @override
  String toString() => 'RevenueCatClientException(operation: $operation)';
}

class RevenueCatEntitlementSnapshot {
  const RevenueCatEntitlementSnapshot({
    required this.isActive,
    required this.isTrial,
    required this.productIdentifier,
    required this.willRenew,
    this.expirationDate,
  });

  final bool isActive;
  final bool isTrial;
  final String productIdentifier;
  final bool willRenew;
  final DateTime? expirationDate;
}

class RevenueCatCustomerInfoSnapshot {
  const RevenueCatCustomerInfoSnapshot({
    required this.activeEntitlements,
    required this.allEntitlements,
    this.managementUrl,
  });

  final Map<String, RevenueCatEntitlementSnapshot> activeEntitlements;
  final Map<String, RevenueCatEntitlementSnapshot> allEntitlements;
  final String? managementUrl;
}

class RevenueCatPackageSnapshot {
  const RevenueCatPackageSnapshot({
    required this.identifier,
    required this.productIdentifier,
    required this.localizedPrice,
    this.price,
    this.currencyCode,
  });

  final String identifier;
  final String productIdentifier;
  final String localizedPrice;
  final double? price;
  final String? currencyCode;
}

class RevenueCatOfferingSnapshot {
  const RevenueCatOfferingSnapshot({
    required this.identifier,
    required this.packages,
  });

  final String identifier;
  final List<RevenueCatPackageSnapshot> packages;
}

abstract interface class RevenueCatClient {
  Future<void> configure({
    required String apiKey,
    required bool enableDebugLogging,
  });

  Future<RevenueCatCustomerInfoSnapshot> logIn(String appUserId);

  Future<RevenueCatCustomerInfoSnapshot> logOut();

  Future<String> getAppUserId();

  Future<RevenueCatCustomerInfoSnapshot> getCustomerInfo();

  Future<RevenueCatOfferingSnapshot?> getCurrentOffering();

  Future<PremiumPurchaseResult> purchasePackage(String packageIdentifier) =>
      throw UnimplementedError('purchasePackage is not implemented');

  Future<RevenueCatCustomerInfoSnapshot> restorePurchases() =>
      throw UnimplementedError('restorePurchases is not implemented');

  void addCustomerInfoListener(RevenueCatCustomerInfoListener listener);

  void removeCustomerInfoListener(RevenueCatCustomerInfoListener listener);
}

class PurchasesRevenueCatClient implements RevenueCatClient {
  final Map<RevenueCatCustomerInfoListener, rc.CustomerInfoUpdateListener>
      _listeners = {};
  Future<void>? _configureFuture;

  @override
  Future<void> configure({
    required String apiKey,
    required bool enableDebugLogging,
  }) {
    return _configureFuture ??= _configure(
      apiKey: apiKey,
      enableDebugLogging: enableDebugLogging,
    ).catchError((Object error) {
      _configureFuture = null;
      throw error;
    });
  }

  Future<void> _configure({
    required String apiKey,
    required bool enableDebugLogging,
  }) async {
    try {
      await rc.Purchases.setLogLevel(
        enableDebugLogging ? rc.LogLevel.debug : rc.LogLevel.info,
      );
      await rc.Purchases.configure(rc.PurchasesConfiguration(apiKey));
    } catch (error) {
      throw RevenueCatClientException(operation: 'configure', cause: error);
    }
  }

  @override
  Future<String> getAppUserId() async {
    try {
      return await rc.Purchases.appUserID;
    } catch (error) {
      throw RevenueCatClientException(
        operation: 'getAppUserId',
        cause: error,
      );
    }
  }

  @override
  Future<RevenueCatCustomerInfoSnapshot> logIn(String appUserId) async {
    try {
      final result = await rc.Purchases.logIn(appUserId);
      return _mapCustomerInfo(result.customerInfo);
    } catch (error) {
      throw RevenueCatClientException(operation: 'logIn', cause: error);
    }
  }

  @override
  Future<RevenueCatCustomerInfoSnapshot> logOut() async {
    try {
      return _mapCustomerInfo(await rc.Purchases.logOut());
    } catch (error) {
      throw RevenueCatClientException(operation: 'logOut', cause: error);
    }
  }

  @override
  Future<RevenueCatCustomerInfoSnapshot> getCustomerInfo() async {
    try {
      return _mapCustomerInfo(await rc.Purchases.getCustomerInfo());
    } catch (error) {
      throw RevenueCatClientException(
        operation: 'getCustomerInfo',
        cause: error,
      );
    }
  }

  @override
  Future<RevenueCatOfferingSnapshot?> getCurrentOffering() async {
    try {
      final offerings = await rc.Purchases.getOfferings();
      final offering = offerings.current;
      if (offering == null) return null;
      return RevenueCatOfferingSnapshot(
        identifier: offering.identifier,
        packages: offering.availablePackages
            .map(
              (package) => RevenueCatPackageSnapshot(
                identifier: package.identifier,
                productIdentifier: package.storeProduct.identifier,
                localizedPrice: package.storeProduct.priceString,
                price: package.storeProduct.price,
                currencyCode: package.storeProduct.currencyCode,
              ),
            )
            .toList(growable: false),
      );
    } catch (error) {
      throw RevenueCatClientException(
        operation: 'getCurrentOffering',
        cause: error,
      );
    }
  }

  @override
  Future<PremiumPurchaseResult> purchasePackage(
      String packageIdentifier) async {
    try {
      final offerings = await rc.Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? const [];
      rc.Package? package;
      for (final candidate in packages) {
        if (candidate.identifier == packageIdentifier) {
          package = candidate;
          break;
        }
      }
      if (package == null) {
        return const PremiumPurchaseResult.failed(
          PremiumPurchaseError(PremiumPurchaseErrorKind.productUnavailable),
        );
      }
      final result = await rc.Purchases.purchase(
        rc.PurchaseParams.package(package),
      );
      final snapshot = _mapCustomerInfo(result.customerInfo);
      final premium = snapshot.activeEntitlements['premium'];
      if (premium?.isActive == true) {
        return const PremiumPurchaseResult.success();
      }
      return const PremiumPurchaseResult.pending();
    } on PlatformException catch (error) {
      final code = rc.PurchasesErrorHelper.getErrorCode(error);
      if (code == rc.PurchasesErrorCode.purchaseCancelledError) {
        return const PremiumPurchaseResult.cancelled();
      }
      if (code == rc.PurchasesErrorCode.paymentPendingError) {
        return const PremiumPurchaseResult.pending();
      }
      return PremiumPurchaseResult.failed(
        PremiumPurchaseError(_mapError(code)),
      );
    } catch (error) {
      throw RevenueCatClientException(
          operation: 'purchasePackage', cause: error);
    }
  }

  @override
  Future<RevenueCatCustomerInfoSnapshot> restorePurchases() async {
    try {
      return _mapCustomerInfo(await rc.Purchases.restorePurchases());
    } catch (error) {
      throw RevenueCatClientException(
          operation: 'restorePurchases', cause: error);
    }
  }

  @override
  void addCustomerInfoListener(RevenueCatCustomerInfoListener listener) {
    if (_listeners.containsKey(listener)) return;
    void sdkListener(rc.CustomerInfo customerInfo) {
      listener(_mapCustomerInfo(customerInfo));
    }

    _listeners[listener] = sdkListener;
    rc.Purchases.addCustomerInfoUpdateListener(sdkListener);
  }

  @override
  void removeCustomerInfoListener(RevenueCatCustomerInfoListener listener) {
    final sdkListener = _listeners.remove(listener);
    if (sdkListener != null) {
      rc.Purchases.removeCustomerInfoUpdateListener(sdkListener);
    }
  }

  RevenueCatCustomerInfoSnapshot _mapCustomerInfo(rc.CustomerInfo info) {
    RevenueCatEntitlementSnapshot mapEntitlement(rc.EntitlementInfo value) {
      return RevenueCatEntitlementSnapshot(
        isActive: value.isActive,
        isTrial: value.periodType == rc.PeriodType.trial,
        productIdentifier: value.productIdentifier,
        willRenew: value.willRenew,
        expirationDate: _parseDate(value.expirationDate),
      );
    }

    return RevenueCatCustomerInfoSnapshot(
      activeEntitlements: info.entitlements.active.map(
        (key, value) => MapEntry(key, mapEntitlement(value)),
      ),
      allEntitlements: info.entitlements.all.map(
        (key, value) => MapEntry(key, mapEntitlement(value)),
      ),
      managementUrl: info.managementURL,
    );
  }

  PremiumPurchaseErrorKind _mapError(rc.PurchasesErrorCode code) {
    switch (code) {
      case rc.PurchasesErrorCode.networkError:
      case rc.PurchasesErrorCode.offlineConnectionError:
        return PremiumPurchaseErrorKind.network;
      case rc.PurchasesErrorCode.productNotAvailableForPurchaseError:
        return PremiumPurchaseErrorKind.productUnavailable;
      case rc.PurchasesErrorCode.purchaseNotAllowedError:
        return PremiumPurchaseErrorKind.notAllowed;
      case rc.PurchasesErrorCode.productAlreadyPurchasedError:
      case rc.PurchasesErrorCode.receiptAlreadyInUseError:
        return PremiumPurchaseErrorKind.alreadyPurchased;
      case rc.PurchasesErrorCode.storeProblemError:
      case rc.PurchasesErrorCode.testStoreSimulatedPurchaseError:
        return PremiumPurchaseErrorKind.storeProblem;
      default:
        return PremiumPurchaseErrorKind.unknown;
    }
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}

@visibleForTesting
RevenueCatCustomerInfoSnapshot customerInfoSnapshotFromSdkForTesting(
  rc.CustomerInfo info,
) {
  return PurchasesRevenueCatClient()._mapCustomerInfo(info);
}
