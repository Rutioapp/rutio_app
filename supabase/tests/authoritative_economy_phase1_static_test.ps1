$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$migration = Join-Path $root 'migrations\20261017120000_authoritative_economy_phase1.sql'
$sql = Get-Content -Raw $migration

function Assert-Contains([string]$value, [string]$needle, [string]$message) {
  if (-not $value.Contains($needle)) { throw "FAIL: $message" }
}

function Assert-NotContains([string]$value, [string]$needle, [string]$message) {
  if ($value.Contains($needle)) { throw "FAIL: $message" }
}

Assert-Contains $sql 'create table if not exists public.economy_xp_ledger' 'XP ledger exists'
Assert-Contains $sql 'create table if not exists public.economy_habit_transition_ledger' 'transition ledger exists'
Assert-Contains $sql 'auth.uid()' 'identity comes from auth.uid'
Assert-Contains $sql 'complete_habit_economy_v1' 'single public habit entry point exists'
Assert-Contains $sql 'economy_assert_client_version' 'version policy is enforced'
Assert-Contains $sql 'economy_level_progress' 'level derives from authoritative XP'
Assert-Contains $sql 'refresh_authoritative_user_progress' 'projection is server refreshed'
Assert-Contains $sql 'request_id || '':xp''' 'XP event is bound to request id'
Assert-Contains $sql 'logical date is outside the allowed completion window' 'date window is fail-closed'
Assert-Contains $sql 'authoritative_achievement_unlocked' 'achievement eligibility is server-derived'
Assert-Contains $sql "special:flash" 'flash achievement is represented'
Assert-Contains $sql "special:turista" 'tourist achievement is represented'
Assert-Contains $sql "special:francotirados" 'exact-count achievement is represented'
Assert-Contains $sql "special:reloj_suizo" 'unsupported timestamp achievement remains explicit'
Assert-Contains $sql "special:ave_fenix" 'gap recovery achievement is represented'
Assert-Contains $sql "special:imparable" 'global streak achievement is represented'
Assert-Contains $sql "special:plusmarquista" 'habit streak achievement is represented'
Assert-Contains $sql "special:coleccionista" 'claimed-achievement count is represented'
Assert-Contains $sql 'authoritative_habit_completion_events' 'achievement queries use authoritative transitions'
Assert-Contains $sql 'default 31' 'offline historical window is bounded'
Assert-Contains $sql 'p_logical_date < (v_habit.created_at at time zone v_timezone)::date' 'completion cannot predate habit creation'
Assert-Contains $sql 'revoke insert, update, delete on table public.user_achievements' 'achievement rows are server-owned'
Assert-NotContains $sql 'p_xp' 'no XP parameter is accepted'
Assert-NotContains $sql 'p_coins' 'no coins parameter is accepted'
Assert-NotContains $sql 'delete from' 'phase 1 does not delete historical data'
Assert-NotContains $sql 'revenuecat_' 'phase 1 does not alter RevenueCat'
Assert-NotContains $sql 'drop table' 'phase 1 does not drop data structures'

# The migration must insert XP only inside the SECURITY DEFINER habit RPC.
if (($sql -split 'create or replace function public.complete_habit_economy_v1').Count -ne 2) {
  throw 'FAIL: expected one habit RPC definition'
}

Write-Output 'PASS: authoritative economy phase 1 static contract'
