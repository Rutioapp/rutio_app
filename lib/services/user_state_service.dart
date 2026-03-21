import '../data/local/asset_json_loader.dart';
import '../data/local/user_state_storage.dart';

class UserStateService {
  UserStateService._();
  static final UserStateService instance = UserStateService._();

  final UserStateStorage _storage = UserStateStorage();
  final AssetJsonLoader _loader = AssetJsonLoader();

  static const String _templatePath =
      'assets/templates/user_state_template.json';

  /// Carga el UserState si existe, si no lo crea desde el template
  Future<Map<String, dynamic>> loadOrCreate() async {
    final existing = await _storage.read();
    if (existing != null) return existing;

    final template = await _loader.loadJsonMap(_templatePath);
    await _storage.write(template);
    return template;
  }

  /// Fuerza creación solo si no existe
  Future<void> createIfMissing() async {
    final existing = await _storage.read();
    if (existing != null) return;

    final template = await _loader.loadJsonMap(_templatePath);
    await _storage.write(template);
  }

  /// Guardar cambios
  Future<void> save(Map<String, dynamic> userState) async {
    await _storage.write(userState);
  }

  /// Borrar estado (logout/reset)
  Future<void> clear() async {
    await _storage.clear();
  }
}
