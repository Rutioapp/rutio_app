import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_controller.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_errors.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_repository.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_snapshot.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_dtos.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_cache.dart';
import 'package:rutio/features/shop/data/cloud/cloud_cosmetics_snapshot.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_equip_dtos.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_errors.dart';
import 'package:rutio/features/shop/data/cloud/shop_cloud_purchase_dtos.dart';
import 'package:rutio/features/shop/data/cloud/shop_cosmetics_cloud_repository.dart';
import 'package:rutio/features/shop/data/shop_cosmetics_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/home/home_screen.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/widgets/home/user_identity_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Provider.debugCheckInvalidValueType = null;

  testWidgets('home screen open asks store for controlled habits auto sync',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = _FakeHomeStore();

    await tester.pumpWidget(_app(store: store));
    await tester.pumpAndSettle();

    expect(store.maybeSyncHabitsFromRemoteBestEffortCalls, 1);
    expect(store.syncHabitsFromRemoteBestEffortCalls, 0);
    expect(find.text('Drink Water'), findsOneWidget);
  });

  testWidgets('pull-to-refresh triggers habits remote sync manually only',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = _FakeHomeStore();

    await tester.pumpWidget(_app(store: store));
    await tester.pumpAndSettle();

    expect(store.syncHabitsFromRemoteBestEffortCalls, 0);
    expect(find.text('Drink Water'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(store.maybeSyncHabitsFromRemoteBestEffortCalls, 2);
    expect(store.lastMaybeSyncIgnoreCooldown, isTrue);
    expect(store.syncHabitsFromRemoteBestEffortCalls, 0);
    expect(find.text('Drink Water'), findsOneWidget);
    expect(store.pendingAchievementUnlockCount, 0);
    expect(store.pendingLevelCelebrationCount, 0);
  });

  testWidgets('pull-to-refresh failure keeps local habits intact',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = _FakeHomeStore(
      syncHabitsFromRemoteBestEffortError: StateError('offline'),
    );

    await tester.pumpWidget(_app(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Drink Water'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(store.maybeSyncHabitsFromRemoteBestEffortCalls, 2);
    expect(store.lastMaybeSyncIgnoreCooldown, isTrue);
    expect(store.syncHabitsFromRemoteBestEffortCalls, 0);
    expect(find.text('Drink Water'), findsOneWidget);
  });

  testWidgets('app resume asks store for controlled habits auto sync',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = _FakeHomeStore();

    await tester.pumpWidget(_app(store: store));
    await tester.pumpAndSettle();
    expect(store.maybeSyncHabitsFromRemoteBestEffortCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(store.maybeSyncHabitsFromRemoteBestEffortCalls, 2);
    expect(store.lastMaybeSyncIgnoreCooldown, isFalse);
  });

  testWidgets('home updates the equipped habit card in the same session',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = _FakeHomeStore();
    final repository = ShopCosmeticsRepository(
      scopeResolver: () => store.activeLocalScopeUserId ?? store.userId,
    );
    await repository.save(
      ShopCosmeticsState(
        ownedAssetIds: <String>[
          'habit_card_warm_beige',
          'habit_card_soft_camel',
        ],
        ownedBundleIds: <String>[],
        equippedHabitCardSkinId: 'habit_card_warm_beige',
      ),
    );
    final controller = ShopCosmeticsController(
      userStateStore: store,
      repository: repository,
    );
    await controller.hydrate();

    await tester.pumpWidget(_app(store: store, controller: controller));
    await tester.pumpAndSettle();

    expect(_habitCardAssetName(tester), contains('habit_card_rutio_beige'));

    await controller.equipAsset('habit_card_soft_camel');
    await tester.pumpAndSettle();

    expect(_habitCardAssetName(tester), contains('habit_card_soft_camel'));
  });

  testWidgets('home updates cloud wallpaper immediately after equip',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = _FakeHomeStore();
    final snapshot = _cloudSnapshot(
      userId: 'home-cloud-user',
      ownedAssetIds: <String>[
        'wallpaper_mist_blue',
        'wallpaper_dusty_lilac',
      ],
      wallpaperId: 'wallpaper_mist_blue',
    );
    final repo = _FakeCloudCosmeticsRepository(
      fetchResponses: <_FetchResponseFactory>[
        () async => _cloudSuccess(snapshot),
        () async => _cloudSuccess(
              _cloudSnapshot(
                userId: 'home-cloud-user',
                ownedAssetIds: <String>[
                  'wallpaper_mist_blue',
                  'wallpaper_dusty_lilac',
                ],
                wallpaperId: 'wallpaper_dusty_lilac',
              ),
            ),
      ],
    );
    final controller = ShopCosmeticsController(
      userStateStore: store,
      cloudRepository: repo,
      cloudCache: _memoryCloudCache(snapshot),
      cloudEnabled: true,
    );

    await tester.pumpWidget(_app(store: store, controller: controller));
    await tester.pumpAndSettle();
    final initialRevision = controller.cloudSnapshotRevision;

    expect(
      _homeWallpaperAssetNames(tester),
      contains('assets/shop/wallpapers/common/wallpaper_mist_blue.webp'),
    );

    final result = await controller.equipAsset('wallpaper_dusty_lilac');
    expect(result.isSuccess, isTrue);

    await tester.pumpAndSettle();
    expect(
      _homeWallpaperAssetNames(tester),
      contains('assets/shop/wallpapers/common/wallpaper_dusty_lilac.webp'),
    );
    expect(controller.cloudSnapshotRevision, greaterThan(initialRevision));
  });

  testWidgets(
      'home updates cloud wallpaper while kept alive in an IndexedStack',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = _FakeHomeStore();
    final snapshot = _cloudSnapshot(
      userId: 'home-cloud-user',
      ownedAssetIds: <String>[
        'wallpaper_mist_blue',
        'wallpaper_dusty_lilac',
      ],
      wallpaperId: 'wallpaper_mist_blue',
    );
    final repo = _FakeCloudCosmeticsRepository(
      fetchResponses: <_FetchResponseFactory>[
        () async => _cloudSuccess(snapshot),
        () async => _cloudSuccess(
              _cloudSnapshot(
                userId: 'home-cloud-user',
                ownedAssetIds: <String>[
                  'wallpaper_mist_blue',
                  'wallpaper_dusty_lilac',
                ],
                wallpaperId: 'wallpaper_dusty_lilac',
              ),
            ),
      ],
    );
    final controller = ShopCosmeticsController(
      userStateStore: store,
      cloudRepository: repo,
      cloudCache: _memoryCloudCache(snapshot),
      cloudEnabled: true,
    );

    await tester.pumpWidget(
      _indexedStackApp(store: store, controller: controller),
    );
    await tester.pumpAndSettle();
    final initialRevision = controller.cloudSnapshotRevision;

    expect(
      _homeWallpaperAssetNames(tester),
      contains('assets/shop/wallpapers/common/wallpaper_mist_blue.webp'),
    );

    final result = await controller.equipAsset('wallpaper_dusty_lilac');
    expect(result.isSuccess, isTrue);

    await tester.pumpAndSettle();
    expect(
      _homeWallpaperAssetNames(tester),
      contains('assets/shop/wallpapers/common/wallpaper_dusty_lilac.webp'),
    );
    expect(controller.cloudSnapshotRevision, greaterThan(initialRevision));
  });

  testWidgets(
      'home user card shows the global wallet balance and clears on logout',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = _FakeHomeStore(walletCoins: 11);
    const userId = 'home-wallet-user';
    final repository = _FakeCloudWalletRepository()
      ..enqueueSuccess(
        _snapshot(
          userId: userId,
          coins: 250,
          version: 3,
          updatedAt: DateTime.utc(2026, 7, 18, 9),
        ),
      );
    final walletController = GlobalWalletController(
      repository: repository,
      currentUserIdProvider: () => userId,
      enabled: true,
    );
    await walletController.syncSession(userId: userId);

    await tester.pumpWidget(
      _app(store: store, walletController: walletController),
    );
    await tester.pumpAndSettle();

    final userCard = tester.widget<UserIdentityRow>(
      find.byType(UserIdentityRow).first,
    );
    expect(userCard.coins, 250);

    await walletController.clearSession();
    await tester.pumpAndSettle();

    final clearedCard = tester.widget<UserIdentityRow>(
      find.byType(UserIdentityRow).first,
    );
    expect(clearedCard.coins, 0);
  });

  testWidgets('home switches wallet balance when the active user changes',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = _FakeHomeStore(walletCoins: 5);
    String currentUserId = 'home-user-a';
    final repository = _FakeCloudWalletRepository()
      ..enqueueSuccess(
        _snapshot(
          userId: 'home-user-a',
          coins: 120,
          version: 1,
          updatedAt: DateTime.utc(2026, 7, 18, 9),
        ),
      )
      ..enqueueSuccess(
        _snapshot(
          userId: 'home-user-b',
          coins: 430,
          version: 2,
          updatedAt: DateTime.utc(2026, 7, 18, 10),
        ),
      );
    final walletController = GlobalWalletController(
      repository: repository,
      currentUserIdProvider: () => currentUserId,
      enabled: true,
    );
    await walletController.syncSession(userId: 'home-user-a');

    await tester.pumpWidget(
      _app(store: store, walletController: walletController),
    );
    await tester.pumpAndSettle();

    final initialCard = tester.widget<UserIdentityRow>(
      find.byType(UserIdentityRow).first,
    );
    expect(initialCard.coins, 120);

    currentUserId = 'home-user-b';
    await walletController.syncSession(userId: 'home-user-b');
    await tester.pumpAndSettle();

    final switchedCard = tester.widget<UserIdentityRow>(
      find.byType(UserIdentityRow).first,
    );
    expect(switchedCard.coins, 430);
  });
}

Widget _app({
  required UserStateStore store,
  ShopCosmeticsController? controller,
  GlobalWalletController? walletController,
}) {
  final home = const MediaQuery(
    data: MediaQueryData(size: Size(430, 932)),
    child: HomeScreen(),
  );

  return ChangeNotifierProvider<UserStateStore>.value(
    value: store,
    child: ChangeNotifierProvider<GlobalWalletController>.value(
      value: walletController ?? GlobalWalletController(enabled: false),
      child: controller == null
          ? MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: home,
            )
          : ChangeNotifierProvider<ShopCosmeticsController>.value(
              value: controller,
              child: MaterialApp(
                locale: const Locale('en'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: home,
              ),
            ),
    ),
  );
}

Widget _indexedStackApp({
  required UserStateStore store,
  required ShopCosmeticsController controller,
}) {
  final home = const MediaQuery(
    data: MediaQueryData(size: Size(430, 932)),
    child: HomeScreen(),
  );

  return ChangeNotifierProvider<UserStateStore>.value(
    value: store,
    child: ChangeNotifierProvider<GlobalWalletController>.value(
      value: GlobalWalletController(enabled: false),
      child: ChangeNotifierProvider<ShopCosmeticsController>.value(
        value: controller,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: IndexedStack(
            index: 0,
            children: <Widget>[
              home,
              const Scaffold(
                body: Center(child: Text('Other tab')),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _habitCardAssetName(WidgetTester tester) {
  final image = tester.widget<Image>(
    find.byKey(const Key('habitCardBackgroundImage')),
  );
  final provider = image.image;
  if (provider is AssetImage) {
    return provider.assetName;
  }
  return provider.toString();
}

List<String> _homeWallpaperAssetNames(WidgetTester tester) {
  return tester
      .widgetList<Image>(find.byKey(const Key('homeBackgroundWallpaperImage')))
      .map((Image image) {
    final provider = image.image;
    if (provider is AssetImage) {
      return provider.assetName;
    }
    return provider.toString();
  }).toList(growable: false);
}

typedef _FetchResponseFactory
    = FutureOr<ShopCloudReadResult<CloudCosmeticsSnapshot>> Function();

CloudCosmeticsSnapshot _cloudSnapshot({
  required String userId,
  required List<String> ownedAssetIds,
  String? wallpaperId,
}) {
  final now = DateTime.utc(2026, 7, 19, 12);
  return CloudCosmeticsSnapshot(
    userId: userId,
    ownedAssetIds: ownedAssetIds,
    ownedBundleIds: const <String>[],
    catalogBundles: const <RemoteShopBundleDto>[],
    equippedWallpaperId: wallpaperId,
    equippedHabitCardSkinId: null,
    equippedUserCardSkinId: null,
    catalogVersion: 1,
    fetchedAt: now,
    updatedAt: now,
  );
}

ShopCloudReadResult<CloudCosmeticsSnapshot> _cloudSuccess(
  CloudCosmeticsSnapshot snapshot,
) {
  return ShopCloudReadResult<CloudCosmeticsSnapshot>.success(data: snapshot);
}

CloudCosmeticsCache _memoryCloudCache(CloudCosmeticsSnapshot snapshot) {
  return _MemoryCloudCosmeticsCache(snapshot);
}

class _MemoryCloudCosmeticsCache implements CloudCosmeticsCache {
  _MemoryCloudCosmeticsCache(this._snapshot) {
    _seed();
  }

  final CloudCosmeticsSnapshot _snapshot;
  final Map<String, CloudCosmeticsCacheEntry> _entries =
      <String, CloudCosmeticsCacheEntry>{};

  void _seed() {
    _entries[_snapshot.userId] = CloudCosmeticsCacheEntry.fromSnapshot(
      _snapshot,
      cachedAt: _snapshot.fetchedAt,
    );
  }

  @override
  Future<void> clearAll() async {
    _entries.clear();
  }

  @override
  Future<void> clearForUser(String userId) async {
    _entries.remove(userId);
  }

  @override
  Future<CloudCosmeticsCacheEntry?> read(String userId) async {
    return _entries[userId];
  }

  @override
  Future<CloudCosmeticsCacheEntry> save(CloudCosmeticsSnapshot snapshot) async {
    final entry = CloudCosmeticsCacheEntry.fromSnapshot(snapshot);
    _entries[snapshot.userId] = entry;
    return entry;
  }
}

class _FakeCloudCosmeticsRepository implements CloudCosmeticsRepository {
  _FakeCloudCosmeticsRepository({
    required List<_FetchResponseFactory> fetchResponses,
  }) : _fetchResponses = fetchResponses;

  final List<_FetchResponseFactory> _fetchResponses;
  int _fetchIndex = 0;

  @override
  Future<RemoteShopEquipResultDto> equipAsset({
    required String itemId,
    required String slot,
    required String requestId,
  }) async {
    return RemoteShopEquipResultDto(
      requestId: requestId,
      operation: 'equip',
      itemId: itemId,
      slot: slot,
      createdAt: DateTime.utc(2026, 7, 19, 12),
    );
  }

  @override
  Future<ShopCloudReadResult<CloudCosmeticsSnapshot>> fetchSnapshot() async {
    if (_fetchIndex < _fetchResponses.length) {
      _fetchIndex += 1;
      return await _fetchResponses[_fetchIndex - 1]();
    }
    return ShopCloudReadResult<CloudCosmeticsSnapshot>.failure(
      error: const ShopCloudReadError(
        code: ShopCloudErrorCode.unknown,
        message: 'No response queued.',
      ),
    );
  }

  @override
  Future<RemoteShopPurchaseResultDto> purchaseAsset({
    required String itemId,
    required String requestId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RemoteShopBundlePurchaseResultDto> purchaseBundle({
    required String bundleId,
    required String requestId,
  }) {
    throw UnimplementedError();
  }
}

class _FakeHomeStore extends ChangeNotifier implements UserStateStore {
  _FakeHomeStore({
    this.syncHabitsFromRemoteBestEffortError,
    int walletCoins = 0,
  }) : _walletCoins = walletCoins {
    _state = <String, dynamic>{
      'userState': <String, dynamic>{
        'userId': 'home-refresh-user',
        'profile': <String, dynamic>{
          'displayName': 'Alex',
        },
        'meta': <String, dynamic>{
          'activeViewDateKey': '2026-06-22',
        },
        'progression': <String, dynamic>{
          'level': 1,
          'xp': 0,
          'prestige': 0,
        },
        'wallet': <String, dynamic>{
          'coins': _walletCoins,
        },
        'history': <String, dynamic>{
          'habitCompletions': <String, dynamic>{},
          'habitCountValues': <String, dynamic>{},
          'habitSkips': <String, dynamic>{},
        },
        'activeHabits': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'habit-1',
            'name': 'Drink Water',
            'type': 'check',
            'doneToday': false,
            'skippedToday': false,
            'archived': false,
            'createdAt': '2026-06-20T09:00:00.000Z',
            'schedule': <String, dynamic>{
              'type': 'daily',
            },
          },
        ],
      },
    };
  }

  final Object? syncHabitsFromRemoteBestEffortError;
  final int _walletCoins;
  int syncHabitsFromRemoteBestEffortCalls = 0;
  int maybeSyncHabitsFromRemoteBestEffortCalls = 0;
  bool? lastMaybeSyncIgnoreCooldown;
  late Map<String, dynamic> _state;

  @override
  bool get isLoading => false;

  @override
  Object? get error => null;

  @override
  Map<String, dynamic> get state => _state;

  @override
  String? get displayName => 'Alex';

  @override
  String? get avatarUrl => null;

  @override
  String? get userId => 'home-refresh-user';

  @override
  String? get activeLocalScopeUserId => 'home-refresh-user';

  @override
  int get pendingAchievementUnlockCount => 0;

  @override
  int get pendingLevelCelebrationCount => 0;

  @override
  Future<void> setActiveViewDate(DateTime date) async {}

  @override
  Future<void> load() async {}

  @override
  Future<void> save(Map<String, dynamic> newState) async {
    _state = newState;
  }

  @override
  Future<void> syncHabitsFromRemoteBestEffort() async {
    syncHabitsFromRemoteBestEffortCalls += 1;
    if (syncHabitsFromRemoteBestEffortError != null) {
      throw syncHabitsFromRemoteBestEffortError!;
    }
  }

  @override
  Future<void> maybeSyncHabitsFromRemoteBestEffort({
    bool ignoreCooldown = false,
  }) async {
    maybeSyncHabitsFromRemoteBestEffortCalls += 1;
    lastMaybeSyncIgnoreCooldown = ignoreCooldown;
    if (ignoreCooldown && syncHabitsFromRemoteBestEffortError != null) {
      throw syncHabitsFromRemoteBestEffortError!;
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CloudWalletSnapshot _snapshot({
  required String userId,
  required int coins,
  required int version,
  required DateTime updatedAt,
}) {
  return CloudWalletSnapshot(
    userId: userId,
    coins: coins,
    version: version,
    createdAt: updatedAt,
    updatedAt: updatedAt,
    fetchedAt: updatedAt,
  );
}

class _FakeCloudWalletRepository implements CloudWalletRepository {
  final List<WalletReadResult<CloudWalletSnapshot>> _responses =
      <WalletReadResult<CloudWalletSnapshot>>[];

  void enqueueSuccess(CloudWalletSnapshot snapshot) {
    _responses.add(
      WalletReadResult<CloudWalletSnapshot>.success(data: snapshot),
    );
  }

  @override
  Future<WalletReadResult<CloudWalletSnapshot>> fetchWallet() async {
    if (_responses.isEmpty) {
      return const WalletReadResult<CloudWalletSnapshot>.failure(
        failure: WalletFailure(
          code: WalletFailureCode.unknown,
          message: 'No response queued.',
        ),
      );
    }
    return _responses.removeAt(0);
  }
}
