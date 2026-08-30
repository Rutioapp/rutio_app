begin;

do $$
declare
  v_feedback_contract text := pg_get_functiondef(
    'app_private.enforce_feedback_report_contract()'::regprocedure
  );
  v_update_my_feedback text := pg_get_functiondef(
    'public.update_my_feedback(uuid, text, text, boolean)'::regprocedure
  );
  v_delete_my_feedback text := pg_get_functiondef(
    'public.delete_my_feedback(uuid)'::regprocedure
  );
begin
  if to_regtype('public.feedback_category') is null then
    raise exception 'public.feedback_category must exist';
  end if;

  if to_regtype('public.feedback_status') is null then
    raise exception 'public.feedback_status must exist';
  end if;

  if to_regclass('public.feedback_reports') is null then
    raise exception 'public.feedback_reports must exist';
  end if;

  if not exists (
    select 1
    from pg_attribute a
    join pg_attrdef d
      on d.adrelid = a.attrelid
     and d.adnum = a.attnum
    where a.attrelid = 'public.feedback_reports'::regclass
      and a.attname = 'technical_context'
      and a.attnotnull
      and lower(pg_get_expr(d.adbin, d.adrelid)) like '%{}%jsonb%'
  ) then
    raise exception 'feedback_reports.technical_context must be required and default to {}::jsonb';
  end if;

  if not exists (
    select 1
    from pg_attribute a
    join pg_attrdef d
      on d.adrelid = a.attrelid
     and d.adnum = a.attnum
    where a.attrelid = 'public.feedback_reports'::regclass
      and a.attname = 'status'
      and a.attnotnull
      and lower(pg_get_expr(d.adbin, d.adrelid)) like '%submitted%feedback_status%'
  ) then
    raise exception 'feedback_reports.status must default to submitted';
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.feedback_reports'::regclass
      and conname = 'feedback_reports_description_check'
      and pg_get_constraintdef(oid) like '%char_length%'
      and pg_get_constraintdef(oid) like '%btrim(description)%'
      and pg_get_constraintdef(oid) like '%20%'
      and pg_get_constraintdef(oid) like '%5000%'
  ) then
    raise exception 'feedback_reports.description check constraint must enforce trimmed length';
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.feedback_reports'::regclass
      and conname = 'feedback_reports_technical_context_check'
      and pg_get_constraintdef(oid) like '%jsonb_typeof%'
      and pg_get_constraintdef(oid) like '%object%'
  ) then
    raise exception 'feedback_reports.technical_context check constraint must require JSON objects';
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.feedback_reports'::regclass
      and conname = 'feedback_reports_screenshot_path_check'
      and pg_get_constraintdef(oid) like '%feedback_screenshot_path_is_valid%'
  ) then
    raise exception 'feedback_reports.screenshot_path check constraint must use the private validator';
  end if;

  if not exists (
    select 1
    from pg_index ix
    join pg_class c on c.oid = ix.indexrelid
    where ix.indrelid = 'public.feedback_reports'::regclass
      and c.relname = 'feedback_reports_user_created_idx'
      and lower(pg_get_indexdef(ix.indexrelid)) like '%(user_id, created_at desc)%'
  ) then
    raise exception 'feedback_reports_user_created_idx must exist on (user_id, created_at desc)';
  end if;

  if not exists (
    select 1
    from pg_index ix
    join pg_class c on c.oid = ix.indexrelid
    where ix.indrelid = 'public.feedback_reports'::regclass
      and c.relname = 'feedback_reports_status_created_idx'
      and lower(pg_get_indexdef(ix.indexrelid)) like '%(status, created_at)%'
  ) then
    raise exception 'feedback_reports_status_created_idx must exist on (status, created_at)';
  end if;

  if not exists (
    select 1
    from pg_class c
    where c.oid = 'public.feedback_reports'::regclass
      and c.relrowsecurity
  ) then
    raise exception 'public.feedback_reports must have row level security enabled';
  end if;

  if not exists (
    select 1
    from pg_trigger
    where tgrelid = 'public.feedback_reports'::regclass
      and tgname = 'trg_feedback_reports_enforce_contract'
      and not tgisinternal
      and lower(pg_get_triggerdef(oid)) like '%before insert or update%'
  ) then
    raise exception 'trg_feedback_reports_enforce_contract must exist as a BEFORE INSERT OR UPDATE trigger';
  end if;

  if lower(v_feedback_contract) not like '%security definer%'
     or lower(v_feedback_contract) not like '%set search_path = ''''%'
     or v_feedback_contract not like '%feedback reports are immutable after closure%'
     or v_feedback_contract not like '%submitted feedback cannot be closed directly%'
     or v_feedback_contract not like '%team response is required before closure%' then
    raise exception 'feedback trigger function must be SECURITY DEFINER with a locked search_path and the expected lifecycle guards';
  end if;

  if lower(v_update_my_feedback) not like '%security definer%'
     or lower(v_update_my_feedback) not like '%set search_path = ''''%'
     or v_update_my_feedback not like '%for update%'
     or v_update_my_feedback not like '%feedback can only be edited while submitted%'
     or v_update_my_feedback not like '%feedback not found%' then
    raise exception 'update_my_feedback must be SECURITY DEFINER, lock rows, and use stable error messages';
  end if;

  if lower(v_delete_my_feedback) not like '%security definer%'
     or lower(v_delete_my_feedback) not like '%set search_path = ''''%'
     or v_delete_my_feedback not like '%for update%'
     or lower(v_delete_my_feedback) not like '%feedback can only be deleted while submitted%'
     or lower(v_delete_my_feedback) not like '%return v_feedback.screenshot_path%' then
    raise exception 'delete_my_feedback must be SECURITY DEFINER, lock rows, and return screenshot_path';
  end if;

  if not has_table_privilege('authenticated', 'public.feedback_reports', 'SELECT')
     or not has_table_privilege('authenticated', 'public.feedback_reports', 'INSERT') then
    raise exception 'authenticated must be able to select and insert feedback_reports';
  end if;

  if has_table_privilege('authenticated', 'public.feedback_reports', 'UPDATE')
     or has_table_privilege('authenticated', 'public.feedback_reports', 'DELETE') then
    raise exception 'authenticated must not have direct UPDATE or DELETE on feedback_reports';
  end if;

  if has_table_privilege('anon', 'public.feedback_reports', 'SELECT')
     or has_table_privilege('anon', 'public.feedback_reports', 'INSERT')
     or has_table_privilege('anon', 'public.feedback_reports', 'UPDATE')
     or has_table_privilege('anon', 'public.feedback_reports', 'DELETE') then
    raise exception 'anon must not have feedback_reports table privileges';
  end if;

  if has_function_privilege('authenticated', 'public.update_my_feedback(uuid, text, text, boolean)'::regprocedure, 'EXECUTE') is false
     or has_function_privilege('authenticated', 'public.delete_my_feedback(uuid)'::regprocedure, 'EXECUTE') is false then
    raise exception 'authenticated must execute both public feedback RPCs';
  end if;

  if has_function_privilege('anon', 'public.update_my_feedback(uuid, text, text, boolean)'::regprocedure, 'EXECUTE')
     or has_function_privilege('anon', 'public.delete_my_feedback(uuid)'::regprocedure, 'EXECUTE')
     or has_function_privilege('public', 'public.update_my_feedback(uuid, text, text, boolean)'::regprocedure, 'EXECUTE')
     or has_function_privilege('public', 'public.delete_my_feedback(uuid)'::regprocedure, 'EXECUTE') then
    raise exception 'public and anon must not execute feedback RPCs';
  end if;

  if not exists (
    select 1
    from storage.buckets
    where id = 'feedback-screenshots'
      and name = 'feedback-screenshots'
      and public is false
      and file_size_limit = 5242880
      and allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
  ) then
    raise exception 'feedback-screenshots bucket must exist, be private, and enforce the expected MIME and size limits';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'feedback_screenshots_select_own'
      and cmd = 'SELECT'
      and roles @> array['authenticated']
  ) then
    raise exception 'storage SELECT policy for feedback screenshots must exist';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'feedback_screenshots_insert_own'
      and cmd = 'INSERT'
      and roles @> array['authenticated']
  ) then
    raise exception 'storage INSERT policy for feedback screenshots must exist';
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'feedback_screenshots_delete_unreferenced'
      and cmd = 'DELETE'
      and roles @> array['authenticated']
  ) then
    raise exception 'storage DELETE policy for feedback screenshots must exist';
  end if;

  if exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and cmd = 'UPDATE'
      and roles @> array['authenticated']
  ) then
    raise exception 'storage.objects must not have an authenticated UPDATE policy';
  end if;
end;
$$;

rollback;
