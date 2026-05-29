-- =============================================================================
-- 0120 · unclaimed_players
-- =============================================================================
-- Spec §2.5, §2.6.
--
-- Placeholder rows created by team managers for players who aren't on Circk
-- yet. Lets a manager record stats for someone in the squad before that
-- person installs the app — when they do, they "claim" the placeholder and
-- everything (memberships, balls, innings stats) atomically rewrites to
-- their real user_id.
--
-- Two claim paths (§2.6):
--   Path A — Manager-initiated invite. Manager links the unclaimed row to a
--            real user_id directly via UPDATE; no claim_request row needed.
--            The cascade trigger (declared with team_members in 0210) does
--            the rewrite + stat migration.
--   Path B — Player-initiated claim. User searches for their name, files a
--            claim_requests row (table in 0230), the manager who originally
--            added the unclaimed row approves via approve_claim_request().
--            Approval flips claimed_by_user_id + cascade triggers fire.
--
-- The cascade itself (cascade_unclaimed_claim) lives in 0210 because it has
-- to query team_members. This file only owns the unclaimed_players table,
-- the BEFORE-UPDATE timestamp normaliser, the is_unclaimed_owner predicate,
-- and the migrate_player_stats stub.
-- =============================================================================

create table public.unclaimed_players (
  unclaimed_id         uuid primary key default gen_random_uuid(),
  display_name         text not null check (length(display_name) between 1 and 80),
  phone_number         text,
  email                text,

  -- Inline player profile (same shape as player_profiles fields). Stored as
  -- jsonb so unclaimed players appear in stats with their batting/bowling
  -- style without needing a real player_profiles row.
  player_profile       jsonb not null default '{}'::jsonb,

  -- Manager who created this placeholder. ON DELETE SET NULL so
  -- self-service account deletion (delete_user RPC in 0700) doesn't
  -- block; the placeholder lives on under its display name.
  added_by             uuid
                          references public.profiles(user_id) on delete set null,

  -- Set when the placeholder is claimed. claimed_at is auto-stamped by the
  -- BEFORE-UPDATE trigger below if the caller didn't set it.
  claimed_by_user_id   uuid references public.profiles(user_id) on delete set null,
  claimed_at           timestamptz,

  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),

  -- Either both claim columns are null, or both are non-null.
  constraint claim_consistency check (
    (claimed_by_user_id is null and claimed_at is null)
    or (claimed_by_user_id is not null and claimed_at is not null)
  )
);

create index unclaimed_players_phone     on public.unclaimed_players (phone_number)
  where phone_number is not null;
create index unclaimed_players_email     on public.unclaimed_players (email)
  where email is not null;
create index unclaimed_players_added_by  on public.unclaimed_players (added_by);
create index unclaimed_players_claimed   on public.unclaimed_players (claimed_by_user_id)
  where claimed_by_user_id is not null;

-- Hard guard against double-claim races: two parallel approve_claim_request()
-- calls on the same unclaimed_id can both pass the FOR UPDATE inside the RPC
-- if they pick different claim_requests rows. The partial unique index here
-- means the loser hits a unique_violation cleanly instead of silently
-- overwriting the winner.
create unique index unclaimed_players_one_claim
  on public.unclaimed_players (unclaimed_id)
  where claimed_by_user_id is not null;

create trigger unclaimed_players_set_updated_at
  before update on public.unclaimed_players
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Auto-stamp claimed_at on the first transition of claimed_by_user_id from
-- null → non-null. Keeps the claim_consistency check passing without forcing
-- the caller to set both columns.
-- -----------------------------------------------------------------------------
create or replace function public.normalize_unclaimed_claim_timestamp()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if new.claimed_by_user_id is not null
     and old.claimed_by_user_id is distinct from new.claimed_by_user_id
     and new.claimed_at is null then
    new.claimed_at = now();
  end if;
  return new;
end;
$$;

create trigger unclaimed_players_normalize_claim
  before update on public.unclaimed_players
  for each row execute function public.normalize_unclaimed_claim_timestamp();

-- -----------------------------------------------------------------------------
-- migrate_player_stats — stub.
-- Will rewrite balls / innings / match-stat rows referencing p_unclaimed_id
-- to reference p_user_id once those tables land (see Stage W6+ in spec §8.9).
-- Today it's a no-op so the cascade trigger (in 0210) can call it safely.
-- -----------------------------------------------------------------------------
create or replace function public.migrate_player_stats(
  p_unclaimed_id uuid,
  p_user_id      uuid
)
returns void
language plpgsql
set search_path = public, pg_temp
as $$
begin
  -- TODO: rewrite balls.batsman_id, balls.bowler_id, etc. to point at the
  -- real user. Refresh player_career_stats. See spec §2.5 critical rule.
  null;
end;
$$;

-- -----------------------------------------------------------------------------
-- is_unclaimed_owner — RLS predicate.
-- SECURITY DEFINER so RLS policies on claim_requests can ask "did this user
-- create the placeholder?" without recursing through claim_requests' own
-- policies.
-- -----------------------------------------------------------------------------
create or replace function public.is_unclaimed_owner(p_unclaimed_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.unclaimed_players u
     where u.unclaimed_id = p_unclaimed_id
       and u.added_by = auth.uid()
  );
$$;

revoke all on function public.is_unclaimed_owner(uuid) from public;
grant execute on function public.is_unclaimed_owner(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- RLS — public read; only the manager who added the row can write. Inserts
-- allowed for any authenticated user (a manager creates these as part of
-- adding players to their team).
-- -----------------------------------------------------------------------------
alter table public.unclaimed_players enable row level security;

create policy "unclaimed_players_read_public"
  on public.unclaimed_players for select
  using (true);

create policy "unclaimed_players_insert_authed"
  on public.unclaimed_players for insert
  to authenticated
  with check ((select auth.uid()) = added_by);

create policy "unclaimed_players_update_owner"
  on public.unclaimed_players for update
  using ((select auth.uid()) = added_by)
  with check ((select auth.uid()) = added_by);

create policy "unclaimed_players_delete_owner"
  on public.unclaimed_players for delete
  using ((select auth.uid()) = added_by);
