import '../data/repositories/game_config_repository.dart';
import '../data/repositories/user_state_repository.dart';

class GameBootstrapService {
  final GameConfigRepository gameConfigRepo;
  final UserStateRepository userStateRepo;

  GameBootstrapService({
    required this.gameConfigRepo,
    required this.userStateRepo,
  });

  Future<BootstrapResult> init() async {
    final config = await gameConfigRepo.getGameConfig();
    final userState = await userStateRepo.loadOrCreate();
    return BootstrapResult(gameConfig: config, userState: userState);
  }
}

class BootstrapResult {
  final Map<String, dynamic> gameConfig;
  final Map<String, dynamic> userState;

  BootstrapResult({required this.gameConfig, required this.userState});
}
