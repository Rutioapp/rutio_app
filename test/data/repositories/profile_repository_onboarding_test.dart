import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rutio/data/local/bootstrap_profile_decision_cache.dart';
import 'package:rutio/data/models/remote/authoritative_bootstrap_decision.dart';
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

  group('ProfileRepository in-flight fetch dedupe', () {
    test('same user concurrent fetch shares one remote call', () async {
      final client = _BlockingHttpClient();
      var currentUserId = 'user-1';
      final repository = ProfileRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => currentUserId,
      );

      final first = repository.fetchCurrentProfile();
      final second = repository.fetchCurrentProfile();

      await Future<void>.delayed(Duration.zero);
      expect(client.callCount, 1);
      client.completeNextJson(
        _profileRow(
          status: 'completed',
          completedAt: '2026-07-27T21:35:00.000Z',
        ),
      );

      final firstResult = await first;
      final secondResult = await second;
      expect(firstResult.isSuccess, isTrue);
      expect(secondResult.isSuccess, isTrue);
      expect(firstResult.data?.id, 'user-1');
      expect(secondResult.data?.id, 'user-1');
    });

    test('concurrent failure is shared and next request can retry', () async {
      final client = _BlockingHttpClient();
      final repository = ProfileRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-1',
      );

      final first = repository.fetchCurrentProfile();
      final second = repository.fetchCurrentProfile();

      await Future<void>.delayed(Duration.zero);
      expect(client.callCount, 1);
      client.completeNextJson(_profileRow(status: 'unexpected'));

      final firstResult = await first;
      final secondResult = await second;
      expect(firstResult.isSuccess, isFalse);
      expect(firstResult.error?.code, RepositoryErrorCode.invalidResponse);
      expect(secondResult.isSuccess, isFalse);
      expect(secondResult.error?.code, RepositoryErrorCode.invalidResponse);

      final retry = repository.fetchCurrentProfile();
      await Future<void>.delayed(Duration.zero);
      expect(client.callCount, 2);
      client.completeNextJson(
        _profileRow(
          status: 'completed',
          completedAt: '2026-07-27T21:35:00.000Z',
        ),
      );
      final retryResult = await retry;
      expect(retryResult.isSuccess, isTrue);
    });

    test('different users do not share the same in-flight operation', () async {
      final client = _BlockingHttpClient();
      var currentUserId = 'user-1';
      final repository = ProfileRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => currentUserId,
      );

      final first = repository.fetchCurrentProfile();
      currentUserId = 'user-2';
      final second = repository.fetchCurrentProfile();

      await Future<void>.delayed(Duration.zero);
      expect(client.callCount, 2);
      client.completeMatchingJson(
        (request) => request.url.query.contains('eq.user-1'),
        _profileRow(
          status: 'completed',
          completedAt: '2026-07-27T21:35:00.000Z',
        ),
      );
      client.completeMatchingJson(
        (request) => request.url.query.contains('eq.user-2'),
        _profileRow(
          status: 'completed',
          completedAt: '2026-07-27T21:35:00.000Z',
        )..['id'] = 'user-2',
      );

      final firstResult = await first;
      final secondResult = await second;
      expect(firstResult.data?.id, 'user-1');
      expect(secondResult.data?.id, 'user-2');
    });
  });

  group('ProfileRepository bootstrap profile decision', () {
    test('selects only minimal columns for bootstrap decision', () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(
            status: 'completed',
            completedAt: '2026-07-27T21:35:00.000Z',
          ),
        );
      final repository = _repository(client);

      final result = await repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );

      expect(result.result.isSuccess, isTrue);
      expect(client.requests, hasLength(1));
      expect(
        client.requests.single.uri.queryParameters['select'],
        'id,onboarding_status,onboarding_version,onboarding_completed_at',
      );
    });

    test('same user concurrent decision fetch shares one remote call',
        () async {
      final client = _BlockingHttpClient();
      var currentUserId = 'user-1';
      final repository = ProfileRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => currentUserId,
      );

      final first = repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );
      final second = repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );

      await Future<void>.delayed(Duration.zero);
      expect(client.callCount, 1);
      client.completeNextJson(
        _profileRow(
          status: 'completed',
          completedAt: '2026-07-27T21:35:00.000Z',
        ),
      );

      final firstResult = await first;
      final secondResult = await second;
      expect(firstResult.result.isSuccess, isTrue);
      expect(secondResult.result.isSuccess, isTrue);
      expect(
        <int>[firstResult.remoteCallCount, secondResult.remoteCallCount],
        unorderedEquals(<int>[1, 0]),
      );
      expect(
        firstResult.deduplicatedLoadCount + secondResult.deduplicatedLoadCount,
        1,
      );
    });

    test('concurrent failure is shared and next decision request can retry',
        () async {
      final client = _BlockingHttpClient();
      final repository = ProfileRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-1',
      );

      final first = repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );
      final second = repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );

      await Future<void>.delayed(Duration.zero);
      expect(client.callCount, 1);
      client.completeNextJson(_profileRow(status: 'unexpected'));

      final firstResult = await first;
      final secondResult = await second;
      expect(firstResult.result.isSuccess, isFalse);
      expect(
        firstResult.result.error?.code,
        RepositoryErrorCode.invalidResponse,
      );
      expect(secondResult.result.isSuccess, isFalse);
      expect(
        secondResult.result.error?.code,
        RepositoryErrorCode.invalidResponse,
      );

      final retry = repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );
      await Future<void>.delayed(Duration.zero);
      expect(client.callCount, 2);
      client.completeNextJson(
        _profileRow(
          status: 'completed',
          completedAt: '2026-07-27T21:35:00.000Z',
        ),
      );
      final retryResult = await retry;
      expect(retryResult.result.isSuccess, isTrue);
      expect(retryResult.remoteCallCount, 1);
    });

    test('different users do not share the same decision operation', () async {
      final client = _BlockingHttpClient();
      var currentUserId = 'user-1';
      final repository = ProfileRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => currentUserId,
      );

      final first = repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );
      currentUserId = 'user-2';
      final second = repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-2',
        scopeEpoch: 1,
      );

      await Future<void>.delayed(Duration.zero);
      expect(client.callCount, 2);
      client.completeNextJson(
        _profileRow(
          status: 'completed',
          completedAt: '2026-07-27T21:35:00.000Z',
        ),
      );
      client.completeNextJson(
        _profileRow(
          status: 'completed',
          completedAt: '2026-07-27T21:35:00.000Z',
        )..['id'] = 'user-2',
      );

      final firstResult = await first;
      final secondResult = await second;
      expect(firstResult.remoteCallCount, 1);
      expect(secondResult.remoteCallCount, 1);
    });

    test('second compatible resolution uses memory and skips remote', () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(
            status: 'completed',
            completedAt: '2026-07-27T21:35:00.000Z',
          ),
        );
      final repository = _repository(client);

      final first = await repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );
      final second = await repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );

      expect(first.memoryMiss, isTrue);
      expect(first.memoryStored, isTrue);
      expect(first.remoteCallCount, 1);
      expect(second.memoryHit, isTrue);
      expect(second.remoteCallCount, 0);
      expect(client.requests, hasLength(1));
    });

    test('scope epoch change invalidates memory and forces a miss', () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(
            status: 'completed',
            completedAt: '2026-07-27T21:35:00.000Z',
          ),
        )
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(
            status: 'completed',
            completedAt: '2026-07-27T21:35:00.000Z',
          ),
        );
      final repository = _repository(client);

      await repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );
      final second = await repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 2,
      );

      expect(second.memoryHit, isFalse);
      expect(second.memoryMiss, isTrue);
      expect(
        second.memoryInvalidationReason,
        BootstrapProfileDecisionMemoryInvalidationReason.epochChanged,
      );
      expect(second.remoteCallCount, 1);
      expect(client.requests, hasLength(2));
    });

    test('explicit invalidation during query prevents stale memory store',
        () async {
      final client = _BlockingHttpClient();
      final cache = InMemoryBootstrapProfileDecisionCache();
      final repository = ProfileRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-1',
        bootstrapProfileDecisionCache: cache,
      );

      final pending = repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );
      await Future<void>.delayed(Duration.zero);
      await repository.invalidateBootstrapProfileDecisionMemory(
        userId: 'user-1',
        reason: BootstrapProfileDecisionMemoryInvalidationReason
            .explicitInvalidation,
        bumpSessionGeneration: true,
      );
      client.completeNextJson(
        _profileRow(
          status: 'completed',
          completedAt: '2026-07-27T21:35:00.000Z',
        ),
      );

      final first = await pending;
      final secondFuture = repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );
      await Future<void>.delayed(Duration.zero);
      client.completeNextJson(
        _profileRow(
          status: 'completed',
          completedAt: '2026-07-27T21:35:00.000Z',
        ),
      );
      final second = await secondFuture;

      expect(first.memoryStored, isFalse);
      expect(second.memoryHit, isFalse);
      expect(second.memoryMiss, isTrue);
      expect(cache.peek('user-1'), isNotNull);
    });

    test('shadow hit still performs one remote query on a fresh repository',
        () async {
      final cache = InMemoryBootstrapProfileDecisionCache();
      await cache.write(
        CachedBootstrapProfileDecision(
          cacheSchemaVersion:
              CachedBootstrapProfileDecision.currentSchemaVersion,
          userId: 'user-1',
          decision: BootstrapProfileDecision(
            userId: 'user-1',
            onboardingStatus: OnboardingStatus.completed,
            onboardingVersion: 1,
            onboardingCompletedAt: DateTime.parse(
              '2026-07-27T21:35:00.000Z',
            ),
          ),
          onboardingPolicyVersion: 1,
          remoteVerifiedAt: DateTime.parse('2026-07-28T08:00:00.000Z'),
          source: BootstrapProfileDecisionCacheSource.remoteDecision,
        ),
      );
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(
            status: 'completed',
            completedAt: '2026-07-27T21:35:00.000Z',
          ),
        );
      final repository = _repository(
        client,
        cache: cache,
        nowProvider: () => DateTime.parse('2026-07-28T09:00:00.000Z'),
      );

      final result = await repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );

      expect(result.persistentCacheRead, isTrue);
      expect(result.persistentCacheHitShadow, isTrue);
      expect(result.remoteCallCount, 1);
      expect(
        result.persistentCacheComparison,
        BootstrapProfilePersistentCacheComparison.match,
      );
      expect(client.requests, hasLength(1));
    });

    test('shadow miss performs one remote query and writes persistent cache',
        () async {
      final cache = InMemoryBootstrapProfileDecisionCache();
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(
            status: 'completed',
            completedAt: '2026-07-27T21:35:00.000Z',
          ),
        );
      final repository = _repository(client, cache: cache);

      final result = await repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );

      expect(result.persistentCacheRead, isTrue);
      expect(result.persistentCacheMiss, isTrue);
      expect(result.persistentCacheHitShadow, isFalse);
      expect(
        result.persistentCacheValidation,
        BootstrapProfileCacheValidation.missing,
      );
      expect(result.remoteCallCount, 1);
      expect(result.persistentCacheWrite, isTrue);
      expect(cache.peek('user-1')?.decision.onboardingStatus,
          OnboardingStatus.completed);
    });

    test('shadow invalid still performs one remote query', () async {
      final cache = InMemoryBootstrapProfileDecisionCache()
        ..seedCorrupt('user-1');
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: _profileRow(
            status: 'completed',
            completedAt: '2026-07-27T21:35:00.000Z',
          ),
        );
      final repository = _repository(client, cache: cache);

      final result = await repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );

      expect(
        result.persistentCacheValidation,
        BootstrapProfileCacheValidation.corrupt,
      );
      expect(result.persistentCacheHitShadow, isFalse);
      expect(result.remoteCallCount, 1);
      expect(result.persistentCacheWrite, isTrue);
    });

    test('remote missing deletes the persistent cache entry', () async {
      final cache = InMemoryBootstrapProfileDecisionCache();
      await cache.write(
        CachedBootstrapProfileDecision(
          cacheSchemaVersion:
              CachedBootstrapProfileDecision.currentSchemaVersion,
          userId: 'user-1',
          decision: BootstrapProfileDecision(
            userId: 'user-1',
            onboardingStatus: OnboardingStatus.completed,
            onboardingVersion: 1,
            onboardingCompletedAt: DateTime.parse(
              '2026-07-27T21:35:00.000Z',
            ),
          ),
          onboardingPolicyVersion: 1,
          remoteVerifiedAt: DateTime.parse('2026-07-28T08:00:00.000Z'),
          source: BootstrapProfileDecisionCacheSource.remoteDecision,
        ),
      );
      final client = _QueueingHttpClient()
        ..enqueueRaw(statusCode: 200, body: 'null');
      final repository = _repository(client, cache: cache);

      final result = await repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );

      expect(result.result.isSuccess, isTrue);
      expect(result.result.data, isNull);
      expect(result.persistentCacheDelete, isTrue);
      expect(cache.peek('user-1'), isNull);
    });

    test('logout removes only the current user persistent cache entry',
        () async {
      final cache = InMemoryBootstrapProfileDecisionCache();
      await cache.write(_cachedDecision('user-1'));
      await cache.write(_cachedDecision('user-2'));
      final repository = _repository(_QueueingHttpClient(), cache: cache);

      await repository.invalidateBootstrapProfileDecisionMemory(
        userId: 'user-1',
        reason: BootstrapProfileDecisionMemoryInvalidationReason.logout,
        bumpSessionGeneration: true,
      );

      expect(cache.peek('user-1'), isNull);
      expect(cache.peek('user-2'), isNotNull);
    });

    test('stale persistent write is discarded after invalidation', () async {
      final client = _BlockingHttpClient();
      final cache = _DelayedWriteBootstrapProfileDecisionCache();
      final repository = ProfileRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-1',
        bootstrapProfileDecisionCache: cache,
      );

      final pending = repository.fetchBootstrapProfileDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );
      await Future<void>.delayed(Duration.zero);
      client.completeNextJson(
        _profileRow(
          status: 'completed',
          completedAt: '2026-07-27T21:35:00.000Z',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await repository.invalidateBootstrapProfileDecisionMemory(
        userId: 'user-1',
        reason: BootstrapProfileDecisionMemoryInvalidationReason.logout,
        bumpSessionGeneration: true,
      );
      cache.releaseWrite();

      final result = await pending;

      expect(result.result.isSuccess, isTrue);
      expect(result.persistentCacheWrite, isFalse);
      expect(result.persistentCacheStaleDiscard, isTrue);
      expect(cache.peek('user-1'), isNull);
    });
  });

  group('ProfileRepository authoritative bootstrap decision', () {
    test('fetches the authoritative decision with no user params', () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: <dynamic>[
            _authoritativeRow(
              decision: 'home',
              onboardingStatus: 'completed',
              completedVersion: 1,
              completedAt: '2026-07-27T21:35:00.000Z',
            ),
          ],
        );
      final repository = _repository(client);

      final result = await repository.loadAuthoritativeBootstrapDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );

      expect(result.isSuccess, isTrue);
      expect(result.decision?.decision, AuthoritativeBootstrapDestination.home);
      expect(client.requests, hasLength(1));
      expect(client.requests.single.method, 'POST');
      expect(
        client.requests.single.uri.path,
        contains('/rpc/get_current_user_bootstrap_decision'),
      );
      expect(client.requests.single.body ?? '', isNot(contains('user_id')));
    });

    test('same user concurrent authoritative fetch shares one remote call',
        () async {
      final client = _BlockingHttpClient();
      var currentUserId = 'user-1';
      final repository = ProfileRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => currentUserId,
      );

      final first = repository.loadAuthoritativeBootstrapDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );
      final second = repository.loadAuthoritativeBootstrapDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );

      await Future<void>.delayed(Duration.zero);
      expect(client.callCount, 1);
      client.completeNextJson(
        <dynamic>[
          _authoritativeRow(
            decision: 'home',
            onboardingStatus: 'completed',
            completedVersion: 1,
            completedAt: '2026-07-27T21:35:00.000Z',
          ),
        ],
      );

      final firstResult = await first;
      final secondResult = await second;
      expect(firstResult.isSuccess, isTrue);
      expect(secondResult.isSuccess, isTrue);
      expect(
        <int>[firstResult.remoteCallCount, secondResult.remoteCallCount],
        unorderedEquals(<int>[1, 0]),
      );
      expect(
        firstResult.deduplicatedLoadCount + secondResult.deduplicatedLoadCount,
        1,
      );
    });

    test('authoritative fetch rejects empty and stale responses', () async {
      final emptyClient = _QueueingHttpClient()
        ..enqueueJson(statusCode: 200, body: <dynamic>[]);
      final emptyRepository = _repository(emptyClient);
      final emptyResult =
          await emptyRepository.loadAuthoritativeBootstrapDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );
      expect(emptyResult.isSuccess, isFalse);
      expect(
        emptyResult.error?.code,
        AuthoritativeBootstrapDecisionFailureCode.emptyResponse,
      );

      final staleClient = _BlockingHttpClient();
      var currentUserId = 'user-1';
      final staleRepository = ProfileRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: staleClient,
        ),
        currentUserIdProvider: () => currentUserId,
      );

      final pending = staleRepository.loadAuthoritativeBootstrapDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );
      await Future<void>.delayed(Duration.zero);
      currentUserId = 'user-2';
      expect(staleClient.callCount, 1);
      staleClient.completeNextJson(
        <dynamic>[
          _authoritativeRow(
            decision: 'home',
            onboardingStatus: 'completed',
            completedVersion: 1,
            completedAt: '2026-07-27T21:35:00.000Z',
          ),
        ],
      );

      final staleResult = await pending;
      expect(staleResult.isSuccess, isFalse);
      expect(
        staleResult.error?.code,
        AuthoritativeBootstrapDecisionFailureCode.staleResult,
      );
    });

    test('authoritative fetch accepts a single-row map response', () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: _authoritativeRow(
            decision: 'home',
            onboardingStatus: 'completed',
            completedVersion: 1,
            completedAt: '2026-07-27T21:35:00.000Z',
          ),
        );
      final repository = _repository(client);

      final result = await repository.loadAuthoritativeBootstrapDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );

      expect(result.isSuccess, isTrue);
      expect(result.decision?.decision, AuthoritativeBootstrapDestination.home);
      expect(client.requests, hasLength(1));
    });

    test('authoritative fetch rejects null and multi-row payloads', () async {
      final nullClient = _QueueingHttpClient()
        ..enqueueRaw(statusCode: 200, body: 'null');
      final nullRepository = _repository(nullClient);
      final nullResult =
          await nullRepository.loadAuthoritativeBootstrapDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );
      expect(nullResult.isSuccess, isFalse);
      expect(
        nullResult.error?.code,
        AuthoritativeBootstrapDecisionFailureCode.emptyResponse,
      );

      final multiClient = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: <dynamic>[
            _authoritativeRow(
              decision: 'home',
              onboardingStatus: 'completed',
              completedVersion: 1,
              completedAt: '2026-07-27T21:35:00.000Z',
            ),
            _authoritativeRow(
              decision: 'home',
              onboardingStatus: 'completed',
              completedVersion: 1,
              completedAt: '2026-07-27T21:35:00.000Z',
            ),
          ],
        );
      final multiRepository = _repository(multiClient);
      final multiResult =
          await multiRepository.loadAuthoritativeBootstrapDecision(
        scopeUserId: 'user-1',
        scopeEpoch: 1,
      );
      expect(multiResult.isSuccess, isFalse);
      expect(
        multiResult.error?.code,
        AuthoritativeBootstrapDecisionFailureCode.invalidPayload,
      );
    });
  });
}

ProfileRepository _repository(
  _QueueingHttpClient client, {
  BootstrapProfileDecisionCache? cache,
  DateTime Function()? nowProvider,
}) {
  return ProfileRepository(
    client: SupabaseClient(
      'https://example.com',
      'anon-key',
      httpClient: client,
    ),
    currentUserIdProvider: () => 'user-1',
    bootstrapProfileDecisionCache: cache,
    nowProvider: nowProvider,
  );
}

CachedBootstrapProfileDecision _cachedDecision(String userId) {
  return CachedBootstrapProfileDecision(
    cacheSchemaVersion: CachedBootstrapProfileDecision.currentSchemaVersion,
    userId: userId,
    decision: BootstrapProfileDecision(
      userId: userId,
      onboardingStatus: OnboardingStatus.completed,
      onboardingVersion: 1,
      onboardingCompletedAt: DateTime.parse('2026-07-27T21:35:00.000Z'),
    ),
    onboardingPolicyVersion: 1,
    remoteVerifiedAt: DateTime.parse('2026-07-28T08:00:00.000Z'),
    source: BootstrapProfileDecisionCacheSource.remoteDecision,
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

Map<String, dynamic> _authoritativeRow({
  required String decision,
  required String? onboardingStatus,
  required int? completedVersion,
  required Object? completedAt,
  String accountStatus = 'active',
  String profileState = 'ready',
  String onboardingEnforcement = 'required',
  int requiredVersion = 1,
  int profileRevision = 1,
  int policyRevision = 1,
}) {
  return <String, dynamic>{
    'user_id': 'user-1',
    'decision': decision,
    'account_status': accountStatus,
    'profile_state': profileState,
    'onboarding_status': onboardingStatus,
    'completed_onboarding_version': completedVersion,
    'required_onboarding_version': requiredVersion,
    'onboarding_enforcement': onboardingEnforcement,
    'onboarding_completed_at': completedAt,
    'profile_revision': profileRevision,
    'policy_revision': policyRevision,
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

class _BlockingHttpClient extends http.BaseClient {
  final List<_PendingBlockingResponse> _pendingResponses =
      <_PendingBlockingResponse>[];
  int callCount = 0;

  void completeNextJson(
    Object body, {
    int statusCode = 200,
    Map<String, String> headers = const <String, String>{
      'content-type': 'application/json',
    },
  }) {
    final pending = _pendingResponses.removeAt(0);
    final completer = pending.completer;
    completer.complete(
      http.StreamedResponse(
        Stream<List<int>>.value(utf8.encode(jsonEncode(body))),
        statusCode,
        request: pending.request,
        headers: headers,
      ),
    );
  }

  void completeMatchingJson(
    bool Function(http.BaseRequest request) predicate,
    Object body, {
    int statusCode = 200,
    Map<String, String> headers = const <String, String>{
      'content-type': 'application/json',
    },
  }) {
    final index = _pendingResponses.indexWhere(
      (pending) => predicate(pending.request),
    );
    if (index < 0) {
      throw StateError('No pending request matched the provided predicate.');
    }
    final pending = _pendingResponses.removeAt(index);
    pending.completer.complete(
      http.StreamedResponse(
        Stream<List<int>>.value(utf8.encode(jsonEncode(body))),
        statusCode,
        request: pending.request,
        headers: headers,
      ),
    );
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    callCount += 1;
    final completer = Completer<http.StreamedResponse>();
    _pendingResponses.add(
      _PendingBlockingResponse(
        request: request,
        completer: completer,
      ),
    );
    return completer.future;
  }
}

class _DelayedWriteBootstrapProfileDecisionCache
    extends InMemoryBootstrapProfileDecisionCache {
  final Completer<void> _writeBarrier = Completer<void>();

  void releaseWrite() {
    if (!_writeBarrier.isCompleted) {
      _writeBarrier.complete();
    }
  }

  @override
  Future<void> write(CachedBootstrapProfileDecision entry) async {
    await _writeBarrier.future;
    return super.write(entry);
  }
}

class _PendingBlockingResponse {
  const _PendingBlockingResponse({
    required this.request,
    required this.completer,
  });

  final http.BaseRequest request;
  final Completer<http.StreamedResponse> completer;
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
