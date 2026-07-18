import 'package:flutter/foundation.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';
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

      final catalogItems = catalogResult.data ?? const <RemoteShopItemDto>[];
      final snapshotWarnings = List<ShopCloudWarning>.unmodifiable(warnings);
      final snapshot = ShopCloudSnapshot(
        authenticatedUserId: userId,
        catalogItems: catalogItems,
        wallet: wallet,
        inventory: inventoryResult.data ?? const <RemoteInventoryItemDto>[],
        equippedCosmetics:
            equippedResult.data ?? const <RemoteEquippedCosmeticDto>[],
        fetchedAt: _nowProvider().toUtc(),
        catalogVersion: _resolveCatalogVersion(catalogItems),
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

  int? _resolveCatalogVersion(List<RemoteShopItemDto> catalogItems) {
    if (catalogItems.isEmpty) return null;
    var maxVersion = catalogItems.first.catalogVersion;
    for (final item in catalogItems.skip(1)) {
      if (item.catalogVersion > maxVersion) {
        maxVersion = item.catalogVersion;
      }
    }
    return maxVersion;
  }
}
