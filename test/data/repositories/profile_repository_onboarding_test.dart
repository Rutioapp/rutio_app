import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rutio/data/models/remote/remote_profile.dart';
import 'package:rutio/data/repositories/profile_repository.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ProfileRepository onboarding state', () {
    test('markOnboardingInProgress updates the remote profile', () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(status: 'pending'),
        )
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(status: 'in_progress'),
        );
      final repository = _repository(client);

      final result = await repository.markOnboardingInProgress();

      expect(result.isSuccess, isTrue);
      expect(result.data!.onboardingStatus, OnboardingStatus.inProgress);
      expect(client.requests, hasLength(2));
      expect(client.requests.last.method, 'POST');
      final body =
          jsonDecode(client.requests.last.body!) as Map<String, dynamic>;
      expect(body['onboarding_status'], 'in_progress');
      expect(body['onboarding_version'], 1);
      expect(body['onboarding_completed_at'], isNull);
    });

    test('markOnboardingCompleted allows pending to completed', () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(status: 'pending'),
        )
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(
            status: 'completed',
            completedAt: '2026-07-27T21:35:00.000Z',
          ),
        );
      final repository = _repository(client);

      final result = await repository.markOnboardingCompleted();

      expect(result.isSuccess, isTrue);
      expect(result.data!.onboardingStatus, OnboardingStatus.completed);
      expect(
        result.data!.onboardingCompletedAt,
        DateTime.parse('2026-07-27T21:35:00.000Z'),
      );
      expect(client.requests, hasLength(2));
      expect(client.requests.last.method, 'PATCH');
      final body =
          jsonDecode(client.requests.last.body!) as Map<String, dynamic>;
      expect(body['onboarding_status'], 'completed');
      expect(body['onboarding_version'], 1);
      expect(body.containsKey('onboarding_completed_at'), isFalse);
    });

    test('markOnboardingCompleted allows in_progress to completed', () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(status: 'in_progress'),
        )
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(
            status: 'completed',
            completedAt: '2026-07-27T21:40:00.000Z',
          ),
        );
      final repository = _repository(client);

      final result = await repository.markOnboardingCompleted();

      expect(result.isSuccess, isTrue);
      expect(result.data!.onboardingStatus, OnboardingStatus.completed);
      expect(
        result.data!.onboardingCompletedAt,
        DateTime.parse('2026-07-27T21:40:00.000Z'),
      );
      expect(client.requests, hasLength(2));
      expect(client.requests.last.method, 'PATCH');
    });

    test('markOnboardingCompleted is idempotent for completed profiles',
        () async {
      const completedAt = '2026-07-27T21:30:00.000Z';
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(
            status: 'completed',
            completedAt: completedAt,
          ),
        )
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(
            status: 'completed',
            completedAt: completedAt,
          ),
        );
      final repository = _repository(client);

      final result = await repository.markOnboardingCompleted();

      expect(result.isSuccess, isTrue);
      expect(result.data!.onboardingStatus, OnboardingStatus.completed);
      expect(
        result.data!.onboardingCompletedAt,
        DateTime.parse(completedAt),
      );
      expect(client.requests, hasLength(2));
      expect(client.requests.last.method, 'PATCH');
      final body =
          jsonDecode(client.requests.last.body!) as Map<String, dynamic>;
      expect(body.containsKey('onboarding_completed_at'), isFalse);
    });

    test('blocks completed to in_progress regression', () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(
            status: 'completed',
            completedAt: '2026-07-27T21:30:00.000Z',
          ),
        );
      final repository = _repository(client);

      final result = await repository.markOnboardingInProgress();

      expect(result.isSuccess, isFalse);
      expect(result.error?.code, RepositoryErrorCode.invalidResponse);
      expect(result.error?.message, contains('completed onboarding'));
      expect(client.requests, hasLength(1));
    });

    test('blocks arbitrary onboarding version changes locally', () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(status: 'pending', version: 1),
        );
      final repository = _repository(client);

      final result = await repository.markOnboardingCompleted(
        onboardingVersion: 2,
      );

      expect(result.isSuccess, isFalse);
      expect(result.error?.code, RepositoryErrorCode.invalidResponse);
      expect(result.error?.message, contains('current remote version'));
      expect(client.requests, hasLength(1));
    });

    test('maps rejected onboarding transition from Supabase', () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(status: 'pending'),
        )
        ..enqueueJson(
          statusCode: 400,
          body: <String, dynamic>{
            'code': 'P0001',
            'message': 'invalid onboarding transition: pending to archived',
            'details': null,
            'hint': null,
          },
        );
      final repository = _repository(client);

      final result = await repository.markOnboardingCompleted();

      expect(result.isSuccess, isFalse);
      expect(result.error?.code, RepositoryErrorCode.invalidResponse);
      expect(result.error?.message, contains('invalid onboarding transition'));
      expect(client.requests, hasLength(2));
    });

    test('fetch maps invalid remote onboarding state as invalidResponse',
        () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(status: 'unexpected'),
        );
      final repository = _repository(client);

      final result = await repository.fetchCurrentProfile();

      expect(result.isSuccess, isFalse);
      expect(result.error?.code, RepositoryErrorCode.invalidResponse);
    });

    test('returns notFound when updating without a profile row', () async {
      final client = _QueueingHttpClient()
        ..enqueueRaw(statusCode: 200, body: 'null');
      final repository = _repository(client);

      final result = await repository.markOnboardingInProgress();

      expect(result.isSuccess, isFalse);
      expect(result.error?.code, RepositoryErrorCode.notFound);
    });
  });
}

ProfileRepository _repository(_QueueingHttpClient client) {
  return ProfileRepository(
    client: SupabaseClient(
      'https://example.com',
      'anon-key',
      httpClient: client,
    ),
    currentUserIdProvider: () => 'user-1',
  );
}

Map<String, dynamic> _profileRow({
  required String status,
  int version = 1,
  Object? completedAt,
}) {
  return <String, dynamic>{
    'id': 'user-1',
    'email': 'rutio@example.com',
    'display_name': 'Rutio',
    'onboarding_status': status,
    'onboarding_version': version,
    'onboarding_completed_at': completedAt,
    'created_at': '2026-07-27T20:00:00.000Z',
    'updated_at': '2026-07-27T20:00:00.000Z',
  };
}

class _QueueingHttpClient extends http.BaseClient {
  final List<_QueuedResponse> _responses = <_QueuedResponse>[];
  final List<_RecordedRequest> requests = <_RecordedRequest>[];

  void enqueueJson({
    required int statusCode,
    required Object body,
    Map<String, String> headers = const <String, String>{
      'content-type': 'application/json',
    },
  }) {
    enqueueRaw(
      statusCode: statusCode,
      body: jsonEncode(body),
      headers: headers,
    );
  }

  void enqueueRaw({
    required int statusCode,
    required String body,
    Map<String, String> headers = const <String, String>{
      'content-type': 'application/json',
    },
  }) {
    _responses.add(
      _QueuedResponse(
        statusCode: statusCode,
        body: body,
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
