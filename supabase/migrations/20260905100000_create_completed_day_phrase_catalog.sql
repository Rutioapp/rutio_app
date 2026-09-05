begin;

create extension if not exists pgcrypto;

create table if not exists public.motivational_phrases (
  id text primary key,
  category text not null check (category in ('personal', 'consistency', 'motivation')),
  tone text not null check (tone in ('gentle', 'balanced', 'energetic')),
  source_type text not null check (source_type in ('original', 'quote', 'proverb')),
  author text,
  required_tokens text[] not null default '{}'::text[],
  weight smallint not null default 100 check (weight > 0),
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (btrim(id) <> ''),
  check (author is null or btrim(author) <> '')
);

create table if not exists public.motivational_phrase_translations (
  phrase_id text not null references public.motivational_phrases(id) on delete restrict,
  locale text not null,
  template text not null,
  review_status text not null default 'draft'
    check (review_status in ('draft', 'reviewed', 'published')),
  translator_note text,
  content_version integer not null default 1 check (content_version > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (phrase_id, locale),
  check (btrim(locale) <> ''),
  check (btrim(template) <> '')
);

create table if not exists public.phrase_catalog_releases (
  id uuid primary key default gen_random_uuid(),
  locale text not null,
  release_version integer not null check (release_version > 0),
  schema_version integer not null default 1 check (schema_version > 0),
  status text not null default 'draft'
    check (status in ('draft', 'published')),
  is_current boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (locale, release_version),
  check (btrim(locale) <> ''),
  check ((status = 'published' and published_at is not null)
      or (status = 'draft' and published_at is null)),
  check ((status = 'published') or is_current = false)
);

create table if not exists public.phrase_catalog_release_entries (
  release_id uuid not null references public.phrase_catalog_releases(id) on delete restrict,
  phrase_id text not null references public.motivational_phrases(id) on delete restrict,
  category text not null check (category in ('personal', 'consistency', 'motivation')),
  tone text not null check (tone in ('gentle', 'balanced', 'energetic')),
  source_type text not null check (source_type in ('original', 'quote', 'proverb')),
  author text,
  template text not null,
  required_tokens text[] not null default '{}'::text[],
  weight smallint not null check (weight > 0),
  enabled boolean not null default true,
  content_version integer not null check (content_version > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (release_id, phrase_id),
  check (btrim(template) <> ''),
  check (author is null or btrim(author) <> ''),
  check ((source_type = 'original' and author is null)
      or (source_type in ('quote', 'proverb') and author is not null))
);

create index if not exists phrase_catalog_releases_locale_version_idx
  on public.phrase_catalog_releases (locale, release_version desc);

create unique index if not exists phrase_catalog_releases_current_locale_idx
  on public.phrase_catalog_releases (locale)
  where status = 'published' and is_current = true;

create index if not exists phrase_catalog_release_entries_release_idx
  on public.phrase_catalog_release_entries (release_id, phrase_id);

create or replace function app_private.guard_completed_day_phrase_release()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  entry_count integer;
begin
  if tg_op = 'DELETE' then
    if old.status = 'published' then
      raise exception 'Published phrase catalog releases are immutable.';
    end if;
    return old;
  end if;

  if old.status = 'published' then
    if new.status <> old.status
       or new.locale <> old.locale
       or new.release_version <> old.release_version
       or new.schema_version <> old.schema_version
       or new.created_at is distinct from old.created_at
       or new.published_at is distinct from old.published_at then
      raise exception 'Published phrase catalog releases are immutable.';
    end if;
    return new;
  end if;

  if new.status = 'published' then
    select count(*) into entry_count
    from public.phrase_catalog_release_entries
    where release_id = old.id;
    if entry_count = 0 then
      raise exception 'A phrase catalog release needs entries before publication.';
    end if;
    if new.published_at is null then
      new.published_at := now();
    end if;
    new.is_current := true;
  end if;
  return new;
end;
$$;

create or replace function app_private.guard_completed_day_phrase_entry()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  release_status text;
  release_id uuid;
begin
  if tg_op = 'INSERT' then
    release_id := new.release_id;
  else
    release_id := old.release_id;
  end if;
  select status into release_status
  from public.phrase_catalog_releases
  where id = release_id;
  if release_status = 'published' then
    raise exception 'Published phrase catalog release entries are immutable.';
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

revoke all on function app_private.guard_completed_day_phrase_release()
  from public, anon, authenticated;
revoke all on function app_private.guard_completed_day_phrase_entry()
  from public, anon, authenticated;

drop trigger if exists motivational_phrases_set_updated_at
  on public.motivational_phrases;
create trigger motivational_phrases_set_updated_at
before update on public.motivational_phrases
for each row execute function app_private.set_updated_at();

drop trigger if exists motivational_phrase_translations_set_updated_at
  on public.motivational_phrase_translations;
create trigger motivational_phrase_translations_set_updated_at
before update on public.motivational_phrase_translations
for each row execute function app_private.set_updated_at();

drop trigger if exists phrase_catalog_releases_set_updated_at
  on public.phrase_catalog_releases;
create trigger phrase_catalog_releases_set_updated_at
before update on public.phrase_catalog_releases
for each row execute function app_private.set_updated_at();

drop trigger if exists phrase_catalog_release_entries_set_updated_at
  on public.phrase_catalog_release_entries;
create trigger phrase_catalog_release_entries_set_updated_at
before update on public.phrase_catalog_release_entries
for each row execute function app_private.set_updated_at();

drop trigger if exists phrase_catalog_releases_immutable
  on public.phrase_catalog_releases;
create trigger phrase_catalog_releases_immutable
before update or delete on public.phrase_catalog_releases
for each row execute function app_private.guard_completed_day_phrase_release();

drop trigger if exists phrase_catalog_release_entries_immutable
  on public.phrase_catalog_release_entries;
create trigger phrase_catalog_release_entries_immutable
before insert or update or delete on public.phrase_catalog_release_entries
for each row execute function app_private.guard_completed_day_phrase_entry();

alter table public.motivational_phrases enable row level security;
alter table public.motivational_phrase_translations enable row level security;
alter table public.phrase_catalog_releases enable row level security;
alter table public.phrase_catalog_release_entries enable row level security;

revoke all on table public.motivational_phrases from public, anon, authenticated;
revoke all on table public.motivational_phrase_translations from public, anon, authenticated;
revoke all on table public.phrase_catalog_releases from public, anon, authenticated;
revoke all on table public.phrase_catalog_release_entries from public, anon, authenticated;

comment on table public.motivational_phrases is
  'Editorial phrase metadata; client reads only through the catalog RPCs.';
comment on table public.motivational_phrase_translations is
  'Editorial translations versioned independently per phrase and locale.';
comment on table public.phrase_catalog_releases is
  'Immutable published catalog identities; is_current is the publication pointer.';
comment on table public.phrase_catalog_release_entries is
  'Materialized immutable snapshot consumed by the mobile catalog RPC.';

commit;
