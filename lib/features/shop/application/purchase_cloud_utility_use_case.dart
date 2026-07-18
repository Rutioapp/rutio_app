import 'dart:math';

import '../data/cloud/shop_cloud_config.dart';
import '../data/cloud/shop_cloud_dtos.dart';
import '../data/cloud/shop_cloud_purchase_repository.dart';
import '../data/cloud/shop_cloud_read_repository.dart';
import '../data/cloud/shop_cloud_errors.dart';
import '../domain/models/pending_shop_purchase.dart';
import '../domain/pending_shop_operation_store.dart';
import '../domain/shop_purchase_failure.dart';
import '../domain/shop_purchase_result.dart';
import '../domain/models/shop_item_enums.dart';
import '../data/shop_catalog.dart';

class PurchaseCloudUtilityUseCase {
  PurchaseCloudUtilityUseCase({
    required ShopCloudPurchaseRepository purchaseRepository,
    required PendingShopOperationStore pendingOperationStore,
    required ShopCloudReadRepository cloudReadRepository,
    required String? Function() currentUserIdProvider,
    bool? purchaseEnabled,
    bool? readEnabled,
    DateTime Function()? nowProvider,
    String Function()? requestIdGenerator,
    int maxAutoRetries = 1,
  })  : _purchaseRepository = purchaseRepository,
        _pendingOperationStore = pendingOperationStore,
        _cloudReadRepository = cloudReadRepository,
        _currentUserIdProvider = currentUserIdProvider,
        _purchaseEnabled =
            ShopCloudConfig.resolvePurchaseEnabled(override: purchaseEnabled),
        _readEnabled =
            ShopCloudConfig.resolveReadEnabled(override: readEnabled),
        _nowProvider = nowProvider ?? DateTime.now,
        _requestIdGenerator = requestIdGenerator ?? _generateUuidV4,
        _maxAutoRetries = maxAutoRetries;

  final ShopCloudPurchaseRepository _purchaseRepository;
  final PendingShopOperationStore _pendingOperationStore;
  final ShopCloudReadRepository _cloudReadRepository;
  final String? Function() _currentUserIdProvider;
  final bool _purchaseEnabled;
  final bool _readEnabled;
  final DateTime Function() _nowProvider;
  final String Function() _requestIdGenerator;
  final int _maxAutoRetries;

  static const Set<String> _supportedUtilityIds = <String>{
    'utility_xp_boost_1d',
    'utility_coin_boost_1d',
    'utility_streak_recover_1',
    'utility_streak_shield_1',
    'utility_mystery_box_basic',
  };

  Future<ShopPurchaseResult> purchaseCloudUtility({
    required String itemId,
    String? requestId,
  }) async {
    return _executePurchase(
      itemId: itemId,
      requestId: requestId,
      resolvingPending: false,
    );
  }

  Future<List<ShopPurchaseResult>> resolvePendingPurchasesForCurrentUser({
    int maxOperations = 3,
  }) async {
    if (!_purchaseEnabled) return const <ShopPurchaseResult>[];

    final userId = _currentUserId();
    if (userId == null) return const <ShopPurchaseResult>[];

    final pendingPurchases =
        await _pendingOperationStore.loadPendingPurchases(userId);
    if (pendingPurchases.isEmpty) return const <ShopPurchaseResult>[];

    final results = <ShopPurchaseResult>[];
    for (final pending in pendingPurchases.take(maxOperations)) {
      final result = await _executePurchase(
        itemId: pending.itemId,
        requestId: pending.requestId,
        resolvingPending: true,
      );
      results.add(result);
      if (!result.isSuccess && !result.isPending) {
        continue;
      }
      if (result.isPending) {
        break;
      }
    }
    return List<ShopPurchaseResult>.unmodifiable(results);
  }

  Future<ShopPurchaseResult> _executePurchase({
    required String itemId,
    String? requestId,
    required bool resolvingPending,
  }) async {
    final normalizedItemId = itemId.trim();
    final normalizedRequestId = requestId?.trim();

    if (!_purchaseEnabled) {
      return ShopPurchaseResult.failure(
        itemId: normalizedItemId,
        requestId: normalizedRequestId ?? '',
        failure: const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.featureDisabled,
          message: 'Shop cloud purchase is disabled.',
          definitive: true,
        ),
      );
    }

    if (!_supportedUtilityIds.contains(normalizedItemId)) {
      return ShopPurchaseResult.failure(
        itemId: normalizedItemId,
        requestId: normalizedRequestId ?? '',
        failure: const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.unsupportedCloudItem,
          message: 'The requested item is not supported by cloud purchase.',
          definitive: true,
        ),
      );
    }

    final item = ShopCatalog.getItemById(normalizedItemId);
    if (item == null ||
        item.category != ShopItemCategory.utility ||
        item.isEnabled == false) {
      return ShopPurchaseResult.failure(
        itemId: normalizedItemId,
        requestId: normalizedRequestId ?? '',
        failure: const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.unsupportedCloudItem,
          message: 'The requested item is not supported by cloud purchase.',
          definitive: true,
        ),
      );
    }

    final initialUserId = _currentUserId();
    if (initialUserId == null) {
      return ShopPurchaseResult.failure(
        itemId: normalizedItemId,
        requestId: normalizedRequestId ?? '',
        failure: const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.unauthenticated,
          message: 'No authenticated user session is available.',
          definitive: true,
        ),
      );
    }

    final walletResult = await _cloudReadRepository.fetchWallet();
    if (!walletResult.isSuccess) {
      final failure = _mapReadError(walletResult.error);
      return ShopPurchaseResult.failure(
        itemId: normalizedItemId,
        requestId: normalizedRequestId ?? '',
        failure: failure,
      );
    }

    final wallet = walletResult.data;
    if (wallet == null) {
      return ShopPurchaseResult.failure(
        itemId: normalizedItemId,
        requestId: normalizedRequestId ?? '',
        failure: const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.cloudWalletMissing,
          message: 'Cloud wallet row is missing.',
          definitive: true,
        ),
      );
    }

    final activeCatalogResult =
        _readEnabled ? await _cloudReadRepository.fetchActiveCatalog() : null;
    if (activeCatalogResult != null && !activeCatalogResult.isSuccess) {
      final failure = _mapReadError(activeCatalogResult.error);
      return ShopPurchaseResult.failure(
        itemId: normalizedItemId,
        requestId: normalizedRequestId ?? '',
        failure: failure,
      );
    }

    final remoteItem = _findRemoteItem(
      activeCatalogResult?.data ?? const <RemoteShopItemDto>[],
      normalizedItemId,
    );
    if (remoteItem == null || !remoteItem.isActive) {
      return ShopPurchaseResult.failure(
        itemId: normalizedItemId,
        requestId: normalizedRequestId ?? '',
        failure: const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.itemNotFoundOrInactive,
          message: 'Shop item not found or inactive.',
          definitive: true,
        ),
      );
    }

    final pendingPurchases =
        await _pendingOperationStore.loadPendingPurchases(initialUserId);
    final matchingByItem = pendingPurchases
        .where((purchase) => purchase.itemId == normalizedItemId)
        .toList(growable: false);
    final matchingByRequest = normalizedRequestId == null
        ? const <PendingShopPurchase>[]
        : pendingPurchases
            .where((purchase) => purchase.requestId == normalizedRequestId)
            .toList(growable: false);
    PendingShopPurchase? existingPending;

    if (!resolvingPending && pendingPurchases.isNotEmpty) {
      if (matchingByRequest.isNotEmpty &&
          matchingByRequest.first.itemId != normalizedItemId) {
        return ShopPurchaseResult.failure(
          itemId: normalizedItemId,
          requestId: normalizedRequestId ?? '',
          failure: const ShopPurchaseFailure(
            code: ShopPurchaseFailureCode.requestIdConflict,
            message: 'request_id is already bound to another item.',
            definitive: true,
          ),
        );
      }

      if (matchingByItem.isNotEmpty) {
        final pending = matchingByItem.first;
        if (normalizedRequestId != null &&
            normalizedRequestId != pending.requestId) {
          return ShopPurchaseResult.failure(
            itemId: normalizedItemId,
            requestId: normalizedRequestId,
            failure: const ShopPurchaseFailure(
              code: ShopPurchaseFailureCode.requestIdConflict,
              message: 'A different request_id is already pending for item.',
              definitive: true,
            ),
          );
        }
        existingPending = pending;
      } else {
        return ShopPurchaseResult.failure(
          itemId: normalizedItemId,
          requestId: normalizedRequestId ?? '',
          failure: const ShopPurchaseFailure(
            code: ShopPurchaseFailureCode.operationPending,
            message: 'Another shop purchase is already pending.',
            definitive: true,
          ),
        );
      }
    } else if (matchingByRequest.isNotEmpty &&
        matchingByRequest.first.itemId != normalizedItemId) {
      return ShopPurchaseResult.failure(
        itemId: normalizedItemId,
        requestId: normalizedRequestId ?? '',
        failure: const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.requestIdConflict,
          message: 'request_id is already bound to another item.',
          definitive: true,
        ),
      );
    } else if (matchingByItem.isNotEmpty && normalizedRequestId == null) {
      existingPending = matchingByItem.first;
    }

    final now = _nowProvider().toUtc().millisecondsSinceEpoch;
    final effectiveRequestId = existingPending?.requestId ??
        (normalizedRequestId?.isNotEmpty == true
            ? normalizedRequestId!
            : _requestIdGenerator());
    final baseAttemptCount = existingPending?.attemptCount ?? 0;
    final purchase = existingPending?.copyWith(
          lastAttemptAtMillis: now,
          attemptCount: baseAttemptCount,
          status: PendingShopPurchaseStatus.pending,
        ) ??
        PendingShopPurchase(
          userId: initialUserId,
          requestId: effectiveRequestId,
          itemId: normalizedItemId,
          createdAtMillis: now,
          lastAttemptAtMillis: now,
          attemptCount: 0,
          status: PendingShopPurchaseStatus.pending,
        );
    await _upsertPending(purchase);

    final maxAttempts = 1 + _maxAutoRetries;
    ShopCloudPurchaseException? lastFailure;
    for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
      final attemptPurchase = purchase.copyWith(
        lastAttemptAtMillis: _nowProvider().toUtc().millisecondsSinceEpoch,
        attemptCount: baseAttemptCount + attempt,
        status: attempt == 1
            ? PendingShopPurchaseStatus.pending
            : PendingShopPurchaseStatus.awaitingResolution,
      );
      await _upsertPending(attemptPurchase);

      try {
        final remoteResult = await _purchaseRepository.purchaseShopItem(
          itemId: normalizedItemId,
          requestId: effectiveRequestId,
        );

        final currentUserId = _currentUserId();
        if (currentUserId == null || currentUserId != initialUserId) {
          final awaiting = attemptPurchase.copyWith(
            status: PendingShopPurchaseStatus.awaitingResolution,
            lastAttemptAtMillis: _nowProvider().toUtc().millisecondsSinceEpoch,
          );
          await _upsertPending(awaiting);
          return ShopPurchaseResult.pendingResolution(
            itemId: normalizedItemId,
            requestId: effectiveRequestId,
            failure: const ShopPurchaseFailure(
              code: ShopPurchaseFailureCode.sessionChanged,
              message: 'Authentication session changed during purchase.',
            ),
            pendingOperation: awaiting,
          );
        }

        await _removePending(initialUserId, effectiveRequestId);
        return ShopPurchaseResult.success(
          itemId: normalizedItemId,
          requestId: effectiveRequestId,
          remoteResult: remoteResult,
        );
      } on ShopCloudPurchaseException catch (error) {
        lastFailure = error;
        if (error.retryable && attempt < maxAttempts) {
          continue;
        }

        if (error.keepPending) {
          final awaiting = attemptPurchase.copyWith(
            status: PendingShopPurchaseStatus.awaitingResolution,
            lastAttemptAtMillis: _nowProvider().toUtc().millisecondsSinceEpoch,
          );
          await _upsertPending(awaiting);
          return ShopPurchaseResult.pendingResolution(
            itemId: normalizedItemId,
            requestId: effectiveRequestId,
            failure: _mapFailure(error),
            pendingOperation: awaiting,
          );
        }

        await _removePending(initialUserId, effectiveRequestId);
        return ShopPurchaseResult.failure(
          itemId: normalizedItemId,
          requestId: effectiveRequestId,
          failure: _mapFailure(error),
        );
      }
    }

    final awaiting = purchase.copyWith(
      status: PendingShopPurchaseStatus.awaitingResolution,
      lastAttemptAtMillis: _nowProvider().toUtc().millisecondsSinceEpoch,
      attemptCount: maxAttempts,
    );
    await _upsertPending(awaiting);
    return ShopPurchaseResult.pendingResolution(
      itemId: normalizedItemId,
      requestId: effectiveRequestId,
      failure: _mapFailure(lastFailure),
      pendingOperation: awaiting,
    );
  }

  RemoteShopItemDto? _findRemoteItem(
    List<RemoteShopItemDto> items,
    String itemId,
  ) {
    for (final item in items) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  Future<void> _upsertPending(PendingShopPurchase purchase) async {
    final userId = purchase.userId.trim();
    if (userId.isEmpty) return;
    final pendingPurchases =
        await _pendingOperationStore.loadPendingPurchases(userId);
    final next = <PendingShopPurchase>[
      for (final existing in pendingPurchases)
        if (existing.requestId != purchase.requestId) existing,
      purchase,
    ]..sort((a, b) {
        final byCreated = a.createdAtMillis.compareTo(b.createdAtMillis);
        if (byCreated != 0) return byCreated;
        return a.requestId.compareTo(b.requestId);
      });
    await _pendingOperationStore.savePendingPurchases(userId, next);
  }

  Future<void> _removePending(String userId, String requestId) async {
    final pendingPurchases =
        await _pendingOperationStore.loadPendingPurchases(userId);
    final next = pendingPurchases
        .where((purchase) => purchase.requestId != requestId)
        .toList(growable: false);
    await _pendingOperationStore.savePendingPurchases(userId, next);
  }

  String? _currentUserId() {
    final current = _currentUserIdProvider();
    final normalized = current?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  ShopPurchaseFailure _mapReadError(ShopCloudReadError? error) {
    final code = error?.code;
    switch (code) {
      case ShopCloudErrorCode.unauthenticated:
        return const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.unauthenticated,
          message: 'No authenticated user session is available.',
          definitive: true,
        );
      case ShopCloudErrorCode.sessionChanged:
        return const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.sessionChanged,
          message: 'Authentication session changed during shop purchase.',
        );
      case ShopCloudErrorCode.networkUnavailable:
        return const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.networkUnavailable,
          message: 'Network unavailable while purchasing shop item.',
          retryable: true,
        );
      case ShopCloudErrorCode.timeout:
        return const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.timeout,
          message: 'Shop purchase timed out.',
          retryable: true,
        );
      case ShopCloudErrorCode.malformedResponse:
        return const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.malformedResponse,
          message: 'The shop response was malformed.',
        );
      case ShopCloudErrorCode.walletMissing:
        return const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.cloudWalletMissing,
          message: 'Cloud wallet row is missing.',
          definitive: true,
        );
      case ShopCloudErrorCode.featureDisabled:
        return const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.featureDisabled,
          message: 'Shop cloud read is disabled.',
          definitive: true,
        );
      case null:
      case ShopCloudErrorCode.invalidRemoteItem:
      case ShopCloudErrorCode.unknown:
        return const ShopPurchaseFailure(
          code: ShopPurchaseFailureCode.unknown,
          message: 'Unexpected shop cloud read error.',
        );
    }
  }

  ShopPurchaseFailure _mapFailure(ShopCloudPurchaseException? error) {
    if (error == null) {
      return const ShopPurchaseFailure(
        code: ShopPurchaseFailureCode.unknown,
        message: 'Unexpected shop purchase error.',
      );
    }
    return ShopPurchaseFailure(
      code: error.code,
      message: error.message,
      cause: error.cause,
      retryable: error.retryable,
      definitive: error.definitive,
    );
  }

  static String _generateUuidV4() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final parts = <String>[
      _hex(bytes.sublist(0, 4)),
      _hex(bytes.sublist(4, 6)),
      _hex(bytes.sublist(6, 8)),
      _hex(bytes.sublist(8, 10)),
      _hex(bytes.sublist(10, 16)),
    ];
    return parts.join('-');
  }

  static String _hex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
