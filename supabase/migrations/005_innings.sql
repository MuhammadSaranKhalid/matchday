-- 005_innings.sql — per-innings state for a live match (online-only, Phase 1).
--
-- Created by the single-phone match-start flow (F6) when a match goes
-- accepted → live. Ball-by-ball scoring (F8) mutates the running totals and
-- the current striker/non-striker/bowler.

create table public.innings (
  innings_id           uuid primary key default gen_random_uuid(),
  match_id             uuid not null references public.matches(match_id) on delete cascade,
  innings_number       int not null check (innings_number between 1 and 4),
  batting_team_id      uuid not null references public.teams(team_id),
  bowling_team_id      uuid not null references public.teams(team_id),
  total_runs           int not null default 0,
  total_wickets        int not null default 0,
  total_overs          numeric(4,1) not null default 0,
  total_balls_faced    int not null default 0,
  extras               jsonb not null default '{"wide":0,"no_ball":0,"bye":0,"leg_bye":0,"penalty":0}',
  target               int,
  status               text not null default 'in_progress'
                         check (status in ('not_started','in_progress','completed','declared')),
  current_striker_id     uuid,
  current_non_striker_id uuid,
  current_bowler_id      uuid,
  created_at           timestamptz not null default now(),
  unique (match_id, innings_number)
);

create index innings_match_idx on public.innings(match_id);

alter table public.innings enable row level security;

-- Innings are publicly readable (spectating).
create policy innings_select on public.innings for select using (true);

-- Only the match creator or an assigned scorer may create/mutate innings.
-- (Phase 1: `assigned_scorers` is always empty — the creator scores — so the
--  `any(assigned_scorers)` branch stays dormant until the two-phone flow, v1.1.)
create policy innings_modify on public.innings for all using (
  exists (
    select 1 from public.matches m
    where m.match_id = innings.match_id
      and (m.created_by = auth.uid() or auth.uid() = any(m.assigned_scorers))
  )
);
