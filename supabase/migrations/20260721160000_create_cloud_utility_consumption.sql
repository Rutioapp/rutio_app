begin;

create extension if not exists pgcrypto;

create table if not exists public.user_utility_effects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  utility_id text not null references public.shop_items(id) on delete restrict,
  utility_type text not null,
  activated_at timestamptz not null default now(),
  remaining_uses integer not null default 0,
  total_uses integer not null default 0,
  status text not null default 'active',
  habit_id uuid references public.habits(id) on delete cascade,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_utility_effects_utility_type_check check (
    utility_type in (
      'xpBoost',
      'coinBoost',
      'streakShield',
      'streakRecover'
    )
  ),
  constraint user_utility_effects_status_check check (
    status in ('active', 'completed', 'expired', 'cancelled')
  ),
  constraint user_utility_effects_remaining_uses_check check (remaining_uses >= 0),
  constraint user_utility_effects_total_uses_check check (total_uses >= 0),
  constraint user_utility_effects_remaining_le_total_check
    check (remaining_uses <= total_uses),
  constraint user_utility_effects_streak_shield_habit_check check (
    utility_id <> 'utility_streak_shield_1'
    or habit_id is not null
  )
);

create index if not exists idx_user_utility_effects_user_status_activated_at
  on public.user_utility_effects (user_id, status, activated_at desc);
create index if not exists idx_user_utility_effects_user_utility_status
  on public.user_utility_effects (user_id, utility_id, status);
create index if not exists idx_user_utility_effects_user_habit_status
  on public.user_utility_effects (user_id, habit_id, status)
  where habit_id is not null;

create unique index if not exists idx_user_utility_effects_unique_active_xp_boost
  on public.user_utility_effects (user_id, utility_id)
  where status = 'active'
    and utility_id = 'utility_xp_boost_1d';

create unique index if not exists idx_user_utility_effects_unique_active_coin_boost
  on public.user_utility_effects (user_id, utility_id)
  where status = 'active'
    and utility_id = 'utility_coin_boost_1d';

create unique index if not exists idx_user_utility_effects_unique_active_streak_shield
  on public.user_utility_effects (user_id, habit_id)
  where status = 'active'
    and utility_id = 'utility_streak_shield_1'
    and habit_id is not null;

create table if not exists public.utility_consumption_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  request_id text not null,
  utility_id text not null references public.shop_items(id) on delete restrict,
  utility_type text not null,
  operation_type text not null,
  source_type text not null,
  source_id text not null,
  effect_id uuid references public.user_utility_effects(id) on delete set null,
  habit_id uuid references public.habits(id) on delete set null,
  break_id text,
  remaining_uses_before integer not null default 0,
  remaining_uses_after integer not null default 0,
  total_uses_before integer not null default 0,
  total_uses_after integer not null default 0,
  related_ledger_id uuid references public.utility_consumption_ledger(id) on delete set null,
  is_idempotent boolean not null default false,
  created_at timestamptz not null default now(),
  constraint utility_consumption_ledger_request_id_check check (btrim(request_id) <> ''),
  constraint utility_consumption_ledger_utility_type_check check (
    utility_type in (
      'xpBoost',
      'coinBoost',
      'streakShield',
      'streakRecover'
    )
  ),
  constraint utility_consumption_ledger_operation_type_check check (
    operation_type in ('activate', 'consume', 'recover')
  ),
  constraint utility_consumption_ledger_source_type_check check (btrim(source_type) <> ''),
  constraint utility_consumption_ledger_source_id_check check (btrim(source_id) <> ''),
  constraint utility_consumption_ledger_remaining_before_check check (
    remaining_uses_before >= 0
  ),
  constraint utility_consumption_ledger_remaining_after_check check (
    remaining_uses_after >= 0
  ),
  constraint utility_consumption_ledger_total_before_check check (
    total_uses_before >= 0
  ),
  constraint utility_consumption_ledger_total_after_check check (
    total_uses_after >= 0
  ),
  constraint utility_consumption_ledger_remaining_bounds_check check (
    remaining_uses_before <= total_uses_before
    and remaining_uses_after <= total_uses_after
  ),
  constraint utility_consumption_ledger_request_unique unique (user_id, request_id),
  constraint utility_consumption_ledger_source_unique unique (
    user_id,
    operation_type,
    source_type,
    source_id
  )
);

create index if not exists idx_utility_consumption_ledger_user_created_at
  on public.utility_consumption_ledger (user_id, created_at desc);
create index if not exists idx_utility_consumption_ledger_user_request_id
  on public.utility_consumption_ledger (user_id, request_id);
create index if not exists idx_utility_consumption_ledger_user_source
  on public.utility_consumption_ledger (user_id, operation_type, source_type, source_id);
create index if not exists idx_utility_consumption_ledger_user_effect_id
  on public.utility_consumption_ledger (user_id, effect_id);
create index if not exists idx_utility_consumption_ledger_user_habit_break
  on public.utility_consumption_ledger (user_id, habit_id, break_id);

alter table public.user_utility_effects enable row level security;
alter table public.utility_consumption_ledger enable row level security;

drop policy if exists user_utility_effects_select_own on public.user_utility_effects;
create policy user_utility_effects_select_own
  on public.user_utility_effects
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists utility_consumption_ledger_select_own on public.utility_consumption_ledger;
create policy utility_consumption_ledger_select_own
  on public.utility_consumption_ledger
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

revoke all on public.user_utility_effects from public, anon, authenticated;
revoke all on public.utility_consumption_ledger from public, anon, authenticated;

grant select on public.user_utility_effects to authenticated;
grant select on public.utility_consumption_ledger to authenticated;

create or replace function public.activate_utility_effect(
  p_request_id text,
  p_utility_id text,
  p_operation_type text,
  p_source_type text,
  p_source_id text,
  p_habit_id uuid default null,
  p_break_id text default null
)
returns public.utility_consumption_ledger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_request_id text := btrim(coalesce(p_request_id, ''));
  v_utility_id text := btrim(coalesce(p_utility_id, ''));
  v_operation_type text := lower(btrim(coalesce(p_operation_type, '')));
  v_source_type text := btrim(coalesce(p_source_type, ''));
  v_source_id text := btrim(coalesce(p_source_id, ''));
  v_habit_id uuid := p_habit_id;
  v_break_id text := btrim(coalesce(p_break_id, ''));
  v_existing public.utility_consumption_ledger%rowtype;
  v_item public.shop_items%rowtype;
  v_inventory_quantity integer;
  v_effect public.user_utility_effects%rowtype;
  v_ledger public.utility_consumption_ledger%rowtype;
  v_total_uses integer;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;
  if v_request_id = '' then
    raise exception 'request_id is required';
  end if;
  if v_utility_id = '' then
    raise exception 'utility_id is required';
  end if;
  if v_operation_type <> 'activate' then
    raise exception 'operation_type must be activate';
  end if;
  if v_source_type = '' then
    raise exception 'source_type is required';
  end if;
  if v_source_id = '' then
    raise exception 'source_id is required';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_user_id::text));
  perform pg_advisory_xact_lock(hashtext('utility_request:' || v_request_id));
  perform pg_advisory_xact_lock(
    hashtext(
      'utility_source:' ||
      v_user_id::text ||
      ':' ||
      v_operation_type ||
      ':' ||
      v_source_type ||
      ':' ||
      v_source_id
    )
  );

  select *
    into v_existing
  from public.utility_consumption_ledger
  where user_id = v_user_id
    and request_id = v_request_id;

  if found then
    if v_existing.utility_id <> v_utility_id
       or v_existing.operation_type <> v_operation_type
       or v_existing.source_type <> v_source_type
       or v_existing.source_id <> v_source_id then
      raise exception 'request_id already used by another utility operation';
    end if;

    update public.utility_consumption_ledger
       set is_idempotent = true
     where id = v_existing.id
       and is_idempotent = false;

    select *
      into v_existing
    from public.utility_consumption_ledger
    where id = v_existing.id;
    return v_existing;
  end if;

  select *
    into v_existing
  from public.utility_consumption_ledger
  where user_id = v_user_id
    and operation_type = v_operation_type
    and source_type = v_source_type
    and source_id = v_source_id;

  if found then
    if v_existing.utility_id <> v_utility_id then
      raise exception 'source_id already used by another utility';
    end if;

    update public.utility_consumption_ledger
       set is_idempotent = true
     where id = v_existing.id
       and is_idempotent = false;

    select *
      into v_existing
    from public.utility_consumption_ledger
    where id = v_existing.id;
    return v_existing;
  end if;

  select *
    into v_item
  from public.shop_items
  where id = v_utility_id
    and is_active = true;

  if not found or v_item.category <> 'utility' then
    raise exception 'utility item not found or inactive';
  end if;

  if v_item.subtype not in ('xpBoost', 'coinBoost', 'streakShield') then
    raise exception 'utility cannot be activated';
  end if;

  if v_item.subtype = 'streakShield' and v_habit_id is null then
    raise exception 'habit_id is required for streak shield';
  end if;

  if v_item.subtype <> 'streakShield' and v_habit_id is not null then
    raise exception 'habit_id is not allowed for this utility';
  end if;

  select quantity
    into v_inventory_quantity
  from public.user_inventory
  where user_id = v_user_id
    and item_id = v_utility_id
  for update;

  if not found or v_inventory_quantity < 1 then
    raise exception 'utility inventory unavailable';
  end if;

  if v_inventory_quantity = 1 then
    delete from public.user_inventory
    where user_id = v_user_id
      and item_id = v_utility_id;
  else
    update public.user_inventory
       set quantity = quantity - 1,
           updated_at = now()
     where user_id = v_user_id
       and item_id = v_utility_id;
  end if;

  v_total_uses := case
    when v_item.subtype = 'streakShield' then 1
    else 10
  end;

  insert into public.user_utility_effects (
    user_id,
    utility_id,
    utility_type,
    activated_at,
    remaining_uses,
    total_uses,
    status,
    habit_id,
    completed_at,
    created_at,
    updated_at
  ) values (
    v_user_id,
    v_utility_id,
    v_item.subtype,
    now(),
    v_total_uses,
    v_total_uses,
    'active',
    v_habit_id,
    null,
    now(),
    now()
  )
  returning * into v_effect;

  insert into public.utility_consumption_ledger (
    user_id,
    request_id,
    utility_id,
    utility_type,
    operation_type,
    source_type,
    source_id,
    effect_id,
    habit_id,
    break_id,
    remaining_uses_before,
    remaining_uses_after,
    total_uses_before,
    total_uses_after,
    related_ledger_id,
    is_idempotent,
    created_at
  ) values (
    v_user_id,
    v_request_id,
    v_utility_id,
    v_item.subtype,
    v_operation_type,
    v_source_type,
    v_source_id,
    v_effect.id,
    v_habit_id,
    nullif(v_break_id, ''),
    0,
    v_total_uses,
    0,
    v_total_uses,
    null,
    false,
    now()
  )
  returning * into v_ledger;

  return v_ledger;
end;
$$;

create or replace function public.consume_utility_use(
  p_request_id text,
  p_utility_id text,
  p_operation_type text,
  p_source_type text,
  p_source_id text,
  p_habit_id uuid default null,
  p_break_id text default null
)
returns public.utility_consumption_ledger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_request_id text := btrim(coalesce(p_request_id, ''));
  v_utility_id text := btrim(coalesce(p_utility_id, ''));
  v_operation_type text := lower(btrim(coalesce(p_operation_type, '')));
  v_source_type text := btrim(coalesce(p_source_type, ''));
  v_source_id text := btrim(coalesce(p_source_id, ''));
  v_habit_id uuid := p_habit_id;
  v_break_id text := btrim(coalesce(p_break_id, ''));
  v_existing public.utility_consumption_ledger%rowtype;
  v_item public.shop_items%rowtype;
  v_effect public.user_utility_effects%rowtype;
  v_ledger public.utility_consumption_ledger%rowtype;
  v_remaining_before integer;
  v_remaining_after integer;
  v_total_before integer;
  v_total_after integer;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;
  if v_request_id = '' then
    raise exception 'request_id is required';
  end if;
  if v_utility_id = '' then
    raise exception 'utility_id is required';
  end if;
  if v_operation_type <> 'consume' then
    raise exception 'operation_type must be consume';
  end if;
  if v_source_type = '' then
    raise exception 'source_type is required';
  end if;
  if v_source_id = '' then
    raise exception 'source_id is required';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_user_id::text));
  perform pg_advisory_xact_lock(hashtext('utility_request:' || v_request_id));
  perform pg_advisory_xact_lock(
    hashtext(
      'utility_source:' ||
      v_user_id::text ||
      ':' ||
      v_operation_type ||
      ':' ||
      v_source_type ||
      ':' ||
      v_source_id
    )
  );

  select *
    into v_existing
  from public.utility_consumption_ledger
  where user_id = v_user_id
    and request_id = v_request_id;

  if found then
    if v_existing.utility_id <> v_utility_id
       or v_existing.operation_type <> v_operation_type
       or v_existing.source_type <> v_source_type
       or v_existing.source_id <> v_source_id then
      raise exception 'request_id already used by another utility operation';
    end if;

    update public.utility_consumption_ledger
       set is_idempotent = true
     where id = v_existing.id
       and is_idempotent = false;

    select *
      into v_existing
    from public.utility_consumption_ledger
    where id = v_existing.id;
    return v_existing;
  end if;

  select *
    into v_existing
  from public.utility_consumption_ledger
  where user_id = v_user_id
    and operation_type = v_operation_type
    and source_type = v_source_type
    and source_id = v_source_id;

  if found then
    if v_existing.utility_id <> v_utility_id then
      raise exception 'source_id already used by another utility';
    end if;

    update public.utility_consumption_ledger
       set is_idempotent = true
     where id = v_existing.id
       and is_idempotent = false;

    select *
      into v_existing
    from public.utility_consumption_ledger
    where id = v_existing.id;
    return v_existing;
  end if;

  select *
    into v_item
  from public.shop_items
  where id = v_utility_id
    and is_active = true;

  if not found or v_item.category <> 'utility' then
    raise exception 'utility item not found or inactive';
  end if;

  if v_item.subtype not in ('xpBoost', 'coinBoost', 'streakShield') then
    raise exception 'utility cannot be consumed';
  end if;

  if v_item.subtype = 'streakShield' and v_habit_id is null then
    raise exception 'habit_id is required for streak shield';
  end if;

  if v_item.subtype <> 'streakShield' and v_habit_id is not null then
    raise exception 'habit_id is not allowed for this utility';
  end if;

  select *
    into v_effect
  from public.user_utility_effects
  where user_id = v_user_id
    and utility_id = v_utility_id
    and status = 'active'
    and (
      (v_habit_id is null and habit_id is null)
      or habit_id = v_habit_id
    )
  order by activated_at desc
  for update;

  if not found then
    raise exception 'active utility effect not found';
  end if;

  v_remaining_before := v_effect.remaining_uses;
  v_total_before := v_effect.total_uses;
  if v_remaining_before < 1 then
    raise exception 'utility effect is exhausted';
  end if;

  v_remaining_after := v_remaining_before - 1;
  v_total_after := v_total_before;

  update public.user_utility_effects
     set remaining_uses = v_remaining_after,
         status = case when v_remaining_after = 0 then 'completed' else 'active' end,
         completed_at = case when v_remaining_after = 0 then now() else completed_at end,
         updated_at = now()
   where id = v_effect.id;

  insert into public.utility_consumption_ledger (
    user_id,
    request_id,
    utility_id,
    utility_type,
    operation_type,
    source_type,
    source_id,
    effect_id,
    habit_id,
    break_id,
    remaining_uses_before,
    remaining_uses_after,
    total_uses_before,
    total_uses_after,
    related_ledger_id,
    is_idempotent,
    created_at
  ) values (
    v_user_id,
    v_request_id,
    v_utility_id,
    v_item.subtype,
    v_operation_type,
    v_source_type,
    v_source_id,
    v_effect.id,
    coalesce(v_effect.habit_id, v_habit_id),
    nullif(v_break_id, ''),
    v_remaining_before,
    v_remaining_after,
    v_total_before,
    v_total_after,
    null,
    false,
    now()
  )
  returning * into v_ledger;

  return v_ledger;
end;
$$;

create or replace function public.apply_streak_recover(
  p_request_id text,
  p_utility_id text,
  p_operation_type text,
  p_break_id text
)
returns public.utility_consumption_ledger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_request_id text := btrim(coalesce(p_request_id, ''));
  v_utility_id text := btrim(coalesce(p_utility_id, ''));
  v_operation_type text := lower(btrim(coalesce(p_operation_type, '')));
  v_break_id text := btrim(coalesce(p_break_id, ''));
  v_existing public.utility_consumption_ledger%rowtype;
  v_item public.shop_items%rowtype;
  v_inventory_quantity integer;
  v_effect public.user_utility_effects%rowtype;
  v_ledger public.utility_consumption_ledger%rowtype;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;
  if v_request_id = '' then
    raise exception 'request_id is required';
  end if;
  if v_utility_id = '' then
    raise exception 'utility_id is required';
  end if;
  if v_operation_type <> 'recover' then
    raise exception 'operation_type must be recover';
  end if;
  if v_break_id = '' then
    raise exception 'break_id is required';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_user_id::text));
  perform pg_advisory_xact_lock(hashtext('utility_request:' || v_request_id));
  perform pg_advisory_xact_lock(
    hashtext(
      'utility_source:' ||
      v_user_id::text ||
      ':' ||
      v_operation_type ||
      ':streak_recover:' ||
      v_break_id
    )
  );

  select *
    into v_existing
  from public.utility_consumption_ledger
  where user_id = v_user_id
    and request_id = v_request_id;

  if found then
    if v_existing.utility_id <> v_utility_id
       or v_existing.operation_type <> v_operation_type
       or v_existing.source_type <> 'streak_recover'
       or v_existing.source_id <> v_break_id then
      raise exception 'request_id already used by another utility operation';
    end if;

    update public.utility_consumption_ledger
       set is_idempotent = true
     where id = v_existing.id
       and is_idempotent = false;

    select *
      into v_existing
    from public.utility_consumption_ledger
    where id = v_existing.id;
    return v_existing;
  end if;

  select *
    into v_existing
  from public.utility_consumption_ledger
  where user_id = v_user_id
    and operation_type = v_operation_type
    and source_type = 'streak_recover'
    and source_id = v_break_id;

  if found then
    if v_existing.utility_id <> v_utility_id then
      raise exception 'break_id already used by another utility';
    end if;

    update public.utility_consumption_ledger
       set is_idempotent = true
     where id = v_existing.id
       and is_idempotent = false;

    select *
      into v_existing
    from public.utility_consumption_ledger
    where id = v_existing.id;
    return v_existing;
  end if;

  select *
    into v_item
  from public.shop_items
  where id = v_utility_id
    and is_active = true;

  if not found or v_item.category <> 'utility' then
    raise exception 'utility item not found or inactive';
  end if;

  if v_item.subtype <> 'streakRecover' then
    raise exception 'utility cannot be applied as streak recover';
  end if;

  select quantity
    into v_inventory_quantity
  from public.user_inventory
  where user_id = v_user_id
    and item_id = v_utility_id
  for update;

  if not found or v_inventory_quantity < 1 then
    raise exception 'utility inventory unavailable';
  end if;

  if v_inventory_quantity = 1 then
    delete from public.user_inventory
    where user_id = v_user_id
      and item_id = v_utility_id;
  else
    update public.user_inventory
       set quantity = quantity - 1,
           updated_at = now()
     where user_id = v_user_id
       and item_id = v_utility_id;
  end if;

  insert into public.user_utility_effects (
    user_id,
    utility_id,
    utility_type,
    activated_at,
    remaining_uses,
    total_uses,
    status,
    habit_id,
    completed_at,
    created_at,
    updated_at
  ) values (
    v_user_id,
    v_utility_id,
    v_item.subtype,
    now(),
    0,
    1,
    'completed',
    null,
    now(),
    now(),
    now()
  )
  returning * into v_effect;

  insert into public.utility_consumption_ledger (
    user_id,
    request_id,
    utility_id,
    utility_type,
    operation_type,
    source_type,
    source_id,
    effect_id,
    habit_id,
    break_id,
    remaining_uses_before,
    remaining_uses_after,
    total_uses_before,
    total_uses_after,
    related_ledger_id,
    is_idempotent,
    created_at
  ) values (
    v_user_id,
    v_request_id,
    v_utility_id,
    v_item.subtype,
    v_operation_type,
    'streak_recover',
    v_break_id,
    v_effect.id,
    null,
    v_break_id,
    1,
    0,
    1,
    1,
    null,
    false,
    now()
  )
  returning * into v_ledger;

  return v_ledger;
end;
$$;

revoke all on function public.activate_utility_effect(
  text,
  text,
  text,
  text,
  text,
  uuid,
  text
) from public, anon, authenticated;

revoke all on function public.consume_utility_use(
  text,
  text,
  text,
  text,
  text,
  uuid,
  text
) from public, anon, authenticated;

revoke all on function public.apply_streak_recover(
  text,
  text,
  text,
  text
) from public, anon, authenticated;

grant execute on function public.activate_utility_effect(
  text,
  text,
  text,
  text,
  text,
  uuid,
  text
) to authenticated;

grant execute on function public.consume_utility_use(
  text,
  text,
  text,
  text,
  text,
  uuid,
  text
) to authenticated;

grant execute on function public.apply_streak_recover(
  text,
  text,
  text,
  text
) to authenticated;

commit;
