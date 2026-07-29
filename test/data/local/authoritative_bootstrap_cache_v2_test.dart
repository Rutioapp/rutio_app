import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rutio/data/local/authoritative_bootstrap_cache_v2.dart';
import 'package:rutio/data/models/remote/authoritative_bootstrap_decision.dart';
import 'package:rutio/data/models/remote/remote_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthoritativeBootstrapCacheCodecV2', () {
    test('round-trips a valid home decision', () {
      final now = DateTime.utc(2026, 7, 29, 12);
      final codec = AuthoritativeBootstrapCacheCodecV2(nowProvider: () => now);
      final entry =
          AuthoritativeBootstrapCacheEntryV2.fromAuthoritativeDecision(
        decision: _decision(
          decision: AuthoritativeBootstrapDestination.home,
          onboardingStatus: OnboardingStatus.completed,
          completedOnboardingVersion: 2,
          onboardingCompletedAt: DateTime.utc(2026, 7, 28, 10, 15),
        ),
        environmentId: 'dev',
        scopeKey: 'user-1|scope-1|1',
        cachedAt: DateTime.utc(2026, 7, 29, 11),
      );

      final decoded = codec.decode(
        codec.encode(entry),
        expectedUserId: 'user-1',
        expectedEnvironmentId: 'dev',
        expectedScopeKey: 'user-1|scope-1|1',
      );

      expect(decoded.status, AuthoritativeBootstrapCacheReadStatusV2.hit);
      expect(decoded.entry, isNotNull);
      expect(
          decoded.entry!.destination, AuthoritativeBootstrapDestination.home);
      expect(decoded.entry!.cachedAt, DateTime.utc(2026, 7, 29, 11));
      expect(decoded.entry!.expiresAt, DateTime.utc(2026, 7, 29, 17));
    });

    test('accepts pending onboarding and preserves scope key', () {
      final now = DateTime.utc(2026, 7, 29, 12);
      final codec = AuthoritativeBootstrapCacheCodecV2(nowProvider: () => now);
      final entry =
          AuthoritativeBootstrapCacheEntryV2.fromAuthoritativeDecision(
        decision: AuthoritativeBootstrapDecision(
          userId: 'user-1',
          decision: AuthoritativeBootstrapDestination.onboarding,
          accountStatus: BootstrapAccountStatus.active,
          profileState: BootstrapProfileState.ready,
          onboardingStatus: OnboardingStatus.pending,
          completedOnboardingVersion: null,
          requiredOnboardingVersion: 1,
          onboardingEnforcement: BootstrapOnboardingEnforcement.advisory,
          onboardingCompletedAt: null,
          profileRevision: 3,
          policyRevision: 4,
        ),
        environmentId: 'dev',
        scopeKey: 'user-1|scope-2|2',
        cachedAt: DateTime.utc(2026, 7, 29, 11),
      );

      final decoded = codec.decode(
        codec.encode(entry),
        expectedUserId: 'user-1',
        expectedEnvironmentId: 'dev',
        expectedScopeKey: 'user-1|scope-2|2',
      );

      expect(decoded.status, AuthoritativeBootstrapCacheReadStatusV2.hit);
      expect(decoded.entry!.matchesScopeKey('user-1|scope-2|2'), isTrue);
      expect(decoded.entry!.completedOnboardingVersion, 0);
      expect(decoded.entry!.onboardingStatus, OnboardingStatus.pending);
    });

    test('classifies expired entries without discarding the payload', () {
      final now = DateTime.utc(2026, 7, 29, 18);
      final codec = AuthoritativeBootstrapCacheCodecV2(nowProvider: () => now);
      final entry =
          AuthoritativeBootstrapCacheEntryV2.fromAuthoritativeDecision(
        decision: _decision(
          decision: AuthoritativeBootstrapDestination.home,
          onboardingStatus: OnboardingStatus.completed,
          completedOnboardingVersion: 1,
          onboardingCompletedAt: DateTime.utc(2026, 7, 28, 10, 15),
        ),
        environmentId: 'dev',
        scopeKey: 'user-1|scope-3|3',
        cachedAt: DateTime.utc(2026, 7, 29, 11),
      );

      final decoded = codec.decode(
        codec.encode(entry),
        expectedUserId: 'user-1',
        expectedEnvironmentId: 'dev',
        expectedScopeKey: 'user-1|scope-3|3',
      );

      expect(decoded.status, AuthoritativeBootstrapCacheReadStatusV2.expired);
      expect(decoded.entry, isNotNull);
      expect(decoded.entry!.isExpiredAt(now), isTrue);
    });

    test('rejects schema, identity, environment and enum mismatches', () {
      final now = DateTime.utc(2026, 7, 29, 12);
      final codec = AuthoritativeBootstrapCacheCodecV2(nowProvider: () => now);
      final entry =
          AuthoritativeBootstrapCacheEntryV2.fromAuthoritativeDecision(
        decision: _decision(),
        environmentId: 'dev',
        scopeKey: 'user-1|scope-4|4',
        cachedAt: DateTime.utc(2026, 7, 29, 11),
      );
      final raw = codec.encode(entry);

      expect(
        codec.decode(
          <String, dynamic>{...raw, 'schemaVersion': 1},
          expectedUserId: 'user-1',
          expectedEnvironmentId: 'dev',
          expectedScopeKey: 'user-1|scope-4|4',
        ).status,
        AuthoritativeBootstrapCacheReadStatusV2.schemaMismatch,
      );
      expect(
        codec.decode(
          <String, dynamic>{...raw, 'userId': 'user-2'},
          expectedUserId: 'user-1',
          expectedEnvironmentId: 'dev',
          expectedScopeKey: 'user-1|scope-4|4',
        ).status,
        AuthoritativeBootstrapCacheReadStatusV2.userMismatch,
      );
      expect(
        codec.decode(
          <String, dynamic>{...raw, 'environmentId': 'prod'},
          expectedUserId: 'user-1',
          expectedEnvironmentId: 'dev',
          expectedScopeKey: 'user-1|scope-4|4',
        ).status,
        AuthoritativeBootstrapCacheReadStatusV2.environmentMismatch,
      );
      expect(
        codec.decode(
          <String, dynamic>{...raw, 'destination': 'mystery'},
          expectedUserId: 'user-1',
          expectedEnvironmentId: 'dev',
          expectedScopeKey: 'user-1|scope-4|4',
        ).status,
        AuthoritativeBootstrapCacheReadStatusV2.unknownEnum,
      );
    });

    test('rejects incoherent contracts and invalid timestamps', () {
      final now = DateTime.utc(2026, 7, 29, 12);
      final codec = AuthoritativeBootstrapCacheCodecV2(nowProvider: () => now);
      final entry =
          AuthoritativeBootstrapCacheEntryV2.fromAuthoritativeDecision(
        decision: _decision(),
        environmentId: 'dev',
        scopeKey: 'user-1|scope-5|5',
        cachedAt: DateTime.utc(2026, 7, 29, 11),
      );
      final raw = codec.encode(entry);

      expect(
        codec.decode(
          <String, dynamic>{
            ...raw,
            'accountStatus': 'active',
            'profileState': 'ready',
            'onboardingStatus': 'completed',
            'completedOnboardingVersion': 0,
            'onboardingCompletedAt': null,
          },
          expectedUserId: 'user-1',
          expectedEnvironmentId: 'dev',
          expectedScopeKey: 'user-1|scope-5|5',
        ).status,
        AuthoritativeBootstrapCacheReadStatusV2.contractInvalid,
      );

      expect(
        codec.decode(
          <String, dynamic>{
            ...raw,
            'cachedAt': DateTime.utc(2026, 7, 29, 13).toIso8601String(),
          },
          expectedUserId: 'user-1',
          expectedEnvironmentId: 'dev',
          expectedScopeKey: 'user-1|scope-5|5',
        ).status,
        AuthoritativeBootstrapCacheReadStatusV2.contractInvalid,
      );

      expect(
        codec.decode(
          <String, dynamic>{
            ...raw,
            'expiresAt': DateTime.utc(2026, 7, 29, 10, 30).toIso8601String(),
          },
          expectedUserId: 'user-1',
          expectedEnvironmentId: 'dev',
          expectedScopeKey: 'user-1|scope-5|5',
        ).status,
        AuthoritativeBootstrapCacheReadStatusV2.contractInvalid,
      );

      expect(
        codec.decode(
          <String, dynamic>{
            ...raw,
            'expiresAt': DateTime.utc(2026, 7, 29, 20).toIso8601String(),
          },
          expectedUserId: 'user-1',
          expectedEnvironmentId: 'dev',
          expectedScopeKey: 'user-1|scope-5|5',
        ).status,
        AuthoritativeBootstrapCacheReadStatusV2.contractInvalid,
      );
    });

    test('rejects invalid JSON payloads safely', () {
      final codec = AuthoritativeBootstrapCacheCodecV2(
        nowProvider: () => DateTime.utc(2026, 7, 29, 12),
      );

      expect(
        codec
            .decode(
              jsonEncode(<dynamic>[1, 2, 3]),
              expectedUserId: 'user-1',
              expectedEnvironmentId: 'dev',
              expectedScopeKey: 'user-1|scope-5|5',
            )
            .status,
        AuthoritativeBootstrapCacheReadStatusV2.corrupt,
      );
      expect(
        codec.decode(
          <String, dynamic>{'schemaVersion': 'abc'},
          expectedUserId: 'user-1',
          expectedEnvironmentId: 'dev',
          expectedScopeKey: 'user-1|scope-5|5',
        ).status,
        AuthoritativeBootstrapCacheReadStatusV2.schemaMismatch,
      );
    });
  });

  group('SharedPreferencesAuthoritativeBootstrapCacheV2', () {
    test('isolates entries by environment and user and supports clear',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final devCache = SharedPreferencesAuthoritativeBootstrapCacheV2(
        environmentId: 'dev',
        nowProvider: () => DateTime.utc(2026, 7, 29, 12),
      );
      final prodCache = SharedPreferencesAuthoritativeBootstrapCacheV2(
        environmentId: 'prod',
        nowProvider: () => DateTime.utc(2026, 7, 29, 12),
      );
      final entry =
          AuthoritativeBootstrapCacheEntryV2.fromAuthoritativeDecision(
        decision: _decision(),
        environmentId: 'dev',
        scopeKey: 'user-1|scope-6|6',
        cachedAt: DateTime.utc(2026, 7, 29, 11),
      );

      await devCache.write(entry);

      final devRead = await devCache.read(
        'user-1',
        expectedScopeKey: 'user-1|scope-6|6',
      );
      final prodRead = await prodCache.read(
        'user-1',
        expectedScopeKey: 'user-1|scope-6|6',
      );

      expect(devRead.status, AuthoritativeBootstrapCacheReadStatusV2.hit);
      expect(prodRead.status, AuthoritativeBootstrapCacheReadStatusV2.notFound);
      expect(
        devCache.storageKeyForUser('user@example.com'),
        isNot(contains('@')),
      );

      await devCache.deleteForUser('user-1');
      expect(
        (await devCache.read(
          'user-1',
          expectedScopeKey: 'user-1|scope-6|6',
        )).status,
        AuthoritativeBootstrapCacheReadStatusV2.notFound,
      );

      await devCache.write(entry);
      await devCache.clear();
      expect(
        (await devCache.read(
          'user-1',
          expectedScopeKey: 'user-1|scope-6|6',
        )).status,
        AuthoritativeBootstrapCacheReadStatusV2.notFound,
      );
    });

    test('rejects writes for mismatched environments', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final cache = SharedPreferencesAuthoritativeBootstrapCacheV2(
        environmentId: 'dev',
      );
      final entry =
          AuthoritativeBootstrapCacheEntryV2.fromAuthoritativeDecision(
        decision: _decision(),
        environmentId: 'prod',
        scopeKey: 'user-1|scope-7|7',
        cachedAt: DateTime.utc(2026, 7, 29, 11),
      );

      await expectLater(
        cache.write(entry),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects scope mismatches and storage failures distinctly', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final cache = SharedPreferencesAuthoritativeBootstrapCacheV2(
        environmentId: 'dev',
        sharedPreferencesProvider: () async =>
            throw const AuthoritativeBootstrapCacheStorageException(
          'storage failed',
        ),
      );
      final entry =
          AuthoritativeBootstrapCacheEntryV2.fromAuthoritativeDecision(
        decision: _decision(),
        environmentId: 'dev',
        scopeKey: 'user-1|scope-8|8',
        cachedAt: DateTime.utc(2026, 7, 29, 11),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        cache.storageKeyForUser('user-1'),
        jsonEncode(entry.toJson()),
      );

      final scopeMismatchCache = SharedPreferencesAuthoritativeBootstrapCacheV2(
        environmentId: 'dev',
      );
      final scopeMismatchRead = await scopeMismatchCache.read(
        'user-1',
        expectedScopeKey: 'user-1|scope-9|9',
      );

      expect(
        scopeMismatchRead.status,
        AuthoritativeBootstrapCacheReadStatusV2.scopeMismatch,
      );
      expect(
        (await cache.read(
          'user-1',
          expectedScopeKey: 'user-1|scope-8|8',
        )).status,
        AuthoritativeBootstrapCacheReadStatusV2.storageError,
      );
    });
  });
}

AuthoritativeBootstrapDecision _decision({
  AuthoritativeBootstrapDestination decision =
      AuthoritativeBootstrapDestination.home,
  BootstrapAccountStatus accountStatus = BootstrapAccountStatus.active,
  BootstrapProfileState profileState = BootstrapProfileState.ready,
  OnboardingStatus? onboardingStatus = OnboardingStatus.completed,
  int? completedOnboardingVersion = 1,
  int requiredOnboardingVersion = 1,
  BootstrapOnboardingEnforcement onboardingEnforcement =
      BootstrapOnboardingEnforcement.required,
  DateTime? onboardingCompletedAt,
  int profileRevision = 3,
  int policyRevision = 4,
}) {
  return AuthoritativeBootstrapDecision(
    userId: 'user-1',
    decision: decision,
    accountStatus: accountStatus,
    profileState: profileState,
    onboardingStatus: onboardingStatus,
    completedOnboardingVersion: completedOnboardingVersion,
    requiredOnboardingVersion: requiredOnboardingVersion,
    onboardingEnforcement: onboardingEnforcement,
    onboardingCompletedAt:
        onboardingCompletedAt ?? DateTime.utc(2026, 7, 28, 10, 15),
    profileRevision: profileRevision,
    policyRevision: policyRevision,
  );
}
