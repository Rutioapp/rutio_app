import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const migrationPath =
      'supabase/migrations/20260727193000_neutralize_legacy_record_habit_log_rewards.sql';

  late String sql;
  late String normalized;

  setUpAll(() {
    sql = File(migrationPath).readAsStringSync();
    normalized = sql.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  });

  test('replaces the exact legacy record_habit_log signature', () {
    expect(normalized, contains('create or replace function public.record_habit_log( habit_id_input uuid, log_date_input date default current_date, value_input integer default null, is_completed_input boolean default null, note_input text default null )'));
    expect(normalized, contains('log_date_input date default current_date'));
    expect(normalized, contains('value_input integer default null'));
    expect(normalized, contains('is_completed_input boolean default null'));
    expect(normalized, contains('note_input text default null'));
    expect(normalized, contains('returns table ( habit_log_id uuid, habit_id uuid, log_date date, final_value integer, final_is_completed boolean, reward_was_granted boolean, xp_granted integer, ambar_granted integer, new_level integer, new_total_xp integer, new_ambar_balance integer )'));
    expect(normalized, contains('security definer'));
    expect(normalized, contains("set search_path = ''"));
    expect(normalized, contains('alter function public.record_habit_log(uuid, date, integer, boolean, text) owner to postgres'));
  });

  test('uses hardened fully qualified table and auth references', () {
    expect(normalized, contains('v_user_id uuid := auth.uid()'));
    expect(normalized, contains('v_habit public.habits%rowtype'));
    expect(normalized, contains('v_existing_log public.habit_logs%rowtype'));
    expect(normalized, contains('v_saved_log public.habit_logs%rowtype'));
    expect(normalized, contains('v_progress public.user_progress%rowtype'));
    expect(normalized, contains('from public.habits as h'));
    expect(normalized, contains('from public.habit_logs as hl'));
    expect(normalized, contains('from public.habit_logs as hl where hl.user_id = v_user_id and hl.habit_id = habit_id_input and hl.log_date = log_date_input for update'));
    expect(normalized, contains('from public.user_progress as up'));
  });

  test('preserves authentication and habit ownership guards', () {
    expect(normalized, contains('if v_user_id is null then'));
    expect(normalized, contains("raise exception 'authentication required'"));
    expect(normalized, contains('if habit_id_input is null then'));
    expect(normalized, contains('if log_date_input is null then'));
    expect(normalized, contains('if value_input is not null and value_input < 0 then'));
    expect(normalized, contains('if not found then raise exception'));
    expect(normalized, contains('if v_habit.user_id <> v_user_id then'));
    expect(normalized, contains('if coalesce(v_habit.is_archived, false) then'));
  });

  test('preserves check and count habit log computation', () {
    expect(normalized, contains("if v_habit.habit_type = 'check' then"));
    expect(normalized, contains('v_computed_is_completed := coalesce(is_completed_input, true)'));
    expect(normalized, contains('v_computed_value := case when v_computed_is_completed then 1 else 0 end'));
    expect(normalized, contains('v_target_count := greatest(coalesce(v_habit.target_count, 1), 1)'));
    expect(normalized, contains('v_computed_value := coalesce(value_input, v_existing_log.value, 0)'));
    expect(normalized, contains('v_computed_value >= v_target_count'));
  });

  test('preserves habit_logs upsert and manual source without legacy reward writes', () {
    expect(normalized, contains('insert into public.habit_logs ( user_id, habit_id, log_date, value, is_completed, note, completed_at, source )'));
    expect(normalized, contains('on conflict (user_id, habit_id, log_date) do update'));
    expect(normalized, contains('set value = excluded.value'));
    expect(normalized, contains('is_completed = excluded.is_completed'));
    expect(normalized, contains('note = coalesce(excluded.note, public.habit_logs.note)'));
    expect(normalized, contains('completed_at = case'));
    expect(normalized, contains("source = 'manual'"));
    expect(normalized, isNot(contains('reward_granted =')));
    expect(normalized, isNot(contains('xp_reward_granted =')));
    expect(normalized, isNot(contains('ambar_reward_granted =')));
  });

  test('neutralizes rewards while keeping compatible response fields', () {
    expect(normalized, contains('reward_was_granted := false'));
    expect(normalized, contains('xp_granted := 0'));
    expect(normalized, contains('ambar_granted := 0'));
    expect(normalized, contains('new_level := coalesce(v_progress.level, 1)'));
    expect(normalized, contains('new_total_xp := coalesce(v_progress.total_xp, 0)'));
    expect(normalized, contains('new_ambar_balance := coalesce(v_progress.ambar_balance, 0)'));
    expect(normalized, contains('return next'));
  });

  test('does not call or write legacy reward systems', () {
    expect(normalized, isNot(contains('grant_user_reward')));
    expect(normalized, isNot(contains('update public.user_progress')));
    expect(normalized, isNot(contains('insert into public.xp_events')));
    expect(normalized, isNot(contains('insert into public.currency_events')));
  });

  test('sets final record_habit_log execute grants only for server-compatible roles', () {
    expect(normalized, contains('revoke execute on function public.record_habit_log(uuid, date, integer, boolean, text) from public'));
    expect(normalized, contains('revoke execute on function public.record_habit_log(uuid, date, integer, boolean, text) from anon'));

    final grantExecuteMatches = RegExp(
      r'grant\s+execute\s+on\s+function\s+public\.record_habit_log\(uuid,\s*date,\s*integer,\s*boolean,\s*text\)\s+to\s+([a-z_]+)',
    ).allMatches(normalized).map((match) => match.group(1)).toList();

    expect(grantExecuteMatches, unorderedEquals(['authenticated', 'service_role']));
  });

  test('does not modify current cloud reward system or wallet tables', () {
    expect(normalized, isNot(contains('create or replace function public.apply_habit_completion_reward')));
    expect(normalized, isNot(contains('create or replace function public.reverse_habit_completion_reward')));
    expect(normalized, isNot(contains('public.user_wallets')));
    expect(normalized, isNot(contains('public.habit_currency_reward_ledger')));
  });
}
