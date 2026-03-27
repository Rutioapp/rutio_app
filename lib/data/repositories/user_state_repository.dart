import 'package:rutio/core/assets/app_assets.dart';

import '../../models/user_state.dart';
import '../local/asset_json_loader.dart';
import '../local/user_state_storage.dart';

class UserStateRepository {
  final UserStateStorage _storage;
  final AssetJsonLoader _assets;

  UserStateRepository({
    required UserStateStorage storage,
    AssetJsonLoader? assets,
  })  : _storage = storage,
        _assets = assets ?? AssetJsonLoader();

  /// Devuelve el estado (si no existe, crea uno desde la plantilla)
  Future<UserState> getUserState() async {
    final json = await loadOrCreate();
    return UserState.fromJson(json);
  }

  /// Guarda el estado actual
  Future<void> saveUserState(UserState state) async {
    await save(state.toJson());
  }

  // ----- Lo que ya tenías -----

  Future<Map<String, dynamic>> loadOrCreate() async {
    final existing = await _storage.read();
    if (existing != null) return existing;

    final template = await _assets.loadJsonMap(AppAssets.userStateTemplate);

    await _storage.write(template);
    return template;
  }

  Future<void> save(Map<String, dynamic> userStateJson) async {
    await _storage.write(userStateJson);
  }

  Future<void> resetToTemplate() async {
    final template = await _assets.loadJsonMap(AppAssets.userStateTemplate);
    await _storage.write(template);
  }
}

