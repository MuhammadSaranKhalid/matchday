-- Migration file: 20260101000120_unclaimed_players.sql

-- 0120 · unclaimed_players
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

-- Section: Tables and constraints

create table public.unclaimed_players(
  unclaimed_id       uuid primary key default gen_random_uuid(),
  sport_id           text not null references public.sports(sport_id) on update restrict on delete restrict,
  display_name       text not null check (length(display_name) between 1 and 80),
  phone_number       text,
  email              text,
  -- Manager who created this placeholder, NULL once they delete their account
  -- (or for the synthetic placeholder delete_user creates for a departing
  -- player, which no manager created).
  --
  -- 20260609000000 made this NOT NULL on the grounds that "the app always sets
  -- it on insert". True at insert time, but NOT NULL and ON DELETE SET NULL
  -- are contradictory: the first account deletion raises a not-null violation.
  -- The placeholder must outlive its creator — that is the entire point of the
  -- table — so the column is nullable and the FK keeps SET NULL. Folded and
  -- corrected 2026-09-06.
  added_by           uuid references public.profiles(user_id) on delete set null,
  -- Set when the placeholder is claimed. claimed_at is auto-stamped by the
  -- BEFORE-UPDATE trigger below if the caller didn't set it.
  claimed_by_user_id uuid references public.profiles(user_id) on delete set null,
  claimed_at         timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  -- Normalised display_name for trigram search. GENERATED — never write it.
  search_name        text generated always as (lower(public.f_unaccent(coalesce(display_name, '')))) stored,
  -- Composite FK target for sport-specific extensions.
  constraint unclaimed_players_id_sport_unique unique (unclaimed_id, sport_id),
  -- Either both claim columns are null, or both are non-null.
  constraint claim_consistency check ((claimed_by_user_id is null and claimed_at is null) or (claimed_by_user_id is not null and claimed_at is not null))
);

-- Section: Indexes

create index unclaimed_players_sport_id on public.unclaimed_players(sport_id);

create index unclaimed_players_phone on public.unclaimed_players(phone_number)
where
  phone_number is not null;

create index unclaimed_players_email on public.unclaimed_players(email)
where
  email is not null;

create index unclaimed_players_added_by on public.unclaimed_players(added_by);

create index unclaimed_players_claimed on public.unclaimed_players(claimed_by_user_id)
where
  claimed_by_user_id is not null;

comment on column public.unclaimed_players.sport_id is 'Single sport represented by this unclaimed placeholder. '
  'Normally derived from the team that created the placeholder.';

-- Section: Triggers

-- An existing placeholder never changes sports.
create trigger unclaimed_players_sport_immutable
  before update of sport_id on public.unclaimed_players for each row
  execute function public.prevent_sport_reassignment();

-- Section: Indexes (continued)

-- Hard guard against double-claim races: two parallel approve_claim_request()
-- calls on the same unclaimed_id can both pass the FOR UPDATE inside the RPC
-- if they pick different claim_requests rows. The partial unique index here
-- means the loser hits a unique_violation cleanly instead of silently
-- overwriting the winner.
create unique index unclaimed_players_one_claim on public.unclaimed_players(unclaimed_id)
where
  claimed_by_user_id is not null;

-- Section: Triggers (continued)

create trigger unclaimed_players_set_updated_at
  before update on public.unclaimed_players for each row
  execute function public.set_updated_at();

-- Section: Functions

-- Auto-stamp claimed_at on the first transition of claimed_by_user_id from
-- null → non-null. Keeps the claim_consistency check passing without forcing
-- the caller to set both columns.
create or replace function public.normalize_unclaimed_claim_timestamp()
  returns trigger
  language plpgsql
  set search_path = public, pg_temp
  as $$
begin
  if new.claimed_by_user_id is not null and old.claimed_by_user_id is distinct from new.claimed_by_user_id and new.claimed_at is null then
    new.claimed_at = now();
  end if;
  return new;
end;
$$;

-- Section: Triggers (continued)

create trigger unclaimed_players_normalize_claim
  before update on public.unclaimed_players for each row
  execute function public.normalize_unclaimed_claim_timestamp();

-- Section: Functions (continued)

-- migrate_player_stats — stub.
-- Will rewrite balls / innings / match-stat rows referencing p_unclaimed_id
-- to reference p_user_id once those tables land (see Stage W6+ in spec §8.9).
-- Today it's a no-op so the cascade trigger (in 0210) can call it safely.
create or replace function public.migrate_player_stats(
  p_unclaimed_id uuid,
  p_user_id uuid
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

-- is_unclaimed_owner — RLS predicate.
-- SECURITY DEFINER so RLS policies on claim_requests can ask "did this user
-- create the placeholder?" without recursing through claim_requests' own
-- policies.
create or replace function public.is_unclaimed_owner(
  p_unclaimed_id uuid
)
  returns boolean
  language sql
  stable
  security definer
  set search_path = public, pg_temp
  as $$
  select
    exists(
      select
        1
      from
        public.unclaimed_players u
      where
        u.unclaimed_id = p_unclaimed_id
        and u.added_by = auth.uid());
$$;

revoke all on function public.is_unclaimed_owner(uuid) from public;

grant execute on function public.is_unclaimed_owner(uuid) to authenticated;

-- Section: Enable row-level security

-- RLS — public read; only the manager who added the row can write. Inserts
-- allowed for any authenticated user (a manager creates these as part of
-- adding players to their team).
alter table public.unclaimed_players enable row level security;

-- Section: Policies

create policy "unclaimed_players_read_public" on public.unclaimed_players
  for select to anon, authenticated
  using (true);

-- Shared placeholder creation is RPC-owned.
-- sport_id must be derived from the team, not trusted from the client.
create policy "unclaimed_players_no_direct_insert" on public.unclaimed_players
  for insert to authenticated
  with check (false);

-- Section: Permissions

revoke insert on public.unclaimed_players from authenticated;

-- Section: Policies (continued)

create policy "unclaimed_players_update_owner" on public.unclaimed_players
  for update to authenticated
  using ((
    select
      auth.uid()) = added_by)
  with check ((
    select
      auth.uid()) = added_by);

create policy "unclaimed_players_delete_owner" on public.unclaimed_players
  for delete to authenticated
  using ((
    select
      auth.uid()) = added_by);

-- Section: Permissions (continued)

-- PII: phone_number and email are NOT readable through the API.
-- These are contact details for people who never signed up and never consented
-- — the most sensitive data in the database. The read policy above is
-- `using (true)` because rosters, scorecards and match lineups all have to
-- render an unclaimed player's NAME to anyone looking at a public match. RLS
-- is row-level, so it cannot make the name public and the phone number private.
--
-- Column-level GRANTs can. Revoking the two sensitive columns from the API
-- roles means PostgREST rejects any select that touches them, while
-- `select unclaimed_id, display_name, ...` keeps working. Writes still work
-- because the insert/update policies above already restrict them to the
-- manager who owns the row, and INSERT privilege is granted at table level.
--
-- The one screen that legitimately needs the phone (team join-request review,
-- teams_remote_datasource.dart) goes through
-- unclaimed_player_contact_for_manager() below, which is SECURITY DEFINER and
-- checks that the caller manages a team the placeholder belongs to.
-- NOTE the shape: you cannot subtract a column from a table-level SELECT.
-- `revoke select (phone_number, email) …` is a no-op while the role still
-- holds SELECT on the whole table (which 0010's ALTER DEFAULT PRIVILEGES
-- grants to every new table). The table-level grant has to go first, and the
-- allowed columns granted back explicitly.
revoke select on public.unclaimed_players from anon, authenticated;

grant select (unclaimed_id, sport_id, display_name, added_by, claimed_by_user_id, claimed_at, created_at, updated_at, search_name) on public.unclaimed_players to anon, authenticated;

-- Section: Functions (continued)

-- The accessor itself, unclaimed_player_contact_for_manager(), is declared in
-- 20260101000210_team_members.sql. It has to be: it is `language sql`, so
-- Postgres checks its body at CREATE time, and it reads teams (0200) and
-- team_members (0210) — neither of which exists yet at 0120.
-- RPC: claim_unclaimed_by_phone()
-- Links any unclaimed_players records matching the authenticated user's phone
-- number to their real user_id, triggering the cascade claim rewrites.
create or replace function public.claim_unclaimed_by_phone()
  returns int
  language plpgsql
  security definer
  set search_path = public, pg_temp
  as $$
declare
  v_phone text;
  v_claimed_count int := 0;
  v_rec record;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;
  select
    phone
  into
    v_phone
  from
    auth.users
  where
    id = auth.uid();
  if v_phone is null or length(trim(v_phone)) = 0 then
    return 0;
  end if;
  v_phone := '+' || ltrim(trim(v_phone), '+');
  for v_rec in
  select
    unclaimed_id
  from
    public.unclaimed_players
  where (phone_number = v_phone
    or phone_number = ltrim(v_phone, '+'))
    and claimed_by_user_id is null loop
      update
        public.unclaimed_players
      set
        claimed_by_user_id = auth.uid(),
        claimed_at = now()
      where
        unclaimed_id = v_rec.unclaimed_id;
      v_claimed_count := v_claimed_count + 1;
    end loop;
  return v_claimed_count;
end;
$$;

revoke all on function public.claim_unclaimed_by_phone() from public;

grant execute on function public.claim_unclaimed_by_phone() to authenticated;

create index if not exists unclaimed_players_search_trgm on public.unclaimed_players using gin(search_name gin_trgm_ops)
where
  claimed_by_user_id is null;
