$ErrorActionPreference = 'Stop'
$migrationPath = Join-Path $PSScriptRoot '..\migrations\20261018110000_restore_level_reward_ambar_helper.sql'
$originalPath = Join-Path $PSScriptRoot '..\migrations\20260719150000_create_achievement_level_reward_ledger_and_rpcs.sql'
$claimPath = Join-Path $PSScriptRoot '..\migrations\20261018100000_sync_level_reward_user_progress.sql'
$migration = Get-Content -Raw $migrationPath
$original = Get-Content -Raw $originalPath
$claim = Get-Content -Raw $claimPath

function Assert-Contains([string]$Text, [string]$Needle, [string]$Message) {
  if (-not $Text.Contains($Needle)) { throw "FAIL: $Message" }
}
function Assert-NotContains([string]$Text, [string]$Needle, [string]$Message) {
  if ($Text.Contains($Needle)) { throw "FAIL: $Message" }
}

Assert-Contains $original 'create or replace function app_private.level_reward_ambar_for_level(' 'original helper definition missing'
Assert-Contains $original 'p_level = 5 then' 'level 5 contract missing from original'
Assert-Contains $original 'return 50;' 'level 5 reward missing from original'
Assert-Contains $migration 'create or replace function app_private.level_reward_ambar_for_level(' 'incremental helper definition missing'
foreach ($contract in @('p_level = 5 then','return 50;','p_level = 10 then','return 150;','p_level = 20 then','return 300;','p_level = 30 then','return 500;','p_level = 40 then','return 750;','p_level = 50 then','return 1000;','p_level > 50 and p_level % 10 = 0','return p_level * 20;')) {
  Assert-Contains $migration $contract "reward contract missing: $contract"
}
Assert-Contains $claim 'app_private.level_reward_ambar_for_level(v_level)' 'claim dependency missing'
Assert-Contains $claim 'app_private.economy_level_progress(v_total_xp)' 'authoritative level dependency missing'
Assert-Contains $claim 'public.economy_xp_ledger' 'XP ledger dependency missing'
Assert-Contains $claim 'public.user_wallets' 'wallet dependency missing'
Assert-Contains $claim 'public.achievement_level_reward_ledger' 'reward ledger dependency missing'
Assert-Contains $claim 'app_private.refresh_authoritative_user_progress(v_user_id)' 'projection dependency missing'
Assert-NotContains $migration 'grant execute' 'migration must not change permissions'
Assert-NotContains $migration 'alter table' 'migration must not change RLS/table configuration'
Assert-NotContains $migration 'insert into public.' 'migration must not write application data'
Assert-NotContains $migration 'kbjecrepjnmucljrpnlp' 'production reference must not appear'

'PASS: level reward helper contract and immediate dependencies are statically covered.'
