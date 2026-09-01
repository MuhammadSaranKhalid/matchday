-- =============================================================================
-- 20260830500000 · match_status_values
-- =============================================================================
-- More drift between the migration history and the deployed database.
--
-- 20260101000400_matches.sql declares match_status as
--   scheduled, toss, live, innings_break, super_over,
--   completed, abandoned, tied, no_result, walkover
--
-- but production actually has
--   scheduled, toss, live, innings_break, super_over,
--   completed, abandoned, rescheduled, walkover
--
-- i.e. it gained `rescheduled` and never got `tied` or `no_result`. Anything
-- referencing those two fails: `tournament_ground_clashes` (language sql) is
-- rejected at create time, while `recalculate_tournament_standings` and
-- `tournament_abandon_match` (plpgsql) compile fine and fail at runtime — the
-- same trap that hid `winner_id` and `batting_team_id`.
--
-- Adding the values is its own migration on purpose: Postgres allows
-- ALTER TYPE ... ADD VALUE inside a transaction, but the new value cannot be
-- *used* until that transaction commits. Every migration runs in one, so the
-- functions that use these labels must live in a later file.
--
-- `rescheduled` is left alone. Nothing in the tournament code writes it, and
-- removing an enum value would mean rebuilding the type.
-- =============================================================================

alter type public.match_status add value if not exists 'tied';
alter type public.match_status add value if not exists 'no_result';
