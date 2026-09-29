import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/premium/data/premium_repository.dart';
import 'package:rutio/features/premium/domain/premium_access.dart';
import 'package:rutio/features/premium/domain/premium_purchase.dart';
import 'package:rutio/features/premium/data/revenuecat/revenuecat_client.dart';
import 'package:rutio/features/premium/data/revenuecat/revenuecat_configuration.dart';

void main() {
  test('duplicate initialization configures RevenueCat only once', () async {
    final client = _FakeRevenueCatClient(
      customerInfo: const RevenueCatCustomerInfoSnapshot(
        activeEntitlements: {},
        allEntitlements: {},
      ),
      offering: const RevenueCatOfferingSnapshot(
        identifier: 'default',
        packages: [],
      ),
    );
    final repository = PremiumRepository(
      client: client,
      configuration: const RevenueCatConfiguration(testApiKey: 'test_key'),
    );

    await Future.wait([repository.initialize(), repository.initialize()]);

    expect(client.configureCalls, 1);
    expect(client.addListenerCalls, 1);
    expect(repository.currentOffering?.identifier, 'default');
    repository.dispose();
    expect(client.removeListenerCalls, 1);
  });

  test('RevenueCat failure does not escape initialization', () async {
    final client = _FakeRevenueCatClient(throwsOnConfigure: true);
    final repository = PremiumRepository(
      client: client,
      configuration: const RevenueCatConfiguration(testApiKey: 'test_key'),
    );

    await expectLater(repository.initialize(), completes);
    expect(repository.accessState.status.name, 'unknown');
    repository.dispose();
  });

  test('missing configuration skips SDK initialization safely', () async {
    final client = _FakeRevenueCatClient();
    final repository = PremiumRepository(
      client: client,
      configuration: const RevenueCatConfiguration(testApiKey: ''),
    );

    await repository.initialize();

    expect(client.configureCalls, 0);
    expect(repository.accessState.status.name, 'unknown');
    repository.dispose();
  });

  test('purchase requires the authenticated RevenueCat identity', () async {
    final repository = PremiumRepository(
      client: _FakeRevenueCatClient(),
      configuration: const RevenueCatConfiguration(testApiKey: 'test_key'),
    );

    final result = await repository.purchasePackage(r'$rc_monthly');

    expect(result.error?.kind, PremiumPurchaseErrorKind.authenticationRequired);
    repository.dispose();
  });

  test('successful purchase refreshes and publishes active Premium', () async {
    const premiumInfo = RevenueCatCustomerInfoSnapshot(
      activeEntitlements: {
        'premium': RevenueCatEntitlementSnapshot(
          isActive: true,
          isTrial: false,
          productIdentifier: 'rutio_test_premium_monthly',
          willRenew: true,
        ),
      },
      allEntitlements: {},
    );
    final client = _FakeRevenueCatClient(customerInfo: premiumInfo);
    final repository = PremiumRepository(
      client: client,
      configuration: const RevenueCatConfiguration(testApiKey: 'test_key'),
    );

    await repository.syncIdentity('user-a');
    final result = await repository.purchasePackage(r'$rc_monthly');

    expect(result.isSuccess, isTrue);
    expect(repository.accessState.isPremium, isTrue);
    expect(client.purchaseCalls, 1);
    repository.dispose();
  });

  test('delayed store purchase is not converted into an application timeout',
      () async {
    const premiumInfo = RevenueCatCustomerInfoSnapshot(
      activeEntitlements: {
        'premium': RevenueCatEntitlementSnapshot(
          isActive: true,
          isTrial: false,
          productIdentifier: 'rutio_test_premium_monthly',
          willRenew: true,
        ),
      },
      allEntitlements: {},
    );
    final repository = PremiumRepository(
      client: _FakeRevenueCatClient(
        customerInfo: premiumInfo,
        purchaseDelay: const Duration(milliseconds: 20),
      ),
      configuration: const RevenueCatConfiguration(testApiKey: 'test_key'),
      operationTimeout: const Duration(milliseconds: 1),
    );

    await repository.syncIdentity('user-a');
    final result = await repository.purchasePackage(r'$rc_monthly');

    expect(result.isSuccess, isTrue);
    expect(repository.accessState.isPremium, isTrue);
    repository.dispose();
  });

  test('purchase cancellation remains a non-error outcome', () async {
    final repository = PremiumRepository(
      client: _FakeRevenueCatClient(
        purchaseResult: const PremiumPurchaseResult.cancelled(),
      ),
      configuration: const RevenueCatConfiguration(testApiKey: 'test_key'),
    );

    await repository.syncIdentity('user-a');
    final result = await repository.purchasePackage(r'$rc_monthly');

    expect(result.isCancelled, isTrue);
    expect(repository.accessState.isPremium, isFalse);
    repository.dispose();
  });

  test('genuine purchase errors remain application errors', () async {
    final repository = PremiumRepository(
      client: _FakeRevenueCatClient(
        purchaseResult: const PremiumPurchaseResult.failed(
          PremiumPurchaseError(PremiumPurchaseErrorKind.network),
        ),
      ),
      configuration: const RevenueCatConfiguration(testApiKey: 'test_key'),
    );

    await repository.syncIdentity('user-a');
    final result = await repository.purchasePackage(r'$rc_monthly');

    expect(result.error?.kind, PremiumPurchaseErrorKind.network);
    repository.dispose();
  });

  test('duplicate purchase calls share one in-flight operation', () async {
    final client = _FakeRevenueCatClient(
      customerInfo: const RevenueCatCustomerInfoSnapshot(
        activeEntitlements: {
          'premium': RevenueCatEntitlementSnapshot(
            isActive: true,
            isTrial: false,
            productIdentifier: 'rutio_test_premium_monthly',
            willRenew: true,
          ),
        },
        allEntitlements: {},
      ),
      purchaseDelay: const Duration(milliseconds: 20),
    );
    final repository = PremiumRepository(
      client: client,
      configuration: const RevenueCatConfiguration(testApiKey: 'test_key'),
    );

    await repository.syncIdentity('user-a');
    final results = await Future.wait([
      repository.purchasePackage(r'$rc_monthly'),
      repository.purchasePackage(r'$rc_monthly'),
    ]);

    expect(client.purchaseCalls, 1);
    expect(results.first.isSuccess, isTrue);
    expect(results[1].isSuccess, isTrue);
    repository.dispose();
  });

  test('debug diagnostics report the initialized RevenueCat state', () async {
    final logs = <String>[];
    final client = _FakeRevenueCatClient(
      appUserId: r'$RCAnonymousID:test',
      customerInfo: const RevenueCatCustomerInfoSnapshot(
        activeEntitlements: {
          'premium': RevenueCatEntitlementSnapshot(
            isActive: true,
            isTrial: false,
            productIdentifier: 'rutio_test_premium_monthly',
            willRenew: true,
          ),
        },
        allEntitlements: {
          'premium': RevenueCatEntitlementSnapshot(
            isActive: true,
            isTrial: false,
            productIdentifier: 'rutio_test_premium_monthly',
            willRenew: true,
          ),
        },
      ),
      offering: const RevenueCatOfferingSnapshot(
        identifier: 'default',
        packages: [
          RevenueCatPackageSnapshot(
            identifier: r'$rc_monthly',
            productIdentifier: 'rutio_test_premium_monthly',
            localizedPrice: '€2.49',
          ),
          RevenueCatPackageSnapshot(
            identifier: r'$rc_annual',
            productIdentifier: 'rutio_test_premium_annual',
            localizedPrice: '€24.99',
          ),
        ],
      ),
    );
    final repository = PremiumRepository(
      client: client,
      configuration: const RevenueCatConfiguration(testApiKey: 'test_key'),
      logger: logs.add,
    );

    await repository.syncIdentity('user-test');

    expect(logs, contains(contains('RevenueCat initialization success')));
    expect(logs, contains(contains('RevenueCat app user ID:')));
    expect(logs, contains(contains(r'RevenueCat $rc_monthly: exists=true')));
    expect(logs, contains(contains(r'RevenueCat $rc_annual: exists=true')));
    expect(logs, contains(contains('localizedPrice=€2.49')));
    expect(logs, contains(contains('localizedPrice=€24.99')));
    expect(logs, contains(contains('premium entitlement active: true')));
    expect(logs, contains(contains('PremiumAccessState: status=premium')));
    repository.dispose();
  });

  test('identity binding is idempotent and switches through anonymous state',
      () async {
    final client = _FakeRevenueCatClient();
    final repository = PremiumRepository(
      client: client,
      configuration: const RevenueCatConfiguration(testApiKey: 'test_key'),
    );

    await repository.syncIdentity('user-a');
    await repository.syncIdentity('user-a');
    expect(client.logInCalls, 1);

    await repository.syncIdentity(null);
    expect(client.logOutCalls, 1);
    expect(repository.accessState.status, PremiumAccessStatus.unknown);

    await repository.syncIdentity('user-b');
    expect(client.logInCalls, 2);
    expect(client.logOutCalls, 1);
    repository.dispose();
  });

  test('existing RevenueCat identity is reused without identity churn',
      () async {
    final client = _FakeRevenueCatClient(appUserId: 'user-a');
    final repository = PremiumRepository(
      client: client,
      configuration: const RevenueCatConfiguration(testApiKey: 'test_key'),
    );

    await repository.syncIdentity('user-a');

    expect(client.logInCalls, 0);
    expect(client.logOutCalls, 0);
    repository.dispose();
  });

  test('RevenueCat identity failures do not escape the auth lifecycle',
      () async {
    final loginClient = _FakeRevenueCatClient(throwsOnLogIn: true);
    final loginRepository = PremiumRepository(
      client: loginClient,
      configuration: const RevenueCatConfiguration(testApiKey: 'test_key'),
    );

    await expectLater(loginRepository.syncIdentity('user-a'), completes);
    expect(loginRepository.accessState.status, PremiumAccessStatus.unknown);
    loginRepository.dispose();

    final logoutClient = _FakeRevenueCatClient(appUserId: 'user-a')
      ..throwsOnLogOut = true;
    final logoutRepository = PremiumRepository(
      client: logoutClient,
      configuration: const RevenueCatConfiguration(testApiKey: 'test_key'),
    );

    await expectLater(logoutRepository.syncIdentity(null), completes);
    expect(logoutRepository.accessState.status, PremiumAccessStatus.unknown);
    logoutRepository.dispose();
  });

  test('stale customer info callbacks are ignored after a user switch',
      () async {
    final client = _FakeRevenueCatClient();
    final repository = PremiumRepository(
      client: client,
      configuration: const RevenueCatConfiguration(testApiKey: 'test_key'),
    );
    const premiumInfo = RevenueCatCustomerInfoSnapshot(
      activeEntitlements: {
        'premium': RevenueCatEntitlementSnapshot(
          isActive: true,
          isTrial: false,
          productIdentifier: 'rutio_test_premium_monthly',
          willRenew: true,
        ),
      },
      allEntitlements: {},
    );

    await repository.syncIdentity('user-a');
    final userAListener = client.listeners[1];
    await repository.syncIdentity('user-b');
    userAListener(premiumInfo);

    expect(repository.accessState.status, PremiumAccessStatus.free);
    repository.dispose();
  });
}

class _FakeRevenueCatClient implements RevenueCatClient {
  _FakeRevenueCatClient({
    this.appUserId = r'$RCAnonymousID:test',
    this.customerInfo = const RevenueCatCustomerInfoSnapshot(
      activeEntitlements: {},
      allEntitlements: {},
    ),
    this.offering,
    this.throwsOnConfigure = false,
    this.throwsOnLogIn = false,
    this.purchaseDelay = Duration.zero,
    this.purchaseResult = const PremiumPurchaseResult.success(),
  });

  String appUserId;
  final RevenueCatCustomerInfoSnapshot customerInfo;
  final RevenueCatOfferingSnapshot? offering;
  final bool throwsOnConfigure;
  final bool throwsOnLogIn;
  bool throwsOnLogOut = false;
  Duration purchaseDelay = Duration.zero;
  final PremiumPurchaseResult purchaseResult;
  int purchaseCalls = 0;
  int configureCalls = 0;
  int logInCalls = 0;
  int logOutCalls = 0;
  int addListenerCalls = 0;
  int removeListenerCalls = 0;
  RevenueCatCustomerInfoListener? _listener;
  final List<RevenueCatCustomerInfoListener> listeners = [];

  @override
  Future<void> configure({
    required String apiKey,
    required bool enableDebugLogging,
  }) async {
    configureCalls++;
    if (throwsOnConfigure) throw StateError('unavailable');
  }

  @override
  Future<RevenueCatCustomerInfoSnapshot> logIn(String appUserId) async {
    logInCalls++;
    if (throwsOnLogIn) throw StateError('login unavailable');
    this.appUserId = appUserId;
    return customerInfo;
  }

  @override
  Future<RevenueCatCustomerInfoSnapshot> logOut() async {
    logOutCalls++;
    if (throwsOnLogOut) throw StateError('logout unavailable');
    appUserId = r'$RCAnonymousID:test';
    return const RevenueCatCustomerInfoSnapshot(
      activeEntitlements: {},
      allEntitlements: {},
    );
  }

  @override
  Future<String> getAppUserId() async => appUserId;

  @override
  void addCustomerInfoListener(RevenueCatCustomerInfoListener listener) {
    addListenerCalls++;
    _listener = listener;
    listeners.add(listener);
  }

  @override
  void removeCustomerInfoListener(RevenueCatCustomerInfoListener listener) {
    removeListenerCalls++;
    if (identical(_listener, listener)) _listener = null;
  }

  @override
  Future<RevenueCatCustomerInfoSnapshot> getCustomerInfo() async =>
      customerInfo;

  @override
  Future<RevenueCatOfferingSnapshot?> getCurrentOffering() async => offering;

  @override
  Future<PremiumPurchaseResult> purchasePackage(String packageIdentifier) =>
      _purchase(packageIdentifier);

  Future<PremiumPurchaseResult> _purchase(String packageIdentifier) async {
    purchaseCalls++;
    if (purchaseDelay > Duration.zero) {
      await Future<void>.delayed(purchaseDelay);
    }
    return purchaseResult;
  }

  @override
  Future<RevenueCatCustomerInfoSnapshot> restorePurchases() async =>
      customerInfo;
}
