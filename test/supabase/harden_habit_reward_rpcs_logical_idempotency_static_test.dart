import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260727200000_harden_habit_reward_rpcs_logical_idempotency.sql';

  late String sql;
  late String normalized;

  setUpAll(() {
    sql = File(migrationPath).readAsStringSync();
    normalized = sql.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  });

  String functionBody(String functionName) {
    final start =
        normalized.indexOf('create or replace function $functionName(');
    expect(start, isNonNegative, reason: '$functionName must be replaced');
    final end = normalized.indexOf('end; \$\$;', start);
    expect(end, isNonNegative, reason: '$functionName body must close');
    return normalized.substring(start, end);
  }

  test('replaces the exact habit reward RPC signatures only', () {
    expect(
      normalized,
      contains(
        'create or replace function public.apply_habit_completion_reward( p_request_id text, p_habit_id uuid, p_logical_date text, p_completion_event_id text, p_operation_type text )',
      ),
    );
    expect(
      normalized,
      contains(
        'create or replace function public.reverse_habit_completion_reward( p_request_id text, p_habit_id uuid, p_logical_date text, p_completion_event_id text, p_operation_type text )',
      ),
    );
    expect(
      normalized,
      allOf(
        contains('returns public.habit_currency_reward_ledger'),
        contains('security definer'),
        contains("set search_path = ''"),
      ),
    );
    expect(normalized, startsWith('begin;'));
    expect(normalized.trimRight(), endsWith('commit;'));
    expect(
      normalized,
      contains(
        'alter function public.apply_habit_completion_reward( text, uuid, text, text, text ) owner to postgres',
      ),
    );
    expect(
      normalized,
      contains(
        'alter function public.reverse_habit_completion_reward( text, uuid, text, text, text ) owner to postgres',
      ),
    );
  });

  test('does not qualify PostgreSQL conditional expressions', () {
    expect(normalized, isNot(contains('pg_catalog.coalesce')));
    expect(normalized, isNot(contains('pg_catalog.least')));
    expect(normalized, isNot(contains('pg_catalog.greatest')));
    expect(normalized, contains('pg_catalog.btrim(coalesce('));
    expect(normalized, contains('pg_catalog.lower('));
    expect(normalized, contains('pg_catalog.hashtext'));
    expect(normalized, contains('pg_catalog.now()'));
  });

  test('normalizes logical dates before locks and lookups', () {
    final apply = functionBody('public.apply_habit_completion_reward');
    final reverse = functionBody('public.reverse_habit_completion_reward');

    for (final body in <String>[apply, reverse]) {
      final normalizeIndex = body
          .indexOf('v_logical_date_key := (v_logical_date_key::date)::text');
      final lockIndex = body.indexOf('habit_currency_reward_logic:');
      final lookupIndex = body.indexOf('logical_date_key = v_logical_date_key');

      expect(normalizeIndex, isNonNegative);
      expect(lockIndex, isNonNegative);
      expect(lookupIndex, isNonNegative);
      expect(normalizeIndex, lessThan(lockIndex));
      expect(normalizeIndex, lessThan(lookupIndex));
    }
  });

  test('apply uses logical lock and logical idempotency before economics', () {
    final apply = functionBody('public.apply_habit_completion_reward');
    final logicalLockIndex = apply.indexOf('habit_currency_reward_logic:');
    final logicalLookupIndex = apply.indexOf(
      "and habit_id = v_habit_id and logical_date_key = v_logical_date_key and operation_type = 'apply'",
    );
    final rewardIndex = apply.indexOf(
      'from app_private.habit_completion_base_reward(v_habit.habit_type, v_habit.target_count)',
    );
    final walletUpdateIndex =
        apply.indexOf('update public.user_wallets set coins = v_balance_after');
    final boostUpdateIndex =
        apply.indexOf('update public.user_utility_effects set remaining_uses');

    expect(logicalLockIndex, isNonNegative);
    expect(logicalLookupIndex, isNonNegative);
    expect(rewardIndex, isNonNegative);
    expect(walletUpdateIndex, isNonNegative);
    expect(boostUpdateIndex, isNonNegative);
    expect(logicalLockIndex, lessThan(logicalLookupIndex));
    expect(logicalLookupIndex, lessThan(rewardIndex));
    expect(logicalLookupIndex, lessThan(walletUpdateIndex));
    expect(logicalLookupIndex, lessThan(boostUpdateIndex));
    expect(apply, contains('set is_idempotent = true'));
    expect(apply, contains('return v_existing'));
  });

  test('apply accepts legacy source ids through user habit date lookup', () {
    final apply = functionBody('public.apply_habit_completion_reward');
    expect(
      apply,
      contains(
        "where user_id = v_user_id and habit_id = v_habit_id and logical_date_key = v_logical_date_key and operation_type = 'apply' and source_type = 'habit_completion'",
      ),
    );
    expect(
      apply,
      isNot(
        contains(
          "and operation_type = 'apply' and source_type = 'habit_completion' and source_id = v_completion_event_id",
        ),
      ),
    );
  });

  test('apply recovers defensively from unique violation', () {
    final apply = functionBody('public.apply_habit_completion_reward');
    expect(apply, contains('when unique_violation then'));
    expect(
      apply,
      contains(
        "where request_id = v_request_id and user_id = v_user_id and operation_type = 'apply' and source_type = 'habit_completion' and habit_id = v_habit_id and logical_date_key = v_logical_date_key",
      ),
    );
    expect(
      apply,
      contains(
        "where user_id = v_user_id and habit_id = v_habit_id and logical_date_key = v_logical_date_key and operation_type = 'apply' and source_type = 'habit_completion'",
      ),
    );
  });

  test('reverse uses the shared logical lock and reverse logical lookup', () {
    final reverse = functionBody('public.reverse_habit_completion_reward');
    final logicalLockIndex = reverse.indexOf('habit_currency_reward_logic:');
    final reverseLookupIndex = reverse.indexOf(
      "and habit_id = v_habit_id and logical_date_key = v_logical_date_key and operation_type = 'reverse'",
    );
    final walletUpdateIndex = reverse
        .indexOf('update public.user_wallets set coins = v_balance_after');
    final restoreIndex = reverse.indexOf('foreach v_effect_id in array');

    expect(logicalLockIndex, isNonNegative);
    expect(reverseLookupIndex, isNonNegative);
    expect(walletUpdateIndex, isNonNegative);
    expect(restoreIndex, isNonNegative);
    expect(logicalLockIndex, lessThan(reverseLookupIndex));
    expect(reverseLookupIndex, lessThan(walletUpdateIndex));
    expect(reverseLookupIndex, lessThan(restoreIndex));
  });

  test('reverse finds the original apply by logical identity', () {
    final reverse = functionBody('public.reverse_habit_completion_reward');
    expect(
      reverse,
      contains(
        "into v_apply_ledger from public.habit_currency_reward_ledger where user_id = v_user_id and habit_id = v_habit_id and logical_date_key = v_logical_date_key and operation_type = 'apply' and source_type = 'habit_completion'",
      ),
    );
    expect(reverse,
        contains("raise exception 'original habit completion not found'"));
    expect(reverse, contains('v_apply_ledger.id'));
    expect(reverse, contains('related_ledger_id'));
  });

  test('reverse supports legacy shared request ids deterministically', () {
    final reverse = functionBody('public.reverse_habit_completion_reward');
    expect(reverse,
        contains("v_effective_request_id := v_request_id || ':reverse'"));
    expect(
      reverse,
      contains(
        "v_existing.operation_type = 'apply' and v_existing.source_type = 'habit_completion' and v_existing.habit_id = v_habit_id and v_existing.logical_date_key = v_logical_date_key",
      ),
    );
    expect(
        reverse, contains('v_restore_request_id := v_effective_request_id ||'));
    expect(reverse, contains('v_effective_request_id, v_user_id, \'reverse\''));
  });

  test('reverse restores boosts exactly from the original apply once', () {
    final reverse = functionBody('public.reverse_habit_completion_reward');
    expect(
      reverse,
      contains(
        "where user_id = v_user_id and habit_id = v_habit_id and logical_date_key = v_logical_date_key and operation_type = 'reverse' and source_type = 'habit_completion'",
      ),
    );
    expect(
      reverse,
      contains(
        "foreach v_effect_id in array coalesce(v_apply_ledger.applied_effect_ids, '{}'::uuid[]) loop",
      ),
    );
    expect(
      reverse,
      contains(
        "v_restore_source_id := v_apply_ledger.completion_event_id || ':' || v_effect.utility_id",
      ),
    );
    expect(
        reverse, contains("operation_type, source_type, source_id, effect_id"));
    expect(reverse, contains("'recover'"));
  });

  test('reverse recovers defensively from unique violation', () {
    final reverse = functionBody('public.reverse_habit_completion_reward');
    expect(reverse, contains('when unique_violation then'));
    expect(
      reverse,
      contains(
        "where request_id = v_effective_request_id and user_id = v_user_id and operation_type = 'reverse' and source_type = 'habit_completion' and habit_id = v_habit_id and logical_date_key = v_logical_date_key",
      ),
    );
  });

  test('uses fully qualified non-search-path references', () {
    expect(normalized, contains('v_user_id uuid := auth.uid()'));
    expect(normalized, contains('from public.habits'));
    expect(normalized, contains('from public.user_wallets'));
    expect(normalized, contains('from public.habit_currency_reward_ledger'));
    expect(normalized, contains('from public.user_utility_effects'));
    expect(
        normalized, contains('insert into public.utility_consumption_ledger'));
    expect(
        normalized, contains('from app_private.habit_completion_base_reward'));
    expect(normalized, contains('pg_catalog.pg_advisory_xact_lock'));
    expect(normalized, contains('pg_catalog.hashtext'));
  });

  test('idempotent returns use the current wallet balance without persistence',
      () {
    expect(
      normalized,
      isNot(
        contains(
          'update public.habit_currency_reward_ledger set balance_after',
        ),
      ),
    );
    expect(
      normalized,
      isNot(
        contains(
          'set balance_after =',
        ),
      ),
    );
    expect(
      RegExp(r'v_existing\.balance_after := v_wallet\.coins')
          .allMatches(normalized)
          .length,
      7,
    );

    final apply = functionBody('public.apply_habit_completion_reward');
    final reverse = functionBody('public.reverse_habit_completion_reward');
    expect(
      RegExp(r'v_existing\.balance_after := v_wallet\.coins')
          .allMatches(apply)
          .length,
      3,
    );
    expect(
      RegExp(r'v_existing\.balance_after := v_wallet\.coins')
          .allMatches(reverse)
          .length,
      4,
    );
    expect(
      RegExp(r'from public\.user_wallets where user_id = v_user_id')
          .allMatches(apply)
          .length,
      greaterThanOrEqualTo(4),
    );
    expect(
      RegExp(r'from public\.user_wallets where user_id = v_user_id')
          .allMatches(reverse)
          .length,
      greaterThanOrEqualTo(5),
    );
    expect(apply, contains("raise exception 'wallet missing for user'"));
    expect(reverse, contains("raise exception 'wallet missing for user'"));
  });

  test('sets deterministic owner and final execute grants', () {
    expect(
      normalized,
      contains(
        'alter function public.apply_habit_completion_reward( text, uuid, text, text, text ) owner to postgres',
      ),
    );
    expect(
      normalized,
      contains(
        'alter function public.reverse_habit_completion_reward( text, uuid, text, text, text ) owner to postgres',
      ),
    );

    for (final functionName in <String>[
      'apply_habit_completion_reward',
      'reverse_habit_completion_reward',
    ]) {
      for (final role in <String>[
        'public',
        'anon',
        'authenticated',
        'service_role',
      ]) {
        expect(
          normalized,
          contains(
            'revoke all on function public.$functionName( text, uuid, text, text, text ) from $role',
          ),
        );
      }
      expect(
        normalized,
        contains(
          'grant execute on function public.$functionName( text, uuid, text, text, text ) to authenticated',
        ),
      );
      expect(
        normalized,
        contains(
          'grant execute on function public.$functionName( text, uuid, text, text, text ) to service_role',
        ),
      );
    }
    expect(normalized,
        isNot(contains('grant insert on public.habit_currency_reward_ledger')));
    expect(normalized, isNot(contains('grant update on public.user_wallets')));
  });

  test('keeps this phase scoped away from schema, Flutter, and legacy economy',
      () {
    expect(normalized, isNot(contains('create index')));
    expect(normalized, isNot(contains('create unique index')));
    expect(normalized, isNot(contains('alter table')));
    expect(normalized, isNot(contains('add column')));
    expect(normalized, isNot(contains('record_habit_log')));
    expect(normalized, isNot(contains('grant_user_reward')));
    expect(normalized, isNot(contains('user_progress')));
    expect(normalized, isNot(contains('xp_events')));
    expect(normalized, isNot(contains('currency_events')));
    expect(normalized, isNot(contains('.dart')));
  });

  test('does not change reward or boost quantities', () {
    expect(normalized, contains('round(v_base_xp::numeric * 0.5)::integer'));
    expect(normalized, contains('ceil(v_base_coins::numeric * 0.5)::bigint'));
    expect(normalized, contains("utility_id = 'utility_xp_boost_1d'"));
    expect(normalized, contains("utility_id = 'utility_coin_boost_1d'"));
    expect(normalized, isNot(contains('base_xp := 10')));
    expect(normalized, isNot(contains('base_coins := 5')));
  });
}
