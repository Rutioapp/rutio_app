import '../../stores/user_state_store.dart';
import '../../data/repositories/account_repository.dart';
import 'user_local_data_cleanup.dart';

class AccountDeletionResult {
  const AccountDeletionResult({
    required this.deletedLocalData,
    this.error,
  });

  const AccountDeletionResult.success()
      : deletedLocalData = true,
        error = null;

  const AccountDeletionResult.failure({this.error}) : deletedLocalData = false;

  final bool deletedLocalData;
  final Object? error;

  bool get isSuccess => deletedLocalData;
}

class AccountDeletionService {
  AccountDeletionService({
    AccountRepository? accountRepository,
    UserLocalDataCleanup localDataCleanup = const UserLocalDataCleanup(),
  })  : _accountRepository = accountRepository ?? AccountRepository(),
        _localDataCleanup = localDataCleanup;

  final AccountRepository _accountRepository;
  final UserLocalDataCleanup _localDataCleanup;

  Future<AccountDeletionResult> launchDeletionFlow({
    required UserStateStore store,
  }) async {
    try {
      await _accountRepository.deleteCurrentAccount();
      await _localDataCleanup.clearAll(store: store);
      return const AccountDeletionResult.success();
    } catch (error) {
      return AccountDeletionResult.failure(error: error);
    }
  }
}
