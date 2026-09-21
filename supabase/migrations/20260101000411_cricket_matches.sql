-- Migration file: 20260101000411_cricket_matches.sql

-- 0411 · cricket_matches
-- Cricket-specific extension of the matches shell. One row per Cricket match.
-- Section: Tables and constraints

create table public.cricket_matches(
  match_id uuid primary key references public.matches(match_id) on delete cascade,
  format_code text not null default 't20',
  rules_snapshot jsonb not null default '{}'::jsonb,
  phase public.cricket_match_phase not null default 'toss',
  toss_won_by text check (toss_won_by in ('team_a', 'team_b')),
  toss_decision public.cricket_toss_decision,
  toss_face text check (toss_face in ('heads', 'tails')),
  toss_recorded_at timestamptz,
  openers_submitted_by text check (openers_submitted_by in ('team_a', 'team_b')),
  openers_submitted_at timestamptz,
  scoring_mode public.cricket_scoring_mode not null default 'standard',
  result jsonb,
  result_summary text,
  revised_conditions jsonb,
  player_of_the_match_id uuid references public.match_players(match_player_id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.cricket_matches is 'Cricket-specific extension of matches. The parent matches row identifies the sporting event; this row contains only Cricket rules and state.';

-- Section: Triggers

create trigger cricket_matches_set_updated_at
  before update on public.cricket_matches for each row
  execute function public.set_updated_at();

-- Sync result to parent matches
create or replace function public._sync_cricket_result_to_parent()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_winner_id uuid;
begin
  if new.result is not null then
    v_winner_id := nullif(new.result ->> 'winner_team_id', '')::uuid;
    update public.matches
    set
      winner_id = v_winner_id,
      status = 'completed',
      completed_at = coalesce(completed_at, now()),
      updated_at = now()
    where match_id = new.match_id;
  end if;
  return new;
end;
$$;

create trigger cricket_match_sync_parent_winner
  after insert or update of result on public.cricket_matches
  for each row
  execute function public._sync_cricket_result_to_parent();

-- Section: Enable row-level security

alter table public.cricket_matches enable row level security;

-- Section: Policies

create policy "cricket_matches_read_all" on public.cricket_matches
  for select to anon, authenticated
  using (true);

-- Section: Permissions

revoke all on table public.cricket_matches from anon, authenticated;
grant select on table public.cricket_matches to anon, authenticated;
grant all on table public.cricket_matches to service_role;

-- Section: Indexes

create index cricket_matches_player_of_the_match on public.cricket_matches(player_of_the_match_id)
where player_of_the_match_id is not null;
