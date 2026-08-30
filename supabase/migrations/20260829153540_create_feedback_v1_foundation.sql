begin;

create extension if not exists pgcrypto;

create schema if not exists app_private;

revoke all on schema app_private from public;
revoke all on schema app_private from anon;
revoke all on schema app_private from authenticated;

create or replace function app_private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create type public.feedback_category as enum (
  'bug',
  'suggestion',
  'improvement',
  'other'
);

create type public.feedback_status as enum (
  'submitted',
  'in_review',
  'resolved',
  'dismissed'
);

create or replace function app_private.feedback_screenshot_path_is_valid(
  p_user_id uuid,
  p_feedback_id uuid,
  p_screenshot_path text
)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select
    p_screenshot_path is null
    or (
      p_user_id is not null
      and p_feedback_id is not null
      and btrim(p_screenshot_path) = p_screenshot_path
      and split_part(p_screenshot_path, '/', 1) = p_user_id::text
      and split_part(p_screenshot_path, '/', 2) = p_feedback_id::text
      and array_length(storage.foldername(p_screenshot_path), 1) = 2
      and (storage.foldername(p_screenshot_path))[1] = p_user_id::text
      and (storage.foldername(p_screenshot_path))[2] = p_feedback_id::text
      and storage.filename(p_screenshot_path) ~ '^screenshot_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|jpeg|png|webp)$'
      and storage.extension(p_screenshot_path) in ('jpg', 'jpeg', 'png', 'webp')
    );
$$;

comment on function app_private.feedback_screenshot_path_is_valid(uuid, uuid, text) is
  'Internal predicate that validates the canonical feedback screenshot path for a given user and feedback row. It only checks structure and namespace ownership; the Storage API still handles the actual object data.';

revoke execute on function app_private.feedback_screenshot_path_is_valid(uuid, uuid, text)
from public;
revoke execute on function app_private.feedback_screenshot_path_is_valid(uuid, uuid, text)
from anon;
revoke execute on function app_private.feedback_screenshot_path_is_valid(uuid, uuid, text)
from authenticated;

create table if not exists public.feedback_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category public.feedback_category not null,
  description text not null,
  screenshot_path text null,
  contact_allowed boolean not null default false,
  status public.feedback_status not null default 'submitted',
  team_response text null,
  technical_context jsonb not null default '{}'::jsonb,
  review_started_at timestamptz null,
  closed_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint feedback_reports_description_check
    check (
      char_length(btrim(description)) between 20 and 5000
    ),
  constraint feedback_reports_technical_context_check
    check (jsonb_typeof(technical_context) = 'object'),
  constraint feedback_reports_screenshot_path_check
    check (
      app_private.feedback_screenshot_path_is_valid(
        user_id,
        id,
        screenshot_path
      )
    )
);

comment on table public.feedback_reports is
  'Authoritative feedback records owned by authenticated users. State transitions, timestamps, and deletions are governed by PostgreSQL.';
comment on column public.feedback_reports.user_id is
  'Owning auth.users.id. The trigger and RLS require feedback rows to belong to the authenticated user for client writes.';
comment on column public.feedback_reports.category is
  'Canonical feedback category for routing and triage.';
comment on column public.feedback_reports.description is
  'Trimmed user description. The database stores the canonical btrim(description) value.';
comment on column public.feedback_reports.screenshot_path is
  'Optional private Storage object path. If present it must stay inside the owning user namespace and match the row id.';
comment on column public.feedback_reports.contact_allowed is
  'Whether the user permits follow-up contact.';
comment on column public.feedback_reports.status is
  'Authoritative lifecycle status. submitted is the only client-created state. resolved and dismissed are terminal.';
comment on column public.feedback_reports.team_response is
  'Internal or public-facing team response. It is normalized with btrim() when written and becomes immutable after closure.';
comment on column public.feedback_reports.technical_context is
  'Extensible technical payload. V1 only requires a JSON object and does not validate keys.';

create index if not exists feedback_reports_user_created_idx
  on public.feedback_reports (user_id, created_at desc);

create index if not exists feedback_reports_status_created_idx
  on public.feedback_reports (status, created_at);

create or replace function app_private.enforce_feedback_report_contract()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if tg_op = 'INSERT' then
    if v_user_id is null then
      raise exception 'authentication required';
    end if;

    if new.user_id is not null and new.user_id is distinct from v_user_id then
      raise exception 'feedback must belong to the authenticated user';
    end if;

    new.id := coalesce(new.id, gen_random_uuid());
    new.user_id := v_user_id;
    new.category := new.category;
    new.description := btrim(new.description);
    new.screenshot_path := btrim(new.screenshot_path);
    new.contact_allowed := coalesce(new.contact_allowed, false);

    if new.status is null then
      new.status := 'submitted';
    elsif new.status <> 'submitted' then
      raise exception 'feedback must start in submitted';
    end if;

    if new.team_response is not null then
      raise exception 'team response must be null on insert';
    end if;

    if new.technical_context is null then
      new.technical_context := '{}'::jsonb;
    end if;

    if new.review_started_at is not null then
      raise exception 'review_started_at is managed by the database';
    end if;

    if new.closed_at is not null then
      raise exception 'closed_at is managed by the database';
    end if;

    if jsonb_typeof(new.technical_context) is distinct from 'object' then
      raise exception 'technical_context must be a JSON object';
    end if;

    if new.description is null
       or char_length(new.description) < 20
       or char_length(new.description) > 5000 then
      raise exception 'description must be between 20 and 5000 characters';
    end if;

    if not app_private.feedback_screenshot_path_is_valid(
      new.user_id,
      new.id,
      new.screenshot_path
    ) then
      raise exception 'invalid screenshot path';
    end if;

    new.team_response := null;
    new.review_started_at := null;
    new.closed_at := null;
    new.created_at := statement_timestamp();
    new.updated_at := statement_timestamp();
    return new;
  end if;

  if old.status in ('resolved', 'dismissed') then
    raise exception 'feedback reports are immutable after closure';
  end if;

  if new.id is distinct from old.id
     or new.user_id is distinct from old.user_id
     or new.category is distinct from old.category
     or new.created_at is distinct from old.created_at
     or new.technical_context is distinct from old.technical_context then
    raise exception 'immutable feedback fields cannot be changed';
  end if;

  new.description := btrim(new.description);
  new.screenshot_path := btrim(new.screenshot_path);
  new.contact_allowed := coalesce(new.contact_allowed, false);
  new.team_response := nullif(btrim(new.team_response), '');

  if new.description is null
     or char_length(new.description) < 20
     or char_length(new.description) > 5000 then
    raise exception 'description must be between 20 and 5000 characters';
  end if;

  if not app_private.feedback_screenshot_path_is_valid(
    old.user_id,
    old.id,
    new.screenshot_path
  ) then
    raise exception 'invalid screenshot path';
  end if;

  if new.status = old.status and new.status = 'submitted' then
    if new.review_started_at is not null then
      raise exception 'review_started_at is managed by the database';
    end if;

    if new.closed_at is not null then
      raise exception 'closed_at is managed by the database';
    end if;

    if new.team_response is not null then
      raise exception 'team response must remain null while submitted';
    end if;

    new.updated_at := statement_timestamp();
    return new;
  end if;

  if old.status = 'submitted' and new.status = 'in_review' then
    if new.description is distinct from old.description
       or new.screenshot_path is distinct from old.screenshot_path
       or new.contact_allowed is distinct from old.contact_allowed then
      raise exception 'submitted feedback content cannot change while moving to in_review';
    end if;

    new.review_started_at := statement_timestamp();
    new.closed_at := null;
    new.updated_at := statement_timestamp();
    return new;
  end if;

  if old.status = 'submitted'
     and new.status in ('resolved', 'dismissed') then
    raise exception 'submitted feedback cannot be closed directly';
  end if;

  if old.status = 'in_review' and new.status = 'in_review' then
    if new.description is distinct from old.description
       or new.screenshot_path is distinct from old.screenshot_path
       or new.contact_allowed is distinct from old.contact_allowed then
      raise exception 'feedback content cannot change while in review';
    end if;

    if new.review_started_at is distinct from old.review_started_at then
      raise exception 'review_started_at is managed by the database';
    end if;

    if new.closed_at is distinct from old.closed_at then
      raise exception 'closed_at is managed by the database';
    end if;

    new.updated_at := statement_timestamp();
    return new;
  end if;

  if old.status = 'in_review'
     and new.status in ('resolved', 'dismissed') then
    if new.description is distinct from old.description
       or new.screenshot_path is distinct from old.screenshot_path
       or new.contact_allowed is distinct from old.contact_allowed then
      raise exception 'feedback content cannot change while closing';
    end if;

    if new.team_response is null then
      raise exception 'team response is required before closure';
    end if;

    if char_length(btrim(new.team_response)) = 0 then
      raise exception 'team response is required before closure';
    end if;

    new.team_response := btrim(new.team_response);
    new.review_started_at := old.review_started_at;
    new.closed_at := statement_timestamp();
    new.updated_at := statement_timestamp();
    return new;
  end if;

  if old.status = 'in_review' and new.status = 'submitted' then
    raise exception 'invalid feedback transition: in_review to submitted';
  end if;

  raise exception 'invalid feedback transition: % to %', old.status, new.status;
end;
$$;

comment on function app_private.enforce_feedback_report_contract() is
  'Trigger-only guard for public.feedback_reports. It canonicalizes text, freezes immutable columns, and governs all state transitions and timestamps.';

drop trigger if exists trg_feedback_reports_enforce_contract on public.feedback_reports;
create trigger trg_feedback_reports_enforce_contract
before insert or update on public.feedback_reports
for each row
execute function app_private.enforce_feedback_report_contract();

comment on trigger trg_feedback_reports_enforce_contract
on public.feedback_reports is
  'Before-insert and before-update guard that enforces the feedback lifecycle, canonicalizes text, and assigns authoritative timestamps.';

alter table public.feedback_reports enable row level security;

drop policy if exists feedback_reports_select_own on public.feedback_reports;
create policy feedback_reports_select_own
  on public.feedback_reports
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists feedback_reports_insert_own on public.feedback_reports;
create policy feedback_reports_insert_own
  on public.feedback_reports
  for insert
  to authenticated
  with check (
    (select auth.uid()) = user_id
    and status = 'submitted'
    and team_response is null
    and review_started_at is null
    and closed_at is null
    and jsonb_typeof(technical_context) = 'object'
    and char_length(btrim(description)) between 20 and 5000
    and app_private.feedback_screenshot_path_is_valid(user_id, id, screenshot_path)
  );

revoke all on public.feedback_reports from public;
revoke all on public.feedback_reports from anon;
revoke all on public.feedback_reports from authenticated;

grant select, insert on public.feedback_reports to authenticated;

create or replace function public.update_my_feedback(
  p_feedback_id uuid,
  p_description text,
  p_screenshot_path text,
  p_contact_allowed boolean
)
returns public.feedback_reports
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_feedback public.feedback_reports%rowtype;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  select *
    into v_feedback
  from public.feedback_reports
  where id = p_feedback_id
  for update;

  if not found or v_feedback.user_id is distinct from v_user_id then
    raise exception 'feedback not found';
  end if;

  if v_feedback.status <> 'submitted' then
    raise exception 'feedback can only be edited while submitted';
  end if;

  update public.feedback_reports
     set description = p_description,
         screenshot_path = p_screenshot_path,
         contact_allowed = p_contact_allowed
   where id = v_feedback.id
   returning * into v_feedback;

  return v_feedback;
end;
$$;

comment on function public.update_my_feedback(uuid, text, text, boolean) is
  'SECURITY DEFINER RPC that lets authenticated users update only their submitted feedback rows. It serializes the read and write with FOR UPDATE and returns the canonical row.';

create or replace function public.delete_my_feedback(
  p_feedback_id uuid
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_feedback public.feedback_reports%rowtype;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  select *
    into v_feedback
  from public.feedback_reports
  where id = p_feedback_id
  for update;

  if not found or v_feedback.user_id is distinct from v_user_id then
    raise exception 'feedback not found';
  end if;

  if v_feedback.status <> 'submitted' then
    raise exception 'feedback can only be deleted while submitted';
  end if;

  delete from public.feedback_reports
  where id = v_feedback.id;

  return v_feedback.screenshot_path;
end;
$$;

comment on function public.delete_my_feedback(uuid) is
  'SECURITY DEFINER RPC that deletes the authenticated user''s submitted feedback row and returns the screenshot path for later Storage cleanup.';

revoke execute on function public.update_my_feedback(uuid, text, text, boolean)
from public;
revoke execute on function public.update_my_feedback(uuid, text, text, boolean)
from anon;
revoke execute on function public.update_my_feedback(uuid, text, text, boolean)
from authenticated;
grant execute on function public.update_my_feedback(uuid, text, text, boolean)
to authenticated;

revoke execute on function public.delete_my_feedback(uuid)
from public;
revoke execute on function public.delete_my_feedback(uuid)
from anon;
revoke execute on function public.delete_my_feedback(uuid)
from authenticated;
grant execute on function public.delete_my_feedback(uuid)
to authenticated;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'feedback-screenshots',
  'feedback-screenshots',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set name = excluded.name,
      public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists feedback_screenshots_select_own on storage.objects;
create policy feedback_screenshots_select_own
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'feedback-screenshots'
    and owner_id = (select auth.uid()::text)
    and split_part(name, '/', 1) = (select auth.uid()::text)
  );

drop policy if exists feedback_screenshots_insert_own on storage.objects;
create policy feedback_screenshots_insert_own
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'feedback-screenshots'
    and owner_id = (select auth.uid()::text)
    and array_length(storage.foldername(name), 1) = 2
    and (storage.foldername(name))[1] = (select auth.uid()::text)
    and (storage.foldername(name))[2] ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    and storage.filename(name) ~ '^screenshot_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|jpeg|png|webp)$'
    and storage.extension(name) in ('jpg', 'jpeg', 'png', 'webp')
  );

drop policy if exists feedback_screenshots_delete_unreferenced on storage.objects;
create policy feedback_screenshots_delete_unreferenced
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'feedback-screenshots'
    and owner_id = (select auth.uid()::text)
    and split_part(name, '/', 1) = (select auth.uid()::text)
    and not exists (
      select 1
      from public.feedback_reports as feedback_reports
      where feedback_reports.screenshot_path = name
    )
  );

commit;
