import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_controller.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_state.dart';
import 'package:rutio/features/shop/application/shop_cloud_refresh_coordinator.dart';
import 'package:rutio/features/shop/application/shop_controller.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_runtime_config.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/domain/shop_purchase_result.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShopCloudRefreshCoordinator', () {
    test('reconciles cloud state in the expected order', () async {
      final fixture = await _Fixture.create(userId: 'user-a');

      final result = await fixture.coordinator.refreshShopCloudState(
        reason: ShopRefreshReason.opened,
        force: true,
      );

      expect(result.status, ShopCloudRefreshStatus.success);
      expect(fixture.events, <String>[
        'pending',
        'wallet:user-a:true',
        'shop:true',
        'cosmetics:true',
        'effects',
        'mystery_boxes',
      ]);
    });

    test('shares one refresh for concurrent resumed events', () async {
      final fixture = await _Fixture.create(userId: 'user-a');
      final gate = Completer<void>();
      fixture.shopController.hydrateGate = gate.future;

      final first = fixture.coordinator.refreshShopCloudState(
        reason: ShopRefreshReason.resumed,
        force: true,
      );
      final second = fixture.coordinator.refreshShopCloudState(
        reason: ShopRefreshReason.resumed,
        force: true,
      );

      await fixture.shopController.waitForHydrateCall();
      expect(fixture.shopController.hydrateCalls, 1);

      gate.complete();
      await Future.wait(<Future<ShopCloudRefreshResult>>[first, second]);

      expect(fixture.shopController.hydrateCalls, 1);
      expect(fixture.walletController.syncCalls, 1);
      expect(fixture.cosmeticsController.refreshCalls, 1);
    });

    test('reports partial refresh when a remote step fails', () async {
      final fixture = await _Fixture.create(userId: 'user-a');
      fixture.cosmeticsController.refreshError = StateError('offline');

      final result = await fixture.coordinator.refreshShopCloudState(
        reason: ShopRefreshReason.opened,
        force: true,
      );

      expect(result.status, ShopCloudRefreshStatus.partial);
      expect(result.errors, hasLength(1));
      expect(fixture.shopController.hydrateCalls, 1);
    });

    test('debounces repeated automatic resumed refreshes only', () async {
      final now = _MutableClock(DateTime.utc(2026, 7, 27, 10));
      final fixture = await _Fixture.create(
        userId: 'user-a',
        nowProvider: now.call,
        minRefreshInterval: const Duration(seconds: 30),
      );

      final first = await fixture.coordinator.refreshShopCloudState(
        reason: ShopRefreshReason.resumed,
      );
      final second = await fixture.coordinator.refreshShopCloudState(
        reason: ShopRefreshReason.resumed,
      );

      expect(first.status, ShopCloudRefreshStatus.success);
      expect(second.status, ShopCloudRefreshStatus.skipped);
      expect(second.skipReason, 'debounced');
      expect(fixture.shopController.hydrateCalls, 1);
    });

    test('force bypasses debounce when no refresh is active', () async {
      final now = _MutableClock(DateTime.utc(2026, 7, 27, 10));
      final fixture = await _Fixture.create(
        userId: 'user-a',
        nowProvider: now.call,
        minRefreshInterval: const Duration(seconds: 30),
      );

      await fixture.coordinator.refreshShopCloudState(
        reason: ShopRefreshReason.resumed,
      );
      final forced = await fixture.coordinator.refreshShopCloudState(
        reason: ShopRefreshReason.resumed,
        force: true,
      );

      expect(forced.status, ShopCloudRefreshStatus.success);
      expect(fixture.shopController.hydrateCalls, 2);
    });

    test('clears the active refresh after failed refresh result', () async {
      final fixture = await _Fixture.create(userId: 'user-a');
      fixture.shopController
        ..pendingError = StateError('pending failed')
        ..hydrateError = StateError('shop failed')
        ..effectsError = StateError('effects failed')
        ..mysteryBoxesError = StateError('boxes failed');
      fixture.walletController.syncError = StateError('wallet failed');
      fixture.cosmeticsController.refreshError = StateError('cosmetics failed');

      final failed = await fixture.coordinator.refreshShopCloudState(
        reason: ShopRefreshReason.opened,
        force: true,
      );
      fixture.shopController
        ..pendingError = null
        ..hydrateError = null
        ..effectsError = null
        ..mysteryBoxesError = null;
      fixture.walletController.syncError = null;
      fixture.cosmeticsController.refreshError = null;
      final retry = await fixture.coordinator.refreshShopCloudState(
        reason: ShopRefreshReason.opened,
        force: true,
      );

      expect(failed.status, ShopCloudRefreshStatus.failed);
      expect(failed.errors, hasLength(6));
      expect(retry.status, ShopCloudRefreshStatus.success);
      expect(fixture.shopController.hydrateCalls, 2);
    });

    test('stops reporting success when the user changes mid-refresh', () async {
      final fixture = await _Fixture.create(userId: 'user-a');
      final gate = Completer<void>();
      fixture.shopController.hydrateGate = gate.future;

      final refresh = fixture.coordinator.refreshShopCloudState(
        reason: ShopRefreshReason.opened,
        force: true,
      );
      await fixture.shopController.waitForHydrateCall();
      fixture.currentUserId = 'user-b';
      gate.complete();
      final result = await refresh;

      expect(result.status, ShopCloudRefreshStatus.skipped);
      expect(result.skipReason, 'user_changed');
      expect(fixture.cosmeticsController.refreshCalls, 0);
    });

    test('skips local demo and screenshot runtime modes', () async {
      final fixture = await _Fixture.create(
        userId: 'user-a',
        runtimeConfig: const ShopCloudRuntimeConfig(
          shopReadEnabled: false,
          shopPurchaseEnabled: false,
          cloudCosmeticsEnabled: false,
          cloudUtilityConsumptionEnabled: false,
          cloudMysteryBoxEnabled: false,
          runtimeMode: ShopRuntimeMode.localDemo,
        ),
      );

      final result = await fixture.coordinator.refreshShopCloudState(
        reason: ShopRefreshReason.opened,
        force: true,
      );

      expect(result.status, ShopCloudRefreshStatus.skipped);
      expect(result.skipReason, 'cloud_disabled');
      expect(fixture.events, isEmpty);
    });

    test('skips when there is no authenticated user', () async {
      final fixture = await _Fixture.create(userId: null);

      final result = await fixture.coordinator.refreshShopCloudState(
        reason: ShopRefreshReason.opened,
        force: true,
      );

      expect(result.status, ShopCloudRefreshStatus.skipped);
      expect(result.skipReason, 'unauthenticated');
      expect(fixture.events, isEmpty);
    });
  });
}

class _Fixture {
  _Fixture({
    required this.events,
    required this.userProvider,
    required this.shopController,
    required this.cosmeticsController,
    required this.walletController,
    required this.coordinator,
  });

  final List<String> events;
  final _MutableUserProvider userProvider;
  final _FakeShopController shopController;
  final _FakeShopCosmeticsController cosmeticsController;
  final _FakeWalletController walletController;
  final ShopCloudRefreshCoordinator coordinator;

  String? get currentUserId => userProvider.userId;

  set currentUserId(String? value) {
    userProvider.userId = value;
  }

  static Future<_Fixture> create({
    required String? userId,
    DateTime Function()? nowProvider,
    Duration minRefreshInterval = Duration.zero,
    ShopCloudRuntimeConfig runtimeConfig = const ShopCloudRuntimeConfig(
      shopReadEnabled: true,
      shopPurchaseEnabled: true,
      cloudCosmeticsEnabled: true,
      cloudUtilityConsumptionEnabled: true,
      cloudMysteryBoxEnabled: true,
      runtimeMode: ShopRuntimeMode.cloud,
    ),
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final events = <String>[];
    final userProvider = _MutableUserProvider(userId);
    final store = UserStateStore(
      UserStateRepository(storage: UserStateStorage()),
      journalEntrySyncService: JournalEntrySyncService(),
    );
    addTearDown(store.dispose);
    final shopController = _FakeShopController(
      store: store,
      userIdProvider: () => userProvider.userId,
      events: events,
    );
    final cosmeticsController = _FakeShopCosmeticsController(
      store: store,
      events: events,
    );
    final walletController = _FakeWalletController(events: events);
    addTearDown(shopController.dispose);
    addTearDown(cosmeticsController.dispose);
    addTearDown(walletController.dispose);

    final coordinator = ShopCloudRefreshCoordinator(
      shopController: shopController,
      cosmeticsController: cosmeticsController,
      walletController: walletController,
      runtimeConfig: runtimeConfig,
      currentUserIdProvider: () => userProvider.userId,
      nowProvider: nowProvider,
      minRefreshInterval: minRefreshInterval,
    );

    return _Fixture(
      events: events,
      userProvider: userProvider,
      shopController: shopController,
      cosmeticsController: cosmeticsController,
      walletController: walletController,
      coordinator: coordinator,
    );
  }
}

class _FakeShopController extends ShopController {
  _FakeShopController({
    required UserStateStore store,
    required this.userIdProvider,
    required this.events,
  }) : super(
          userStateStore: store,
          cloudReadEnabled: false,
          cloudPurchaseEnabled: false,
        );

  final String? Function() userIdProvider;
  final List<String> events;
  Future<void>? hydrateGate;
  Object? pendingError;
  Object? hydrateError;
  Object? effectsError;
  Object? mysteryBoxesError;
  int hydrateCalls = 0;
  Completer<void>? _hydrateCallCompleter;

  @override
  String? get currentSupabaseUserIdForShop => userIdProvider();

  @override
  Future<List<ShopPurchaseResult>> resolvePendingPurchasesForCurrentUser({
    int maxOperations = 3,
  }) async {
    events.add('pending');
    final error = pendingError;
    if (error != null) throw error;
    return const <ShopPurchaseResult>[];
  }

  @override
  Future<void> hydrateVisibleEconomy({bool force = false}) async {
    hydrateCalls += 1;
    events.add('shop:$force');
    _hydrateCallCompleter?.complete();
    _hydrateCallCompleter = null;
    await hydrateGate;
    final error = hydrateError;
    if (error != null) throw error;
  }

  Future<void> waitForHydrateCall() {
    if (hydrateCalls > 0) return Future<void>.value();
    return (_hydrateCallCompleter ??= Completer<void>()).future;
  }

  @override
  Future<List<ActiveUtilityEffect>> getActiveUtilityEffects() async {
    events.add('effects');
    final error = effectsError;
    if (error != null) throw error;
    return const <ActiveUtilityEffect>[];
  }

  @override
  Future<List<MysteryBoxOpeningTransaction>>
      getPendingMysteryBoxOpenings() async {
    events.add('mystery_boxes');
    final error = mysteryBoxesError;
    if (error != null) throw error;
    return const <MysteryBoxOpeningTransaction>[];
  }

  @override
  Future<ShopState> getVisibleShopState() async => const ShopState.initial();
}

class _FakeShopCosmeticsController extends ShopCosmeticsController {
  _FakeShopCosmeticsController({
    required UserStateStore store,
    required this.events,
  }) : super(
          userStateStore: store,
          cloudEnabled: false,
        );

  final List<String> events;
  Object? refreshError;
  int refreshCalls = 0;

  @override
  Future<ShopCosmeticsState> refreshCloudState({bool force = false}) async {
    refreshCalls += 1;
    events.add('cosmetics:$force');
    final error = refreshError;
    if (error != null) throw error;
    return const ShopCosmeticsState.initial();
  }
}

class _FakeWalletController extends GlobalWalletController {
  _FakeWalletController({required this.events}) : super(enabled: false);

  final List<String> events;
  int syncCalls = 0;
  Object? syncError;

  @override
  Future<GlobalWalletState> syncSession({
    String? userId,
    bool force = false,
  }) async {
    syncCalls += 1;
    events.add('wallet:$userId:$force');
    final error = syncError;
    if (error != null) throw error;
    return GlobalWalletState.unauthenticated();
  }
}

class _MutableUserProvider {
  _MutableUserProvider(this.userId);

  String? userId;
}

class _MutableClock {
  _MutableClock(this.now);

  DateTime now;

  DateTime call() => now;
}
