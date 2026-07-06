import 'package:rutio/features/shop/application/shop_cosmetics_service.dart';
import 'package:rutio/features/shop/data/shop_cosmetics_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_operation_result.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/stores/user_state_store.dart';

class ShopCosmeticsController {
  ShopCosmeticsController({
    required UserStateStore userStateStore,
    ShopCosmeticsRepository? repository,
  })  : _userStateStore = userStateStore,
        _repository = repository ?? ShopCosmeticsRepository();

  final UserStateStore _userStateStore;
  final ShopCosmeticsRepository _repository;

  Future<ShopCosmeticsState> getState() async {
    return _repository.load();
  }

  Future<int> getWalletCoins() => _walletCoins();

  Future<bool> canPurchaseAsset(String assetId) async {
    final service = await _service();
    return service.canPurchaseAsset(assetId);
  }

  Future<bool> canPurchaseBundle(String bundleId) async {
    final service = await _service();
    return service.canPurchaseBundle(bundleId);
  }

  Future<bool> isAssetOwned(String assetId) async {
    final service = await _service();
    return service.isAssetOwned(assetId);
  }

  Future<bool> isBundleOwned(String bundleId) async {
    final service = await _service();
    return service.isBundleOwned(bundleId);
  }

  Future<ShopAssetOwnershipState> assetOwnershipState(String assetId) async {
    final service = await _service();
    return service.assetOwnershipState(assetId);
  }

  Future<ShopAsset?> getEquippedAssetForCategory(
    ShopAssetCategory category,
  ) async {
    final service = await _service();
    return service.getEquippedAssetForCategory(category);
  }

  Future<ShopCosmeticsOperationResult> purchaseAsset(String assetId) async {
    final service = await _service();
    final result = service.purchaseAsset(assetId);
    if (!result.isSuccess) return result;
    await _persist(result.state, result.walletCoins);
    return result;
  }

  Future<ShopCosmeticsOperationResult> purchaseBundle(String bundleId) async {
    final service = await _service();
    final result = service.purchaseBundle(bundleId);
    if (!result.isSuccess) return result;
    await _persist(result.state, result.walletCoins);
    return result;
  }

  Future<ShopCosmeticsOperationResult> equipAsset(String assetId) async {
    final service = await _service();
    final result = service.equipAsset(assetId);
    if (!result.isSuccess) return result;
    await _persist(result.state, result.walletCoins);
    return result;
  }

  Future<ShopCosmeticsOperationResult> unequipAsset(
    ShopAssetCategory category,
  ) async {
    final service = await _service();
    final result = service.unequipAsset(category);
    if (!result.isSuccess) return result;
    await _persist(result.state, result.walletCoins);
    return result;
  }

  Future<ShopCosmeticsService> _service() async {
    final walletCoins = await _walletCoins();
    final state = await _repository.load();
    return ShopCosmeticsService(state: state, walletCoins: walletCoins);
  }

  Future<int> _walletCoins() async {
    if (_userStateStore.state == null) {
      await _userStateStore.load();
    }

    final root = _userStateStore.state;
    if (root == null) return 0;
    final userState = (root['userState'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final wallet = (userState['wallet'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    return ((wallet['coins'] as num?) ?? 0).toInt();
  }

  Future<void> _persist(ShopCosmeticsState state, int walletCoins) async {
    final root = await _ensureRoot();
    if (root == null) return;

    await _repository.save(state);
    final userState = Map<String, dynamic>.from(
      root['userState'] as Map? ?? <String, dynamic>{},
    );
    final wallet = Map<String, dynamic>.from(
      userState['wallet'] as Map? ?? <String, dynamic>{},
    );
    wallet['coins'] = walletCoins;
    userState['wallet'] = wallet;
    root['userState'] = userState;
    await _userStateStore.save(root);
  }

  Future<Map<String, dynamic>?> _ensureRoot() async {
    if (_userStateStore.state == null) {
      await _userStateStore.load();
    }
    final root = _userStateStore.state;
    if (root == null) return null;
    return Map<String, dynamic>.from(root);
  }
}
