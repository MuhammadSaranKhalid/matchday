-- =============================================================================
-- Migration: 20260101000560_follows.sql
-- =============================================================================

-- 0560 · follows
-- Spec §6.4, §8.2.6.
--
-- Polymorphic target:
--   target_type ∈ {user, team, tournament}; target_id is the matching uuid.
--   We can't use a real FK (one column, three possible target tables), so:
--     - The unique index keeps "one row per (follower, target_type, target_id)".
--     - The cleanup_follows_on_entity_delete AFTER-DELETE trigger fires on
--       profiles/teams/tournaments and removes orphaned follow rows. The
--       trigger function is SECURITY DEFINER so the deleter doesn't need
--       write permission on every follower's row.
--   v1.2 will add target_type='pending' for private accounts (follow request
--   flow). Today every follow is immediate (active) or muted by the user.
--
-- Notification:
--   notify_on_follow fires for `target_type = 'user'` only — team /
--   tournament follows are silent (the entity isn't a person).
--
-- Self-follow:
--   The no_self_follow CHECK forbids `target_type='user' AND
--   target_id=follower_id`. Following your own team/tournament is allowed.

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.follows (
  follow_id   uuid primary key default gen_random_uuid(),
  follower_id uuid not null
    references public.profiles (user_id)
    on delete cascade,
  target_type public.follow_target_type not null,
  target_id   uuid not null,
  status      public.follow_status not null default 'active',
  created_at  timestamptz not null default now(),
  unique (follower_id, target_type, target_id),
  constraint no_self_follow
    check (not (target_type = 'user' and target_id = follower_id))
);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

create index follows_target
  on public.follows (target_type, target_id);

create index follows_follower
  on public.follows (follower_id);

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- cleanup_follows_on_entity_delete — keeps follows clean of dangling targets.
-- One generic function dispatches on tg_table_name; trigger registered on
-- each target table separately.
create or replace function public.cleanup_follows_on_entity_delete()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_table_name = 'profiles' then
    delete from public.follows
    where target_type = 'user'
      and target_id = old.user_id;
  elsif tg_table_name = 'teams' then
    delete from public.follows
    where target_type = 'team'
      and target_id = old.team_id;
  elsif tg_table_name = 'tournaments' then
    delete from public.follows
    where target_type = 'tournament'
      and target_id = old.tournament_id;
  end if;
  return old;
end;
$$;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger profiles_cleanup_follows
  after delete on public.profiles
  for each row
  execute function public.cleanup_follows_on_entity_delete();

create trigger teams_cleanup_follows
  after delete on public.teams
  for each row
  execute function public.cleanup_follows_on_entity_delete();

create trigger tournaments_cleanup_follows
  after delete on public.tournaments
  for each row
  execute function public.cleanup_follows_on_entity_delete();

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

-- NOTIFICATION TRIGGER MOVED → 20260101000620_notification_triggers.sql
--
-- notify_on_follow now calls public.notify() (0570), which is declared
-- AFTER this file. A plpgsql body referencing a not-yet-created function
-- compiles but fails at runtime (§12.0), so the trigger follows its dependency
-- — the same remedy the teams UPDATE policies got when they moved to 0210.
-- RLS — public read (follower lists are visible); writes only by the
-- follower themselves.
alter table public.follows enable row level security;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

create policy "follows_read_public"
  on public.follows
  for select
  to anon, authenticated
  using (true);

create policy "follows_insert_self"
  on public.follows
  for insert
  to authenticated
  with check (
    (
      select
        auth.uid()
    ) = follower_id
  );

create policy "follows_update_self"
  on public.follows
  for update
  to authenticated
  using (
    (
      select
        auth.uid()
    ) = follower_id
  )
  with check (
    (
      select
        auth.uid()
    ) = follower_id
  );

create policy "follows_delete_self"
  on public.follows
  for delete
  to authenticated
  using (
    (
      select
        auth.uid()
    ) = follower_id
  );
