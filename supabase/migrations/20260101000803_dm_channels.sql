-- =============================================================================
-- 0803 · dm_channels — canonical direct-message pairing
-- =============================================================================

-- =============================================================================
-- dm_channels — 1-on-1 Direct Messages canonical pairing
-- =============================================================================
-- Mathematically guarantees exactly 1 DM channel between any two users.
-- Canonical ordering: user_a < user_b
-- =============================================================================
create table public.dm_channels (
  chat_id    uuid primary key references public.chats(chat_id) on delete cascade,
  user_a     uuid not null references public.profiles(user_id) on delete cascade,
  user_b     uuid not null references public.profiles(user_id) on delete cascade,
  created_at timestamptz not null default now(),

  -- DM request acceptance. A DM from a non-follower lands as a request; these
  -- two are stamped by accept_dm_request (20260816000000) when the recipient
  -- accepts. Null = still pending.
  accepted_at timestamptz,
  accepted_by uuid references public.profiles(user_id) on delete set null,
  constraint dm_channels_users_order check (user_a < user_b),
  constraint dm_channels_unique_pair unique (user_a, user_b)
);

create index dm_channels_user_a on public.dm_channels (user_a);
create index dm_channels_user_b on public.dm_channels (user_b);

alter table public.dm_channels enable row level security;

-- -----------------------------------------------------------------------------
-- Foreign-key indexes (Supabase advisor 0001_unindexed_foreign_keys)
-- -----------------------------------------------------------------------------
-- Postgres does NOT index the referencing side of a foreign key for you. Every
-- one of these columns points at a parent that gets deleted or updated
-- (profiles on account deletion, matches/teams on cascade), and without an
-- index each such statement seq-scans this table once per affected parent row.
-- They are also the columns joined on when reading.

create index if not exists idx_dm_channels_accepted_by
  on public.dm_channels (accepted_by);
-- =============================================================================
-- dm_channels RLS
-- =============================================================================
create policy "dm_channels_read_members"
  on public.dm_channels for select
  to authenticated
  using (user_a = (select auth.uid()) or user_b = (select auth.uid()));

-- ---- get_or_create_dm_chat ----
create or replace function public.get_or_create_dm_chat(p_target_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_user_a uuid;
  v_user_b uuid;
  v_chat_id uuid;
begin
  if v_actor is null then
    raise exception 'Unauthenticated';
  end if;

  if p_target_user_id is null or p_target_user_id = v_actor then
    raise exception 'Cannot create DM with self or null target';
  end if;

  -- Canonical ordering
  if v_actor < p_target_user_id then
    v_user_a := v_actor;
    v_user_b := p_target_user_id;
  else
    v_user_a := p_target_user_id;
    v_user_b := v_actor;
  end if;

  -- Check if DM channel already exists
  select chat_id into v_chat_id
    from public.dm_channels
   where user_a = v_user_a
     and user_b = v_user_b;

  if v_chat_id is not null then
    return v_chat_id;
  end if;

  -- Create new chat container
  insert into public.chats (type)
  values ('dm')
  returning chat_id into v_chat_id;

  -- Insert pairing row
  insert into public.dm_channels (chat_id, user_a, user_b)
  values (v_chat_id, v_user_a, v_user_b);

  -- Insert both members into chat_members
  insert into public.chat_members (chat_id, user_id, role)
  values
    (v_chat_id, v_actor, 'member'),
    (v_chat_id, p_target_user_id, 'member')
  on conflict (chat_id, user_id) do nothing;

  return v_chat_id;
end;
$$;

revoke all on function public.get_or_create_dm_chat(uuid) from public;
grant execute on function public.get_or_create_dm_chat(uuid) to authenticated;
