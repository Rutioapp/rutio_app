import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/rutio_supabase_client.dart';
import '../../../data/repositories/repository_result.dart';
import '../domain/feedback_category.dart';
import '../domain/feedback_report.dart';
import '../domain/feedback_technical_context.dart';
import 'feedback_repository.dart';

class SupabaseFeedbackRepository implements FeedbackRepository {
  SupabaseFeedbackRepository({
    SupabaseClient? client,
    FeedbackCurrentUserIdProvider? currentUserIdProvider,
    void Function(String message)? logger,
  })  : _client = client ?? RutioSupabaseClient.instance,
        _currentUserIdProvider = currentUserIdProvider,
        _logger = logger;

  final SupabaseClient _client;
  final FeedbackCurrentUserIdProvider? _currentUserIdProvider;
  final void Function(String message)? _logger;

  static const String _tableName = 'feedback_reports';
  static const String _columns = '''
id,
user_id,
category,
description,
screenshot_path,
contact_allowed,
status,
team_response,
technical_context,
review_started_at,
closed_at,
created_at,
updated_at
''';

  @override
  Future<RepositoryResult<FeedbackReport>> createFeedback({
    required String id,
    required FeedbackCategory category,
    required String description,
    required bool contactAllowed,
    required FeedbackTechnicalContext technicalContext,
    String? screenshotPath,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<FeedbackReport>.failure(_notAuthenticated());
    }

    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      return RepositoryResult<FeedbackReport>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Feedback id is required.',
        ),
      );
    }

    final normalizedDescription = description.trim();
    if (normalizedDescription.isEmpty) {
      return RepositoryResult<FeedbackReport>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Feedback description is required.',
        ),
      );
    }

    final payload = <String, dynamic>{
      'id': normalizedId,
      'user_id': userId,
      'category': category.postgresValue,
      'description': normalizedDescription,
      'screenshot_path': null,
      'contact_allowed': contactAllowed,
      'technical_context': technicalContext.toJson(),
    };

    if (screenshotPath != null && screenshotPath.trim().isNotEmpty) {
      payload['screenshot_path'] = screenshotPath.trim();
    }

    try {
      final row = await _client
          .from(_tableName)
          .insert(payload)
          .select(_columns)
          .single();
      final mapped = FeedbackReport.fromSupabaseRow(
        Map<String, dynamic>.from(row),
      );
      if (mapped.id != normalizedId || mapped.userId != userId) {
        return RepositoryResult<FeedbackReport>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.invalidResponse,
            message: 'Feedback insert response did not match the request.',
          ),
        );
      }
      return RepositoryResult<FeedbackReport>.success(data: mapped);
    } on FormatException catch (error) {
      return RepositoryResult<FeedbackReport>.failure(
        RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: error.message,
          cause: error,
        ),
      );
    } on ArgumentError catch (error) {
      return RepositoryResult<FeedbackReport>.failure(
        RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: error.message ?? 'Invalid feedback payload.',
          cause: error,
        ),
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<FeedbackReport>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not send feedback.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        _logger?.call(
          '[feedback_repository] unexpected create error: ${error.runtimeType}',
        );
      }
      return RepositoryResult<FeedbackReport>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not send feedback.',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<RepositoryResult<FeedbackReport>> updateMyFeedback({
    required String feedbackId,
    required String description,
    required bool contactAllowed,
    String? screenshotPath,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<FeedbackReport>.failure(_notAuthenticated());
    }

    final normalizedFeedbackId = feedbackId.trim();
    if (normalizedFeedbackId.isEmpty) {
      return RepositoryResult<FeedbackReport>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Feedback id is required.',
        ),
      );
    }

    final normalizedDescription = description.trim();
    if (normalizedDescription.isEmpty) {
      return RepositoryResult<FeedbackReport>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Feedback description is required.',
        ),
      );
    }

    try {
      final response = await _client.rpc(
        'update_my_feedback',
        params: <String, dynamic>{
          'p_feedback_id': normalizedFeedbackId,
          'p_description': normalizedDescription,
          'p_screenshot_path':
              screenshotPath?.trim().isEmpty == true ? null : screenshotPath?.trim(),
          'p_contact_allowed': contactAllowed,
        },
      );
      final row = _coerceRpcRow(response);
      final mapped = FeedbackReport.fromSupabaseRow(row);
      if (mapped.userId == null || mapped.userId != userId) {
        return RepositoryResult<FeedbackReport>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.invalidResponse,
            message: 'Feedback update response did not match the session.',
          ),
        );
      }

      if (mapped.id != normalizedFeedbackId) {
        return RepositoryResult<FeedbackReport>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.invalidResponse,
            message: 'Feedback update response did not match the request.',
          ),
        );
      }

      return RepositoryResult<FeedbackReport>.success(data: mapped);
    } on FormatException catch (error) {
      return RepositoryResult<FeedbackReport>.failure(
        RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: error.message,
          cause: error,
        ),
      );
    } on ArgumentError catch (error) {
      return RepositoryResult<FeedbackReport>.failure(
        RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: error.message ?? 'Invalid feedback payload.',
          cause: error,
        ),
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<FeedbackReport>.failure(
        _mapMutationPostgrestError(
          error,
          fallbackMessage: 'Could not update this feedback.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        _logger?.call(
          '[feedback_repository] unexpected update error: ${error.runtimeType}',
        );
      }
      return RepositoryResult<FeedbackReport>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not update this feedback.',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<RepositoryResult<String?>> deleteMyFeedback({
    required String feedbackId,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<String?>.failure(_notAuthenticated());
    }

    final normalizedFeedbackId = feedbackId.trim();
    if (normalizedFeedbackId.isEmpty) {
      return RepositoryResult<String?>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Feedback id is required.',
        ),
      );
    }

    try {
      final response = await _client.rpc(
        'delete_my_feedback',
        params: <String, dynamic>{
          'p_feedback_id': normalizedFeedbackId,
        },
      );

      if (response == null) {
        return const RepositoryResult<String?>.success(data: null);
      }

      if (response is String) {
        final trimmed = response.trim();
        return RepositoryResult<String?>.success(
          data: trimmed.isEmpty ? null : trimmed,
        );
      }

      if (response is Map) {
        final value = response['screenshot_path'];
        final path = value?.toString().trim();
        return RepositoryResult<String?>.success(
          data: path == null || path.isEmpty ? null : path,
        );
      }

      throw const FormatException('Unexpected delete RPC response.');
    } on FormatException catch (error) {
      return RepositoryResult<String?>.failure(
        RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: error.message,
          cause: error,
        ),
      );
    } on ArgumentError catch (error) {
      return RepositoryResult<String?>.failure(
        RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: error.message ?? 'Invalid feedback payload.',
          cause: error,
        ),
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<String?>.failure(
        _mapMutationPostgrestError(
          error,
          fallbackMessage: 'Could not delete this feedback.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        _logger?.call(
          '[feedback_repository] unexpected delete error: ${error.runtimeType}',
        );
      }
      return RepositoryResult<String?>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not delete this feedback.',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<RepositoryResult<FeedbackReport>> getMyFeedbackById({
    required String feedbackId,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<FeedbackReport>.failure(_notAuthenticated());
    }

    final normalizedFeedbackId = feedbackId.trim();
    if (normalizedFeedbackId.isEmpty) {
      return RepositoryResult<FeedbackReport>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Feedback id is required.',
        ),
      );
    }

    try {
      final row = await _client
          .from(_tableName)
          .select(_columns)
          .eq('id', normalizedFeedbackId)
          .maybeSingle();

      if (row == null) {
        return RepositoryResult<FeedbackReport>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.notFound,
            message: 'Feedback not found.',
          ),
        );
      }

      final mapped = FeedbackReport.fromSupabaseRow(
        Map<String, dynamic>.from(row),
      );
      if (mapped.userId == null || mapped.userId != userId) {
        return RepositoryResult<FeedbackReport>.failure(
          const RepositoryError(
            code: RepositoryErrorCode.notFound,
            message: 'Feedback not found.',
          ),
        );
      }

      return RepositoryResult<FeedbackReport>.success(data: mapped);
    } on FormatException catch (error) {
      return RepositoryResult<FeedbackReport>.failure(
        RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: error.message,
          cause: error,
        ),
      );
    } on ArgumentError catch (error) {
      return RepositoryResult<FeedbackReport>.failure(
        RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: error.message ?? 'Invalid feedback payload.',
          cause: error,
        ),
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<FeedbackReport>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not load this feedback.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        _logger?.call(
          '[feedback_repository] unexpected detail read error: '
          '${error.runtimeType}',
        );
      }
      return RepositoryResult<FeedbackReport>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not load this feedback.',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<RepositoryResult<List<FeedbackReport>>> getMyFeedback() async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<List<FeedbackReport>>.failure(
          _notAuthenticated());
    }

    try {
      final rows = await _client
          .from(_tableName)
          .select(_columns)
          .order('created_at', ascending: false);

      final reports = _mapReports(rows, expectedUserId: userId);
      return RepositoryResult<List<FeedbackReport>>.success(data: reports);
    } on FormatException catch (error) {
      return RepositoryResult<List<FeedbackReport>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: error.message,
          cause: error,
        ),
      );
    } on ArgumentError catch (error) {
      return RepositoryResult<List<FeedbackReport>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: error.message ?? 'Invalid feedback payload.',
          cause: error,
        ),
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<List<FeedbackReport>>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not load your feedback.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        _logger?.call(
          '[feedback_repository] unexpected read error: ${error.runtimeType}',
        );
      }
      return RepositoryResult<List<FeedbackReport>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not load your feedback.',
          cause: error,
        ),
      );
    }
  }

  String? _currentUserId() {
    final providedUserId = _currentUserIdProvider?.call();
    final current =
        providedUserId?.trim() ?? _client.auth.currentUser?.id.trim();
    if (current == null || current.isEmpty) return null;
    return current;
  }

  RepositoryError _notAuthenticated() {
    return const RepositoryError(
      code: RepositoryErrorCode.notAuthenticated,
      message: 'No authenticated user session is available.',
    );
  }

  RepositoryError _mapPostgrestError(
    PostgrestException error, {
    required String fallbackMessage,
  }) {
    return _mapMutationPostgrestError(
      error,
      fallbackMessage: fallbackMessage,
    );
  }

  RepositoryError _mapMutationPostgrestError(
    PostgrestException error, {
    required String fallbackMessage,
  }) {
    if (kDebugMode) {
      _logger?.call(
        '[feedback_repository] postgrest error code=${error.code}',
      );
    }

    final code = (error.code ?? '').trim().toUpperCase();
    if (code == '42501') {
      return RepositoryError(
        code: RepositoryErrorCode.permissionDenied,
        message: fallbackMessage,
        cause: error,
      );
    }
    if (code == '42P01' || code == 'PGRST204' || code == '42703') {
      return RepositoryError(
        code: RepositoryErrorCode.invalidResponse,
        message: 'Feedback schema is missing expected columns.',
        cause: error,
      );
    }
    if (code == '23502' ||
        code == '23503' ||
        code == '23505' ||
        code == '23514' ||
        code == '22P02') {
      return RepositoryError(
        code: RepositoryErrorCode.invalidResponse,
        message: error.message,
        cause: error,
      );
    }

    final rawMessage = '${error.code ?? ''} ${error.message}'.toLowerCase();
    if (rawMessage.contains('authentication required') ||
        rawMessage.contains('no authenticated user')) {
      return RepositoryError(
        code: RepositoryErrorCode.notAuthenticated,
        message: 'No authenticated user session is available.',
        cause: error,
      );
    }
    if (rawMessage.contains('feedback not found')) {
      return RepositoryError(
        code: RepositoryErrorCode.notFound,
        message: 'Feedback not found.',
        cause: error,
      );
    }
    if (rawMessage.contains('can only be edited while submitted') ||
        rawMessage.contains('can only be deleted while submitted') ||
        rawMessage.contains('feedback reports are immutable after closure') ||
        rawMessage.contains('feedback cannot be closed directly') ||
        rawMessage.contains('feedback content cannot change while') ||
        rawMessage.contains('invalid feedback transition')) {
      return RepositoryError(
        code: RepositoryErrorCode.permissionDenied,
        message: 'This feedback is no longer editable.',
        cause: error,
      );
    }
    if (rawMessage.contains('invalid screenshot path') ||
        rawMessage.contains('description must be between') ||
        rawMessage.contains('technical_context must be a json object') ||
        rawMessage.contains('team response must') ||
        rawMessage.contains('review_started_at is managed by the database') ||
        rawMessage.contains('closed_at is managed by the database')) {
      return RepositoryError(
        code: RepositoryErrorCode.invalidResponse,
        message: fallbackMessage,
        cause: error,
      );
    }
    if (rawMessage.contains('network') ||
        rawMessage.contains('socket') ||
        rawMessage.contains('timeout') ||
        rawMessage.contains('connection') ||
        rawMessage.contains('failed host lookup')) {
      return RepositoryError(
        code: RepositoryErrorCode.network,
        message: fallbackMessage,
        cause: error,
      );
    }

    return RepositoryError(
      code: RepositoryErrorCode.unknown,
      message: fallbackMessage,
      cause: error,
    );
  }

  Map<String, dynamic> _coerceRpcRow(Object? response) {
    if (response is Map) {
      return Map<String, dynamic>.from(response.cast<String, dynamic>());
    }

    if (response is List) {
      if (response.length == 1 && response.first is Map) {
        return Map<String, dynamic>.from(
          (response.first as Map).cast<String, dynamic>(),
        );
      }
    }

    throw const FormatException('Unexpected RPC response.');
  }

  List<FeedbackReport> _mapReports(
    Object? rows, {
    required String expectedUserId,
  }) {
    if (rows is! List) {
      throw FormatException('Expected a list of feedback rows.');
    }

    final reports = <FeedbackReport>[];
    for (final row in rows) {
      if (row is! Map) {
        throw FormatException('Expected feedback rows as JSON objects.');
      }

      final mapped = FeedbackReport.fromSupabaseRow(
        Map<String, dynamic>.from(row.cast<String, dynamic>()),
      );
      if (mapped.userId == null || mapped.userId != expectedUserId) {
        throw FormatException('Feedback row user_id did not match session.');
      }
      reports.add(mapped);
    }

    return reports;
  }
}
