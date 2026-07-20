import 'cloud_cosmetics_snapshot.dart';
import 'shop_cloud_equip_repository.dart';
import 'shop_cloud_purchase_repository.dart';
import 'shop_cloud_read_repository.dart';
import 'shop_cloud_purchase_dtos.dart';
import 'shop_cloud_equip_dtos.dart';
import 'shop_cloud_errors.dart';

abstract class CloudCosmeticsRepository {
  Future<ShopCloudReadResult<CloudCosmeticsSnapshot>> fetchSnapshot();

  Future<RemoteShopPurchaseResultDto> purchaseAsset({
    required String itemId,
    required String requestId,
  });

  Future<RemoteShopEquipResultDto> equipAsset({
    required String itemId,
    required String slot,
    required String requestId,
  });
}

class SupabaseCloudCosmeticsRepository implements CloudCosmeticsRepository {
  SupabaseCloudCosmeticsRepository({
    ShopCloudReadRepository? readRepository,
    ShopCloudPurchaseRepository? purchaseRepository,
    ShopCloudEquipRepository? equipRepository,
  })  : _readRepository =
            readRepository ?? ShopCloudReadRepository(readEnabled: true),
        _purchaseRepository =
            purchaseRepository ?? ShopCloudPurchaseRepository(),
        _equipRepository = equipRepository ?? ShopCloudEquipRepository();

  final ShopCloudReadRepository _readRepository;
  final ShopCloudPurchaseRepository _purchaseRepository;
  final ShopCloudEquipRepository _equipRepository;

  @override
  Future<ShopCloudReadResult<CloudCosmeticsSnapshot>> fetchSnapshot() async {
    final result = await _readRepository.fetchShopSnapshot();
    if (!result.isSuccess || result.data == null) {
      return ShopCloudReadResult<CloudCosmeticsSnapshot>.failure(
        error: result.error ??
            const ShopCloudReadError(
              code: ShopCloudErrorCode.unknown,
              message: 'Could not fetch cloud cosmetics snapshot.',
            ),
        warnings: result.warnings,
      );
    }

    return ShopCloudReadResult<CloudCosmeticsSnapshot>.success(
      data: CloudCosmeticsSnapshot.fromShopSnapshot(result.data!),
      warnings: result.warnings,
    );
  }

  @override
  Future<RemoteShopPurchaseResultDto> purchaseAsset({
    required String itemId,
    required String requestId,
  }) {
    return _purchaseRepository.purchaseShopItem(
      itemId: itemId,
      requestId: requestId,
    );
  }

  @override
  Future<RemoteShopEquipResultDto> equipAsset({
    required String itemId,
    required String slot,
    required String requestId,
  }) async {
    return _equipRepository.equipShopCosmetic(
      itemId: itemId,
      slot: slot,
      requestId: requestId,
    );
  }
}
