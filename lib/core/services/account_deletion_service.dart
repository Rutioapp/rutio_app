import '../../stores/user_state_store.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/auth_repository.dart';
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

  bool get isNetworkError =>
      error is AccountDeletionException &&
      (error! as AccountDeletionException).reason ==
          AccountDeletionFailureReason.network;
}

class AccountDeletionService {
  AccountDeletionService({
    AccountRepository? accountRepository,
    AuthRepository? authRepository,
    UserLocalDataCleanup localDataCleanup = const UserLocalDataCleanup(),
  })  : _accountRepository = accountRepository ?? AccountRepository(),
        _authRepository = authRepository ?? AuthRepository(),
        _localDataCleanup = localDataCleanup;

  final AccountRepository _accountRepository;
  final AuthRepository _authRepository;
  final UserLocalDataCleanup _localDataCleanup;

  Future<AccountDeletionResult> launchDeletionFlow({
    required UserStateStore store,
  }) async {
    try {
      await _accountRepository.deleteCurrentAccount();
      try {
        await _authRepository.signOut();
      } catch (_) {
        // The backend deletion already succeeded; local cleanup must continue.
      }
      await _localDataCleanup.clearAll(store: store);
      return const AccountDeletionResult.success();
    } catch (error) {
      return AccountDeletionResult.failure(error: error);
    }
  }
}
