import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/models/remote/remote_profile.dart';

void main() {
  group('RemoteProfile onboarding state', () {
    test('parses pending', () {
      final profile = RemoteProfile.fromMap(_profileRow(
        onboardingStatus: 'pending',
        completedAt: null,
      ));

      expect(profile.onboardingStatus, OnboardingStatus.pending);
      expect(profile.onboardingVersion, 1);
      expect(profile.onboardingCompletedAt, isNull);
    });

    test('parses in_progress', () {
      final profile = RemoteProfile.fromMap(_profileRow(
        onboardingStatus: 'in_progress',
        completedAt: null,
      ));

      expect(profile.onboardingStatus, OnboardingStatus.inProgress);
      expect(profile.onboardingCompletedAt, isNull);
    });

    test('parses completed with timestamp', () {
      final profile = RemoteProfile.fromMap(_profileRow(
        onboardingStatus: 'completed',
        completedAt: '2026-07-27T21:30:00.000Z',
      ));

      expect(profile.onboardingStatus, OnboardingStatus.completed);
      expect(
        profile.onboardingCompletedAt,
        DateTime.parse('2026-07-27T21:30:00.000Z'),
      );
      expect(profile.onboardingCompletedAt!.isUtc, isTrue);
    });

    test('rejects unknown status', () {
      expect(
        () => RemoteProfile.fromMap(_profileRow(
          onboardingStatus: 'done',
          completedAt: null,
        )),
        throwsA(isA<RemoteProfileParseException>()),
      );
    });

    test('rejects version lower than 1', () {
      expect(
        () => RemoteProfile.fromMap(_profileRow(
          onboardingStatus: 'pending',
          onboardingVersion: 0,
          completedAt: null,
        )),
        throwsA(isA<RemoteProfileParseException>()),
      );
    });

    test('rejects completed without timestamp', () {
      expect(
        () => RemoteProfile.fromMap(_profileRow(
          onboardingStatus: 'completed',
          completedAt: null,
        )),
        throwsA(isA<RemoteProfileParseException>()),
      );
    });

    test('rejects pending with timestamp', () {
      expect(
        () => RemoteProfile.fromMap(_profileRow(
          onboardingStatus: 'pending',
          completedAt: '2026-07-27T21:30:00.000Z',
        )),
        throwsA(isA<RemoteProfileParseException>()),
      );
    });

    test('rejects in_progress with timestamp', () {
      expect(
        () => RemoteProfile.fromMap(_profileRow(
          onboardingStatus: 'in_progress',
          completedAt: '2026-07-27T21:30:00.000Z',
        )),
        throwsA(isA<RemoteProfileParseException>()),
      );
    });

    test('serializes to Supabase values', () {
      final profile = RemoteProfile.fromMap(_profileRow(
        onboardingStatus: 'in_progress',
        onboardingVersion: 2,
        completedAt: null,
      ));

      final map = profile.toMap();

      expect(map['onboarding_status'], 'in_progress');
      expect(map['onboarding_version'], 2);
      expect(map.containsKey('onboarding_completed_at'), isFalse);
      expect(OnboardingStatus.completed.toSupabase(), 'completed');
    });
  });
}

Map<String, dynamic> _profileRow({
  required String onboardingStatus,
  required Object? completedAt,
  int onboardingVersion = 1,
}) {
  return <String, dynamic>{
    'id': 'user-1',
    'email': 'rutio@example.com',
    'display_name': 'Rutio',
    'onboarding_status': onboardingStatus,
    'onboarding_version': onboardingVersion,
    'onboarding_completed_at': completedAt,
    'created_at': '2026-07-27T20:00:00.000Z',
    'updated_at': '2026-07-27T20:00:00.000Z',
  };
}
