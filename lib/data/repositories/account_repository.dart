import 'package:supabase_flutter/supabase_flutter.dart';

enum AccountDeletionFailureReason {
  unauthenticated,
  network,
  server,
  unknown,
}

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.reason);

  final AccountDeletionFailureReason reason;
}

class AccountRepository {
  AccountRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> deleteCurrentAccount() async {
    final session = _client.auth.currentSession;
    if (session == null || session.accessToken.isEmpty) {
      throw const AccountDeletionException(
        AccountDeletionFailureReason.unauthenticated,
      );
    }

    try {
      final response = await _client.functions.invoke(
        'delete-account',
        method: HttpMethod.post,
      );

      final data = response.data;
      final succeeded = response.status >= 200 &&
          response.status < 300 &&
          data is Map &&
          data['success'] == true;

      if (succeeded) return;

      throw AccountDeletionException(
        response.status == 401
            ? AccountDeletionFailureReason.unauthenticated
            : AccountDeletionFailureReason.server,
      );
    } on AccountDeletionException {
      rethrow;
    } on FunctionException catch (error) {
      throw AccountDeletionException(
        error.status == 401
            ? AccountDeletionFailureReason.unauthenticated
            : AccountDeletionFailureReason.server,
      );
    } catch (_) {
      throw const AccountDeletionException(
          AccountDeletionFailureReason.network);
    }
  }
}
