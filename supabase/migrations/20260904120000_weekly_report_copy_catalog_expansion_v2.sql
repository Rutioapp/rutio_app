begin;

-- Expand the existing content_version=1 pools without changing the key
-- contract, selection algorithm, or any persisted report text.
insert into app_private.weekly_report_copy_catalog
  (message_key, family, content_version, sort_order)
select 'weekly_report_' || x.family_key || '_' || lpad(g.n::text, 2, '0'),
       x.family, 1, g.n
from (values
  ('summary_first_partial', 'summary_first_partial', 9, 18),
  ('summary_provisional', 'summary_provisional', 9, 18),
  ('summary_no_schedule', 'summary_no_schedule', 7, 14),
  ('summary_strong', 'summary_strong', 11, 20),
  ('summary_good', 'summary_good', 11, 20),
  ('summary_mixed', 'summary_mixed', 11, 20),
  ('summary_needs_recovery', 'summary_needs_recovery', 11, 20),
  ('summary_improved', 'summary_improved', 9, 18),
  ('summary_declined', 'summary_declined', 9, 18),
  ('habit_highlighted', 'habit_highlighted', 9, 16),
  ('habit_stable', 'habit_stable', 9, 16),
  ('habit_needs_attention', 'habit_needs_attention', 9, 16)
) as x(family_key, family, first_n, last_n)
cross join lateral generate_series(x.first_n, x.last_n) as g(n)
on conflict (message_key) do nothing;

revoke all on app_private.weekly_report_copy_catalog
  from public, anon, authenticated;

commit;
