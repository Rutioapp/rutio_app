import 'package:flutter/foundation.dart';
import 'dart:async';

import '../domain/premium_access.dart';
import '../domain/premium_mappers.dart';
import '../domain/premium_purchase.dart';
import 'revenuecat/revenuecat_client.dart';
import 'revenuecat/revenuecat_configuration.dart';
import '../../../core/observability/crash_reporting_keys.dart';
import '../../../core/observability/crash_reporting_service.dart';

typedef PremiumRepositoryLogger = void Function(String message);

class PremiumRepository extends ChangeNotifier {
  PremiumRepository({
    required RevenueCatClient client,
    required RevenueCatConfiguration configuration,
    PremiumRepositoryLogger? logger,
    Duration operationTimeout = const Duration(seconds: 15),
    CrashReportingService? crashReportingService,
  })  : _client = client,
        _configuration = configuration,
        _logger = logger ?? _defaultLogger,
        _operationTimeout = operationTimeout,
        _crashReportingService = crashReportingService;

  final RevenueCatClient _client;
  final RevenueCatConfiguration _configuration;
  final PremiumRepositoryLogger _logger;
  final Duration _operationTimeout;
  final CrashReportingService? _crashReportingService;

  PremiumAccessState _accessState = const PremiumAccessState.unknown();
  PremiumOffering? _currentOffering;
  Future<void>? _initialization;
  RevenueCatCustomerInfoListener? _customerInfoListener;
  Future<void> _identityTransition = Future<void>.value();
  int _identityGeneration = 0;
  String? _boundUserId;
  bool _sdkIdentityIsIdentified = false;
  bool _identityResolved = false;
  String? _managementUrl;
  Future<PremiumPurchaseResult>? _purchaseInFlight;
  bool _disposed = false;

  PremiumAccessState get accessState => _accessState;
  PremiumOffering? get currentOffering => _currentOffering;
  String? get managementUrl => _managementUrl;
  String? get boundUserId => _boundUserId;
  bool get hasAuthenticatedIdentity =>
      _identityResolved && _sdkIdentityIsIdentified && _boundUserId != null;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> syncIdentity(String? userId) {
    if (_disposed) return Future<void>.value();
    final normalizedUserId = _normalizeUserId(userId);
    final generation = ++_identityGeneration;
    final transition = _identityTransition.then(
      (_) => _transitionIdentity(
        userId: normalizedUserId,
        generation: generation,
      ),
    );
    _identityTransition = transition;
    return transition;
  }

  Future<void> _initialize() async {
    if (!_configuration.isConfigured) {
      _log('RevenueCat initialization skipped: missing API key configuration');
      return;
    }

    try {
      await _client
          .configure(
            apiKey: _configuration.testApiKey,
            enableDebugLogging: kDebugMode,
          )
          .timeout(_operationTimeout);
      try {
        final appUserId =
            await _client.getAppUserId().timeout(_operationTimeout);
        _sdkIdentityIsIdentified = !_isAnonymousUserId(appUserId);
        _boundUserId = _sdkIdentityIsIdentified ? appUserId : null;
      } catch (_) {
        _sdkIdentityIsIdentified = false;
        _boundUserId = null;
      }
      _registerCustomerInfoListener(
        generation: _identityGeneration,
        expectedUserId: null,
      );
      await _refreshOffering();
      _debugLog('RevenueCat initialization success');
      await _logDebugDiagnostics();
    } catch (error) {
      _debugLog('RevenueCat initialization failure: ${_safeError(error)}');
      _reportNonFatal(
        error,
        StackTrace.current,
        CrashReportingReasons.revenueCatInitializationFailure,
      );
    }
  }

  Future<void> refresh() async {
    await initialize();
    if (!_configuration.isConfigured || !_identityResolved) return;
    await Future.wait<void>([
      _refreshCustomerInfo(),
      _refreshOffering(),
    ]);
  }

  Future<void> loadCustomerInfo() async {
    await initialize();
    if (_configuration.isConfigured && _identityResolved) {
      await _refreshCustomerInfo();
    }
  }

  Future<void> loadSubscriptionPlans() async {
    await initialize();
    if (_configuration.isConfigured) await _refreshOffering();
  }

  Future<PremiumPurchaseResult> purchasePackage(String packageIdentifier) {
    if (!hasAuthenticatedIdentity) {
      return Future.value(const PremiumPurchaseResult.failed(
        PremiumPurchaseError(PremiumPurchaseErrorKind.authenticationRequired),
      ));
    }
    return _purchaseInFlight ??= _purchase(packageIdentifier).whenComplete(
      () => _purchaseInFlight = null,
    );
  }

  Future<PremiumPurchaseResult> _purchase(String packageIdentifier) async {
    _debugLog('Purchase started: ${_planLabel(packageIdentifier)}');
    PremiumPurchaseResult result;
    try {
      // The native store transaction owns this lifetime. An application-level
      // timeout here can report failure while the store is still processing.
      result = await _client.purchasePackage(packageIdentifier);
    } catch (error) {
      _debugLog('Purchase failed: ${_safeError(error)}');
      await _refreshCustomerInfo();
      if (_accessState.isPremium) {
        _debugLog('Premium entitlement active after delayed purchase');
        return const PremiumPurchaseResult.success();
      }
      return const PremiumPurchaseResult.failed(
        PremiumPurchaseError(PremiumPurchaseErrorKind.unknown),
      );
    }
    if (result.isCancelled) {
      _debugLog('Purchase cancelled');
      return result;
    }
    if (!result.isSuccess) {
      _debugLog(
          'Purchase failed: ${result.error?.kind.name ?? result.kind.name}');
      return result;
    }
    await _refreshCustomerInfo();
    if (_accessState.isPremium) {
      _debugLog('Purchase completed');
      _debugLog('Premium entitlement active after purchase');
      return result;
    }
    return const PremiumPurchaseResult.failed(
      PremiumPurchaseError(PremiumPurchaseErrorKind.premiumNotActive),
    );
  }

  Future<PremiumPurchaseResult> restorePurchases() {
    if (!hasAuthenticatedIdentity) {
      return Future.value(const PremiumPurchaseResult.failed(
        PremiumPurchaseError(PremiumPurchaseErrorKind.authenticationRequired),
      ));
    }
    return _restoreInFlight ??= _restore().whenComplete(
      () => _restoreInFlight = null,
    );
  }

  Future<PremiumPurchaseResult>? _restoreInFlight;

  Future<PremiumPurchaseResult> _restore() async {
    _debugLog('Restore started');
    try {
      final snapshot =
          await _client.restorePurchases().timeout(_operationTimeout);
      _applyCustomerInfoSnapshot(snapshot);
      final active = _accessState.isPremium;
      _debugLog('Restore completed');
      _debugLog('Restore found active Premium: $active');
      return active
          ? const PremiumPurchaseResult.success()
          : const PremiumPurchaseResult.failed(
              PremiumPurchaseError(PremiumPurchaseErrorKind.premiumNotActive),
            );
    } catch (error) {
      _debugLog('Restore failed: ${_safeError(error)}');
      return const PremiumPurchaseResult.failed(
        PremiumPurchaseError(PremiumPurchaseErrorKind.unknown),
      );
    }
  }

  Future<void> _transitionIdentity({
    required String? userId,
    required int generation,
  }) async {
    if (_disposed) return;
    _identityResolved = true;
    await initialize();
    if (!_isCurrentIdentityRequest(generation)) return;
    if (!_configuration.isConfigured) {
      _clearPremiumState();
      return;
    }

    if (userId == null &&
        _boundUserId == null &&
        _customerInfoListener != null &&
        !_sdkIdentityIsIdentified) {
      if (userId == null) {
        _clearPremiumState();
      }
      return;
    }

    if (userId != null && userId == _boundUserId && _sdkIdentityIsIdentified) {
      _removeCustomerInfoListener();
      try {
        final customerInfo =
            await _client.getCustomerInfo().timeout(_operationTimeout);
        if (!_isCurrentIdentityRequest(generation)) return;
        _applyCustomerInfoSnapshot(customerInfo);
        _registerCustomerInfoListener(
          generation: generation,
          expectedUserId: userId,
        );
        await _logDebugDiagnostics();
      } catch (error) {
        _clearPremiumState();
        _debugLog('RevenueCat customer info unavailable: ${_safeError(error)}');
      }
      return;
    }

    _clearPremiumState();
    _removeCustomerInfoListener();

    if (_sdkIdentityIsIdentified) {
      try {
        await _client.logOut().timeout(_operationTimeout);
        _sdkIdentityIsIdentified = false;
        _boundUserId = null;
        _debugLog('RevenueCat identity cleared on logout');
      } catch (error) {
        _boundUserId = null;
        _debugLog(
          'RevenueCat identity logout unavailable: ${_safeError(error)}',
        );
        return;
      }
    }

    if (!_isCurrentIdentityRequest(generation)) return;
    if (userId == null) {
      _registerCustomerInfoListener(
        generation: generation,
        expectedUserId: null,
      );
      return;
    }

    try {
      final customerInfo =
          await _client.logIn(userId).timeout(_operationTimeout);
      _sdkIdentityIsIdentified = true;
      _boundUserId = userId;
      if (_isCurrentIdentityRequest(generation)) {
        _applyCustomerInfoSnapshot(customerInfo);
        _registerCustomerInfoListener(
          generation: generation,
          expectedUserId: userId,
        );
        _debugLog(
          'RevenueCat bound to Supabase user: ${_shortUserId(userId)}',
        );
        await _logDebugDiagnostics();
      }
    } catch (error) {
      _sdkIdentityIsIdentified = false;
      _boundUserId = null;
      _debugLog('RevenueCat identity login unavailable: ${_safeError(error)}');
      _reportNonFatal(
        error,
        StackTrace.current,
        CrashReportingReasons.revenueCatIdentityFailure,
      );
    }
  }

  void _registerCustomerInfoListener({
    required int generation,
    required String? expectedUserId,
  }) {
    _removeCustomerInfoListener();
    void listener(RevenueCatCustomerInfoSnapshot snapshot) {
      if (!_isCurrentIdentityRequest(generation) ||
          !_identityResolved ||
          _boundUserId != expectedUserId) {
        _debugLog('Ignored stale CustomerInfo update');
        return;
      }
      _applyCustomerInfoSnapshot(snapshot);
    }

    _customerInfoListener = listener;
    _client.addCustomerInfoListener(listener);
  }

  void _removeCustomerInfoListener() {
    final listener = _customerInfoListener;
    if (listener == null) return;
    _client.removeCustomerInfoListener(listener);
    _customerInfoListener = null;
  }

  Future<void> _refreshCustomerInfo() async {
    if (!_identityResolved) return;
    final generation = _identityGeneration;
    final expectedUserId = _boundUserId;
    try {
      final snapshot =
          await _client.getCustomerInfo().timeout(_operationTimeout);
      if (generation != _identityGeneration || expectedUserId != _boundUserId) {
        _debugLog('Ignored stale CustomerInfo update');
        return;
      }
      _applyCustomerInfoSnapshot(snapshot);
    } catch (error) {
      _log('RevenueCat customer info unavailable: ${_safeError(error)}');
    }
  }

  Future<void> _refreshOffering() async {
    try {
      final snapshot =
          await _client.getCurrentOffering().timeout(_operationTimeout);
      _applyOffering(premiumOfferingFromSnapshot(snapshot));
    } catch (error) {
      _log('RevenueCat offering unavailable: ${_safeError(error)}');
    }
  }

  void _applyAccessState(PremiumAccessState next) {
    if (_accessState == next) return;
    _accessState = next;
    _notifyListeners();
  }

  void _applyCustomerInfoSnapshot(RevenueCatCustomerInfoSnapshot snapshot) {
    _managementUrl = snapshot.managementUrl;
    _applyAccessState(premiumAccessStateFromCustomerInfo(snapshot));
  }

  void _applyOffering(PremiumOffering? next) {
    _currentOffering = next;
    _notifyListeners();
  }

  void _clearPremiumState() {
    _applyAccessState(const PremiumAccessState.unknown());
  }

  bool _isCurrentIdentityRequest(int generation) =>
      generation == _identityGeneration;

  String? _normalizeUserId(String? userId) {
    final normalized = userId?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  bool _isAnonymousUserId(String userId) =>
      userId.startsWith(r'$RCAnonymousID:');

  String _shortUserId(String userId) {
    if (userId.length <= 8) return userId;
    return '${userId.substring(0, 8)}…';
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  void _reportNonFatal(Object error, StackTrace stackTrace, String reason) {
    unawaited(_crashReportingService?.recordNonFatal(
      error,
      stackTrace,
      reason: reason,
    ));
  }

  Future<void> _logDebugDiagnostics() async {
    if (!kDebugMode) return;

    String appUserId;
    try {
      appUserId = await _client.getAppUserId().timeout(_operationTimeout);
    } catch (error) {
      appUserId = 'unavailable (${_safeError(error)})';
    }

    final offering = _currentOffering;
    final monthly = offering?.monthly;
    final annual = offering?.annual;
    const monthlyPackageIdentifier = r'$rc_monthly';
    const annualPackageIdentifier = r'$rc_annual';
    _log('RevenueCat app user ID: $appUserId');
    _log('RevenueCat current offering: ${offering?.identifier ?? 'none'}');
    _log(
      'RevenueCat $monthlyPackageIdentifier: exists=${monthly != null}, '
      'localizedPrice=${monthly?.localizedPrice ?? 'none'}',
    );
    _log(
      'RevenueCat $annualPackageIdentifier: exists=${annual != null}, '
      'localizedPrice=${annual?.localizedPrice ?? 'none'}',
    );
    _log(
      'RevenueCat premium entitlement active: ${_accessState.isPremium}',
    );
    _log(
      'RevenueCat PremiumAccessState: '
      'status=${_accessState.status.name}, '
      'isPremium=${_accessState.isPremium}',
    );
  }

  void _debugLog(String message) {
    if (kDebugMode) _log(message);
  }

  void _log(String message) => _logger('[premium] $message');

  String _safeError(Object error) => error.runtimeType.toString();

  String _planLabel(String packageIdentifier) =>
      packageIdentifier == r'$rc_annual' ? 'annual' : 'monthly';

  @override
  void dispose() {
    _disposed = true;
    _identityGeneration++;
    _removeCustomerInfoListener();
    super.dispose();
  }

  static void _defaultLogger(String message) {
    if (kDebugMode) debugPrint(message);
  }
}
