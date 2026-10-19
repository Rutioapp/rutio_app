$ErrorActionPreference = 'Stop'
$migration = Get-Content -Raw (Join-Path $PSScriptRoot '..\migrations\20261018100000_sync_level_reward_user_progress.sql')

function Assert-Contains([string]$Text, [string]$Needle, [string]$Message) {
  if (-not $Text.Contains($Needle)) { throw "FAIL: $Message" }
}
function Assert-Count([string]$Text, [string]$Needle, [int]$Expected, [string]$Message) {
  $actual = ([regex]::Matches($Text, [regex]::Escape($Needle))).Count
  if ($actual -ne $Expected) { throw "FAIL: $Message (expected $Expected, got $actual)" }
}

Assert-Contains $migration 'auth.uid()' 'identity is server-derived'
Assert-Contains $migration 'from public.economy_xp_ledger where user_id = v_user_id' 'eligibility uses authoritative XP ledger'
Assert-Contains $migration 'update public.user_wallets set coins = v_balance_after, version = version + 1' 'wallet remains the economic authority'
Assert-Contains $migration 'insert into public.achievement_level_reward_ledger' 'level reward ledger remains auditable'
Assert-Contains $migration 'perform app_private.refresh_authoritative_user_progress(v_user_id)' 'projection refresh is present'
Assert-Count $migration 'perform app_private.refresh_authoritative_user_progress(v_user_id)' 3 'new and both idempotent paths refresh projection'
Assert-Contains $migration 'where id = v_existing.id and not is_idempotent' 'idempotent replay does not insert a second ledger row'
Assert-Contains $migration 'pg_advisory_xact_lock(pg_catalog.hashtext(v_user_id::text))' 'same-user claims are serialized'
Assert-Contains $migration 'v_reward_ambar := app_private.level_reward_ambar_for_level(v_level)' 'reward mapping is unchanged'
if ($migration -match '(?i)inserts+intos+public.economy_xp_ledger') { throw 'FAIL: level claim must not write XP' }
if ($migration -match '(?i)grants+|revokes+|alters+table.*enables+rows+levels+security') { throw 'FAIL: migration must not change privileges or RLS' }

Write-Output 'PASS: level reward projection synchronization static contract'
