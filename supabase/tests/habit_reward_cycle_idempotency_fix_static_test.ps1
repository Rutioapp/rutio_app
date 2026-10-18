$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$migrationPath = Join-Path $root 'migrations\20261017140000_habit_reward_cycle_idempotency_fix.sql'
$sql = (Get-Content -Raw $migrationPath).ToLowerInvariant()

function Assert-Contains([string]$value, [string]$needle, [string]$message) {
  if (-not $value.Contains($needle.ToLowerInvariant())) {
    throw "FAIL: $message"
  }
}

function Assert-NotContains([string]$value, [string]$needle, [string]$message) {
  if ($value.Contains($needle.ToLowerInvariant())) {
    throw "FAIL: $message"
  }
}

Assert-Contains $sql 'drop index if exists public.idx_habit_currency_reward_ledger_user_op_habit_date_unique' 'legacy logical index is replaced explicitly'
Assert-Contains $sql 'create unique index idx_habit_currency_reward_ledger_user_op_habit_date_event_unique' 'event-aware uniqueness replaces the legacy index'
Assert-Contains $sql 'completion_event_id' 'cycle identity is part of the replacement protection'
Assert-Contains $sql 'auth.uid()' 'reward ownership remains bound to the authenticated user'
Assert-Contains $sql 'pg_advisory_xact_lock' 'transactional advisory locks remain present'
Assert-Contains $sql 'security definer' 'reward functions remain security definer'
Assert-Contains $sql "set search_path = ''" 'reward functions keep an empty search path'
Assert-Contains $sql 'not exists (' 'reverse selects an active apply, not the oldest historical apply'
Assert-Contains $sql 'reverse_ledger.related_ledger_id = apply_ledger.id' 'reverse is linked to the apply it actually undoes'
Assert-Contains $sql 'and completion_event_id = v_completion_event_id' 'idempotency lookups include the transition event'
Assert-Contains $sql 'grant execute on function public.apply_habit_completion_reward' 'apply execute grants are restored'
Assert-Contains $sql 'grant execute on function public.reverse_habit_completion_reward' 'reverse execute grants are restored'
Assert-NotContains $sql 'drop table' 'migration does not delete tables'
Assert-NotContains $sql 'delete from' 'migration does not delete economic data'
Assert-NotContains $sql 'revenuecat_' 'migration does not alter RevenueCat'

if (($sql -split 'create or replace function public.apply_habit_completion_reward').Count -ne 2) {
  throw 'FAIL: expected one apply function definition'
}
if (($sql -split 'create or replace function public.reverse_habit_completion_reward').Count -ne 2) {
  throw 'FAIL: expected one reverse function definition'
}
if (-not $sql.TrimEnd().EndsWith('commit;')) {
  throw 'FAIL: migration must end with commit'
}

Write-Output 'PASS: habit reward cycle idempotency fix static contract'
