-- F2 — Relax the format-blind CHECK constraints.
--
-- These bounds assumed 11-a-side, 6-ball overs. With `format` now authoritative
-- (the scoring engine enforces wicketsToAllOut = playersPerTeam-1, ballsPerOver,
-- and oversPerInnings), the DB constraints recede to permissive sanity bounds so
-- non-XI team sizes and non-6-ball overs can be stored:
--   * match_innings_state.total_wickets  0..10 -> 0..14
--       (batting_order allows up to 15 players => up to 14 wickets)
--   * balls.ball_in_over                 0..6  -> 0..10
--       (covers 8-ball overs and The Hundred's 5-ball sets)
-- innings_number 1..4 is unchanged (covers super-over = 3 and Test = 4).

alter table public.match_innings_state
  drop constraint if exists match_innings_state_total_wickets_check;
alter table public.match_innings_state
  add constraint match_innings_state_total_wickets_check
  check (total_wickets >= 0 and total_wickets <= 14);

alter table public.balls
  drop constraint if exists balls_ball_in_over_check;
alter table public.balls
  add constraint balls_ball_in_over_check
  check (ball_in_over >= 0 and ball_in_over <= 10);
