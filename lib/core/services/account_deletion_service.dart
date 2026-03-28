import '../../stores/user_state_store.dart';
import 'user_local_data_cleanup.dart';

class AccountDeletionResult {
  const AccountDeletionResult({
    required this.deletedLocalData,
    this.error,
  });

  const AccountDeletionResult.success()
      : deletedLocalData = true,
        error = null;

  const AccountDeletionResult.failure({this.error})
      : deletedLocalData = false;

  final bool deletedLocalData;
  final Object? error;

  bool get isSuccess => deletedLocalData;
}

class AccountDeletionService {
  const AccountDeletionService({
    UserLocalDataCleanup localDataCleanup = const UserLocalDataCleanup(),
  }) : _localDataCleanup = localDataCleanup;

  final UserLocalDataCleanup _localDataCleanup;

  Future<AccountDeletionResult> launchDeletionFlow({
    required UserStateStore store,
  }) async {
    try {
      await _localDataCleanup.clearAll(store: store);
      return const AccountDeletionResult.success();
    } catch (error) {
      return AccountDeletionResult.failure(error: error);
    }
  }
}
