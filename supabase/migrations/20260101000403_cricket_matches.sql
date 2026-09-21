-- =============================================================================
-- Migration: 20260101000403_cricket_matches.sql
-- =============================================================================

-- 0403 · cricket_matches
-- Cricket-specific extension of the matches shell. One row per Cricket match.

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.cricket_matches (
  match_id               uuid primary key
    references public.matches (match_id)
    on delete cascade,
  format_code            text not null default 't20',
  rules_snapshot         jsonb not null default '{}'::jsonb,
  phase                  public.cricket_match_phase not null default 'toss',
  toss_won_by            text check (toss_won_by in ('team_a', 'team_b')),
  toss_decision          public.cricket_toss_decision,
  toss_face              text check (toss_face in ('heads', 'tails')),
  toss_recorded_at       timestamptz,
  openers_submitted_by   uuid
    references public.profiles (user_id)
    on delete set null,
  openers_submitted_at   timestamptz,
  scoring_mode           public.cricket_scoring_mode not null default 'standard',
  result                 jsonb,
  result_summary         text,
  revised_conditions     jsonb,
  player_of_the_match_id uuid
    references public.match_players (match_player_id)
    on delete set null,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  constraint cricket_matches_toss_side_fkey
    foreign key (match_id, toss_won_by)
    references public.match_teams (match_id, team_side)
    on delete restrict
);

comment on table public.cricket_matches is
  'Cricket-specific extension of matches. The parent matches row identifies the sporting event; this row contains only Cricket rules and state.';

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger cricket_matches_set_updated_at
  before update on public.cricket_matches
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

alter table public.cricket_matches enable row level security;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

create policy "cricket_matches_read_all"
  on public.cricket_matches
  for select
  to anon, authenticated
  using (true);

-- -----------------------------------------------------------------------------
-- Permissions
-- -----------------------------------------------------------------------------

revoke all on table public.cricket_matches from anon, authenticated;

grant select on table public.cricket_matches to anon, authenticated;

grant all on table public.cricket_matches to service_role;

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

create index cricket_matches_player_of_the_match
  on public.cricket_matches (
    player_of_the_match_id
  )
  where player_of_the_match_id is not null;
