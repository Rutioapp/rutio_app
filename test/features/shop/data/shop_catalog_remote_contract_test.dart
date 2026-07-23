import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/shop_catalog_contract/shop_catalog_contract.dart';
import '../../../../tool/shop_catalog_contract/shop_catalog_sql_parser.dart';

void main() {
  group('Shop catalog remote contract parity', () {
    test('Dart catalog matches the current SQL seed contract exactly', () {
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

      expect(comparison.dartItemCount, 66);
      expect(comparison.sqlItemCount, 66);
      expect(comparison.assetCount, 61);
      expect(comparison.bundleCount, 22);
      expect(comparison.sqlBundleCount, 22);
      expect(
        comparison.hasDifferences,
        isFalse,
        reason: comparison.renderMarkdownReport(remoteParityConfirmed: false),
      );
    });
  });
}
