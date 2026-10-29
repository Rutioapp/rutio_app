import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/observability/crash_reporting_service.dart';
import '../../../../core/storage/pending_queue_storage.dart';
import '../../domain/models/pending_reward_claim.dart';
import '../../domain/pending_reward_claim_store.dart';

class SharedPreferencesPendingRewardClaimStore
    implements PendingRewardClaimStore, PendingRewardClaimStoreWithStatus {
  SharedPreferencesPendingRewardClaimStore({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    PendingQueueDiagnosticSink? diagnosticSink,
    CrashReportingService? crashReportingService,
  }) : _storage = PendingQueueStorage(
          queueName: 'achievement_reward_claim',
          sharedPreferencesProvider:
              sharedPreferencesProvider ?? SharedPreferences.getInstance,
          diagnosticSink: diagnosticSink,
          crashReportingService: crashReportingService,
        );

  static const String storagePrefix = 'rutio_pending_reward_claim_v1';

  final PendingQueueStorage _storage;

  @override
  Future<List<PendingRewardClaim>> loadPendingClaims(String userId) async {
    return (await loadPendingClaimsWithStatus(userId)).values;
  }

  @override
  Future<PendingQueueReadResult<PendingRewardClaim>>
      loadPendingClaimsWithStatus(String userId) {
    return _storage.read<PendingRewardClaim>(
      key: _storageKey(userId),
      decode: _decode,
    );
  }

  @override
  Future<void> savePendingClaims(
    String userId,
    List<PendingRewardClaim> claims,
  ) async {
    await _storage.write<PendingRewardClaim>(
      key: _storageKey(userId),
      values: claims,
      decode: _decode,
      encode: (values) =>
          values.map((claim) => claim.toJson()).toList(growable: false),
    );
  }

  @override
  Future<bool> savePendingClaimsConfirmed(
    String userId,
    List<PendingRewardClaim> claims,
  ) {
    return _storage.write<PendingRewardClaim>(
      key: _storageKey(userId),
      values: claims,
      decode: _decode,
      encode: (values) =>
          values.map((claim) => claim.toJson()).toList(growable: false),
    );
  }

  @override
  Future<void> clearPendingClaims(String userId) async {
    await _storage.clear<PendingRewardClaim>(
      key: _storageKey(userId),
      decode: _decode,
    );
  }

  List<PendingRewardClaim> _decode(List<dynamic> rows) {
    final claims = <PendingRewardClaim>[];
    for (final value in rows) {
      if (value is! Map) throw const FormatException('Invalid queue row.');
      claims.add(
        PendingRewardClaim.fromJson(
          Map<String, dynamic>.from(value.cast<String, dynamic>()),
        ),
      );
    }
    claims.sort((a, b) {
      final byCreated = a.createdAtMillis.compareTo(b.createdAtMillis);
      if (byCreated != 0) return byCreated;
      return a.requestId.compareTo(b.requestId);
    });
    return claims;
  }

  String _storageKey(String userId) {
    return '${storagePrefix}_${userId.trim()}';
  }
}
