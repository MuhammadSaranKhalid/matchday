-- 20261001000210_tournament_entries.sql
-- Canonical Tournament Entries (Accepted Competitive Participants)
-- Clean Architecture Step 6 / Phase 3

-- Enums
do $$ begin
  create type public.tournament_entry_status as enum (
    'active',
    'withdrawn',
    'disqualified'
  );
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type public.tournament_squad_state as enum (
    'editable',
    'frozen'
  );
exception
  when duplicate_object then null;
end $$;

-- Table definition
create table if not exists public.tournament_entries (
  entry_id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(tournament_id) on delete cascade,
  team_id uuid not null references public.teams(team_id) on delete restrict,
  registration_id uuid,
  status public.tournament_entry_status not null default 'active',
  entry_source text not null default 'application',
  accepted_by uuid references public.profiles(user_id) on delete set null,
  accepted_at timestamptz not null default now(),
  withdrawn_at timestamptz,
  withdrawn_by uuid references public.profiles(user_id) on delete set null,
  withdrawal_reason text,
  disqualified_at timestamptz,
  disqualified_by uuid references public.profiles(user_id) on delete set null,
  disqualification_reason text,
  squad_state public.tournament_squad_state not null default 'editable',
  squad_revision integer not null default 1,
  squad_frozen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint tournament_entries_source_check
    check (entry_source in ('application', 'invitation', 'direct_add')),
  constraint tournament_entries_squad_revision_check
    check (squad_revision >= 1),
  constraint tournament_entries_withdrawal_reason_check
    check (withdrawal_reason is null or length(withdrawal_reason) <= 500),
  constraint tournament_entries_disqualification_reason_check
    check (disqualification_reason is null or length(disqualification_reason) <= 500),
  constraint tournament_entries_withdrawn_consistency
    check (status != 'withdrawn' or withdrawn_at is not null),
  constraint tournament_entries_disqualified_consistency
    check (status != 'disqualified' or disqualified_at is not null),
  constraint tournament_entries_squad_frozen_consistency
    check (squad_state != 'frozen' or squad_frozen_at is not null),

  -- Composite candidate key on Entry identity
  constraint tournament_entries_identity_unique
    unique (entry_id, tournament_id, team_id),

  -- Entry <-> Registration consistency invariant (Item 33)
  -- Guarantees that source Registration belongs to the exact same Tournament and Team.
  constraint tournament_entries_source_registration_fk
    foreign key (registration_id, tournament_id, team_id)
    references public.tournament_registrations (registration_id, tournament_id, team_id)
    on delete restrict
);

-- Unique constraint: A team cannot have two active entries in the same tournament.
-- Withdrawn and disqualified entries remain as historical records.
create unique index if not exists idx_tournament_entries_active
  on public.tournament_entries (tournament_id, team_id)
  where status = 'active';

-- Fast lookup indexes
create index if not exists idx_tournament_entries_tournament_status
  on public.tournament_entries (tournament_id, status);

create index if not exists idx_tournament_entries_team
  on public.tournament_entries (team_id);

create index if not exists idx_tournament_entries_registration
  on public.tournament_entries (registration_id);

-- Trigger: set updated_at
drop trigger if exists trg_tournament_entries_set_updated_at on public.tournament_entries;
create trigger trg_tournament_entries_set_updated_at
  before update on public.tournament_entries
  for each row
  execute function public.set_updated_at();

-- RLS Security Policies
alter table public.tournament_entries enable row level security;

-- Read policy (Item 20): Tournament staff or Team managers of the participating team ONLY
-- Public sanitized read-models / projections provide public spectator data
drop policy if exists "tournament_entries_read" on public.tournament_entries;
create policy "tournament_entries_read"
  on public.tournament_entries
  for select
  to authenticated
  using (
    public.can('tournament', tournament_id, 'tournament.entries.manage')
    or public.can('team', team_id, 'team.tournament.enter')
  );

-- Insert policy (Item 12): Direct Data API insertion is BLOCKED.
-- Entries are created exclusively through authorized server-side approval / creation commands.
drop policy if exists "tournament_entries_insert" on public.tournament_entries;
create policy "tournament_entries_insert"
  on public.tournament_entries
  for insert
  to authenticated
  with check (false);

-- Update policy (Item 13): Direct Data API updates are BLOCKED.
-- Transitions (e.g. withdrawal, disqualification, squad freeze) occur through authorized transactional RPCs.
drop policy if exists "tournament_entries_update" on public.tournament_entries;
create policy "tournament_entries_update"
  on public.tournament_entries
  for update
  to authenticated
  using (false)
  with check (false);

-- Delete policy: No hard deletion of accepted tournament entries
drop policy if exists "tournament_entries_delete" on public.tournament_entries;
create policy "tournament_entries_delete"
  on public.tournament_entries
  for delete
  to authenticated
  using (false);
