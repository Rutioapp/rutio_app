begin;

-- 20260903130000 added a six-argument overload with default parameters while
-- the five-argument private function from Phase 10 remained. Calls using four
-- or five arguments then become ambiguous inside the report triggers, so the
-- public current-week refresh fails before the generator can run.
drop function if exists app_private.weekly_report_pick_copy_key(
  uuid, date, text, integer, text
);

-- Keep the surviving overload private even if an earlier grant changes later.
revoke all on function app_private.weekly_report_pick_copy_key(
  uuid, date, text, integer, text, uuid
) from public, anon, authenticated;

commit;
