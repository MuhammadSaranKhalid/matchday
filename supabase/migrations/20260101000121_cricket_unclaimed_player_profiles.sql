-- Migration file: 20260101000121_cricket_unclaimed_player_profiles.sql

-- 0121 · cricket_unclaimed_player_profiles
-- Cricket-specific unclaimed profile

-- Section: Tables and constraints

create table public.cricket_unclaimed_player_profiles(
  unclaimed_id         uuid primary key,
  sport_id             text not null default 'cricket' check (sport_id = 'cricket'),
  batting_style        public.batting_style,
  bowling_style        public.bowling_style,
  player_role          public.player_role,
  preferred_ball_types public.ball_type[] not null default '{}',
  years_playing        integer check (years_playing is null or years_playing between 0 and 80),
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  constraint cricket_unclaimed_player_profile_identity_fkey foreign key (unclaimed_id, sport_id) references public.unclaimed_players(unclaimed_id, sport_id) on update restrict on delete cascade
);

-- Section: Triggers

create trigger cricket_unclaimed_player_profiles_set_updated_at
  before update on public.cricket_unclaimed_player_profiles for each row
  execute function public.set_updated_at();

comment on table public.cricket_unclaimed_player_profiles is 'Cricket-specific attributes for an unclaimed Cricket player. '
  'The shared unclaimed identity remains in unclaimed_players.';

-- Section: Enable row-level security

-- Cricket unclaimed-profile security
alter table public.cricket_unclaimed_player_profiles enable row level security;

-- Section: Policies

create policy "cricket_unclaimed_profiles_read_public" on public.cricket_unclaimed_player_profiles
  for select to anon, authenticated
  using (true);

-- Section: Permissions

-- Creation / mutation happens through domain RPCs only.
revoke all on public.cricket_unclaimed_player_profiles from anon, authenticated;

grant select on public.cricket_unclaimed_player_profiles to anon, authenticated;

grant all on public.cricket_unclaimed_player_profiles to service_role;
