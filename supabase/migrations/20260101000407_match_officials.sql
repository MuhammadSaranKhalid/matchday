-- =============================================================================
-- 0407 · match_officials
-- =============================================================================
-- WHAT THIS TABLE IS
-- ------------------
-- The set of people authorised to act on a match in some official
-- capacity. Today that means scorers; tomorrow it means umpires and the
-- match referee. One row per (match, role, user).
--
-- WHY IT EXISTS
-- -------------
-- The previous design held this as `matches.assigned_scorers uuid[]` — a
-- single Postgres array carrying the list of scorer user ids. That had
-- three problems:
--
--   1. No role. Cricket has more officials than scorers. The on-field
--      umpire(s), the third umpire, and the match referee are all roles
--      with different decision authorities; lumping them into one array
--      flattens that distinction.
--
--   2. Slow RLS check. Every ball insert ran
--      `auth.uid() = any(assigned_scorers)` inside the RLS predicate, a
--      sequential scan of the array per row. An indexed EXISTS lookup
--      against a real table is dramatically cheaper at scale.
--
--   3. No audit. An array assignment overwrites silently — you cannot
--      see who added a scorer and when. The rows here record both.
--
-- One person may hold multiple roles on one match (in club cricket the
-- senior scorer is sometimes also the field umpire when a second umpire
-- can't be found). The composite primary key (match_id, role, user_id)
-- supports that without duplicating the row.
--
-- WHO READS THIS
-- --------------
--   * _can_score_match (the redefinition below) — for every record_ball,
--     undo_last_ball, submit_match_openers, submit_match_result call.
--   * The match-detail screen renders the officials list on the scorecard
--     header.
--   * Push notifications target umpires for "review requested" pings.
--
-- WHO WRITES THIS
-- ---------------
--   * start_match_now (0623) — auto-registers the batting captain as a
--     scorer when they tip the match to Live so they can record the first
--     ball.
--   * A future assign_match_official RPC will handle umpire and referee
--     assignment from the tournament dashboard.
--   * The cascade_unclaimed_claim trigger does NOT need to touch this
--     table because officials are always claimed users (only profiles
--     have authentication, and only authenticated users can score).
-- =============================================================================

create table public.match_officials (
  -- Which match this assignment applies to.
  match_id     uuid not null
                   references public.matches(match_id) on delete cascade,

  -- Which user. References profiles (not match_players) because officials
  -- need to authenticate — only claimed users have an auth identity. A
  -- match official is not necessarily a player in the match.
  user_id      uuid not null
                   references public.profiles(user_id) on delete cascade,

  -- What role they hold for this match. Closed enumeration; expand the
  -- CHECK when a new role is needed (no ALTER TYPE dance because this is
  -- a text column with a check constraint rather than a PostgreSQL enum).
  role         text not null
                   check (role in (
                     'scorer',        -- can record_ball / undo_last_ball
                     'umpire_main',   -- on-field umpire at the bowler's end
                     'umpire_leg',    -- on-field umpire at square leg
                     'umpire_third',  -- TV / off-field umpire (DRS)
                     'referee'        -- match referee (code-of-conduct)
                   )),

  assigned_at  timestamptz not null default now(),

  -- Who made the assignment. SET NULL on deletion so a removed admin
  -- doesn't take the audit trail with them.
  assigned_by  uuid references public.profiles(user_id) on delete set null,

  -- Composite PK enforces "one (match, role, user) row at most" — the
  -- same person cannot be assigned the same role twice on the same match,
  -- but can hold multiple distinct roles.
  primary key (match_id, role, user_id)
);

-- -----------------------------------------------------------------------------
-- INDEX
-- A user-side lookup: "what matches am I scoring / umpiring?" The (user, role)
-- composite serves both the unscoped "my upcoming officiating duties" feed
-- and the role-scoped "my scoring queue" / "my umpire queue".
-- -----------------------------------------------------------------------------
create index match_officials_user
  on public.match_officials (user_id, role);

-- -----------------------------------------------------------------------------
-- ROW-LEVEL SECURITY
--
-- READ: public. The published scorecard names the officials.
-- WRITE: SECURITY DEFINER RPCs only. No direct policy is necessary because
-- the only legitimate writers are the RPCs listed above. Direct INSERT
-- attempts are denied implicitly by the absence of a policy.
-- -----------------------------------------------------------------------------
alter table public.match_officials enable row level security;

create policy "match_officials_read_public"
  on public.match_officials for select
  using (true);

-- =============================================================================
-- _can_score_match — extend the stub from 0400 with the per-match scorer
-- branch.
-- =============================================================================
-- WHY THIS LIVES HERE
-- -------------------
-- 0400 (matches.sql) declared a STUB version of _can_score_match that only
-- recognised tournament organisers and friendly/practice creators. We
-- couldn't include the match_officials branch there because the table did
-- not exist yet.
--
-- Now that match_officials is in place, we replace the body with the full
-- predicate. The signature, language, volatility, security mode, and
-- search_path are unchanged, so:
--   * the GRANT to `authenticated` from 0400 carries through;
--   * every existing caller (balls RLS, scoring RPCs, submit_match_result)
--     picks up the new body automatically — no other CREATE OR REPLACE
--     needed elsewhere.
--
-- THE PREDICATE
-- -------------
-- Returns true if any of these is true for the calling auth.uid():
--   1. The match belongs to a tournament AND the caller is one of its
--      organisers (is_tournament_organizer).
--   2. The caller has a 'scorer' row in match_officials for this match.
--   3. The match is friendly/practice AND the caller created it.
--
-- All other RPCs that need "can this user act as a scorer here?" call
-- this predicate. The same predicate also gates the balls table's
-- INSERT / UPDATE / DELETE policies. Centralising the rule here means
-- changing it once changes it everywhere.
-- =============================================================================
create or replace function public._can_score_match(p_match_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.matches m
     where m.match_id = p_match_id
       and (
         -- Tournament organiser branch
         (m.tournament_id is not null
           and public.is_tournament_organizer(m.tournament_id))

         -- Per-match scorer branch (the reason this file extends the stub)
         or exists (
           select 1 from public.match_officials mo
            where mo.match_id = m.match_id
              and mo.user_id  = (select auth.uid())
              and mo.role     = 'scorer'
         )

         -- Friendly / practice fallback — the creator can always score
         -- their own friendly even if they haven't been added as a
         -- formal scorer (preserves the v1.0 single-captain UX).
         or (m.match_type in ('friendly', 'practice')
             and m.created_by = (select auth.uid()))
       )
  );
$$;
