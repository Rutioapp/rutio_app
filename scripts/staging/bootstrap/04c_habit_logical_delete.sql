-- Rutio staging bootstrap 04C — logical habit deletion.
-- Structural/security-only migration. It does not delete or backfill rows.

begin;

revoke delete on table public.habits from public, anon, authenticated;

commit;
