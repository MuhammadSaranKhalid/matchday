-- =============================================================================
-- 0405 · match_players
-- =============================================================================
-- WHAT THIS TABLE IS
-- ------------------
-- The playing XI for a single match. One row per (match, side, player).
-- This is the table the scoring screen, scoreboard, and result builder all
-- treat as the source of truth for "who is on the field today".
--
-- WHY IT EXISTS (vs. team_members)
-- --------------------------------
-- team_members is the team's permanent roster — it answers "who is on
-- Lahore Lions?" That set doesn't change for an individual match. The XI
-- for a specific match does change — guest players, substitutes,
-- concussion replacements, impact-player swaps, players unavailable
-- through injury. None of those edits should ripple into the team roster,
-- and none of them should be expressed as edits to a uuid array column on
-- the matches row.
--
-- match_players also unifies the polymorphism: a roster entry can be a
-- profile (claimed user) or an unclaimed placeholder. team_members
-- handles this via an XOR pair (user_id, unclaimed_id). The match_players
-- row carries the same XOR (profile_id, unclaimed_id) once, and every
-- downstream table — balls, match_innings_state, matches.man_of_the_match
-- — points at match_player_id, a clean uuid. The "is this a profile or
-- an unclaimed placeholder?" question is asked exactly once per match,
-- right here.
--
-- LIFECYCLE
-- ---------
--   • Rows are inserted at lineup-lock time:
--       - For friendly matches arriving via match_requests:
--         accept_match_request (0600) inserts both sides' XIs at the
--         moment the request is accepted.
--       - For tournament matches: the Pick-XI step of MatchStart (a
--         future RPC) inserts the chosen players.
--   • Mid-match additions (substitutes, impact players) are appended with
--     is_substitute = true.
--   • When an unclaimed player claims a profile, cascade_unclaimed_claim
--     (extended in 0411) rewrites every match_players row pointing at the
--     placeholder so the same person is visible across past and future
--     matches.
--   • When a profile is deleted (delete_user RPC in 0700), the user's
--     match_players rows must first be promoted to a synthetic unclaimed
--     entry — match_players.profile_id is ON DELETE RESTRICT so the
--     delete cannot proceed without that promotion.
--
-- POLYMORPHISM CONTRACT
-- ---------------------
-- Each row references EITHER profiles.user_id (claimed player) OR
-- unclaimed_players.unclaimed_id (placeholder). Postgres cannot express a
-- polymorphic FK in one column, so we use two real FKs and the
-- match_players_xor CHECK enforces "exactly one of them is non-null".
-- Mirror of the team_members pattern.
-- =============================================================================

create table public.match_players (
  -- Surface uuid that every downstream table references. Stable across the
  -- match's lifetime; survives a profile/unclaimed identity reconciliation
  -- (the row's profile_id / unclaimed_id columns flip, the PK does not).
  match_player_id   uuid primary key default gen_random_uuid(),

  -- Which match this lineup row belongs to. Deletes cascade because the
  -- entire scorecard for that match is moot if the match itself is gone.
  match_id          uuid not null
                       references public.matches(match_id) on delete cascade,

  -- Which side of the match. Matches the 'a' / 'b' naming used everywhere
  -- else on the matches row (team_a_id, team_a_captain, ...).
  team_side         char(1) not null check (team_side in ('a', 'b')),

  -- Polymorphic player reference — exactly one is set, enforced by the
  -- match_players_xor CHECK constraint below.
  --   profile_id   → profiles.user_id    (claimed player; has an account)
  --   unclaimed_id → unclaimed_players   (placeholder created by a manager)
  -- ON DELETE RESTRICT on both sides because losing a historical lineup
  -- entry silently would corrupt the scorecard / stats lineage. The
  -- delete_user RPC (0700) and the unclaimed-cleanup paths must promote
  -- or rewrite these rows explicitly.
  profile_id        uuid references public.profiles(user_id) on delete restrict,
  unclaimed_id      uuid references public.unclaimed_players(unclaimed_id)
                       on delete restrict,

  -- Per-match attributes. NULL until the captain locks the order at toss.
  --   batting_order is 1 = opener, 2 = second batter, etc. Up to 15 to
  --     leave room for substitutes / impact players.
  --   jersey_number is uniquely allocated per (match, side) when set —
  --     a player may wear a different number for different matches,
  --     which is why this lives here and not on team_members.
  batting_order     smallint
                       check (batting_order is null
                              or batting_order between 1 and 15),
  jersey_number     smallint
                       check (jersey_number is null
                              or jersey_number between 0 and 999),

  -- Captain / keeper / substitute flags for THIS match only. A player may
  -- be Team A's permanent captain (team_members.role='captain') but vice
  -- on the day because the regular captain is unavailable; that's a
  -- match_players.is_captain edit, not a team_members edit.
  is_captain        boolean not null default false,
  is_keeper         boolean not null default false,
  is_substitute     boolean not null default false,

  added_at          timestamptz not null default now(),

  constraint match_players_xor
    check (num_nonnulls(profile_id, unclaimed_id) = 1)
);

-- -----------------------------------------------------------------------------
-- INDEXES
--
-- Two partial-unique indexes — one per "namespace" of the polymorphic ref —
-- enforce "the same person cannot appear twice on the same side of one
-- match". The same person CAN appear on the opposite side of a friendly
-- (rare but legitimate — a player guests for both sides on a charity day),
-- which is why the uniqueness is keyed on (match, side, ref), not
-- (match, ref).
--
-- jersey_number is unique per (match, side); a player wears one number per
-- match. Different sides may share a number; different matches may reuse it.
--
-- The remaining indexes serve the hot read paths:
--   * (match_id, team_side) — "show this side's XI" on the scoreboard
--   * (profile_id) partial — "show this player's match history"
--   * (unclaimed_id) partial — "show this placeholder's match history"
-- -----------------------------------------------------------------------------
create unique index match_players_unique_profile
  on public.match_players (match_id, team_side, profile_id)
  where profile_id is not null;

create unique index match_players_unique_unclaimed
  on public.match_players (match_id, team_side, unclaimed_id)
  where unclaimed_id is not null;

create unique index match_players_unique_jersey
  on public.match_players (match_id, team_side, jersey_number)
  where jersey_number is not null;

create index match_players_match_side
  on public.match_players (match_id, team_side);

create index match_players_profile
  on public.match_players (profile_id)
  where profile_id is not null;

create index match_players_unclaimed
  on public.match_players (unclaimed_id)
  where unclaimed_id is not null;

-- -----------------------------------------------------------------------------
-- CROSS-TABLE LINKAGE — matches.man_of_the_match
--
-- matches.man_of_the_match was declared as a plain uuid in 0400 because
-- match_players didn't exist yet at that point in the migration order. We
-- now attach the FK constraint. ON DELETE SET NULL because losing the
-- "best player on the day" link is preferable to blocking a match
-- deletion or a substitution-cleanup flow.
-- -----------------------------------------------------------------------------
alter table public.matches
  add constraint matches_motm_match_player
    foreign key (man_of_the_match)
    references public.match_players(match_player_id)
    on delete set null;

-- -----------------------------------------------------------------------------
-- ROW-LEVEL SECURITY
--
-- READ: public. Scorecards are public artefacts; anyone (signed-in or not)
-- can see who is in the XI of any match. Mirrors the matches / balls posture.
--
-- WRITE: no direct INSERT/UPDATE/DELETE policy. Every legitimate write
-- path is a SECURITY DEFINER RPC that runs validation we cannot express
-- as a simple RLS predicate:
--   * accept_match_request (0600) — captures the XI at request-accept time
--   * cascade_unclaimed_claim (0411) — rewrites placeholder refs to profile
--   * (future) lock_match_lineup, add_substitute — Pick-XI / mid-match swap
-- These functions bypass RLS because they own integrity.
-- -----------------------------------------------------------------------------
alter table public.match_players enable row level security;

create policy "match_players_read_public"
  on public.match_players for select
  using (true);
