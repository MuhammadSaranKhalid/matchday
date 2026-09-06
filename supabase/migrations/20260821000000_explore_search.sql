-- =============================================================================
-- 20260821 · explore search (players)
-- =============================================================================
-- Extends the search foundation from `20260611000000_teams_search.sql` to
-- profiles, so the Explore tab can search players alongside teams.
--
-- Mirrors the teams pattern exactly (docs/search-feature-design.md §7):
--   normalised generated column + partial GIN trigram index scoped to the
--   discoverable hot set. `f_unaccent()` already exists from 0611.
--
-- What we add
--   1. profiles.search_name — generated, stored:
--        lower(f_unaccent(display_name || ' ' || username))
--      Both fields in one column so "salah" matches a display name and
--      "@salah_a" matches a handle through a single index. username is
--      nullable until onboarding completes, hence the coalesce.
--   2. profiles_search_trgm — partial GIN trigram index over the set that is
--      actually discoverable: active accounts that have not opted out of
--      search. The predicate MUST match the search-all edge function's WHERE
--      byte-for-byte or the planner will not pick this index (same trap as
--      teams_search_trgm — see docs §17).
--
-- Privacy note (the reason for the predicate)
--   `profiles.discoverability` has shipped since 0100 with an
--   `appear_in_search` flag defaulting to true, and NOTHING has ever enforced
--   it — not the client, not an edge function, not RLS. This migration makes
--   the flag real: opted-out profiles fall out of the index and are hard-
--   filtered by the search SQL. The search-all function runs as service role
--   and therefore bypasses RLS, so this predicate IS the access control.
--
-- What we deliberately leave alone
--   - `profiles_username_trgm` (raw username GIN from 0100) stays for now: the
--     add-player picker in teams still uses a bare ILIKE against username.
--     Drop it in the follow-up that retires teams_remote_datasource.searchUsers.
--   - No geo. Explore v1 ships without proximity ranking (no coordinates exist
--     yet — nothing in the app captures them). `profiles.location_point` and
--     `profiles_location_point` already exist from 0100 and are untouched,
--     ready for when near-me lands.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Normalised, generated search column.
-- -----------------------------------------------------------------------------
-- display_name is NOT NULL; username is nullable until onboarding sets it.
-- coalesce keeps the expression total so the generated column never goes NULL
-- (a NULL here would silently drop the row out of the trigram index).
-- profiles.search_name is declared inline in 20260101000100_profiles.sql
-- (folded there 2026-09-06). The index below is what this migration owns.

comment on column public.profiles.search_name is
  'Normalised (lower + accent-folded) "display_name username" for trigram '
  'search. Generated — never write to it directly.';

-- -----------------------------------------------------------------------------
-- 2. Partial trigram index on the discoverable hot set.
-- -----------------------------------------------------------------------------
-- Predicate mirrors search-all's WHERE clause exactly. `discoverability` is
-- `not null default '{...}'`, but a hand-written row could still omit the key,
-- so coalesce to true (opt-out, not opt-in) to match the column's documented
-- default-on semantics.
create index profiles_search_trgm
  on public.profiles using gin (search_name gin_trgm_ops)
  where account_status = 'active'
    and coalesce((discoverability->>'appear_in_search')::boolean, true);

-- -----------------------------------------------------------------------------
-- 3. Unclaimed players — same treatment.
-- -----------------------------------------------------------------------------
-- Unclaimed players are people a captain added to a squad who have not signed
-- up yet. They must be searchable: design/spec.txt §3.1 "Path B: search-and-
-- claim" has the player find their own record ("Ahmed Khan in Lahore Lions,
-- added by Bilal Ahmed") and claim it. The Explore player results render them
-- with an "Unclaimed" badge.
--
-- PRIVACY: this row can hold `phone_number` and `email`, captured by a captain
-- WITHOUT the person's consent. Those columns must never leave the server.
-- The search-all edge function selects display_name + player_profile + team
-- context only — never contact fields. Do not widen that projection.
--
-- Only unclaimed rows are indexed: once claimed, the person has a real profile
-- and should surface through `profiles` instead (otherwise they appear twice).
-- unclaimed_players.search_name is declared inline in
-- 20260101000120_unclaimed_players.sql (folded there 2026-09-06).

comment on column public.unclaimed_players.search_name is
  'Normalised display_name for trigram search. Generated — never write directly.';

create index unclaimed_players_search_trgm
  on public.unclaimed_players using gin (search_name gin_trgm_ops)
  where claimed_by_user_id is null;
