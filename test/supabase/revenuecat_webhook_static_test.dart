import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'RevenueCat webhook authenticates, queues Hybrid D work, and avoids raw payload logging',
      () {
    final source = File('supabase/functions/revenuecat-webhook/index.ts')
        .readAsStringSync();
    expect(source, contains('REVENUECAT_WEBHOOK_AUTHORIZATION'));
    expect(source, contains('constantTimeEqual'));
    expect(source, contains('REVENUECAT_ENVIRONMENT'));
    expect(source, contains('REVENUECAT_ALLOWED_USER_IDS'));
    expect(source, contains('enqueue_revenuecat_premium_sync'));
    expect(source, contains('apply_revenuecat_positive_event'));
    expect(source, contains('claim_revenuecat_webhook_event'));
    expect(source, contains('finalize_revenuecat_webhook_event'));
    final logic = File('supabase/functions/revenuecat-webhook/logic.ts')
        .readAsStringSync();
    expect(logic, contains('transferred_from'));
    expect(logic, contains('transferred_to'));
    expect(source, isNot(contains('console.log')));
  });

  test('identity attribution is restricted to Supabase UUID app user IDs', () {
    final logic = File('supabase/functions/revenuecat-webhook/logic.ts')
        .readAsStringSync();
    expect(logic, contains('^[0-9a-f]{8}-'));
    expect(logic, contains('parseAllowedUserIds'));
    expect(logic, contains('areIdentitiesAllowed'));
  });

  test('authenticated TEST events are acknowledged before identity or database work', () {
    final source = File('supabase/functions/revenuecat-webhook/index.ts')
        .readAsStringSync();
    final authIndex = source.indexOf(
        "if (!constantTimeEqual(request.headers.get('Authorization') ?? '', expected))");
    final appIndex = source.indexOf("value.app_id !== expectedAppId");
    final environmentIndex =
        source.indexOf('isExpectedWebhookEnvironment(value.environment, expectedEnvironment)');
    final testIndex = source.indexOf("if (type === 'TEST') return response({ accepted: true, test: true });");
    final identityIndex = source.indexOf('areIdentitiesAllowed(value, allowedUserIds)');
    final adminIndex = source.indexOf(
      'const admin = injectedAdmin ?? defaultAdminClient();',
    );
    expect(authIndex, greaterThanOrEqualTo(0));
    expect(appIndex, greaterThan(authIndex));
    expect(environmentIndex, greaterThan(appIndex));
    expect(testIndex, greaterThan(environmentIndex));
    expect(testIndex, lessThan(identityIndex));
    expect(testIndex, lessThan(adminIndex));
  });

  test('TEST events with incorrect Authorization are rejected before the TEST shortcut', () {
    final source = File('supabase/functions/revenuecat-webhook/index.ts')
        .readAsStringSync();
    final authIndex = source.indexOf(
        "if (!constantTimeEqual(request.headers.get('Authorization') ?? '', expected)) return response({ error: 'unauthorized' }, 401);");
    final testIndex = source.indexOf("if (type === 'TEST') return response({ accepted: true, test: true });");
    expect(authIndex, greaterThanOrEqualTo(0));
    expect(testIndex, greaterThan(authIndex));
    expect(source, contains("response({ error: 'unauthorized' }, 401)"));
  });
}
