import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProfileRecord {
  const SupabaseProfileRecord({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;

  factory SupabaseProfileRecord.fromMap(Map<String, dynamic> map) {
    return SupabaseProfileRecord(
      id: (map['id'] ?? '').toString(),
      email: map['email']?.toString(),
      displayName: map['display_name']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
    );
  }
}

class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    final userId = currentUser?.id;
    if (userId == null || userId.isEmpty) return null;

    final response = await _client
        .from('profiles')
        .select('id, email, display_name, avatar_url')
        .eq('id', userId)
        .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  }

  Future<SupabaseProfileRecord?> fetchCurrentUserProfileRecord() async {
    final rawProfile = await fetchCurrentUserProfile();
    if (rawProfile == null) return null;
    return SupabaseProfileRecord.fromMap(rawProfile);
  }

  Future<Map<String, dynamic>?> fetchCurrentUserProgress() async {
    final userId = currentUser?.id;
    if (userId == null || userId.isEmpty) return null;

    final response = await _client
        .from('user_progress')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  }
}
