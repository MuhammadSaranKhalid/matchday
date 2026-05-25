-- =============================================================================
-- 0400 · matches
-- =============================================================================
-- Spec §4.3, §4.4, §4.11, §3.8. Feature 4 (Match Lifecycle).
--
-- A match is the unit of play: scheduled → toss → live → completed. Three
-- match_type values:
--   tournament   — must reference a tournaments row (FK enforced via CHECK)
--   friendly     — open friendly match between two teams (no tournament)
--   practice     — same as friendly but tagged for filtering / stats decay
--
-- Polymorphic team refs:
--   team_a_id / team_b_id are nullable so knockout rounds beyond R1 can be
--   pre-created with empty slots and filled in by the after-match-complete
--   trigger (0420) when feeder matches finish. round-robin / friendly always
--   has both teams set.
--
-- Bracket linkage (knockout):
--   bracket_round_number  1..N where N = total rounds (Final = N).
--   bracket_match_number  1-indexed position within the round.
--   prev_match_a_id /     point at the two feeder matches whose winners flow
--   prev_match_b_id       in here.
--
-- Toss / XI / scoring:
--   toss_won_by + toss_decision flip together (CHECK constraint).
--   team_a_squad / team_b_squad are uuid[] of the playing XI locked at toss.
--   captain / keeper indices are stored separately to avoid a follow-up scan.
--
-- Scoring mode (§4.6):
--   live_ball_by_ball — scorer enters every delivery (drives 0410 balls).
--   post_match_scorecard — final result is jsonb-blob via submit_match_result.
--
-- On-field state (§4.6):
--   current_striker_id / current_non_striker_id / current_bowler_id persist
--   the live-scoring widget state on the match row so a reconnecting scorer
--   (or a second authorized scorer) picks up exactly where the last one
--   left off, and the spectator scoreboard can render the on-strike
--   batter's name. All three are nullable: pre-toss the field is empty,
--   between innings (status='innings_break') they reset to null, and the
--   bowler is cleared at the end of every over until the scorer picks the
--   next one.
--
-- This file owns the table, RLS, and the fixture-generation RPCs for the
-- two formats currently supported (round-robin / league / knockout). Result
-- handling + standings recompute live in 0420.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Match-only enums.
-- -----------------------------------------------------------------------------
create type public.match_type   as enum ('tournament', 'friendly', 'practice');
create type public.match_status as enum (
  'scheduled',
  'toss',
  'live',
  'innings_break',
  'super_over',
  'completed',
  'abandoned',
  'rescheduled',
  'walkover'
);
create type public.toss_decision as enum ('bat', 'bowl');
create type public.scoring_mode as enum (
  'live_ball_by_ball',
  'post_match_scorecard'
);

-- Pre-Live sub-state machine for the MatchStartScreen stepper. Forward-only;
-- enforced by a trigger declared after the matches table below. `status`
-- stays the cricket-domain lifecycle; `start_phase` is the UI sub-state
-- between "request accepted" and "first ball bowled".
create type public.match_start_phase as enum (
  'toss',     -- waiting on / mid-toss
  'lineup',   -- toss done; batting captain picking openers
  'ready',    -- openers locked; waiting for Start
  'live'      -- mirrors status='live'
);

-- -----------------------------------------------------------------------------
-- matches table.
-- -----------------------------------------------------------------------------
create table public.matches (
  match_id              uuid primary key default gen_random_uuid(),
  tournament_id         uuid references public.tournaments(tournament_id) on delete cascade,
  match_type            public.match_type not null default 'friendly',

  -- Free-text round label ("QF1", "SF1", "Final", "Group A · R1").
  round                 text,
  bracket_round_number  integer
                          check (bracket_round_number is null
                                 or bracket_round_number >= 1),
  bracket_match_number  integer
                          check (bracket_match_number is null
                                 or bracket_match_number >= 1),
  -- For pre-created later rounds — winners flow in via the after-complete
  -- trigger declared in 0420.
  prev_match_a_id       uuid references public.matches(match_id) on delete set null,
  prev_match_b_id       uuid references public.matches(match_id) on delete set null,
  group_id              text,

  -- Knockout seeding (§3.8.1). Null for round-robin.
  seed_a                integer,
  seed_b                integer,

  team_a_id             uuid references public.teams(team_id) on delete set null,
  team_b_id             uuid references public.teams(team_id) on delete set null,
  team_a_squad          uuid[] not null default '{}',
  team_b_squad          uuid[] not null default '{}',
  team_a_captain        uuid references public.profiles(user_id) on delete set null,
  team_b_captain        uuid references public.profiles(user_id) on delete set null,
  team_a_keeper         uuid references public.profiles(user_id) on delete set null,
  team_b_keeper         uuid references public.profiles(user_id) on delete set null,

  -- Per-match override of tournament defaults; falls back to the parent
  -- tournament's `format` jsonb when null/empty.
  format                jsonb not null default '{}'::jsonb,
  venue                 text,

  scheduled_start_time  timestamptz,
  actual_start_time     timestamptz,
  end_time              timestamptz,

  toss_won_by           uuid references public.teams(team_id) on delete set null,
  toss_decision         public.toss_decision,
  -- Coin face recorded on the host phone — UX recap only; non-load-bearing.
  toss_face             char(1) check (toss_face is null or toss_face in ('H', 'T')),

  -- MatchStart stepper sub-state. New matches default to 'toss'; forward-only
  -- trigger below prevents flipping back to earlier phases.
  start_phase           public.match_start_phase not null default 'toss',
  openers_submitted_by  uuid references public.profiles(user_id) on delete set null,
  openers_submitted_at  timestamptz,

  scoring_mode          public.scoring_mode not null default 'live_ball_by_ball',
  assigned_scorers      uuid[] not null default '{}',
  current_innings       integer not null default 1
                          check (current_innings between 1 and 4),

  -- Live on-field state — persisted so scorer-handoff and spectator
  -- scoreboard both see the same striker / non-striker / bowler.
  current_striker_id     uuid references public.profiles(user_id) on delete set null,
  current_non_striker_id uuid references public.profiles(user_id) on delete set null,
  current_bowler_id      uuid references public.profiles(user_id) on delete set null,

  status                public.match_status not null default 'scheduled',
  result                jsonb,                       -- §4.10 result jsonb
  man_of_the_match      uuid references public.profiles(user_id) on delete set null,

  created_by            uuid not null
                            references public.profiles(user_id) on delete restrict,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),

  -- Tournament matches must have a tournament_id; friendly/practice must not.
  constraint matches_type_consistency check (
    (match_type = 'tournament' and tournament_id is not null)
    or (match_type in ('friendly', 'practice') and tournament_id is null)
  ),
  constraint matches_toss_consistency check (
    (toss_won_by is null and toss_decision is null)
    or (toss_won_by is not null and toss_decision is not null)
  ),
  -- A team can't play itself (when both are set).
  constraint matches_distinct_teams check (
    team_a_id is null or team_b_id is null or team_a_id <> team_b_id
  ),
  -- Striker and non-striker must be two different players (when both are set).
  constraint matches_current_batters_distinct check (
    current_striker_id is null
    or current_non_striker_id is null
    or current_striker_id <> current_non_striker_id
  )
);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------
create index matches_tournament       on public.matches (tournament_id) where tournament_id is not null;
create index matches_team_a           on public.matches (team_a_id) where team_a_id is not null;
create index matches_team_b           on public.matches (team_b_id) where team_b_id is not null;
create index matches_status           on public.matches (status);
create index matches_scheduled        on public.matches (scheduled_start_time);
create index matches_tournament_round on public.matches (tournament_id, bracket_round_number, bracket_match_number)
  where tournament_id is not null;

create trigger matches_set_updated_at
  before update on public.matches
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Forward-only enforcement on start_phase (toss → lineup → ready → live).
-- Without this, a buggy client or a stale RPC call could flip a live match
-- back to 'toss' and re-render the start stepper, hiding the scoring screen.
-- -----------------------------------------------------------------------------
create or replace function public._enforce_start_phase_forward()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_old_rank int;
  v_new_rank int;
begin
  if new.start_phase = old.start_phase then
    return new;
  end if;
  v_old_rank := case old.start_phase
    when 'toss'   then 1
    when 'lineup' then 2
    when 'ready'  then 3
    when 'live'   then 4
  end;
  v_new_rank := case new.start_phase
    when 'toss'   then 1
    when 'lineup' then 2
    when 'ready'  then 3
    when 'live'   then 4
  end;
  if v_new_rank < v_old_rank then
    raise exception 'start_phase is forward-only (% → %)',
      old.start_phase, new.start_phase
      using errcode = '23000';
  end if;
  return new;
end;
$$;

create trigger matches_start_phase_forward_only
  before update of start_phase on public.matches
  for each row execute function public._enforce_start_phase_forward();

-- -----------------------------------------------------------------------------
-- tournament_approved_teams — helper used by every fixture generator.
-- Returns approved teams ordered by seed_number then registration time so
-- seeding is deterministic.
-- -----------------------------------------------------------------------------
create or replace function public.tournament_approved_teams(p_tournament_id uuid)
returns table(team_id uuid)
language sql
stable
as $$
  select tt.team_id
    from public.tournament_teams tt
   where tt.tournament_id = p_tournament_id
     and tt.status = 'approved'
   order by tt.seed_number nulls last, tt.registered_at;
$$;

-- -----------------------------------------------------------------------------
-- Round-label helper (used by knockout generator).
-- -----------------------------------------------------------------------------
create or replace function public._knockout_round_label(
  p_round integer,
  p_total integer
) returns text
language sql
immutable
as $$
  select case
    when p_round = p_total then 'Final'
    when p_round = p_total - 1 then 'SF'
    when p_round = p_total - 2 then 'QF'
    when p_round = p_total - 3 then 'R16'
    when p_round = p_total - 4 then 'R32'
    else 'R' || p_round
  end;
$$;

-- =============================================================================
-- Round-robin fixture generator (§3.8.2 circle method).
-- Each team plays every other once → n*(n-1)/2 matches. p_double=true does
-- the home/away mirror (league format §3.8.3).
-- =============================================================================
create or replace function public.generate_round_robin_fixtures(
  p_tournament_id uuid,
  p_double boolean default false
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid             uuid := auth.uid();
  v_start_date      date;
  v_team_ids        uuid[];
  v_n               integer;
  v_padded          uuid[];
  v_matches_created integer := 0;
  v_round           integer;
  v_pair_idx        integer;
  v_a               uuid;
  v_b               uuid;
  v_rotated         uuid[];
  v_round_count     integer;
  v_pass            integer;
  v_label           text;
  v_scheduled       timestamptz;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if not public.is_tournament_organizer(p_tournament_id) then
    raise exception 'Only tournament organizers can generate fixtures'
      using errcode = '42501';
  end if;

  -- Refuse to overwrite a tournament that's already started.
  if exists (
    select 1 from public.matches
     where tournament_id = p_tournament_id
       and status not in ('scheduled', 'rescheduled')
  ) then
    raise exception 'Cannot regenerate — tournament has matches in progress'
      using errcode = '23000';
  end if;

  delete from public.matches
   where tournament_id = p_tournament_id
     and status in ('scheduled', 'rescheduled');

  select start_date into v_start_date from public.tournaments
   where tournament_id = p_tournament_id;

  select array_agg(team_id)
    into v_team_ids
    from public.tournament_approved_teams(p_tournament_id);

  v_n := coalesce(array_length(v_team_ids, 1), 0);
  if v_n < 2 then
    raise exception 'Need at least 2 approved teams (have %)', v_n
      using errcode = 'P0001';
  end if;

  -- Pad to even with sentinel NULL for byes.
  v_padded := v_team_ids;
  if v_n % 2 = 1 then
    v_padded := v_padded || array[null::uuid];
  end if;
  v_round_count := array_length(v_padded, 1) - 1;

  for v_pass in 1..(case when p_double then 2 else 1 end) loop
    v_padded := v_team_ids;
    if v_n % 2 = 1 then
      v_padded := v_padded || array[null::uuid];
    end if;

    for v_round in 1..v_round_count loop
      v_label := case
        when p_double and v_pass = 2 then 'R' || v_round || ' (return)'
        else 'R' || v_round
      end;
      v_scheduled := case
        when v_start_date is null then null
        else (v_start_date + ((v_round - 1) + (v_pass - 1) * v_round_count))::timestamptz
      end;

      for v_pair_idx in 0..(array_length(v_padded, 1) / 2 - 1) loop
        v_a := v_padded[v_pair_idx + 1];
        v_b := v_padded[array_length(v_padded, 1) - v_pair_idx];
        if v_a is not null and v_b is not null then
          insert into public.matches (
            tournament_id, match_type, round, team_a_id, team_b_id,
            scheduled_start_time, status, created_by
          )
          values (
            p_tournament_id,
            'tournament',
            v_label,
            case when p_double and v_pass = 2 then v_b else v_a end,
            case when p_double and v_pass = 2 then v_a else v_b end,
            v_scheduled,
            'scheduled',
            v_uid
          );
          v_matches_created := v_matches_created + 1;
        end if;
      end loop;

      -- Rotate: keep first team fixed, move last to position 2.
      v_rotated := array[v_padded[1]]
                || array[v_padded[array_length(v_padded, 1)]]
                || v_padded[2 : array_length(v_padded, 1) - 1];
      v_padded := v_rotated;
    end loop;
  end loop;

  perform public.recalculate_standings(p_tournament_id);
  return v_matches_created;
end;
$$;

revoke all on function public.generate_round_robin_fixtures(uuid, boolean) from public;
grant execute on function public.generate_round_robin_fixtures(uuid, boolean) to authenticated;

-- =============================================================================
-- Knockout fixture generator (§3.8.1).
-- Bracket size B = next power of 2 ≥ N teams; B − N teams get byes in R1.
-- All bracket positions pre-created — R2..Final start with NULL teams +
-- prev_match links so the bracket UI renders the full ladder up front.
-- =============================================================================
create or replace function public.generate_knockout_fixtures(
  p_tournament_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid              uuid := auth.uid();
  v_start_date       date;
  v_team_ids         uuid[];
  v_n                integer;
  v_bracket_size     integer;
  v_byes             integer;
  v_total_rounds     integer;
  v_rd               integer;
  v_match_in_round   integer;
  v_match_count      integer;
  v_match_id         uuid;
  v_team_a           uuid;
  v_team_b           uuid;
  v_seed_a           integer;
  v_seed_b           integer;
  v_round_label      text;
  v_match_ids        uuid[];
  v_prev_a           uuid;
  v_prev_b           uuid;
  v_inserted         integer := 0;
  v_round_offset     integer := 0;
  v_scheduled        timestamptz;
  v_round_team_count integer;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if not public.is_tournament_organizer(p_tournament_id) then
    raise exception 'Only tournament organizers can generate fixtures'
      using errcode = '42501';
  end if;

  if exists (
    select 1 from public.matches
     where tournament_id = p_tournament_id
       and status not in ('scheduled', 'rescheduled')
  ) then
    raise exception 'Cannot regenerate — tournament has matches in progress'
      using errcode = '23000';
  end if;

  delete from public.matches
   where tournament_id = p_tournament_id
     and status in ('scheduled', 'rescheduled');

  select start_date into v_start_date from public.tournaments
   where tournament_id = p_tournament_id;

  select array_agg(team_id)
    into v_team_ids
    from public.tournament_approved_teams(p_tournament_id);

  v_n := coalesce(array_length(v_team_ids, 1), 0);
  if v_n < 2 then
    raise exception 'Need at least 2 approved teams (have %)', v_n
      using errcode = 'P0001';
  end if;

  v_bracket_size := 2;
  while v_bracket_size < v_n loop
    v_bracket_size := v_bracket_size * 2;
  end loop;
  v_byes         := v_bracket_size - v_n;
  v_total_rounds := round(ln(v_bracket_size) / ln(2))::integer;

  -- Pre-allocate id slots: [round][match]. Insert top-down so we can fill
  -- prev_match links before inserting downstream rows.
  v_match_ids := array_fill(null::uuid, array[v_total_rounds, v_bracket_size / 2]);

  for v_rd in 1..v_total_rounds loop
    v_round_team_count := v_bracket_size / (2 ^ (v_rd - 1))::integer;
    v_match_count      := v_round_team_count / 2;
    v_round_label      := public._knockout_round_label(v_rd, v_total_rounds);
    v_scheduled        := case
      when v_start_date is null then null
      else (v_start_date + (v_rd - 1))::timestamptz
    end;

    for v_match_in_round in 1..v_match_count loop
      v_team_a := null;  v_team_b := null;
      v_seed_a := null;  v_seed_b := null;
      v_prev_a := null;  v_prev_b := null;

      if v_rd = 1 then
        -- Standard high-vs-low pairing on seeds 1..bracket_size, with the
        -- top `v_byes` seeds receiving byes (no R1 match — they show up
        -- pre-placed in R2 via the bye-resolution branch below).
        v_seed_a := v_match_in_round;
        v_seed_b := v_bracket_size - v_match_in_round + 1;
        if v_seed_a > v_byes then
          v_team_a := v_team_ids[v_seed_a - v_byes];
        end if;
        if v_seed_b > v_byes then
          v_team_b := v_team_ids[v_seed_b - v_byes];
        end if;
        if v_team_a is null and v_team_b is null then
          continue;
        end if;
        if v_team_a is not null and v_team_b is null then
          continue;
        end if;
        if v_team_b is not null and v_team_a is null then
          continue;
        end if;
      else
        v_prev_a := v_match_ids[v_rd - 1][2 * v_match_in_round - 1];
        v_prev_b := v_match_ids[v_rd - 1][2 * v_match_in_round];

        -- Bye resolution — when a R(r-1) feeder slot is null, the team with
        -- the original seed advances directly into R(r).
        if v_rd = 2 then
          if v_prev_a is null then
            v_team_a := v_team_ids[(2 * v_match_in_round - 1) - v_byes];
          end if;
          if v_prev_b is null then
            v_team_b := v_team_ids[(2 * v_match_in_round) - v_byes];
          end if;
        end if;
      end if;

      v_match_id := gen_random_uuid();
      v_match_ids[v_rd][v_match_in_round] := v_match_id;

      insert into public.matches (
        match_id, tournament_id, match_type, round,
        bracket_round_number, bracket_match_number,
        prev_match_a_id, prev_match_b_id,
        seed_a, seed_b, team_a_id, team_b_id,
        scheduled_start_time, status, created_by
      )
      values (
        v_match_id, p_tournament_id, 'tournament', v_round_label,
        v_rd, v_match_in_round,
        v_prev_a, v_prev_b,
        v_seed_a, v_seed_b, v_team_a, v_team_b,
        v_scheduled, 'scheduled', v_uid
      );
      v_inserted := v_inserted + 1;
    end loop;
    v_round_offset := v_round_offset + 1;
  end loop;

  perform public.recalculate_standings(p_tournament_id);
  return v_inserted;
end;
$$;

revoke all on function public.generate_knockout_fixtures(uuid) from public;
grant execute on function public.generate_knockout_fixtures(uuid) to authenticated;

-- =============================================================================
-- Dispatcher — pick the generator from the tournament's type. UI calls this.
-- =============================================================================
create or replace function public.generate_tournament_fixtures(p_tournament_id uuid)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_type public.tournament_type;
begin
  select tournament_type into v_type
    from public.tournaments
   where tournament_id = p_tournament_id;
  if v_type is null then
    raise exception 'Tournament not found' using errcode = 'P0002';
  end if;

  case v_type
    when 'knockout'    then return public.generate_knockout_fixtures(p_tournament_id);
    when 'round_robin' then return public.generate_round_robin_fixtures(p_tournament_id, false);
    when 'league'      then return public.generate_round_robin_fixtures(p_tournament_id, true);
    else
      -- group_knockout / double_elimination = v1.1+ (spec §3.2).
      raise exception 'Format % not yet supported', v_type using errcode = '0A000';
  end case;
end;
$$;

revoke all on function public.generate_tournament_fixtures(uuid) from public;
grant execute on function public.generate_tournament_fixtures(uuid) to authenticated;

-- =============================================================================
-- reschedule_match (§3.8.6) — constrained UPDATE for schedule + venue.
-- Full match editing happens via the scoring screens once W6 lands.
-- =============================================================================
create or replace function public.reschedule_match(
  p_match_id uuid,
  p_scheduled_start_time timestamptz default null,
  p_venue text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid           uuid := auth.uid();
  v_tournament_id uuid;
  v_status        public.match_status;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  select tournament_id, status
    into v_tournament_id, v_status
    from public.matches
   where match_id = p_match_id
   for update;
  if v_tournament_id is null then
    raise exception 'Match not found or not in a tournament' using errcode = '42501';
  end if;
  if not public.is_tournament_organizer(v_tournament_id) then
    raise exception 'Only tournament organizers can reschedule' using errcode = '42501';
  end if;
  if v_status not in ('scheduled', 'rescheduled') then
    raise exception 'Cannot reschedule a match in status %', v_status using errcode = '23000';
  end if;

  update public.matches
     set scheduled_start_time = coalesce(p_scheduled_start_time, scheduled_start_time),
         venue                = coalesce(p_venue, venue),
         status               = 'rescheduled'
   where match_id = p_match_id;
end;
$$;

revoke all on function public.reschedule_match(uuid, timestamptz, text) from public;
grant execute on function public.reschedule_match(uuid, timestamptz, text) to authenticated;

-- =============================================================================
-- _can_score_match — auth shared by every scoring RPC (start_innings,
-- record_ball, undo_last_ball). Returns true when the caller is the
-- tournament organiser, an assigned scorer, or the friendly/practice
-- creator. Mirrors the matches_update / balls_insert RLS predicates.
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
         (m.tournament_id is not null
           and public.is_tournament_organizer(m.tournament_id))
         or auth.uid() = any(coalesce(m.assigned_scorers, '{}'::uuid[]))
         or (m.match_type in ('friendly', 'practice')
             and m.created_by = auth.uid())
       )
  );
$$;

revoke all on function public._can_score_match(uuid) from public;
grant execute on function public._can_score_match(uuid) to authenticated;

-- =============================================================================
-- start_innings — open or reopen an innings on the live scoring screen.
--
-- Sets matches.current_innings + (current_striker_id, current_non_striker_id,
-- current_bowler_id) and flips status to 'live'. Called once at toss (innings
-- 1) and again after the innings break (innings 2). The two batters must
-- be distinct; the bowler can be either side's player but in practice is
-- from the bowling XI — we do not enforce squad membership here because
-- squads aren't required to be locked in v1.0.
--
-- No-op-safe: re-calling with the same innings_number just updates the
-- on-field trio (useful when the scorer corrects a wrong pick at the toss).
-- =============================================================================
create or replace function public.start_innings(
  p_match_id uuid,
  p_innings_number integer,
  p_striker_id uuid,
  p_non_striker_id uuid,
  p_bowler_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid    uuid := auth.uid();
  v_status public.match_status;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if not public._can_score_match(p_match_id) then
    raise exception 'Only organisers or assigned scorers can score this match'
      using errcode = '42501';
  end if;
  if p_innings_number not between 1 and 4 then
    raise exception 'innings_number must be between 1 and 4' using errcode = '23514';
  end if;
  if p_striker_id is null or p_non_striker_id is null or p_bowler_id is null then
    raise exception 'Striker, non-striker and bowler are all required'
      using errcode = '23502';
  end if;
  if p_striker_id = p_non_striker_id then
    raise exception 'Striker and non-striker must be different players'
      using errcode = '23514';
  end if;

  select status into v_status from public.matches
   where match_id = p_match_id for update;
  if not found then
    raise exception 'Match not found' using errcode = '42501';
  end if;
  if v_status in ('completed', 'abandoned', 'walkover') then
    raise exception 'Cannot start innings on a finalised match (status %)', v_status
      using errcode = '23000';
  end if;

  update public.matches
     set current_innings        = p_innings_number,
         current_striker_id     = p_striker_id,
         current_non_striker_id = p_non_striker_id,
         current_bowler_id      = p_bowler_id,
         status                 = 'live',
         actual_start_time      = coalesce(actual_start_time, now())
   where match_id = p_match_id;
end;
$$;

revoke all on function public.start_innings(uuid, integer, uuid, uuid, uuid) from public;
grant execute on function public.start_innings(uuid, integer, uuid, uuid, uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- RLS (§4.11) — public read; organizers + assigned scorers write tournament
-- matches; created_by writes friendlies / practice.
-- -----------------------------------------------------------------------------
alter table public.matches enable row level security;

create policy "matches_read_public"
  on public.matches for select
  using (true);

create policy "matches_insert_organizer_or_creator"
  on public.matches for insert
  to authenticated
  with check (
    (select auth.uid()) = created_by
    and (
      (match_type = 'tournament' and tournament_id is not null
        and public.is_tournament_organizer(tournament_id))
      or (match_type in ('friendly', 'practice'))
    )
  );

-- Pre-Live edits only — schedule changes, squad picks, captain assignments,
-- the toss, start-phase advancement. Once the match goes Live (or beyond)
-- the only valid mutation path is the SECURITY DEFINER RPC family
-- (record_ball, undo_last_ball, submit_match_result, start_innings) which
-- bypass this policy. Closing direct UPDATE on live rows prevents any
-- assigned scorer or stale client from bypassing the strike-rotation /
-- bowler-clearing / wicket logic baked into record_ball.
create policy "matches_update_pre_live"
  on public.matches for update
  to authenticated
  using (
    status in ('scheduled', 'rescheduled', 'toss')
    and (
      (tournament_id is not null and public.is_tournament_organizer(tournament_id))
      or (select auth.uid()) = any(assigned_scorers)
      or (match_type in ('friendly', 'practice') and (select auth.uid()) = created_by)
    )
  )
  with check (
    status in ('scheduled', 'rescheduled', 'toss', 'live')
    and (
      (tournament_id is not null and public.is_tournament_organizer(tournament_id))
      or (select auth.uid()) = any(assigned_scorers)
      or (match_type in ('friendly', 'practice') and (select auth.uid()) = created_by)
    )
  );

create policy "matches_delete_organizer"
  on public.matches for delete
  to authenticated
  using (
    (tournament_id is not null and public.is_tournament_organizer(tournament_id))
    or (match_type in ('friendly', 'practice') and (select auth.uid()) = created_by)
  );

-- =============================================================================
-- Realtime — Broadcast on scoreboard-facing state changes.
-- =============================================================================
-- Topic: match:<match_id>:state
-- Event: 'match_state_updated'
-- WHEN clause filters out updates that don't affect the scoreboard
-- (description, scheduled_at, etc.) so routine edits don't fan out.
-- =============================================================================
create or replace function public.broadcast_match_state()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform realtime.send(
    to_jsonb(new),
    'match_state_updated',
    'match:' || new.match_id::text || ':state',
    true
  );
  return null;
end;
$$;

revoke all on function public.broadcast_match_state() from public;

create trigger matches_after_update_state_broadcast
  after update on public.matches
  for each row
  when (
    old.status                    is distinct from new.status
    or old.team_a_squad           is distinct from new.team_a_squad
    or old.team_b_squad           is distinct from new.team_b_squad
    or old.current_striker_id     is distinct from new.current_striker_id
    or old.current_non_striker_id is distinct from new.current_non_striker_id
    or old.current_bowler_id      is distinct from new.current_bowler_id
    or old.toss_won_by            is distinct from new.toss_won_by
    or old.toss_decision          is distinct from new.toss_decision
    or old.toss_face              is distinct from new.toss_face
    or old.start_phase            is distinct from new.start_phase
    or old.openers_submitted_by   is distinct from new.openers_submitted_by
  )
  execute function public.broadcast_match_state();
