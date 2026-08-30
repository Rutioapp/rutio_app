begin;

create temporary table feedback_test_state (
  user_a uuid,
  user_b uuid,
  feedback_a uuid,
  feedback_b uuid,
  feedback_c uuid,
  feedback_delete uuid,
  screenshot_a text,
  screenshot_delete text
) on commit drop;

create or replace function pg_temp.assert_true(
  p_condition boolean,
  p_message text
)
returns void
language plpgsql
as $$
begin
  if not p_condition then
    raise exception '%', p_message;
  end if;
end;
$$;

create or replace function pg_temp.assert_failure(
  p_sql text,
  p_expected_fragment text default null
)
returns void
language plpgsql
as $$
begin
  execute p_sql;
  raise exception 'expected failure but the statement succeeded: %', p_sql;
exception
  when others then
    if p_expected_fragment is not null
       and position(lower(p_expected_fragment) in lower(sqlerrm)) = 0 then
      raise exception 'unexpected error: %, expected fragment: %', sqlerrm, p_expected_fragment;
    end if;
end;
$$;

do $$
declare
  v_user_a uuid;
  v_user_b uuid;
  v_feedback_a uuid := gen_random_uuid();
  v_feedback_b uuid := gen_random_uuid();
  v_feedback_c uuid := gen_random_uuid();
  v_feedback_delete uuid := gen_random_uuid();
  v_screenshot_a text;
  v_screenshot_delete text;
  v_state_exists boolean;
begin
  select
    max(id) filter (where rn = 1),
    max(id) filter (where rn = 2)
  into v_user_a, v_user_b
  from (
    select
      id,
      row_number() over (order by created_at, id) as rn
    from auth.users
  ) as ordered_users;

  if v_user_a is null or v_user_b is null then
    raise exception 'need at least two auth.users rows for feedback tests';
  end if;

  v_screenshot_a :=
    v_user_a::text || '/' || v_feedback_a::text || '/screenshot_' || gen_random_uuid()::text || '.png';
  v_screenshot_delete :=
    v_user_a::text || '/' || v_feedback_delete::text || '/screenshot_' || gen_random_uuid()::text || '.png';

  insert into feedback_test_state (
    user_a,
    user_b,
    feedback_a,
    feedback_b,
    feedback_c,
    feedback_delete,
    screenshot_a,
    screenshot_delete
  )
  values (
    v_user_a,
    v_user_b,
    v_feedback_a,
    v_feedback_b,
    v_feedback_c,
    v_feedback_delete,
    v_screenshot_a,
    v_screenshot_delete
  );

  execute 'set role authenticated';
  perform set_config('request.jwt.claim.sub', v_user_a::text, true);

  insert into public.feedback_reports (
    id,
    user_id,
    category,
    description,
    screenshot_path,
    contact_allowed,
    status,
    team_response,
    technical_context
  )
  values (
    v_feedback_a,
    v_user_a,
    'bug',
    'This submitted feedback description is long enough for validation.',
    null,
    false,
    'submitted',
    null,
    '{}'::jsonb
  );

  insert into public.feedback_reports (
    id,
    user_id,
    category,
    description,
    screenshot_path,
    contact_allowed,
    status,
    team_response,
    technical_context
  )
  values (
    v_feedback_c,
    v_user_a,
    'improvement',
    'This second submitted feedback description is also long enough.',
    null,
    false,
    'submitted',
    null,
    '{}'::jsonb
  );

  insert into public.feedback_reports (
    id,
    user_id,
    category,
    description,
    screenshot_path,
    contact_allowed,
    status,
    team_response,
    technical_context
  )
  values (
    v_feedback_delete,
    v_user_a,
    'suggestion',
    'This submitted feedback is reserved for delete testing.',
    v_screenshot_delete,
    false,
    'submitted',
    null,
    '{}'::jsonb
  );

  perform set_config('request.jwt.claim.sub', v_user_b::text, true);

  insert into public.feedback_reports (
    id,
    user_id,
    category,
    description,
    screenshot_path,
    contact_allowed,
    status,
    team_response,
    technical_context
  )
  values (
    v_feedback_b,
    v_user_b,
    'other',
    'This submitted feedback belongs to user B and should stay hidden from A.',
    null,
    false,
    'submitted',
    null,
    '{}'::jsonb
  );

  perform set_config('request.jwt.claim.sub', v_user_a::text, true);

  select pg_temp.assert_true(
    (select count(*) from public.feedback_reports) = 3,
    'authenticated user A should only see their three own rows'
  );

  select pg_temp.assert_true(
    (select count(*) from public.feedback_reports where user_id = v_user_b) = 0,
    'authenticated user A must not see user B rows'
  );

  select pg_temp.assert_failure(
    format(
      $$insert into public.feedback_reports (
           id,
           user_id,
           category,
           description,
           screenshot_path,
           contact_allowed,
           status,
           team_response,
           technical_context
         ) values (
           gen_random_uuid(),
           %L::uuid,
           'bug',
           'This row tries to claim another user.',
           null,
           false,
           'submitted',
           null,
           '{}'::jsonb
         )$$,
      v_user_b::text
    ),
    'feedback must belong to the authenticated user'
  );

  select pg_temp.assert_failure(
    $$insert into public.feedback_reports (
         id,
         user_id,
         category,
         description,
         screenshot_path,
         contact_allowed,
         status,
         team_response,
         technical_context
       ) values (
         gen_random_uuid(),
         (select user_a from feedback_test_state),
         'bug',
         'This row tries to start in resolved.',
         null,
         false,
         'resolved',
         null,
         '{}'::jsonb
       )$$,
    'feedback must start in submitted'
  );

  select pg_temp.assert_failure(
    $$insert into public.feedback_reports (
         id,
         user_id,
         category,
         description,
         screenshot_path,
         contact_allowed,
         status,
         team_response,
         technical_context
       ) values (
         gen_random_uuid(),
         (select user_a from feedback_test_state),
         'bug',
         'This row tries to set team response on insert.',
         null,
         false,
         'submitted',
         'not allowed',
         '{}'::jsonb
       )$$,
    'team response must be null on insert'
  );

  select pg_temp.assert_failure(
    format(
      $$update public.feedback_reports
           set description = 'This attempted direct update should fail.'
         where id = %L::uuid$$,
      v_feedback_a::text
    ),
    'permission denied'
  );

  select pg_temp.assert_failure(
    format(
      $$delete from public.feedback_reports
         where id = %L::uuid$$,
      v_feedback_a::text
    ),
    'permission denied'
  );

  execute 'reset role';
end;
$$;

do $$
declare
  v_user_a uuid;
  v_feedback_a uuid;
  v_feedback_b uuid;
  v_feedback_delete uuid;
  v_screenshot_a text;
  v_screenshot_delete text;
  v_before_updated_at timestamptz;
  v_updated public.feedback_reports%rowtype;
begin
  select user_a, feedback_a, feedback_b, feedback_delete, screenshot_a, screenshot_delete
    into v_user_a, v_feedback_a, v_feedback_b, v_feedback_delete, v_screenshot_a, v_screenshot_delete
  from feedback_test_state;

  execute 'set role authenticated';
  perform set_config('request.jwt.claim.sub', v_user_a::text, true);

  select updated_at
    into v_before_updated_at
  from public.feedback_reports
  where id = v_feedback_a;

  select public.update_my_feedback(
    v_feedback_a,
    '  This submitted feedback description is now trimmed by the database.  ',
    v_screenshot_a,
    true
  ) into v_updated;

  perform pg_temp.assert_true(
    v_updated.description = 'This submitted feedback description is now trimmed by the database.',
    'update_my_feedback must trim description'
  );

  perform pg_temp.assert_true(
    v_updated.screenshot_path = v_screenshot_a,
    'update_my_feedback must keep a valid screenshot path'
  );

  perform pg_temp.assert_true(
    v_updated.contact_allowed is true,
    'update_my_feedback must persist contact_allowed'
  );

  perform pg_temp.assert_true(
    v_updated.status = 'submitted',
    'update_my_feedback must not change status'
  );

  perform pg_temp.assert_true(
    v_updated.updated_at > v_before_updated_at,
    'update_my_feedback must bump updated_at'
  );

  select pg_temp.assert_failure(
    format(
      $$select public.update_my_feedback(
           %L::uuid,
           'This submitted feedback description is still valid.',
           %L::text,
           true
         )$$,
      v_feedback_a::text,
      v_screenshot_delete
    ),
    'invalid screenshot path'
  );

  select pg_temp.assert_failure(
    format(
      $$select public.update_my_feedback(
           %L::uuid,
           'This submitted feedback description is still valid.',
           null,
           true
         )$$,
      v_feedback_b::text
    ),
    'feedback not found'
  );

  execute 'reset role';
end;
$$;

do $$
declare
  v_user_a uuid;
  v_feedback_a uuid;
  v_feedback_b uuid;
  v_feedback_c uuid;
  v_feedback_delete uuid;
  v_screenshot_a text;
  v_before_updated_at timestamptz;
  v_row public.feedback_reports%rowtype;
begin
  select user_a, feedback_a, feedback_b, feedback_c, feedback_delete, screenshot_a
    into v_user_a, v_feedback_a, v_feedback_b, v_feedback_c, v_feedback_delete, v_screenshot_a
  from feedback_test_state;

  select updated_at
    into v_before_updated_at
  from public.feedback_reports
  where id = v_feedback_a;

  update public.feedback_reports
     set status = 'in_review',
         review_started_at = timestamptz '2001-01-01 00:00:00+00',
         closed_at = timestamptz '2002-02-02 00:00:00+00'
   where id = v_feedback_a;

  select *
    into v_row
  from public.feedback_reports
  where id = v_feedback_a;

  perform pg_temp.assert_true(
    v_row.status = 'in_review',
    'submitted -> in_review must be allowed'
  );

  perform pg_temp.assert_true(
    v_row.review_started_at is not null,
    'submitted -> in_review must set review_started_at'
  );

  perform pg_temp.assert_true(
    v_row.review_started_at > v_row.created_at,
    'review_started_at must be assigned by the database'
  );

  perform pg_temp.assert_true(
    v_row.closed_at is null,
    'submitted -> in_review must keep closed_at null'
  );

  perform pg_temp.assert_true(
    v_row.description = 'This submitted feedback description is now trimmed by the database.',
    'submitted -> in_review must not change user description'
  );

  perform pg_temp.assert_true(
    v_row.category = 'bug',
    'submitted -> in_review must keep category immutable'
  );

  perform pg_temp.assert_true(
    v_row.updated_at > v_before_updated_at,
    'submitted -> in_review must bump updated_at'
  );

  perform pg_temp.assert_true(
    v_row.review_started_at <> timestamptz '2001-01-01 00:00:00+00',
    'review_started_at must not be caller controlled'
  );

  perform pg_temp.assert_true(
    v_row.closed_at is distinct from timestamptz '2002-02-02 00:00:00+00',
    'closed_at must not be caller controlled'
  );

  select pg_temp.assert_failure(
    format(
      $$update public.feedback_reports
           set status = 'submitted'
         where id = %L::uuid$$,
      v_feedback_a::text
    ),
    'invalid feedback transition: in_review to submitted'
  );

  execute 'set role authenticated';
  perform set_config('request.jwt.claim.sub', v_user_a::text, true);

  select pg_temp.assert_failure(
    format(
      $$select public.update_my_feedback(
           %L::uuid,
           'This submitted feedback description is still valid.',
           null,
           true
         )$$,
      v_feedback_a::text
    ),
    'feedback can only be edited while submitted'
  );

  execute 'reset role';

  select pg_temp.assert_failure(
    format(
      $$update public.feedback_reports
           set status = 'resolved'
         where id = %L::uuid$$,
      v_feedback_a::text
    ),
    'team response is required before closure'
  );

  select pg_temp.assert_failure(
    format(
      $$update public.feedback_reports
           set status = 'dismissed'
         where id = %L::uuid$$,
      v_feedback_a::text
    ),
    'team response is required before closure'
  );

  select updated_at
    into v_before_updated_at
  from public.feedback_reports
  where id = v_feedback_a;

  update public.feedback_reports
     set status = 'resolved',
         team_response = '  The team has reviewed this feedback.  ',
         review_started_at = timestamptz '2004-04-04 04:04:04+00',
         closed_at = timestamptz '2003-03-03 03:03:03+00'
   where id = v_feedback_a;

  select *
    into v_row
  from public.feedback_reports
  where id = v_feedback_a;

  perform pg_temp.assert_true(
    v_row.status = 'resolved',
    'in_review -> resolved must be allowed'
  );

  perform pg_temp.assert_true(
    v_row.team_response = 'The team has reviewed this feedback.',
    'team_response must be trimmed on closure'
  );

  perform pg_temp.assert_true(
    v_row.closed_at is not null,
    'closed_at must be set on closure'
  );

  perform pg_temp.assert_true(
    v_row.closed_at > v_row.created_at,
    'closed_at must be assigned by the database'
  );

  perform pg_temp.assert_true(
    v_row.review_started_at <> timestamptz '2001-01-01 00:00:00+00',
    'review_started_at must remain database-controlled'
  );

  perform pg_temp.assert_true(
    v_row.updated_at > v_before_updated_at,
    'closure must bump updated_at'
  );

  select pg_temp.assert_failure(
    format(
      $$update public.feedback_reports
           set description = 'This should never be possible after closure.'
         where id = %L::uuid$$,
      v_feedback_a::text
    ),
    'feedback reports are immutable after closure'
  );

  execute 'set role authenticated';
  perform set_config('request.jwt.claim.sub', v_user_a::text, true);

  select pg_temp.assert_failure(
    format(
      $$select public.delete_my_feedback(%L::uuid)$$,
      v_feedback_a::text
    ),
    'feedback can only be deleted while submitted'
  );

  execute 'reset role';

  select pg_temp.assert_failure(
    format(
      $$update public.feedback_reports
           set status = 'resolved'
         where id = %L::uuid$$,
      v_feedback_c::text
    ),
    'submitted feedback cannot be closed directly'
  );

  select pg_temp.assert_failure(
    format(
      $$update public.feedback_reports
           set status = 'dismissed'
         where id = %L::uuid$$,
      v_feedback_c::text
    ),
    'submitted feedback cannot be closed directly'
  );

  select pg_temp.assert_failure(
    format(
      $$update public.feedback_reports
           set status = 'in_review',
               description = 'This altered description should force a rejection.',
               category = 'other'
         where id = %L::uuid$$,
      v_feedback_c::text
    ),
    'submitted feedback content cannot change while moving to in_review'
  );

  select updated_at
    into v_before_updated_at
  from public.feedback_reports
  where id = v_feedback_c;

  update public.feedback_reports
     set status = 'in_review',
         review_started_at = timestamptz '2010-10-10 10:10:10+00',
         closed_at = timestamptz '2011-11-11 11:11:11+00'
   where id = v_feedback_c;

  select *
    into v_row
  from public.feedback_reports
  where id = v_feedback_c;

  perform pg_temp.assert_true(
    v_row.status = 'in_review',
    'second submitted -> in_review transition must be allowed'
  );

  perform pg_temp.assert_true(
    v_row.review_started_at is not null,
    'second review_started_at must be generated'
  );

  perform pg_temp.assert_true(
    v_row.review_started_at <> timestamptz '2010-10-10 10:10:10+00',
    'second review_started_at must not be caller controlled'
  );

  perform pg_temp.assert_true(
    v_row.closed_at is null,
    'second submitted -> in_review must keep closed_at null'
  );

  perform pg_temp.assert_true(
    v_row.updated_at > v_before_updated_at,
    'second transition must bump updated_at'
  );

  select pg_temp.assert_failure(
    format(
      $$update public.feedback_reports
           set status = 'submitted'
         where id = %L::uuid$$,
      v_feedback_c::text
    ),
    'invalid feedback transition: in_review to submitted'
  );

  select pg_temp.assert_failure(
    format(
      $$update public.feedback_reports
           set status = 'resolved'
         where id = %L::uuid$$,
      v_feedback_c::text
    ),
    'team response is required before closure'
  );

  select pg_temp.assert_failure(
    format(
      $$update public.feedback_reports
           set status = 'dismissed'
         where id = %L::uuid$$,
      v_feedback_c::text
    ),
    'team response is required before closure'
  );

  select updated_at
    into v_before_updated_at
  from public.feedback_reports
  where id = v_feedback_c;

  update public.feedback_reports
     set status = 'dismissed',
         team_response = '  The team has dismissed this feedback.  ',
         review_started_at = timestamptz '2020-01-01 00:00:00+00',
         closed_at = timestamptz '2020-02-02 00:00:00+00'
   where id = v_feedback_c;

  select *
    into v_row
  from public.feedback_reports
  where id = v_feedback_c;

  perform pg_temp.assert_true(
    v_row.status = 'dismissed',
    'in_review -> dismissed must be allowed'
  );

  perform pg_temp.assert_true(
    v_row.team_response = 'The team has dismissed this feedback.',
    'dismissal response must be trimmed'
  );

  perform pg_temp.assert_true(
    v_row.closed_at is not null,
    'dismissed feedback must get closed_at'
  );

  perform pg_temp.assert_true(
    v_row.closed_at <> timestamptz '2020-02-02 00:00:00+00',
    'closed_at must not be caller controlled on dismissal'
  );

  perform pg_temp.assert_true(
    v_row.updated_at > v_before_updated_at,
    'dismissal must bump updated_at'
  );

  select pg_temp.assert_failure(
    format(
      $$update public.feedback_reports
           set contact_allowed = false
         where id = %L::uuid$$,
      v_feedback_c::text
    ),
    'feedback reports are immutable after closure'
  );

end;
$$;

do $$
declare
  v_user_a uuid;
  v_feedback_a uuid;
  v_feedback_b uuid;
  v_feedback_delete uuid;
  v_screenshot_delete text;
  v_deleted_path text;
begin
  select user_a, feedback_a, feedback_b, feedback_delete, screenshot_delete
    into v_user_a, v_feedback_a, v_feedback_b, v_feedback_delete, v_screenshot_delete
  from feedback_test_state;

  execute 'set role authenticated';
  perform set_config('request.jwt.claim.sub', v_user_a::text, true);

  select public.delete_my_feedback(v_feedback_delete) into v_deleted_path;

  perform pg_temp.assert_true(
    v_deleted_path = v_screenshot_delete,
    'delete_my_feedback must return the screenshot_path'
  );

  perform pg_temp.assert_true(
    not exists (
      select 1
      from public.feedback_reports
      where id = v_feedback_delete
    ),
    'delete_my_feedback must delete the feedback row'
  );

  select pg_temp.assert_failure(
    format(
      $$select public.delete_my_feedback(%L::uuid)$$,
      v_feedback_b::text
    ),
    'feedback not found'
  );

  select pg_temp.assert_failure(
    format(
      $$select public.delete_my_feedback(%L::uuid)$$,
      v_feedback_a::text
    ),
    'feedback can only be deleted while submitted'
  );

  execute 'reset role';
end;
$$;

rollback;
