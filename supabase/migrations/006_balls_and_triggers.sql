-- 006_balls_and_triggers.sql — ball-by-ball deliveries + the innings-totals
-- cascade (online-only; offline scoring is Phase 2).
--
-- Each row is one delivery. An AFTER INSERT trigger rolls the delivery up into
-- the parent innings (runs, wickets, legal balls → overs, extras). Strike
-- rotation / new batter / bowler change are handled by the scoring engine
-- (the repository) which also updates innings.current_*_id.
--
-- Phase 1 covers 5 cases: normal runs, boundary 4/6, wide, no-ball, wicket.
-- (Bye/leg-bye, run-out, stumping, etc. are later cases.)

create table public.balls (
  ball_id            uuid primary key default gen_random_uuid(),
  innings_id         uuid not null references public.innings(innings_id) on delete cascade,
  match_id           uuid not null references public.matches(match_id) on delete cascade,
  over_number        int not null,
  ball_number        int not null,   -- position within the over incl. extras (1-based)
  legal_ball_number  int not null,   -- count of legal balls in the innings after this one
  bowler_id          uuid not null,
  striker_id         uuid not null,
  non_striker_id     uuid not null,
  runs_scored        int not null default 0,   -- off the bat
  extra_runs         int not null default 0,
  extra_type         text check (extra_type in ('wide','no_ball','bye','leg_bye','penalty')),
  total_runs         int not null default 0,   -- runs_scored + extra_runs
  is_four            boolean not null default false,
  is_six             boolean not null default false,
  is_wicket          boolean not null default false,
  wicket_type        text check (wicket_type in ('bowled','caught','lbw','run_out','stumped','hit_wicket','retired','retired_hurt','obstructing','timed_out','handling_ball')),
  dismissed_player_id uuid,
  fielder_id         uuid,
  is_free_hit        boolean not null default false,
  commentary         text,
  entered_by         uuid not null references public.profiles(user_id),
  entered_at         timestamptz not null default now(),
  is_deleted         boolean not null default false
);

create index balls_innings_idx on public.balls(innings_id, over_number, ball_number);
create index balls_match_idx   on public.balls(match_id);

alter table public.balls enable row level security;

create policy balls_select on public.balls for select using (true);
create policy balls_insert on public.balls for insert with check (
  exists (
    select 1 from public.matches m
    where m.match_id = balls.match_id
      and (m.created_by = auth.uid() or auth.uid() = any(m.assigned_scorers))
  )
);
create policy balls_update on public.balls for update using (
  exists (
    select 1 from public.matches m
    where m.match_id = balls.match_id
      and (m.created_by = auth.uid() or auth.uid() = any(m.assigned_scorers))
  )
);

-- Realtime so spectators (F7) get pushed deliveries.
alter publication supabase_realtime add table public.balls;
alter publication supabase_realtime add table public.innings;

-- ─── Cascade: a delivery rolls up into its innings ──────────────────────────
--
-- A "legal" ball (extra_type not in wide/no_ball) advances the over count.
-- total_overs is encoded as OO.B (e.g. 14.3 = 14 overs and 3 balls).
create or replace function public.apply_ball_to_innings() returns trigger as $$
declare
  legal   boolean;
  balls   int;
begin
  if new.is_deleted then
    return new;
  end if;

  legal := new.extra_type is null or new.extra_type in ('bye','leg_bye');

  update public.innings i set
    total_runs        = i.total_runs + new.total_runs,
    total_wickets     = i.total_wickets + (case when new.is_wicket then 1 else 0 end),
    total_balls_faced = i.total_balls_faced + (case when legal then 1 else 0 end),
    extras = case
      when new.extra_type is null then i.extras
      else jsonb_set(i.extras, array[new.extra_type],
             to_jsonb(coalesce((i.extras ->> new.extra_type)::int, 0) + new.extra_runs))
    end
  where i.innings_id = new.innings_id
  returning i.total_balls_faced into balls;

  -- Recompute OO.B overs from the new legal-ball count.
  update public.innings
    set total_overs = (balls / 6) + ((balls % 6)::numeric / 10)
    where innings_id = new.innings_id;

  return new;
end;
$$ language plpgsql;

create trigger balls_apply_to_innings
  after insert on public.balls
  for each row execute function public.apply_ball_to_innings();
