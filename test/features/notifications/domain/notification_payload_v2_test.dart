import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';

void main() {
  test('encodes and decodes payload v2 round trip', () {
    const payload = NotificationPayloadV2(
      schema: 2,
      family: NotificationFamily.personalizedGeneral,
      kind: NotificationKind.generalProgressNudge,
      logicalId: 'rutio:v2:general:generalProgressNudge:abc:today:morning',
      templateId: 'template-1',
      scopeHash: 'abc123',
      scopeEpoch: 4,
      categoryTag: 'encouragement',
      route: 'home',
    );

    expect(NotificationPayloadV2.tryParse(payload.encode()), payload);
  });

  test('returns null for malformed payload', () {
    expect(NotificationPayloadV2.tryParse('{bad json'), isNull);
  });

  test('returns null for unknown schema', () {
    expect(
      NotificationPayloadV2.tryParse(
        '{"schema":1,"family":"personalizedGeneral","kind":"generalProgressNudge"}',
      ),
      isNull,
    );
  });

  test('returns null for legacy payload strings', () {
    expect(NotificationPayloadV2.tryParse('habit:habit-1'), isNull);
  });

  test('returns null when required fields are missing', () {
    expect(
      NotificationPayloadV2.tryParse(
        '{"schema":2,"family":"personalizedGeneral","kind":"generalProgressNudge"}',
      ),
      isNull,
    );
  });
}
