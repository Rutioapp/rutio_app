import 'package:path/path.dart' as p;

const Set<String> explicitlyRegisteredAuxiliaryShopAssets = <String>{
  'assets/shop/utilities/mystery_box/mystery_box_closed.png',
  'assets/shop/utilities/mystery_box/mystery_box_opened.png',
  'assets/shop/utilities/mystery_box/mystery_box_opening.png',
};

bool isStructuralShopAssetPath(String relativePath) {
  final fileName = p.basename(relativePath).trim().toLowerCase();
  if (fileName.isEmpty) return true;
  if (fileName.startsWith('.')) return true;
  if (fileName == 'readme' || fileName.startsWith('readme.')) return true;
  if (fileName == 'thumbs.db' || fileName == 'desktop.ini') return true;
  return false;
}

String formatAssetPathList(Iterable<String> paths) {
  final sorted = paths.toList(growable: false)..sort();
  return sorted.map((path) => '- $path').join('\n');
}
