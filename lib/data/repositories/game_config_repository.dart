import 'package:rutio/core/assets/app_assets.dart';

import '../local/asset_json_loader.dart';

class GameConfigRepository {
  final AssetJsonLoader _loader;
  Map<String, dynamic>? _cached;

  GameConfigRepository(this._loader);

  Future<Map<String, dynamic>> getGameConfig() async {
    _cached ??= await _loader.loadJsonMap(AppAssets.gameConfig);
    return _cached!;
  }
}
