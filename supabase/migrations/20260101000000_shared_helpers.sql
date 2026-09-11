-- =============================================================================
-- 0000 · Shared helpers
-- =============================================================================
-- Foundation that every later migration assumes is already there:
--
--  1. Extensions
--       pgcrypto  → gen_random_uuid() for primary keys
--       postgis   → "near me" geo queries (Feature 7, future)
--       pg_trgm   → trigram fuzzy search (usernames, team names, profiles)
--       unaccent  → fold diacritics before trigram matching
--
--  1b. f_unaccent(text)
--       IMMUTABLE wrapper around unaccent(). Moved here 2026-09-06 from
--       20260611000000_teams_search: three tables declare a GENERATED
--       search_name column that calls it, and a generated column cannot
--       reference a function that does not exist yet. It belongs with the
--       other cross-cutting helpers.
--
--  2. set_updated_at()
--       Generic BEFORE-UPDATE trigger that stamps `updated_at = now()` on any
--       row that carries an `updated_at` column. Wired by every later table
--       via a one-liner trigger declared in that table's migration. Keeping
--       this function here means we never duplicate it.
--
--  3. THE ENUM CATALOGUE — every enum type in the schema.
--       Consolidated here 2026-09-06. They used to sit next to the table that
--       first used one, which meant a type could be created in one migration
--       and then extended by `alter type ... add value` in two others, so the
--       real definition of an enum was spread across the run and you had to
--       replay the whole history to know what values it accepted. Postgres
--       also refuses `alter type ... add value` inside a transaction block in
--       older versions, which is why those extensions were awkward.
--
--       Types are free-standing: they depend on nothing and everything else
--       depends on them, so declaring them all first is the only ordering that
--       needs no forward references.
--
--       ONE RULE: a new enum value is added to the list below, in place. Do
--       NOT add `alter type ... add value` to a later migration — this project
--       is pre-production and migrations are edited at the source.
-- =============================================================================

create extension if not exists pgcrypto;
create extension if not exists postgis;
create extension if not exists pg_trgm;
create extension if not exists unaccent;

-- -----------------------------------------------------------------------------
-- f_unaccent(text) — IMMUTABLE unaccent, safe inside generated columns.
-- -----------------------------------------------------------------------------
create or replace function public.f_unaccent(text)
returns text
language sql
immutable
parallel safe
strict
set search_path = public, pg_temp
as $$
  -- Two-arg form is IMMUTABLE (single-arg is only STABLE). Bind the
  -- dictionary explicitly so the planner can constant-fold inside the
  -- generated column / index expression.
  select public.unaccent('public.unaccent', $1)
$$;

-- -----------------------------------------------------------------------------
-- set_updated_at() — generic BEFORE-UPDATE trigger function.
-- Each table that needs it wires it via:
--   create trigger <table>_set_updated_at
--     before update on public.<table>
--     for each row execute function public.set_updated_at();
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- =============================================================================
-- 3. Enum catalogue
-- =============================================================================
-- Grouped by the domain that owns them. `do $$ … exception when
-- duplicate_object` guards let the whole file re-run against a database that
-- already has some of these.

-- -----------------------------------------------------------------------------
-- 3.1 Cross-cutting
-- -----------------------------------------------------------------------------
-- request_status — shared by team_join_requests and claim_requests.
-- 'pending' is the default; 'approved' / 'rejected' come from the manager's
-- decision; 'cancelled' is requester-initiated withdrawal before a decision.
do $$ begin
  create type public.request_status as enum (
    'pending',
    'approved',
    'rejected',
    'cancelled'
  );
exception when duplicate_object then null;
end $$;

-- -----------------------------------------------------------------------------
-- 3.2 Identity — profiles, player_profiles
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.account_status as enum ('active', 'suspended', 'deleted');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.user_gender as enum (
    'male',
    'female',
    'other',
    'prefer_not_to_say'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.batting_style as enum ('right_hand', 'left_hand');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.bowling_style as enum (
    'right_arm_fast',
    'right_arm_medium',
    'right_arm_spin',
    'left_arm_fast',
    'left_arm_spin',
    'doesnt_bowl'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.player_role as enum (
    'batter',
    'bowler',
    'all_rounder',
    'wicket_keeper'
  );
exception when duplicate_object then null;
end $$;

-- The ball a match is played with. NOT to be confused with the former
-- match_deliveries.ball_type, which held 'legal'/'wide'/… — that column was a
-- duplicate of delivery_kind and was dropped on 2026-09-06, which leaves this
-- name meaning exactly one thing.
do $$ begin
  create type public.ball_type as enum ('leather', 'tape', 'tennis');
exception when duplicate_object then null;
end $$;

-- -----------------------------------------------------------------------------
-- 3.3 Teams
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.team_type as enum (
    'club',
    'village',
    'casual',
    'corporate',
    'school',
    'university'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.team_privacy as enum ('public', 'private');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.team_status as enum ('active', 'disbanded', 'archived');
exception when duplicate_object then null;
end $$;

-- member_role was DELETED 2026-09-11. Roles are rows now, in public.roles
-- (20260101000205_authz.sql), so that adding one is an INSERT rather than a
-- schema migration — and so that a member can hold SEVERAL, which a single
-- enum-typed column could never express. See docs/team-roles-design.md.
--
-- Its old values are worth recording, because two of them did not survive:
--   captain, player       → rows in public.roles (plus owner, manager)
--   vice_captain          → dropped for v1
--   wicket_keeper         → never belonged. A keeper can also be the captain,
--                           so it cannot be a rung. It lives where it means
--                           something: player_profiles.player_role (a career
--                           fact) and match_players.role (this match's XI).

do $$ begin
  create type public.member_status as enum ('active', 'inactive', 'removed');
exception when duplicate_object then null;
end $$;

-- -----------------------------------------------------------------------------
-- 3.4 Tournaments
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.tournament_type as enum (
    'knockout',
    'round_robin',
    'league',
    'group_knockout',          -- v1.1
    'double_elimination'       -- v1.2
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.tournament_status as enum (
    'draft',
    'registration',
    'upcoming',
    'live',
    'completed',
    'cancelled',
    'abandoned'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.tournament_privacy as enum ('public', 'private');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.tournament_registration_status as enum (
    'pending',
    'approved',
    'rejected',
    'withdrawn'
  );
exception when duplicate_object then null;
end $$;

-- -----------------------------------------------------------------------------
-- 3.5 Grounds
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.ground_surface as enum (
    'turf', 'matting', 'concrete', 'astro', 'other'
  );
exception when duplicate_object then null;
end $$;

-- -----------------------------------------------------------------------------
-- 3.6 Matches & scoring
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.match_format as enum (
    't20', 'odi', 'test', 'the_hundred', 'custom_limited', 'pairs'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.match_type as enum (
    'friendly', 'tournament', 'practice', 'league'
  );
exception when duplicate_object then null;
end $$;

-- 'tied' and 'no_result' were appended by 20260830500000 via `alter type`;
-- folded in 2026-09-06 and that migration deleted.
--
-- 'rescheduled' is folded in from the other direction: it was NEVER in any
-- create-type in this repo, yet match_request_expiry_cron filters
-- `status in ('scheduled', 'rescheduled')` and the Dart MatchStatus enum
-- carries it. That query raises "invalid input value for enum match_status"
-- the moment it runs. The two halves of the drift are now one list.
do $$ begin
  create type public.match_status as enum (
    'scheduled', 'toss', 'rescheduled', 'live', 'innings_break', 'super_over',
    'completed', 'abandoned', 'tied', 'no_result', 'walkover'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.toss_decision as enum ('bat', 'bowl');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.match_stage as enum (
    'group', 'quarter_final', 'semi_final', 'final', 'playoff'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.match_start_phase as enum (
    'toss', 'lineup', 'ready', 'live'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.scoring_mode as enum (
    'live_ball_by_ball', 'post_match_scorecard'
  );
exception when duplicate_object then null;
end $$;

-- Note 'bye' and 'leg_bye' ARE legal deliveries (they count towards the over);
-- only 'wide' and 'no_ball' are re-bowled. match_deliveries states that as a
-- check constraint.
do $$ begin
  create type public.delivery_kind as enum (
    'legal', 'wide', 'no_ball', 'bye', 'leg_bye', 'penalty'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.wicket_kind as enum (
    'bowled', 'caught', 'caught_and_bowled', 'lbw', 'run_out',
    'stumped', 'hit_wicket', 'retired_hurt', 'retired_out',
    'obstructing_the_field', 'timed_out', 'handled_the_ball'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.match_role as enum (
    'captain', 'vice_captain', 'wicket_keeper', 'player', 'substitute'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.match_request_status as enum (
    'pending',
    'countered',
    'accepted',
    'declined',
    'cancelled',
    'expired'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.decline_reason as enum (
    'roster',       -- "Roster too thin"
    'busy',         -- "Already playing that day"
    'no_interest',  -- "No interest right now"
    'format',       -- "Format doesn't suit us"
    'venue',        -- "Venue too far"
    'other'         -- free-text in decision_note
  );
exception when duplicate_object then null;
end $$;

-- -----------------------------------------------------------------------------
-- 3.7 Social — posts, comments, follows
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.post_author_context as enum (
    'personal',
    'team_manager',
    'tournament_organizer'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.post_type as enum (
    'text',
    'photo',
    'match_announcement',
    'recruitment',
    'tournament_update'
  );
exception when duplicate_object then null;
end $$;

-- Deliberately one value. 'followers_only' arrives with private accounts
-- (v1.2); the column exists now so the wire format does not change then.
do $$ begin
  create type public.post_visibility as enum ('public');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.post_status as enum ('active', 'hidden', 'deleted', 'reported');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.comment_status as enum ('active', 'deleted', 'reported');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.follow_target_type as enum ('user', 'team', 'tournament');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.follow_status as enum ('active', 'muted');
exception when duplicate_object then null;
end $$;

-- -----------------------------------------------------------------------------
-- 3.8 Chat
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.chat_type as enum ('team', 'dm', 'match', 'group');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.chat_role as enum ('admin', 'member');
exception when duplicate_object then null;
end $$;

-- -----------------------------------------------------------------------------
-- 3.9 Notifications
-- -----------------------------------------------------------------------------
-- The full taxonomy. 'match_request' / 'match_request_decision' were appended
-- by 20260101000600 via `alter type`; folded in 2026-09-06. The five values
-- after them close gaps found in the 2026-09-06 schema audit: flows that exist
-- in the schema (team join requests, tournament registration decisions, DM
-- requests, chat messages) had no notification type to fire.
do $$ begin
  create type public.notification_type as enum (
    'follow',
    'post_like',
    'post_comment',
    'comment_reply',
    'mention',
    'team_post',
    'tournament_post',
    'match_starting',
    'match_upcoming',
    'stat_milestone',
    'claim_decision',
    'team_invitation',
    'match_request',
    'match_request_decision',
    'team_join_request',
    'team_join_decision',
    'tournament_registration',
    'tournament_registration_decision',
    'dm_request',
    'chat_message'
  );
exception when duplicate_object then null;
end $$;
