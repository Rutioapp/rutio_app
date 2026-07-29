import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rutio/data/local/bootstrap_profile_decision_cache.dart';
import 'package:rutio/data/models/remote/remote_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesBootstrapProfileDecisionCache', () {
    test('round-trips a valid entry and preserves UTC timestamp', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final cache = SharedPreferencesBootstrapProfileDecisionCache(
        environmentNamespace: 'dev',
      );
      final entry = _entry(
        remoteVerifiedAt: DateTime.parse('2026-07-28T10:15:30+02:00'),
      );

      await cache.write(entry);
      final read = await cache.read('user-a');

      expect(read.validation, BootstrapProfileCacheValidation.valid);
      expect(read.entry?.userId, 'user-a');
      expect(
        read.entry?.remoteVerifiedAt,
        DateTime.parse('2026-07-28T08:15:30.000Z'),
      );
      expect(
        read.entry?.decision.onboardingCompletedAt,
        DateTime.parse('2026-07-27T21:35:00.000Z'),
      );
    });

    test('rejects an incompatible schema version', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final cache = SharedPreferencesBootstrapProfileDecisionCache(
        environmentNamespace: 'dev',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        cache.storageKeyForUser('user-a'),
        jsonEncode(
          _entry().toJson()..['cacheSchemaVersion'] = 999,
        ),
      );

      final read = await cache.read('user-a');

      expect(read.validation, BootstrapProfileCacheValidation.schemaMismatch);
      expect(read.entry, isNull);
    });

    test('rejects missing user id and inconsistent user ids', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final cache = SharedPreferencesBootstrapProfileDecisionCache(
        environmentNamespace: 'dev',
      );
      final prefs = await SharedPreferences.getInstance();
      final missingUserId = _entry().toJson()..remove('userId');
      await prefs.setString(
        cache.storageKeyForUser('user-a'),
        jsonEncode(missingUserId),
      );

      final missingRead = await cache.read('user-a');
      expect(
        missingRead.validation,
        BootstrapProfileCacheValidation.incompleteDecision,
      );

      await prefs.setString(
        cache.storageKeyForUser('user-a'),
        jsonEncode(
          _entry().toJson()..['decision']['userId'] = 'user-b',
        ),
      );

      final mismatchedRead = await cache.read('user-a');
      expect(
        mismatchedRead.validation,
        BootstrapProfileCacheValidation.userMismatch,
      );
    });

    test('rejects incomplete decisions and unknown status', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final cache = SharedPreferencesBootstrapProfileDecisionCache(
        environmentNamespace: 'dev',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        cache.storageKeyForUser('user-a'),
        jsonEncode(
          _entry().toJson()..['decision']['onboardingVersion'] = null,
        ),
      );

      final incompleteRead = await cache.read('user-a');
      expect(
        incompleteRead.validation,
        BootstrapProfileCacheValidation.incompleteDecision,
      );

      await prefs.setString(
        cache.storageKeyForUser('user-a'),
        jsonEncode(
          _entry().toJson()..['decision']['onboardingStatus'] = 'archived',
        ),
      );

      final invalidStatusRead = await cache.read('user-a');
      expect(
        invalidStatusRead.validation,
        BootstrapProfileCacheValidation.invalidStatus,
      );
    });

    test('handles corrupt JSON safely', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final cache = SharedPreferencesBootstrapProfileDecisionCache(
        environmentNamespace: 'dev',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cache.storageKeyForUser('user-a'), '{broken');

      final read = await cache.read('user-a');

      expect(read.validation, BootstrapProfileCacheValidation.corrupt);
      expect(read.entry, isNull);
    });

    test('user isolation and environment namespace prevent cache reuse',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final devCache = SharedPreferencesBootstrapProfileDecisionCache(
        environmentNamespace: 'dev',
      );
      final prodCache = SharedPreferencesBootstrapProfileDecisionCache(
        environmentNamespace: 'prod',
      );

      await devCache.write(_entry(userId: 'user-a'));
      await devCache.write(_entry(userId: 'user-b'));

      final readA = await devCache.read('user-a');
      final readB = await devCache.read('user-b');
      final crossUserRead = await devCache.read('user-c');
      final otherEnvRead = await prodCache.read('user-a');

      expect(readA.validation, BootstrapProfileCacheValidation.valid);
      expect(readB.validation, BootstrapProfileCacheValidation.valid);
      expect(crossUserRead.validation, BootstrapProfileCacheValidation.missing);
      expect(otherEnvRead.validation, BootstrapProfileCacheValidation.missing);
      expect(
          devCache.storageKeyForUser('user@example.com'), isNot(contains('@')));
    });
  });
}

CachedBootstrapProfileDecision _entry({
  String userId = 'user-a',
  DateTime? remoteVerifiedAt,
}) {
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
    remoteVerifiedAt:
        (remoteVerifiedAt ?? DateTime.parse('2026-07-28T08:15:30.000Z'))
            .toUtc(),
    source: BootstrapProfileDecisionCacheSource.remoteDecision,
  );
}
