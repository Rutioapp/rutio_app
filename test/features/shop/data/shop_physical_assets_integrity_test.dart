import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';

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

    test('assets/shop contains no obvious orphan files', () {
      final expectedPaths = ShopAssetsCatalog.allAssets
          .expand((asset) => <String>{asset.assetPath, asset.previewAssetPath})
          .map((path) => p.normalize(p.join(projectRoot, path)))
          .toSet();
      final actualPaths = Directory(p.join(projectRoot, 'assets', 'shop'))
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => p.normalize(file.path))
          .toSet();

      expect(actualPaths, equals(expectedPaths));
    });
  });
}
