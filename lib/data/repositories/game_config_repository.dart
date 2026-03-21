import '../local/asset_json_loader.dart';

class GameConfigRepository {
  final AssetJsonLoader _loader;
  Map<String, dynamic>? _cached;

  GameConfigRepository(this._loader);

  Future<Map<String, dynamic>> getGameConfig() async {
    _cached ??= await _loader.loadJsonMap('assets/config/game_config.json');
    return _cached!;
  }
}
