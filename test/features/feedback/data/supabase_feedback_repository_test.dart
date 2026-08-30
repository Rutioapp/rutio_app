import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/features/feedback/data/supabase_feedback_repository.dart';
import 'package:rutio/features/feedback/domain/feedback_category.dart';
import 'package:rutio/features/feedback/domain/feedback_status.dart';
import 'package:rutio/features/feedback/domain/feedback_technical_context.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('createFeedback sends the expected payload and maps the response',
      () async {
    final client = _RecordingHttpClient()
      ..enqueueJson(
        statusCode: 201,
        body: <String, dynamic>{
          'id': 'feedback-123',
          'user_id': 'user-1',
          'category': 'bug',
          'description': 'A' * 20,
          'screenshot_path': null,
          'contact_allowed': true,
          'status': 'submitted',
          'team_response': null,
          'technical_context': <String, dynamic>{
            'appVersion': '1.2.3',
            'buildNumber': '456',
            'platform': 'android',
            'osVersion': '15',
            'deviceModel': 'Pixel 8',
            'appLocale': 'es_ES',
            'sourceRoute': '/feedback/new',
          },
          'review_started_at': null,
          'closed_at': null,
          'created_at': '2026-08-30T12:00:00.000Z',
          'updated_at': '2026-08-30T12:00:00.000Z',
        },
      );
    final repository = SupabaseFeedbackRepository(
      client: SupabaseClient(
        'https://example.com',
        'anon-key',
        httpClient: client,
      ),
      currentUserIdProvider: () => 'user-1',
    );
    final technicalContext = const FeedbackTechnicalContext(
      appVersion: '1.2.3',
      buildNumber: '456',
      platform: 'android',
      osVersion: '15',
      deviceModel: 'Pixel 8',
      appLocale: 'es_ES',
      sourceRoute: '/feedback/new',
    );

    final result = await repository.createFeedback(
      id: 'feedback-123',
      category: FeedbackCategory.bug,
      description: '  ${'A' * 20}  ',
      screenshotPath: null,
      contactAllowed: true,
      technicalContext: technicalContext,
    );

    expect(result.isSuccess, isTrue);
    expect(result.data?.id, 'feedback-123');
    expect(result.data?.userId, 'user-1');
    expect(result.data?.technicalContext?.sourceRoute, '/feedback/new');
    expect(client.requests, hasLength(1));
    expect(client.requests.single.method, 'POST');
    expect(
      client.requests.single.uri.path,
      '/rest/v1/feedback_reports',
    );
    expect(
      client.requests.single.uri.queryParameters['select'],
      contains('technical_context'),
    );

    final body =
        jsonDecode(client.requests.single.body!) as Map<String, dynamic>;
    expect(body['id'], 'feedback-123');
    expect(body['user_id'], 'user-1');
    expect(body['category'], 'bug');
    expect(body['description'], 'A' * 20);
    expect(body['screenshot_path'], isNull);
    expect(body['contact_allowed'], isTrue);
    expect(
      body['technical_context'],
      <String, dynamic>{
        'appVersion': '1.2.3',
        'buildNumber': '456',
        'platform': 'android',
        'osVersion': '15',
        'deviceModel': 'Pixel 8',
        'appLocale': 'es_ES',
        'sourceRoute': '/feedback/new',
      },
    );
  });

  test('createFeedback forwards screenshotPath when provided', () async {
    final client = _RecordingHttpClient()
      ..enqueueJson(
        statusCode: 201,
        body: <String, dynamic>{
          'id': 'feedback-123',
          'user_id': 'user-1',
          'category': 'bug',
          'description': 'A' * 20,
          'screenshot_path':
              'user-1/feedback-123/screenshot_aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg',
          'contact_allowed': false,
          'status': 'submitted',
          'team_response': null,
          'technical_context': <String, dynamic>{
            'appVersion': '1.2.3',
            'buildNumber': '456',
            'platform': 'android',
            'osVersion': '15',
            'deviceModel': 'Pixel 8',
            'appLocale': 'es_ES',
            'sourceRoute': '/feedback/new',
          },
          'review_started_at': null,
          'closed_at': null,
          'created_at': '2026-08-30T12:00:00.000Z',
          'updated_at': '2026-08-30T12:00:00.000Z',
        },
      );
    final repository = SupabaseFeedbackRepository(
      client: SupabaseClient(
        'https://example.com',
        'anon-key',
        httpClient: client,
      ),
      currentUserIdProvider: () => 'user-1',
    );

    final result = await repository.createFeedback(
      id: 'feedback-123',
      category: FeedbackCategory.bug,
      description: 'A' * 20,
      screenshotPath:
          'user-1/feedback-123/screenshot_aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg',
      contactAllowed: false,
      technicalContext: const FeedbackTechnicalContext(
        appVersion: '1.2.3',
        buildNumber: '456',
        platform: 'android',
        osVersion: '15',
        deviceModel: 'Pixel 8',
        appLocale: 'es_ES',
        sourceRoute: '/feedback/new',
      ),
    );

    expect(result.isSuccess, isTrue);
    final body =
        jsonDecode(client.requests.single.body!) as Map<String, dynamic>;
    expect(
      body['screenshot_path'],
      'user-1/feedback-123/screenshot_aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg',
    );
  });

  test('createFeedback fails safely without an authenticated user', () async {
    final client = _RecordingHttpClient();
    final repository = SupabaseFeedbackRepository(
      client: SupabaseClient(
        'https://example.com',
        'anon-key',
        httpClient: client,
      ),
      currentUserIdProvider: () => null,
    );

    final result = await repository.createFeedback(
      id: 'feedback-123',
      category: FeedbackCategory.bug,
      description: 'A' * 20,
      screenshotPath: null,
      contactAllowed: false,
      technicalContext: const FeedbackTechnicalContext(
        appVersion: '1.2.3',
        buildNumber: '456',
        platform: 'android',
        osVersion: '15',
        deviceModel: 'Pixel 8',
        appLocale: 'es_ES',
        sourceRoute: '/feedback/new',
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.error?.code, RepositoryErrorCode.notAuthenticated);
    expect(client.requests, isEmpty);
  });

  test('createFeedback rejects empty ids before calling Supabase', () async {
    final client = _RecordingHttpClient();
    final repository = SupabaseFeedbackRepository(
      client: SupabaseClient(
        'https://example.com',
        'anon-key',
        httpClient: client,
      ),
      currentUserIdProvider: () => 'user-1',
    );

    final result = await repository.createFeedback(
      id: '   ',
      category: FeedbackCategory.bug,
      description: 'A' * 20,
      screenshotPath: null,
      contactAllowed: false,
      technicalContext: const FeedbackTechnicalContext(
        appVersion: '1.2.3',
        buildNumber: '456',
        platform: 'android',
        osVersion: '15',
        deviceModel: 'Pixel 8',
        appLocale: 'es_ES',
        sourceRoute: '/feedback/new',
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.error?.code, RepositoryErrorCode.invalidResponse);
    expect(client.requests, isEmpty);
  });

  test('getMyFeedback queries feedback_reports ordered by created_at desc',
      () async {
    final client = _RecordingHttpClient()
      ..enqueueJson(
        statusCode: 200,
        body: <Map<String, dynamic>>[
          _feedbackRow(
            id: 'feedback-2',
            userId: 'user-1',
            category: 'suggestion',
            description: 'Second report',
            status: 'in_review',
            createdAt: '2026-08-30T12:00:00.000Z',
            updatedAt: '2026-08-30T12:30:00.000Z',
            reviewStartedAt: '2026-08-30T12:15:00.000Z',
          ),
          _feedbackRow(
            id: 'feedback-1',
            userId: 'user-1',
            category: 'bug',
            description: 'First report',
            status: 'submitted',
            createdAt: '2026-08-29T10:00:00.000Z',
            updatedAt: '2026-08-29T10:05:00.000Z',
          ),
        ],
      );
    final repository = SupabaseFeedbackRepository(
      client: SupabaseClient(
        'https://example.com',
        'anon-key',
        httpClient: client,
      ),
      currentUserIdProvider: () => 'user-1',
    );

    final result = await repository.getMyFeedback();

    expect(result.isSuccess, isTrue);
    expect(result.data, hasLength(2));
    expect(result.data!.first.id, 'feedback-2');
    expect(result.data!.last.id, 'feedback-1');
    expect(result.data!.first.status, FeedbackStatus.inReview);
    expect(result.data!.last.status, FeedbackStatus.submitted);
    expect(result.data!.first.reviewStartedAt, isNotNull);
    expect(result.data!.first.teamResponse, isNull);
    expect(client.requests, hasLength(1));
    expect(client.requests.single.method, 'GET');
    expect(client.requests.single.uri.path, '/rest/v1/feedback_reports');
    expect(
      client.requests.single.uri.toString(),
      contains('order=created_at.desc'),
    );
  });

  test('getMyFeedback fails safely without an authenticated user', () async {
    final client = _RecordingHttpClient();
    final repository = SupabaseFeedbackRepository(
      client: SupabaseClient(
        'https://example.com',
        'anon-key',
        httpClient: client,
      ),
      currentUserIdProvider: () => null,
    );

    final result = await repository.getMyFeedback();

    expect(result.isSuccess, isFalse);
    expect(result.error?.code, RepositoryErrorCode.notAuthenticated);
    expect(client.requests, isEmpty);
  });

  test('getMyFeedback maps network-like Supabase errors', () async {
    final client = _RecordingHttpClient()
      ..enqueueJson(
        statusCode: 500,
        body: <String, dynamic>{
          'message': 'failed host lookup: example.com',
        },
      );
    final repository = SupabaseFeedbackRepository(
      client: SupabaseClient(
        'https://example.com',
        'anon-key',
        httpClient: client,
      ),
      currentUserIdProvider: () => 'user-1',
    );

    final result = await repository.getMyFeedback();

    expect(result.isSuccess, isFalse);
    expect(result.error?.code, RepositoryErrorCode.network);
  });

  test('getMyFeedback maps an unknown enum to invalidResponse', () async {
    final client = _RecordingHttpClient()
      ..enqueueJson(
        statusCode: 200,
        body: <Map<String, dynamic>>[
          _feedbackRow(
            id: 'feedback-1',
            userId: 'user-1',
            category: 'unexpected',
            description: 'Broken row',
            status: 'submitted',
            createdAt: '2026-08-29T10:00:00.000Z',
            updatedAt: '2026-08-29T10:05:00.000Z',
          ),
        ],
      );
    final repository = SupabaseFeedbackRepository(
      client: SupabaseClient(
        'https://example.com',
        'anon-key',
        httpClient: client,
      ),
      currentUserIdProvider: () => 'user-1',
    );

    final result = await repository.getMyFeedback();

    expect(result.isSuccess, isFalse);
    expect(result.error?.code, RepositoryErrorCode.invalidResponse);
  });
}

Map<String, dynamic> _feedbackRow({
  required String id,
  required String userId,
  required String category,
  required String description,
  required String status,
  required String createdAt,
  required String updatedAt,
  String? screenshotPath,
  bool contactAllowed = false,
  String? teamResponse,
  Map<String, dynamic>? technicalContext,
  String? reviewStartedAt,
  String? closedAt,
}) {
  return <String, dynamic>{
    'id': id,
    'user_id': userId,
    'category': category,
    'description': description,
    'screenshot_path': screenshotPath,
    'contact_allowed': contactAllowed,
    'status': status,
    'team_response': teamResponse,
    'technical_context': technicalContext,
    'review_started_at': reviewStartedAt,
    'closed_at': closedAt,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class _RecordingHttpClient extends http.BaseClient {
  final List<_QueuedResponse> _responses = <_QueuedResponse>[];
  final List<_RecordedRequest> requests = <_RecordedRequest>[];

  void enqueueJson({
    required int statusCode,
    required Object body,
    Map<String, String> headers = const <String, String>{
      'content-type': 'application/json',
    },
  }) {
    _responses.add(
      _QueuedResponse(
        statusCode: statusCode,
        body: jsonEncode(body),
        headers: headers,
      ),
    );
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    String? body;
    if (request is http.Request) {
      body = request.body;
    }
    requests.add(
      _RecordedRequest(
        method: request.method,
        uri: request.url,
        body: body,
      ),
    );

    if (_responses.isEmpty) {
      throw StateError(
          'No queued response for ${request.method} ${request.url}');
    }

    final next = _responses.removeAt(0);
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(next.body)),
      next.statusCode,
      request: request,
      headers: next.headers,
    );
  }
}

class _QueuedResponse {
  const _QueuedResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;
}

class _RecordedRequest {
  const _RecordedRequest({
    required this.method,
    required this.uri,
    required this.body,
  });

  final String method;
  final Uri uri;
  final String? body;
}
