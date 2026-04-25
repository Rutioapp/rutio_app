import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/rutio_supabase_config.dart';

class AccountDeletionException implements Exception {
  AccountDeletionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AccountRepository {
  AccountRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> deleteCurrentAccount() async {
    if (!RutioSupabaseConfig.isConfigured) {
      throw AccountDeletionException(
        'Supabase is not configured for this build.',
      );
    }

    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw AccountDeletionException('No authenticated user found.');
    }

    final response = await _client.functions.invoke('delete-account');
    final statusCode = response.status;
    final data = response.data;
    final success = data is Map && data['success'] == true;

    if (statusCode >= 200 && statusCode < 300 && success) return;

    final errorMessage = data is Map
        ? (data['error']?.toString() ?? 'Unknown deletion error.')
        : 'Unknown deletion error.';
    throw AccountDeletionException(errorMessage);
  }
}
