import 'package:flutter/foundation.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';
import '../shop_assets_catalog.dart';
import '../../data/shop_catalog.dart';
import 'shop_cloud_config.dart';
import 'shop_cloud_dtos.dart';
import 'shop_cloud_errors.dart';
import 'shop_cloud_reconciliation.dart';
import 'shop_cloud_remote_data_sources.dart';
import 'shop_cloud_snapshot.dart';

class ShopCloudReadRepository {
  ShopCloudReadRepository({
    ShopCatalogRemoteDataSource? catalogRemoteDataSource,
    ShopUserStateRemoteDataSource? userStateRemoteDataSource,
    bool? readEnabled,
    String? Function()? currentUserIdProvider,
    DateTime Function()? nowProvider,
  })  : _catalogRemoteDataSource =
            catalogRemoteDataSource ?? SupabaseShopCatalogRemoteDataSource(),
        _userStateRemoteDataSource = userStateRemoteDataSource ??
            SupabaseShopUserStateRemoteDataSource(),
        _readEnabled =
            ShopCloudConfig.resolveReadEnabled(override: readEnabled),
        _currentUserIdProvider =
            currentUserIdProvider ?? _defaultCurrentUserIdProvider,
        _nowProvider = nowProvider ?? DateTime.now;

  final ShopCatalogRemoteDataSource _catalogRemoteDataSource;
  final ShopUserStateRemoteDataSource _userStateRemoteDataSource;
  final bool _readEnabled;
  final String? Function() _currentUserIdProvider;
  final DateTime Function() _nowProvider;
  final Map<String, ShopCloudSnapshot> _snapshotCacheByUserId =
      <String, ShopCloudSnapshot>{};
  Map<String, List<RemoteShopBundleItemDto>> _lastValidBundleItemsByBundleId =
      <String, List<RemoteShopBundleItemDto>>{};
  String? _lastObservedUserId;

  static String? _defaultCurrentUserIdProvider() {
    try {
      return RutioSupabaseClient.instance.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  Future<ShopCloudReadResult<List<RemoteShopItemDto>>>
      fetchActiveCatalog() async {
    if (!_readEnabled) {
      return const ShopCloudReadResult<List<RemoteShopItemDto>>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.featureDisabled,
          message: 'Shop cloud read is disabled.',
        ),
      );
    }

    final userId = _requireAuthenticatedUserId();
    if (userId == null) {
      return const ShopCloudReadResult<List<RemoteShopItemDto>>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.unauthenticated,
          message: 'No authenticated user session is available.',
        ),
      );
    }

    try {
      final rows = await _catalogRemoteDataSource.fetchActiveCatalogRows();
      if (!_isCurrentSession(userId)) {
        return const ShopCloudReadResult<List<RemoteShopItemDto>>.failure(
          error: ShopCloudReadError(
            code: ShopCloudErrorCode.sessionChanged,
            message: 'Authentication session changed during shop fetch.',
          ),
        );
      }

      final parsed = <RemoteShopItemDto>[];
      final warnings = <ShopCloudWarning>[];
      for (final row in rows) {
        final dto = _parseCatalogRow(row);
        if (dto == null) {
          warnings.add(
            const ShopCloudWarning(
              code: ShopCloudWarningCode.invalidRemoteItem,
              message: 'Remote shop item row could not be parsed.',
            ),
          );
          continue;
        }
        parsed.add(dto);
        _collectCatalogWarnings(dto, warnings);
      }

      final reconciliation = ShopCloudCatalogReconciler.reconcile(
        remoteItems: parsed,
        localItems: ShopCatalog.allItems,
      );
      warnings.addAll(reconciliation.warnings);

      return ShopCloudReadResult<List<RemoteShopItemDto>>.success(
        data: List<RemoteShopItemDto>.unmodifiable(parsed),
        warnings: List<ShopCloudWarning>.unmodifiable(warnings),
      );
    } on ShopCloudReadException catch (error) {
      return ShopCloudReadResult<List<RemoteShopItemDto>>.failure(
        error: ShopCloudReadError(
          code: error.code,
          message: error.message,
          cause: error.cause,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[shop_cloud_read] unexpected catalog read error: $error');
      }
      return ShopCloudReadResult<List<RemoteShopItemDto>>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.unknown,
          message: 'Could not fetch shop catalog.',
          cause: error,
        ),
      );
    }
  }

  Future<ShopCloudReadResult<List<RemoteShopBundleDto>>>
      fetchActiveBundleCatalog() async {
    if (!_readEnabled) {
      return const ShopCloudReadResult<List<RemoteShopBundleDto>>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.featureDisabled,
          message: 'Shop cloud read is disabled.',
        ),
      );
    }

    final userId = _requireAuthenticatedUserId();
    if (userId == null) {
      return const ShopCloudReadResult<List<RemoteShopBundleDto>>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.unauthenticated,
          message: 'No authenticated user session is available.',
        ),
      );
    }

    try {
      final bundleRows = await _catalogRemoteDataSource.fetchActiveBundleRows();
      if (!_isCurrentSession(userId)) {
        return const ShopCloudReadResult<List<RemoteShopBundleDto>>.failure(
          error: ShopCloudReadError(
            code: ShopCloudErrorCode.sessionChanged,
            message: 'Authentication session changed during shop fetch.',
          ),
        );
      }

      final bundleItemRows =
          await _catalogRemoteDataSource.fetchBundleItemRows();
      if (!_isCurrentSession(userId)) {
        return const ShopCloudReadResult<List<RemoteShopBundleDto>>.failure(
          error: ShopCloudReadError(
            code: ShopCloudErrorCode.sessionChanged,
            message: 'Authentication session changed during shop fetch.',
          ),
        );
      }

      final parsedBundles = <RemoteShopBundleDto>[];
      final warnings = <ShopCloudWarning>[];
      for (final row in bundleRows) {
        final dto = _parseBundleRow(row);
        if (dto == null) {
          warnings.add(
            ShopCloudWarning(
              code: ShopCloudWarningCode.invalidRemoteItem,
              itemId: _trim(row['id']),
              message: _bundleHasUnknownRarity(row)
                  ? 'Remote bundle has an unknown rarity.'
                  : 'Remote shop bundle row could not be parsed.',
            ),
          );
          continue;
        }
        parsedBundles.add(dto);
      }

      final bundleItemsByBundleId = <String, List<RemoteShopBundleItemDto>>{};
      for (final row in bundleItemRows) {
        final dto = _parseBundleItemRow(row);
        if (dto == null) {
          warnings.add(
            ShopCloudWarning(
              code: ShopCloudWarningCode.invalidRemoteItem,
              itemId: _trim(row['bundleId'] ?? row['bundle_id']),
              message: 'Remote shop bundle item row could not be parsed.',
            ),
          );
          continue;
        }
        bundleItemsByBundleId
            .putIfAbsent(dto.bundleId, () => <RemoteShopBundleItemDto>[])
            .add(dto);
      }

      final validBundles = <RemoteShopBundleDto>[];
      final validBundleItemsByBundleId =
          <String, List<RemoteShopBundleItemDto>>{};
      for (final bundle in parsedBundles) {
        final composition = bundleItemsByBundleId[bundle.id] ?? const [];
        final resolvedComposition = _resolveBundleComposition(
          bundleId: bundle.id,
          items: composition,
          warnings: warnings,
        );
        if (resolvedComposition == null) {
          continue;
        }
        validBundles.add(bundle);
        validBundleItemsByBundleId[bundle.id] = resolvedComposition;
      }

      final reconciliation = ShopCloudBundleCatalogReconciler.reconcile(
        remoteBundles: validBundles,
        remoteCompositionByBundleId: validBundleItemsByBundleId,
        localBundles: ShopAssetsCatalog.allBundles,
      );
      warnings.addAll(reconciliation.warnings);
      _lastValidBundleItemsByBundleId =
          Map<String, List<RemoteShopBundleItemDto>>.unmodifiable(
        {
          for (final entry in validBundleItemsByBundleId.entries)
            entry.key: List<RemoteShopBundleItemDto>.unmodifiable(entry.value),
        },
      );

      return ShopCloudReadResult<List<RemoteShopBundleDto>>.success(
        data: List<RemoteShopBundleDto>.unmodifiable(validBundles),
        warnings: List<ShopCloudWarning>.unmodifiable(warnings),
      );
    } on ShopCloudReadException catch (error) {
      return ShopCloudReadResult<List<RemoteShopBundleDto>>.failure(
        error: ShopCloudReadError(
          code: error.code,
          message: error.message,
          cause: error.cause,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
            '[shop_cloud_read] unexpected bundle catalog read error: $error');
      }
      return ShopCloudReadResult<List<RemoteShopBundleDto>>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.unknown,
          message: 'Could not fetch shop bundle catalog.',
          cause: error,
        ),
      );
    }
  }

  Future<ShopCloudReadResult<RemoteWalletDto?>> fetchWallet() async {
    if (!_readEnabled) {
      return const ShopCloudReadResult<RemoteWalletDto?>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.featureDisabled,
          message: 'Shop cloud read is disabled.',
        ),
      );
    }

    final userId = _requireAuthenticatedUserId();
    if (userId == null) {
      return const ShopCloudReadResult<RemoteWalletDto?>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.unauthenticated,
          message: 'No authenticated user session is available.',
        ),
      );
    }

    try {
      final row = await _userStateRemoteDataSource.fetchWalletRow();
      if (!_isCurrentSession(userId)) {
        return const ShopCloudReadResult<RemoteWalletDto?>.failure(
          error: ShopCloudReadError(
            code: ShopCloudErrorCode.sessionChanged,
            message: 'Authentication session changed during shop fetch.',
          ),
        );
      }

      if (row == null) {
        return const ShopCloudReadResult<RemoteWalletDto?>.failure(
          error: ShopCloudReadError(
            code: ShopCloudErrorCode.walletMissing,
            message: 'Wallet row is missing for the authenticated user.',
          ),
        );
      }

      final wallet = _parseWallet(row, expectedUserId: userId);
      if (wallet == null) {
        return const ShopCloudReadResult<RemoteWalletDto?>.failure(
          error: ShopCloudReadError(
            code: ShopCloudErrorCode.malformedResponse,
            message: 'Wallet row could not be parsed.',
          ),
        );
      }

      return ShopCloudReadResult<RemoteWalletDto?>.success(data: wallet);
    } on ShopCloudReadException catch (error) {
      return ShopCloudReadResult<RemoteWalletDto?>.failure(
        error: ShopCloudReadError(
          code: error.code,
          message: error.message,
          cause: error.cause,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[shop_cloud_read] unexpected wallet read error: $error');
      }
      return ShopCloudReadResult<RemoteWalletDto?>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.unknown,
          message: 'Could not fetch shop wallet.',
          cause: error,
        ),
      );
    }
  }

  Future<ShopCloudReadResult<List<RemoteInventoryItemDto>>>
      fetchInventory() async {
    if (!_readEnabled) {
      return const ShopCloudReadResult<List<RemoteInventoryItemDto>>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.featureDisabled,
          message: 'Shop cloud read is disabled.',
        ),
      );
    }

    final userId = _requireAuthenticatedUserId();
    if (userId == null) {
      return const ShopCloudReadResult<List<RemoteInventoryItemDto>>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.unauthenticated,
          message: 'No authenticated user session is available.',
        ),
      );
    }

    try {
      final rows = await _userStateRemoteDataSource.fetchInventoryRows();
      if (!_isCurrentSession(userId)) {
        return const ShopCloudReadResult<List<RemoteInventoryItemDto>>.failure(
          error: ShopCloudReadError(
            code: ShopCloudErrorCode.sessionChanged,
            message: 'Authentication session changed during shop fetch.',
          ),
        );
      }

      final parsed = <RemoteInventoryItemDto>[];
      final warnings = <ShopCloudWarning>[];
      for (final row in rows) {
        final dto = _parseInventoryRow(row, expectedUserId: userId);
        if (dto == null) {
          warnings.add(
            const ShopCloudWarning(
              code: ShopCloudWarningCode.invalidRemoteItem,
              message: 'Remote inventory row could not be parsed.',
            ),
          );
          continue;
        }
        parsed.add(dto);
      }

      return ShopCloudReadResult<List<RemoteInventoryItemDto>>.success(
        data: List<RemoteInventoryItemDto>.unmodifiable(parsed),
        warnings: List<ShopCloudWarning>.unmodifiable(warnings),
      );
    } on ShopCloudReadException catch (error) {
      return ShopCloudReadResult<List<RemoteInventoryItemDto>>.failure(
        error: ShopCloudReadError(
          code: error.code,
          message: error.message,
          cause: error.cause,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[shop_cloud_read] unexpected inventory read error: $error');
      }
      return ShopCloudReadResult<List<RemoteInventoryItemDto>>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.unknown,
          message: 'Could not fetch shop inventory.',
          cause: error,
        ),
      );
    }
  }

  Future<ShopCloudReadResult<List<RemoteEquippedCosmeticDto>>>
      fetchEquippedCosmetics() async {
    if (!_readEnabled) {
      return const ShopCloudReadResult<List<RemoteEquippedCosmeticDto>>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.featureDisabled,
          message: 'Shop cloud read is disabled.',
        ),
      );
    }

    final userId = _requireAuthenticatedUserId();
    if (userId == null) {
      return const ShopCloudReadResult<List<RemoteEquippedCosmeticDto>>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.unauthenticated,
          message: 'No authenticated user session is available.',
        ),
      );
    }

    try {
      final rows =
          await _userStateRemoteDataSource.fetchEquippedCosmeticsRows();
      if (!_isCurrentSession(userId)) {
        return const ShopCloudReadResult<
            List<RemoteEquippedCosmeticDto>>.failure(
          error: ShopCloudReadError(
            code: ShopCloudErrorCode.sessionChanged,
            message: 'Authentication session changed during shop fetch.',
          ),
        );
      }

      final parsed = <RemoteEquippedCosmeticDto>[];
      final warnings = <ShopCloudWarning>[];
      for (final row in rows) {
        final dto = _parseEquippedCosmeticRow(row, expectedUserId: userId);
        if (dto == null) {
          warnings.add(
            const ShopCloudWarning(
              code: ShopCloudWarningCode.invalidRemoteItem,
              message: 'Remote equipped cosmetic row could not be parsed.',
            ),
          );
          continue;
        }
        parsed.add(dto);
      }

      return ShopCloudReadResult<List<RemoteEquippedCosmeticDto>>.success(
        data: List<RemoteEquippedCosmeticDto>.unmodifiable(parsed),
        warnings: List<ShopCloudWarning>.unmodifiable(warnings),
      );
    } on ShopCloudReadException catch (error) {
      return ShopCloudReadResult<List<RemoteEquippedCosmeticDto>>.failure(
        error: ShopCloudReadError(
          code: error.code,
          message: error.message,
          cause: error.cause,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[shop_cloud_read] unexpected equipped cosmetics read error: $error',
        );
      }
      return ShopCloudReadResult<List<RemoteEquippedCosmeticDto>>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.unknown,
          message: 'Could not fetch equipped cosmetics.',
          cause: error,
        ),
      );
    }
  }

  Future<ShopCloudReadResult<List<RemoteOwnedBundleDto>>>
      fetchOwnedBundles() async {
    if (!_readEnabled) {
      return const ShopCloudReadResult<List<RemoteOwnedBundleDto>>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.featureDisabled,
          message: 'Shop cloud read is disabled.',
        ),
      );
    }

    final userId = _requireAuthenticatedUserId();
    if (userId == null) {
      return const ShopCloudReadResult<List<RemoteOwnedBundleDto>>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.unauthenticated,
          message: 'No authenticated user session is available.',
        ),
      );
    }

    try {
      final rows = await _userStateRemoteDataSource.fetchOwnedBundleRows();
      if (!_isCurrentSession(userId)) {
        return const ShopCloudReadResult<List<RemoteOwnedBundleDto>>.failure(
          error: ShopCloudReadError(
            code: ShopCloudErrorCode.sessionChanged,
            message: 'Authentication session changed during shop fetch.',
          ),
        );
      }

      final parsed = <RemoteOwnedBundleDto>[];
      final warnings = <ShopCloudWarning>[];
      for (final row in rows) {
        final dto = _parseOwnedBundleRow(row, expectedUserId: userId);
        if (dto == null) {
          warnings.add(
            const ShopCloudWarning(
              code: ShopCloudWarningCode.invalidRemoteItem,
              message: 'Remote owned bundle row could not be parsed.',
            ),
          );
          continue;
        }
        parsed.add(dto);
      }

      return ShopCloudReadResult<List<RemoteOwnedBundleDto>>.success(
        data: List<RemoteOwnedBundleDto>.unmodifiable(parsed),
        warnings: List<ShopCloudWarning>.unmodifiable(warnings),
      );
    } on ShopCloudReadException catch (error) {
      return ShopCloudReadResult<List<RemoteOwnedBundleDto>>.failure(
        error: ShopCloudReadError(
          code: error.code,
          message: error.message,
          cause: error.cause,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
            '[shop_cloud_read] unexpected owned bundle read error: $error');
      }
      return ShopCloudReadResult<List<RemoteOwnedBundleDto>>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.unknown,
          message: 'Could not fetch owned bundles.',
          cause: error,
        ),
      );
    }
  }

  Future<ShopCloudReadResult<ShopCloudSnapshot>> fetchShopSnapshot() async {
    if (!_readEnabled) {
      return const ShopCloudReadResult<ShopCloudSnapshot>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.featureDisabled,
          message: 'Shop cloud read is disabled.',
        ),
      );
    }

    final userId = _requireAuthenticatedUserId();
    if (userId == null) {
      return const ShopCloudReadResult<ShopCloudSnapshot>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.unauthenticated,
          message: 'No authenticated user session is available.',
        ),
      );
    }

    final warnings = <ShopCloudWarning>[];

    try {
      final catalogResult = await fetchActiveCatalog();
      if (!catalogResult.isSuccess) {
        return ShopCloudReadResult<ShopCloudSnapshot>.failure(
          error: catalogResult.error!,
          warnings: catalogResult.warnings,
        );
      }
      warnings.addAll(catalogResult.warnings);

      final bundleCatalogResult = await fetchActiveBundleCatalog();
      if (!bundleCatalogResult.isSuccess) {
        return ShopCloudReadResult<ShopCloudSnapshot>.failure(
          error: bundleCatalogResult.error!,
          warnings: bundleCatalogResult.warnings,
        );
      }
      warnings.addAll(bundleCatalogResult.warnings);

      final walletResult = await fetchWallet();
      warnings.addAll(walletResult.warnings);
      final wallet = walletResult.data;
      if (!walletResult.isSuccess &&
          walletResult.error?.code != ShopCloudErrorCode.walletMissing) {
        return ShopCloudReadResult<ShopCloudSnapshot>.failure(
          error: walletResult.error!,
          warnings: List<ShopCloudWarning>.unmodifiable(warnings),
        );
      }
      if (walletResult.error?.code == ShopCloudErrorCode.walletMissing) {
        warnings.add(
          const ShopCloudWarning(
            code: ShopCloudWarningCode.walletMissing,
            message: 'Wallet row is missing for the authenticated user.',
          ),
        );
      }

      final inventoryResult = await fetchInventory();
      if (!inventoryResult.isSuccess) {
        return ShopCloudReadResult<ShopCloudSnapshot>.failure(
          error: inventoryResult.error!,
          warnings: inventoryResult.warnings,
        );
      }
      warnings.addAll(inventoryResult.warnings);

      final equippedResult = await fetchEquippedCosmetics();
      if (!equippedResult.isSuccess) {
        return ShopCloudReadResult<ShopCloudSnapshot>.failure(
          error: equippedResult.error!,
          warnings: equippedResult.warnings,
        );
      }
      warnings.addAll(equippedResult.warnings);

      final ownedBundlesResult = await fetchOwnedBundles();
      if (!ownedBundlesResult.isSuccess) {
        return ShopCloudReadResult<ShopCloudSnapshot>.failure(
          error: ownedBundlesResult.error!,
          warnings: ownedBundlesResult.warnings,
        );
      }
      warnings.addAll(ownedBundlesResult.warnings);

      final catalogItems = catalogResult.data ?? const <RemoteShopItemDto>[];
      final catalogBundles =
          bundleCatalogResult.data ?? const <RemoteShopBundleDto>[];
      final catalogBundleItems = _lastValidBundleItemsByBundleId.values
          .expand((items) => items)
          .toList(
            growable: false,
          );
      final snapshotWarnings = List<ShopCloudWarning>.unmodifiable(warnings);
      final snapshot = ShopCloudSnapshot(
        authenticatedUserId: userId,
        catalogItems: catalogItems,
        catalogBundles: catalogBundles,
        catalogBundleItems: catalogBundleItems,
        wallet: wallet,
        inventory: inventoryResult.data ?? const <RemoteInventoryItemDto>[],
        equippedCosmetics:
            equippedResult.data ?? const <RemoteEquippedCosmeticDto>[],
        ownedBundles: ownedBundlesResult.data ?? const <RemoteOwnedBundleDto>[],
        fetchedAt: _nowProvider().toUtc(),
        catalogVersion: _resolveCatalogVersion(catalogItems, catalogBundles),
        warnings: snapshotWarnings,
      );

      _snapshotCacheByUserId[userId] = snapshot;
      return ShopCloudReadResult<ShopCloudSnapshot>.success(
        data: snapshot,
        warnings: snapshotWarnings,
      );
    } on ShopCloudReadException catch (error) {
      return ShopCloudReadResult<ShopCloudSnapshot>.failure(
        error: ShopCloudReadError(
          code: error.code,
          message: error.message,
          cause: error.cause,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[shop_cloud_read] unexpected snapshot read error: $error');
      }
      return ShopCloudReadResult<ShopCloudSnapshot>.failure(
        error: ShopCloudReadError(
          code: ShopCloudErrorCode.unknown,
          message: 'Could not fetch shop snapshot.',
          cause: error,
        ),
      );
    }
  }

  void clearCache() {
    _snapshotCacheByUserId.clear();
  }

  ShopCloudSnapshot? cachedSnapshotForCurrentUser() {
    final userId = _requireAuthenticatedUserId();
    if (userId == null) return null;
    return _snapshotCacheByUserId[userId];
  }

  String? _requireAuthenticatedUserId() {
    String current;
    try {
      current = _currentUserIdProvider()?.trim() ?? '';
    } catch (_) {
      clearCache();
      _lastObservedUserId = null;
      return null;
    }
    if (current.isEmpty) {
      clearCache();
      _lastObservedUserId = null;
      return null;
    }
    if (_lastObservedUserId != current) {
      clearCache();
      _lastObservedUserId = current;
    }
    return current;
  }

  bool _isCurrentSession(String userId) {
    final current = _requireAuthenticatedUserId();
    if (current == null) return false;
    return current == userId;
  }

  RemoteShopItemDto? _parseCatalogRow(Map<String, dynamic> row) {
    try {
      return RemoteShopItemDto.fromJson(row);
    } on FormatException catch (error) {
      if (kDebugMode) {
        debugPrint('[shop_cloud_read] catalog row rejected: ${error.message}');
      }
      return null;
    }
  }

  void _collectCatalogWarnings(
    RemoteShopItemDto dto,
    List<ShopCloudWarning> warnings,
  ) {
    if (dto.hasUnknownCategory) {
      warnings.add(
        ShopCloudWarning(
          code: ShopCloudWarningCode.invalidRemoteItem,
          itemId: dto.id,
          message: 'Remote shop item has an unknown category.',
        ),
      );
    }
    if (dto.isCosmetic && (dto.rarity == null || dto.hasUnknownRarity)) {
      warnings.add(
        ShopCloudWarning(
          code: ShopCloudWarningCode.invalidRemoteItem,
          itemId: dto.id,
          message: 'Remote cosmetic item is missing a valid rarity.',
        ),
      );
    }
    if (dto.isCosmetic && dto.equipSlot == null) {
      warnings.add(
        ShopCloudWarning(
          code: ShopCloudWarningCode.invalidRemoteItem,
          itemId: dto.id,
          message: 'Remote cosmetic item is missing equip slot.',
        ),
      );
    }
    if (dto.assetKey == null || dto.assetKey!.isEmpty) {
      warnings.add(
        ShopCloudWarning(
          code: ShopCloudWarningCode.invalidRemoteItem,
          itemId: dto.id,
          message: 'Remote shop item is missing an asset key.',
        ),
      );
    }
  }

  RemoteWalletDto? _parseWallet(
    Map<String, dynamic> row, {
    required String expectedUserId,
  }) {
    try {
      return RemoteWalletDto.fromJson(row, expectedUserId: expectedUserId);
    } on FormatException catch (error) {
      if (kDebugMode) {
        debugPrint('[shop_cloud_read] wallet row rejected: ${error.message}');
      }
      return null;
    }
  }

  RemoteInventoryItemDto? _parseInventoryRow(
    Map<String, dynamic> row, {
    required String expectedUserId,
  }) {
    try {
      return RemoteInventoryItemDto.fromJson(
        row,
        expectedUserId: expectedUserId,
      );
    } on FormatException catch (error) {
      if (kDebugMode) {
        debugPrint(
            '[shop_cloud_read] inventory row rejected: ${error.message}');
      }
      return null;
    }
  }

  RemoteEquippedCosmeticDto? _parseEquippedCosmeticRow(
    Map<String, dynamic> row, {
    required String expectedUserId,
  }) {
    try {
      return RemoteEquippedCosmeticDto.fromJson(
        row,
        expectedUserId: expectedUserId,
      );
    } on FormatException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[shop_cloud_read] equipped cosmetic row rejected: ${error.message}',
        );
      }
      return null;
    }
  }

  RemoteOwnedBundleDto? _parseOwnedBundleRow(
    Map<String, dynamic> row, {
    required String expectedUserId,
  }) {
    try {
      return RemoteOwnedBundleDto.fromJson(
        row,
        expectedUserId: expectedUserId,
      );
    } on FormatException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[shop_cloud_read] owned bundle row rejected: ${error.message}',
        );
      }
      return null;
    }
  }

  RemoteShopBundleDto? _parseBundleRow(Map<String, dynamic> row) {
    try {
      return RemoteShopBundleDto.fromJson(row);
    } on FormatException catch (error) {
      if (kDebugMode) {
        debugPrint('[shop_cloud_read] bundle row rejected: ${error.message}');
      }
      return null;
    }
  }

  RemoteShopBundleItemDto? _parseBundleItemRow(Map<String, dynamic> row) {
    try {
      return RemoteShopBundleItemDto.fromJson(row);
    } on FormatException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[shop_cloud_read] bundle item row rejected: ${error.message}',
        );
      }
      return null;
    }
  }

  List<RemoteShopBundleItemDto>? _resolveBundleComposition({
    required String bundleId,
    required List<RemoteShopBundleItemDto> items,
    required List<ShopCloudWarning> warnings,
  }) {
    final bySlot = <RemoteShopEquipSlot, RemoteShopBundleItemDto>{};
    for (final item in items) {
      if (bySlot.containsKey(item.slot)) {
        warnings.add(
          ShopCloudWarning(
            code: ShopCloudWarningCode.invalidRemoteItem,
            itemId: bundleId,
            message: 'Remote bundle composition has duplicate slots.',
          ),
        );
        return null;
      }
      bySlot[item.slot] = item;
    }

    const requiredSlots = <RemoteShopEquipSlot>[
      RemoteShopEquipSlot.screenBackground,
      RemoteShopEquipSlot.habitCardBackground,
      RemoteShopEquipSlot.userCardBackground,
    ];
    if (requiredSlots.any((slot) => !bySlot.containsKey(slot)) ||
        bySlot.length != requiredSlots.length) {
      warnings.add(
        ShopCloudWarning(
          code: ShopCloudWarningCode.invalidRemoteItem,
          itemId: bundleId,
          message: 'Remote bundle composition is incomplete.',
        ),
      );
      return null;
    }

    return <RemoteShopBundleItemDto>[
      bySlot[RemoteShopEquipSlot.screenBackground]!,
      bySlot[RemoteShopEquipSlot.habitCardBackground]!,
      bySlot[RemoteShopEquipSlot.userCardBackground]!,
    ];
  }

  bool _bundleHasUnknownRarity(Map<String, dynamic> row) {
    final rarity = (row['rarity'] ?? '').toString().trim();
    if (rarity.isEmpty) return false;
    return RemoteShopItemRarityX.fromKey(rarity) ==
        RemoteShopItemRarity.unknown;
  }

  int? _resolveCatalogVersion(
    List<RemoteShopItemDto> catalogItems,
    List<RemoteShopBundleDto> catalogBundles,
  ) {
    var hasVersion = false;
    var maxVersion = 0;

    for (final item in catalogItems) {
      hasVersion = true;
      if (item.catalogVersion > maxVersion) {
        maxVersion = item.catalogVersion;
      }
    }

    for (final bundle in catalogBundles) {
      hasVersion = true;
      if (bundle.catalogVersion > maxVersion) {
        maxVersion = bundle.catalogVersion;
      }
    }

    return hasVersion ? maxVersion : null;
  }
}

String? _trim(Object? value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
}
