import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';

void main() {
  group('NotificationIdNamespace', () {
    final scopeA = NotificationScope(
      userId: 'user-a',
      scopeEpoch: 7,
      installId: 'install-a',
      locale: 'es',
    );
    final scopeB = NotificationScope(
      userId: 'user-b',
      scopeEpoch: 7,
      installId: 'install-a',
      locale: 'es',
    );

    test('builds stable keys with family and scope separation', () {
      final keyA = NotificationIdNamespace.buildNotificationKey(
        family: NotificationFamily.personalizedGeneral,
        kind: NotificationKind.generalDayClosure,
        scope: scopeA,
        entityRef: 'today',
        slot: 'slot_1',
      );
      final keyB = NotificationIdNamespace.buildNotificationKey(
        family: NotificationFamily.personalizedGeneral,
        kind: NotificationKind.generalDayClosure,
        scope: scopeB,
        entityRef: 'today',
        slot: 'slot_1',
      );

      expect(keyA, startsWith('rutio:v2:general:generalDayClosure:'));
      expect(keyA, isNot(keyB));
    });

    test('maps every family to a disjoint id range', () {
      expect(
        NotificationIdNamespace.rangeForFamily(NotificationFamily.habitReminder)
            .end,
        lessThan(
          NotificationIdNamespace.rangeForFamily(
            NotificationFamily.personalizedGeneral,
          ).start,
        ),
      );
      expect(
        NotificationIdNamespace.rangeForFamily(NotificationFamily.diary).end,
        lessThan(
          NotificationIdNamespace.rangeForFamily(
            NotificationFamily.weeklyReport,
          ).start,
        ),
      );
    });
  });

  group('NotificationPlatformIdAllocator', () {
    test('keeps repeated allocations deterministic for the same key', () {
      final allocator = NotificationPlatformIdAllocator();
      const key = 'rutio:v2:habit:habitReminder:abc123:habit_1:daily';

      final first = allocator.allocate(
        family: NotificationFamily.habitReminder,
        notificationKey: key,
      );
      final second = allocator.allocate(
        family: NotificationFamily.habitReminder,
        notificationKey: key,
      );

      expect(first, second);
      expect(
        NotificationIdNamespace.habitReminderRange.contains(first),
        isTrue,
      );
    });

    test('resolves collisions without leaving the family range', () {
      final seed = <String, int>{
        'taken-a': NotificationIdNamespace.personalizedGeneralRange.start,
        'taken-b': NotificationIdNamespace.personalizedGeneralRange.start + 1,
      };
      final allocator = NotificationPlatformIdAllocator(
        initialAssignments: seed,
      );

      final allocated = allocator.allocate(
        family: NotificationFamily.personalizedGeneral,
        notificationKey: 'rutio:v2:general:generalInactivity:x:y:z',
      );

      expect(allocated, isNot(seed['taken-a']));
      expect(allocated, isNot(seed['taken-b']));
      expect(
        NotificationIdNamespace.personalizedGeneralRange.contains(allocated),
        isTrue,
      );
    });

    test('allocates many ids without collisions across relevant families', () {
      final allocator = NotificationPlatformIdAllocator();
      final allIds = <int>{};

      for (final family in NotificationFamily.values) {
        for (var index = 0; index < 250; index += 1) {
          final key = 'rutio:v2:${family.name}:kind:$index:slot';
          final id = allocator.allocate(
            family: family,
            notificationKey: key,
          );
          expect(
            NotificationIdNamespace.rangeForFamily(family).contains(id),
            isTrue,
          );
          expect(allIds.add(id), isTrue, reason: 'duplicate id for $family');
        }
      }
    });
  });
}
