-- 003_teams.sql — teams, members, and unclaimed players (offline-first).
--
-- Differs from the spec's draft in two deliberate ways, both required by the
-- offline-first sync layer (CLAUDE.md §6.4):
--   * every table carries `updated_at timestamptz` + a BEFORE UPDATE trigger
--     (LWW conflict resolution compares it),
--   * all three tables are added to the supabase_realtime publication.

create table public.teams (
  team_id      uuid primary key default gen_random_uuid(),
  team_name    text not null check (char_length(team_name) between 3 and 50),
  team_type    text not null check (team_type in ('club','village','casual','corporate','school','university')),
  description  text,
  home_ground  text,
  location     jsonb not null default '{}'::jsonb,
  founded_year int,
  owner_id     uuid not null references public.profiles(user_id) on delete restrict,
  managers     uuid[] not null default '{}',
  team_colors  jsonb,
  privacy      text default 'public' check (privacy in ('public','private')),
  status       text default 'active' check (status in ('active','disbanded','archived')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index teams_owner_idx on public.teams(owner_id);
create index teams_city_idx  on public.teams ((location->>'city'));

create table public.unclaimed_players (
  unclaimed_id   uuid primary key default gen_random_uuid(),
  display_name   text not null,
  added_by       uuid not null references public.profiles(user_id),
  player_profile jsonb,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- Phase 1 uses a HARD delete for "remove from roster" (offline simplicity),
-- so there is no soft-delete `status` column — removing a member physically
-- deletes the row both locally and remotely. (Soft-delete is a v1.1 concern.)
create table public.team_members (
  membership_id uuid primary key default gen_random_uuid(),
  team_id       uuid not null references public.teams(team_id) on delete cascade,
  player_id     uuid not null,   -- profiles.user_id OR unclaimed_players.unclaimed_id
  player_type   text not null check (player_type in ('claimed','unclaimed')),
  jersey_number int,
  role          text not null default 'player' check (role in ('captain','vice_captain','wicket_keeper','player')),
  joined_at     timestamptz not null default now(),
  added_by      uuid not null references public.profiles(user_id),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index team_members_team_idx   on public.team_members(team_id);
create index team_members_player_idx on public.team_members(player_id);

-- Jersey numbers are unique within a team.
create unique index team_members_jersey_idx
  on public.team_members(team_id, jersey_number)
  where jersey_number is not null;

-- ─── RLS ─────────────────────────────────────────────────────────────────────

alter table public.teams             enable row level security;
alter table public.team_members      enable row level security;
alter table public.unclaimed_players enable row level security;

create policy teams_select on public.teams for select
  using (privacy = 'public' or owner_id = auth.uid() or auth.uid() = any(managers));
create policy teams_insert on public.teams for insert
  with check (owner_id = auth.uid());
create policy teams_update_owner on public.teams for update
  using (owner_id = auth.uid() or auth.uid() = any(managers));
create policy teams_delete_owner on public.teams for delete
  using (owner_id = auth.uid());

create policy team_members_select on public.team_members for select using (
  exists (
    select 1 from public.teams t
    where t.team_id = team_members.team_id
      and (t.privacy = 'public' or t.owner_id = auth.uid() or auth.uid() = any(t.managers))
  )
);
create policy team_members_modify on public.team_members for all using (
  exists (
    select 1 from public.teams t
    where t.team_id = team_members.team_id
      and (t.owner_id = auth.uid() or auth.uid() = any(t.managers))
  )
);

create policy unclaimed_players_select on public.unclaimed_players for select using (true);
create policy unclaimed_players_modify on public.unclaimed_players for all
  using (added_by = auth.uid())
  with check (added_by = auth.uid());

-- ─── updated_at triggers (set_updated_at defined in the todos migration) ──────

create trigger teams_updated_at
  before update on public.teams
  for each row execute function set_updated_at();
create trigger team_members_updated_at
  before update on public.team_members
  for each row execute function set_updated_at();
create trigger unclaimed_players_updated_at
  before update on public.unclaimed_players
  for each row execute function set_updated_at();

-- ─── Realtime ─────────────────────────────────────────────────────────────────

alter publication supabase_realtime add table public.teams;
alter publication supabase_realtime add table public.team_members;
alter publication supabase_realtime add table public.unclaimed_players;
