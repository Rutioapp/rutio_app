begin;

create temporary table feedback_storage_state (
  user_a uuid,
  user_b uuid,
  feedback_a uuid,
  feedback_review uuid,
  feedback_closed uuid,
  feedback_delete uuid,
  feedback_b uuid,
  object_a text,
  object_orphan text,
  object_review text,
  object_closed text,
  object_delete text,
  object_b text,
  replacement_path text
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

do $do$
declare
  v_user_a uuid;
  v_user_b uuid;
  v_feedback_a uuid := gen_random_uuid();
  v_feedback_review uuid := gen_random_uuid();
  v_feedback_closed uuid := gen_random_uuid();
  v_feedback_delete uuid := gen_random_uuid();
  v_feedback_b uuid := gen_random_uuid();
  v_object_a text;
  v_object_orphan text;
  v_object_review text;
  v_object_closed text;
  v_object_delete text;
  v_object_b text;
  v_replacement_path text;
begin
  select id
    into v_user_a
  from auth.users
  order by created_at, id
  limit 1;

  select id
    into v_user_b
  from auth.users
  order by created_at, id
  offset 1
  limit 1;

  if v_user_a is null or v_user_b is null then
    raise exception 'need at least two auth.users rows for storage tests';
  end if;

  v_object_a :=
    v_user_a::text || '/' || v_feedback_a::text || '/screenshot_' || gen_random_uuid()::text || '.png';
  v_object_orphan :=
    v_user_a::text || '/' || gen_random_uuid()::text || '/screenshot_' || gen_random_uuid()::text || '.png';
  v_object_review :=
    v_user_a::text || '/' || v_feedback_review::text || '/screenshot_' || gen_random_uuid()::text || '.png';
  v_object_closed :=
    v_user_a::text || '/' || v_feedback_closed::text || '/screenshot_' || gen_random_uuid()::text || '.png';
  v_object_delete :=
    v_user_a::text || '/' || v_feedback_delete::text || '/screenshot_' || gen_random_uuid()::text || '.png';
  v_object_b :=
    v_user_b::text || '/' || v_feedback_b::text || '/screenshot_' || gen_random_uuid()::text || '.png';
  v_replacement_path :=
    v_user_a::text || '/' || v_feedback_a::text || '/screenshot_' || gen_random_uuid()::text || '.png';

  insert into feedback_storage_state (
    user_a,
    user_b,
    feedback_a,
    feedback_review,
    feedback_closed,
    feedback_delete,
    feedback_b,
    object_a,
    object_orphan,
    object_review,
    object_closed,
    object_delete,
    object_b,
    replacement_path
  )
  values (
    v_user_a,
    v_user_b,
    v_feedback_a,
    v_feedback_review,
    v_feedback_closed,
    v_feedback_delete,
    v_feedback_b,
    v_object_a,
    v_object_orphan,
    v_object_review,
    v_object_closed,
    v_object_delete,
    v_object_b,
    v_replacement_path
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
    'This feedback owns the primary object for delete policy tests.',
    v_object_a,
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
    v_feedback_review,
    v_user_a,
    'suggestion',
    'This feedback will move into review for delete policy tests.',
    v_object_review,
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
    v_feedback_closed,
    v_user_a,
    'improvement',
    'This feedback will later be closed for delete policy tests.',
    v_object_closed,
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
    'other',
    'This feedback exists to prove delete_my_feedback unlocks its old object.',
    v_object_delete,
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
    'bug',
    'User B feedback stays separate for storage namespace tests.',
    v_object_b,
    false,
    'submitted',
    null,
    '{}'::jsonb
  );

  execute 'set role authenticated';
  perform set_config('request.jwt.claim.sub', v_user_a::text, true);

  insert into storage.objects (
    bucket_id,
    name,
    owner_id,
    metadata
  )
  values (
    'feedback-screenshots',
    v_object_a,
    v_user_a::text,
    '{}'::jsonb
  );

  insert into storage.objects (
    bucket_id,
    name,
    owner_id,
    metadata
  )
  values (
    'feedback-screenshots',
    v_object_orphan,
    v_user_a::text,
    '{}'::jsonb
  );

  insert into storage.objects (
    bucket_id,
    name,
    owner_id,
    metadata
  )
  values (
    'feedback-screenshots',
    v_object_review,
    v_user_a::text,
    '{}'::jsonb
  );

  insert into storage.objects (
    bucket_id,
    name,
    owner_id,
    metadata
  )
  values (
    'feedback-screenshots',
    v_object_closed,
    v_user_a::text,
    '{}'::jsonb
  );

  insert into storage.objects (
    bucket_id,
    name,
    owner_id,
    metadata
  )
  values (
    'feedback-screenshots',
    v_object_delete,
    v_user_a::text,
    '{}'::jsonb
  );

  perform set_config('request.jwt.claim.sub', v_user_b::text, true);

  insert into storage.objects (
    bucket_id,
    name,
    owner_id,
    metadata
  )
  values (
    'feedback-screenshots',
    v_object_b,
    v_user_b::text,
    '{}'::jsonb
  );

  execute 'reset role';
end;
$do$;

do $do$
declare
  v_user_a uuid;
  v_user_b uuid;
  v_object_a text;
  v_object_orphan text;
  v_object_review text;
  v_object_closed text;
  v_object_delete text;
  v_object_b text;
begin
  select user_a, user_b, object_a, object_orphan, object_review, object_closed, object_delete, object_b
    into v_user_a, v_user_b, v_object_a, v_object_orphan, v_object_review, v_object_closed, v_object_delete, v_object_b
  from feedback_storage_state;

  execute 'set role authenticated';
  perform set_config('request.jwt.claim.sub', v_user_a::text, true);

  perform pg_temp.assert_true(
    (select count(*) from storage.objects where name = v_object_a) = 1,
    'user A should be able to see its own object'
  );

  perform pg_temp.assert_true(
    (select count(*) from storage.objects where name = v_object_orphan) = 1,
    'user A should be able to see other objects in its namespace'
  );

  perform pg_temp.assert_true(
    (select count(*) from storage.objects where name = v_object_b) = 0,
    'user A must not see user B storage objects'
  );

  perform pg_temp.assert_failure(
    format(
      $$insert into storage.objects (
           bucket_id,
           name,
           owner_id,
           metadata
         ) values (
           'feedback-screenshots',
           %L::text,
           %L::text,
           '{}'::jsonb
         )$$,
      v_user_b::text || '/' || gen_random_uuid()::text || '/screenshot_' || gen_random_uuid()::text || '.png',
      v_user_b::text
    ),
    null
  );

  perform pg_temp.assert_failure(
    format(
      $$insert into storage.objects (
           bucket_id,
           name,
           owner_id,
           metadata
         ) values (
           'feedback-screenshots',
           %L::text,
           %L::text,
           '{}'::jsonb
         )$$,
      v_user_b::text || '/' || gen_random_uuid()::text || '/screenshot_' || gen_random_uuid()::text || '.png',
      v_user_a::text
    ),
    null
  );

  execute 'set role anon';

  perform pg_temp.assert_failure(
    format(
      $$select count(*) from storage.objects where name = %L::text$$,
      v_object_a
    ),
    null
  );

  perform pg_temp.assert_failure(
    format(
      $$insert into storage.objects (
           bucket_id,
           name,
           owner_id,
           metadata
         ) values (
           'feedback-screenshots',
           %L::text,
           %L::text,
           '{}'::jsonb
         )$$,
      v_user_a::text || '/' || gen_random_uuid()::text || '/screenshot_' || gen_random_uuid()::text || '.png',
      v_user_a::text
    ),
    null
  );

  execute 'reset role';

  perform pg_temp.assert_true(
    not exists (
      select 1
      from pg_policies
      where schemaname = 'storage'
        and tablename = 'objects'
        and cmd = 'UPDATE'
        and roles @> array['authenticated'::name]
    ),
    'storage.objects must not expose an authenticated UPDATE policy'
  );
end;
$do$;

do $do$
declare
  v_user_a uuid;
  v_user_b uuid;
  v_feedback_a uuid;
  v_feedback_review uuid;
  v_feedback_closed uuid;
  v_feedback_delete uuid;
  v_feedback_b uuid;
  v_object_a text;
  v_object_orphan text;
  v_object_review text;
  v_object_closed text;
  v_object_delete text;
  v_object_b text;
  v_replacement_path text;
  v_deleted_path text;
begin
  select
    user_a,
    user_b,
    feedback_a,
    feedback_review,
    feedback_closed,
    feedback_delete,
    feedback_b,
    object_a,
    object_orphan,
    object_review,
    object_closed,
    object_delete,
    object_b,
    replacement_path
  into
    v_user_a,
    v_user_b,
    v_feedback_a,
    v_feedback_review,
    v_feedback_closed,
    v_feedback_delete,
    v_feedback_b,
    v_object_a,
    v_object_orphan,
    v_object_review,
    v_object_closed,
    v_object_delete,
    v_object_b,
    v_replacement_path
  from feedback_storage_state;

  execute 'set role authenticated';
  perform set_config('request.jwt.claim.sub', v_user_a::text, true);

  perform pg_temp.assert_failure(
    format(
      $$delete from storage.objects
         where bucket_id = 'feedback-screenshots'
           and name = %L::text$$,
      v_object_a
    ),
    null
  );

  perform public.update_my_feedback(
    v_feedback_a,
    'This feedback owns the primary object for delete policy tests.',
    v_replacement_path,
    true
  );

  delete from storage.objects
   where bucket_id = 'feedback-screenshots'
     and name = v_object_a;

  perform pg_temp.assert_true(
    not exists (
      select 1
      from storage.objects
      where bucket_id = 'feedback-screenshots'
        and name = v_object_a
    ),
    'the old object should be deletable once feedback points elsewhere'
  );

  delete from storage.objects
   where bucket_id = 'feedback-screenshots'
     and name = v_object_orphan;

  perform pg_temp.assert_true(
    not exists (
      select 1
      from storage.objects
      where bucket_id = 'feedback-screenshots'
        and name = v_object_orphan
    ),
    'an orphaned object in the user namespace must be deletable'
  );

  execute 'reset role';

  update public.feedback_reports
     set status = 'in_review',
         review_started_at = timestamptz '2001-01-01 00:00:00+00',
         closed_at = timestamptz '2002-02-02 00:00:00+00'
   where id = v_feedback_review;

  update public.feedback_reports
     set status = 'dismissed',
         team_response = 'The team closed this example feedback.',
         review_started_at = timestamptz '2003-03-03 00:00:00+00',
         closed_at = timestamptz '2004-04-04 00:00:00+00'
   where id = v_feedback_closed;

  execute 'set role authenticated';
  perform set_config('request.jwt.claim.sub', v_user_a::text, true);

  perform pg_temp.assert_failure(
    format(
      $$delete from storage.objects
         where bucket_id = 'feedback-screenshots'
           and name = %L::text$$,
      v_object_review
    ),
    null
  );

  perform pg_temp.assert_failure(
    format(
      $$delete from storage.objects
         where bucket_id = 'feedback-screenshots'
           and name = %L::text$$,
      v_object_closed
    ),
    null
  );

  select public.delete_my_feedback(v_feedback_delete) into v_deleted_path;

  delete from storage.objects
   where bucket_id = 'feedback-screenshots'
     and name = v_object_delete;

  perform pg_temp.assert_true(
    not exists (
      select 1
      from storage.objects
      where bucket_id = 'feedback-screenshots'
        and name = v_object_delete
    ),
    'delete_my_feedback should unlock the old screenshot object'
  );

  perform pg_temp.assert_failure(
    format(
      $$delete from storage.objects
         where bucket_id = 'feedback-screenshots'
           and name = %L::text$$,
      v_object_b
    ),
    null
  );

  perform pg_temp.assert_true(
    v_deleted_path = v_object_delete,
    'delete_my_feedback must return the final screenshot_path'
  );

  execute 'reset role';
end;
$do$;

rollback;
