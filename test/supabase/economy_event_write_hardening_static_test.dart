import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _normalized(String value) =>
    value.replaceAll('\r\n', '\n').replaceAll('\r', '\n').toLowerCase();

void main() {
  test('event repositories expose reads but no client insert path', () {
    final xpRepository = _normalized(
      File('lib/data/repositories/xp_event_repository.dart').readAsStringSync(),
    );
    final currencyRepository = _normalized(
      File(
        'lib/data/repositories/currency_event_repository.dart',
      ).readAsStringSync(),
    );
    final syncService = _normalized(
      File(
        'lib/data/services/user_progress_sync_service.dart',
      ).readAsStringSync(),
    );

    expect(xpRepository, isNot(contains(".from(_xpeventstable).insert")));
    expect(
      currencyRepository,
      isNot(contains(".from(_currencyeventstable).insert")),
    );
    expect(syncService, isNot(contains('insertxpevent')));
    expect(syncService, isNot(contains('insertcurrencyevent')));
    expect(syncService, contains('xp_events is read-only for clients'));
    expect(syncService, contains('currency_events is read-only for clients'));
  });

  test('migration revokes client DML and legacy insert policies', () {
    final migration = _normalized(
      File(
        'supabase/migrations/20261012100000_revoke_client_event_writes.sql',
      ).readAsStringSync(),
    );

    expect(
      migration,
      contains(
        'revoke insert, update, delete on table public.xp_events from public, anon, authenticated',
      ),
    );
    expect(
      migration,
      contains(
        'revoke insert, update, delete on table public.currency_events from public, anon, authenticated',
      ),
    );
    expect(migration, contains('drop policy if exists xp_events_insert_own'));
    expect(
      migration,
      contains('drop policy if exists currency_events_insert_own'),
    );
  });

  test('analytics migration uses authoritative ledgers and canonical DAU', () {
    final migration = _normalized(
      File(
        'supabase/migrations/20261012110000_use_authoritative_ledgers_for_analytics.sql',
      ).readAsStringSync(),
    );

    expect(migration, contains('analytics_economic_movements'));
    expect(migration, contains('habit_currency_reward_ledger'));
    expect(migration, contains('achievement_level_reward_ledger'));
    expect(migration, contains('mystery_box_opening_ledger'));
    expect(migration, contains('shop_ledger'));
    expect(
        migration,
        contains(
            'grant select on public.analytics_economic_movements to service_role'));
    expect(migration, contains('from public.analytics_economic_movements m'));
    expect(migration, isNot(contains('from public.xp_events')));
    expect(migration, isNot(contains('from public.currency_events')));
    expect(migration, contains('economic events are not activity proxies'));
  });

  test('legacy event mirror has an explicit skipped outcome', () {
    final service = _normalized(
      File(
        'lib/data/services/user_progress_sync_service.dart',
      ).readAsStringSync(),
    );

    expect(service, contains('enum legacyeventsyncoutcome'));
    expect(service, contains('skippedlegacyeventwrite'));
    expect(service, isNot(contains('if (amount <= 0) return true')));
    expect(service, isNot(contains('if (amount == 0) return true')));
  });
}
