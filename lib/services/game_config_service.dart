import '../data/local/asset_json_loader.dart';
import '../data/repositories/game_config_repository.dart';

class GameConfigService {
  GameConfigService._();
  static final GameConfigService instance = GameConfigService._();

  final GameConfigRepository _repo = GameConfigRepository(AssetJsonLoader());
  Map<String, dynamic>? _cached;

  Future<Map<String, dynamic>> ensureLoaded() async {
    _cached ??= await _repo.getGameConfig();
    return _cached!;
  }

  Map<String, dynamic>? get cached => _cached;
}



