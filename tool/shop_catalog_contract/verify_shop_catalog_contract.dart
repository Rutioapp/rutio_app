import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';

import 'shop_catalog_contract.dart';
import 'shop_catalog_sql_parser.dart';

void main() {
  final parser = ShopCatalogSqlSeedParser();
  final sqlSnapshot = parser.parseFiles(<String>[
    'supabase/migrations/20260718101000_seed_shop_catalog_v1.sql',
    'supabase/migrations/20260719194500_seed_shop_cosmetics_catalog_v1.sql',
    'supabase/migrations/20260722121000_seed_shop_bundles_catalog_v1.sql',
    'supabase/migrations/20260723220000_sync_shop_catalog_contract.sql',
  ]);
  final comparison = compareShopCatalogContracts(
    dartSnapshot: ShopCatalogContractSnapshot.fromLocal(),
    sqlSnapshot: sqlSnapshot,
  );

  print(
    comparison.renderMarkdownReport(
      remoteParityConfirmed: false,
    ),
  );

  if (comparison.hasDifferences) {
    throw StateError('Shop catalog contract parity failed.');
  }

  print('\nNo drift detected in Dart ↔ migration contract.');
  print('Local items: ${ShopCatalog.allItems.length}');
  print('Local assets: ${ShopAssetsCatalog.allAssets.length}');
  print('Local bundles: ${ShopAssetsCatalog.allBundles.length}');
}
