-- 004_matches.sql — matches between two teams (online-only in Phase 1).
--
-- F4 creates a row in status='pending' with team A's side filled in. The
-- opponent fills team B's side and flips the status (F5). No offline mirror, so
-- no updated_at/LWW and not in the realtime publication (Phase 1).

create table public.matches (
  match_id             uuid primary key default gen_random_uuid(),
  match_type           text not null default 'friendly'
                         check (match_type in ('friendly','tournament','practice')),
  tournament_id        uuid,                       -- reserved for v1.1
  round                text,
  team_a_id            uuid not null references public.teams(team_id),
  team_b_id            uuid not null references public.teams(team_id),
  team_a_squad         uuid[] not null default '{}',
  team_b_squad         uuid[] not null default '{}',
  team_a_captain       uuid,
  team_b_captain       uuid,
  team_a_keeper        uuid,
  team_b_keeper        uuid,
  format               jsonb not null,
  venue                jsonb,
  scheduled_start_time timestamptz,
  actual_start_time    timestamptz,
  end_time             timestamptz,
  toss_won_by          uuid,
  toss_decision        text check (toss_decision in ('bat','bowl')),
  scoring_mode         text default 'live_ball_by_ball'
                         check (scoring_mode in ('live_ball_by_ball','post_match_scorecard')),
  assigned_scorers     uuid[] not null default '{}',
  current_innings      int default 0,
  status               text not null default 'pending'
                         check (status in ('pending','accepted','declined','scheduled','toss','live','innings_break','completed','abandoned','cancelled')),
  decline_reason       jsonb,
  result               jsonb,
  created_by           uuid not null references public.profiles(user_id),
  created_at           timestamptz not null default now()
);

create index matches_team_a_idx on public.matches(team_a_id);
create index matches_team_b_idx on public.matches(team_b_id);
create index matches_status_idx on public.matches(status);

alter table public.matches enable row level security;

-- All matches are publicly readable in Phase 1 (spectating).
create policy matches_select on public.matches for select using (true);

-- Only the creator can insert (and they must be a manager of team A — enforced
-- in the app; RLS keeps the floor at "created_by is me").
create policy matches_insert on public.matches for insert
  with check (created_by = auth.uid());

-- A manager of either team can update (accept/decline, toss, scoring, …).
create policy matches_update on public.matches for update using (
  exists (
    select 1 from public.teams t
    where t.team_id in (matches.team_a_id, matches.team_b_id)
      and (t.owner_id = auth.uid() or auth.uid() = any(t.managers))
  )
);
