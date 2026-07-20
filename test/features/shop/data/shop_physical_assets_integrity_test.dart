import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';

import 'shop_asset_test_support.dart';

void main() {
  group('Shop physical assets integrity', () {
    final projectRoot = Directory.current.path;

    test('every catalog assetPath exists in the project', () {
      for (final asset in ShopAssetsCatalog.allAssets) {
        final file = File(p.join(projectRoot, asset.assetPath));
        expect(file.existsSync(), isTrue, reason: asset.assetPath);
      }
    });

    test('every catalog previewAssetPath exists in the project', () {
      for (final asset in ShopAssetsCatalog.allAssets) {
        final file = File(p.join(projectRoot, asset.previewAssetPath));
        expect(file.existsSync(), isTrue, reason: asset.previewAssetPath);
      }
    });

    test('every catalog assetPath and previewAssetPath uses webp extension',
        () {
      for (final asset in ShopAssetsCatalog.allAssets) {
        expect(
          p.extension(asset.assetPath).toLowerCase(),
          '.webp',
          reason: asset.assetPath,
        );
        expect(
          p.extension(asset.previewAssetPath).toLowerCase(),
          '.webp',
          reason: asset.previewAssetPath,
        );
      }
    });

    test('catalog asset paths are unique', () {
      final assetPaths = ShopAssetsCatalog.allAssets
          .map((asset) => asset.assetPath)
          .toList(growable: false);
      final previewPaths = ShopAssetsCatalog.allAssets
          .map((asset) => asset.previewAssetPath)
          .toList(growable: false);

      expect(assetPaths.toSet(), hasLength(assetPaths.length));
      expect(previewPaths.toSet(), hasLength(previewPaths.length));
    });

    test('catalog asset paths match on-disk paths exactly', () {
      final actualRelativePaths =
          Directory(p.join(projectRoot, 'assets', 'shop'))
              .listSync(recursive: true)
              .whereType<File>()
              .map(
                (file) => p
                    .relative(
                      p.normalize(file.path),
                      from: p.normalize(projectRoot),
                    )
                    .replaceAll('\\', '/'),
              )
              .toSet();

      for (final asset in ShopAssetsCatalog.allAssets) {
        expect(actualRelativePaths.contains(asset.assetPath), isTrue,
            reason: asset.assetPath);
        expect(
          actualRelativePaths.contains(asset.previewAssetPath),
          isTrue,
          reason: asset.previewAssetPath,
        );
      }
    });

    test('assets/shop contains no obvious orphan files', () {
      final catalogReferencedAssets = ShopAssetsCatalog.allAssets
          .expand((asset) => <String>{asset.assetPath, asset.previewAssetPath})
          .followedBy(
            ShopCatalog.allItems
                .map((item) => item.assetRef)
                .whereType<String>()
                .where((assetRef) => assetRef.startsWith('assets/shop/')),
          )
          .map((path) => p.normalize(p.join(projectRoot, path)))
          .toSet();
      final allowedPhysicalAssets = <String>{
        ...catalogReferencedAssets,
        ...explicitlyRegisteredAuxiliaryShopAssets
            .map((path) => p.normalize(p.join(projectRoot, path))),
      };
      final actualPaths = Directory(p.join(projectRoot, 'assets', 'shop'))
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => p.normalize(file.path))
          .where((path) => !isStructuralShopAssetPath(path))
          .toSet();
      final unexpectedPhysicalAssets =
          actualPaths.difference(allowedPhysicalAssets);
      final missingAssets = catalogReferencedAssets.difference(actualPaths);

      expect(
        unexpectedPhysicalAssets,
        isEmpty,
        reason: [
          'Unexpected files under assets/shop:',
          formatAssetPathList(
            unexpectedPhysicalAssets.map(
              (path) =>
                  p.relative(path, from: projectRoot).replaceAll('\\', '/'),
            ),
          ),
          'Register them as catalog assets, auxiliary assets, or remove them.',
        ].join('\n'),
      );
      expect(
        missingAssets,
        isEmpty,
        reason: [
          'Referenced but missing assets:',
          formatAssetPathList(
            missingAssets.map(
              (path) =>
                  p.relative(path, from: projectRoot).replaceAll('\\', '/'),
            ),
          ),
        ].join('\n'),
      );
    });
  });
}
