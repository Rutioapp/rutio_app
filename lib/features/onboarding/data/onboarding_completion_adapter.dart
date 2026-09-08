import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth/onboarding_auth_contracts.dart';

/// AUTH-3 client boundary. It sends only the minimized completion contract;
/// authentication credentials and the draft's UI/recommendation metadata never
/// cross this adapter.
class SupabaseOnboardingCompletionAdapter implements OnboardingCompletionPort {
  SupabaseOnboardingCompletionAdapter({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<OnboardingCompletionResult> completeOnboarding(
    OnboardingCompletionIntent intent,
  ) async {
    final preparedHabit = intent.preparedHabit == null
        ? null
        : _canonicalHabit(intent.preparedHabit!);
    final reminder = preparedHabit == null || intent.reminder == null
        ? null
        : _canonicalReminder(intent.reminder!);
    try {
      final raw = await _client.rpc(
        'complete_onboarding_v1',
        params: <String, dynamic>{
          'p_operation_id': intent.operationId,
          'p_account_resolution': _resolutionCode(intent.accountResolution),
          'p_prepared_habit_decision': intent.preparedHabitDecision.name,
          'p_profile': <String, dynamic>{
            if (intent.name != null) 'name': intent.name!.trim(),
          },
          'p_prepared_habit': preparedHabit,
          'p_reminder': reminder,
        },
      );
      final row = _asMap(raw);
      return _parseResult(row, intent);
    } on PostgrestException catch (error) {
      return OnboardingCompletionResult(
        kind: _kindFor(error),
        operationId: intent.operationId,
        userId: intent.authenticatedUserId,
        error: _errorFor(error),
      );
    } on SocketException catch (error) {
      return OnboardingCompletionResult(
        kind: OnboardingCompletionResultKind.retryableFailure,
        operationId: intent.operationId,
        userId: intent.authenticatedUserId,
        error:
            OnboardingAuthError(OnboardingAuthErrorCode.network, cause: error),
      );
    } catch (error) {
      return OnboardingCompletionResult(
        kind: OnboardingCompletionResultKind.retryableFailure,
        operationId: intent.operationId,
        userId: intent.authenticatedUserId,
        error:
            OnboardingAuthError(OnboardingAuthErrorCode.network, cause: error),
      );
    }
  }

  OnboardingCompletionResult _parseResult(
    Map<String, dynamic> row,
    OnboardingCompletionIntent intent,
  ) {
    final operationId =
        (row['operationId'] ?? row['operation_id'] ?? '').toString().trim();
    final userId = (row['userId'] ?? row['user_id'] ?? '').toString().trim();
    final status = (row['status'] ?? '').toString();
    final resolution = _parseResolution(row['accountResolution']);
    return OnboardingCompletionResult(
      kind: status == 'alreadyCompletedSameOperation'
          ? OnboardingCompletionResultKind.alreadyCompletedSameOperation
          : status == 'completed'
              ? OnboardingCompletionResultKind.completed
              : OnboardingCompletionResultKind.terminalFailure,
      operationId: operationId,
      userId: userId,
      habitId: _nullable(row['habitId'] ?? row['habit_id']),
      preparedHabitApplied: row['preparedHabitApplied'] == true,
      accountResolution: resolution,
      completedAt: DateTime.tryParse((row['completedAt'] ?? '').toString()),
      error: status == 'completed' || status == 'alreadyCompletedSameOperation'
          ? null
          : const OnboardingAuthError(OnboardingAuthErrorCode.completionFailed),
    );
  }

  static Map<String, dynamic> _canonicalHabit(Map<String, dynamic> source) {
    final schedule = source['schedule'];
    final target =
        source['target'] ?? source['targetCount'] ?? source['target_count'];
    return <String, dynamic>{
      'name': (source['name'] ?? '').toString().trim(),
      if (_nullable(source['familyId'] ?? source['family_id']) != null)
        'family_id': _nullable(source['familyId'] ?? source['family_id']),
      if (_nullable(source['emoji']) != null)
        'emoji': _nullable(source['emoji']),
      'habit_type': (source['type'] ?? source['habit_type'] ?? 'check')
          .toString()
          .trim()
          .toLowerCase(),
      if (target != null) 'target_count': target,
      if (_nullable(source['unit'] ?? source['unitLabel']) != null)
        'unit': _nullable(source['unit'] ?? source['unitLabel']),
      'schedule': schedule,
    };
  }

  static Map<String, dynamic> _canonicalReminder(Map<String, dynamic> source) {
    final selected = source['selectedTime'];
    final selectedMap = selected is Map
        ? Map<String, dynamic>.from(selected.cast<String, dynamic>())
        : const <String, dynamic>{};
    return <String, dynamic>{
      'enabled': source['enabled'] == true,
      if (source['enabled'] == true) ...{
        'hour': selectedMap['hour'],
        'minute': selectedMap['minute'],
      },
    };
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw.cast<String, dynamic>());
    }
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(
          (raw.first as Map).cast<String, dynamic>());
    }
    throw const FormatException('Completion RPC returned an invalid response.');
  }

  static String _resolutionCode(OnboardingAccountResolution value) =>
      value.name;

  static OnboardingAccountResolution? _parseResolution(dynamic value) {
    for (final candidate in OnboardingAccountResolution.values) {
      if (candidate.name == value?.toString()) {
        return candidate;
      }
    }
    return null;
  }

  static String? _nullable(dynamic value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static OnboardingCompletionResultKind _kindFor(PostgrestException error) {
    final message = '${error.code} ${error.message}'.toLowerCase();
    if (message.contains('operation_conflict') ||
        message.contains('remote_state_conflict')) {
      return OnboardingCompletionResultKind.conflict;
    }
    if (message.contains('invalid_payload') || error.code == '22023') {
      return OnboardingCompletionResultKind.terminalFailure;
    }
    return OnboardingCompletionResultKind.retryableFailure;
  }

  static OnboardingAuthError _errorFor(PostgrestException error) {
    final message = '${error.code} ${error.message}'.toLowerCase();
    if (message.contains('auth_required') || error.code == '28000') {
      return OnboardingAuthError(OnboardingAuthErrorCode.sessionExpired,
          cause: error);
    }
    if (message.contains('operation_conflict') ||
        message.contains('remote_state_conflict')) {
      return OnboardingAuthError(OnboardingAuthErrorCode.operationConflict,
          cause: error);
    }
    if (message.contains('invalid_payload')) {
      return OnboardingAuthError(OnboardingAuthErrorCode.completionFailed,
          cause: error);
    }
    return OnboardingAuthError(OnboardingAuthErrorCode.completionRetryable,
        cause: error);
  }
}
