-- Migration: 20261001000300_tournament_stages.sql
-- Description: Phase 4 canonical tournament competition stages.

-- 1. Format and State Enums
do $$
begin
  if not exists (select 1 from pg_type where typname = 'tournament_stage_format') then
    create type public.tournament_stage_format as enum (
      'round_robin',
      'single_elimination',
      'double_elimination'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'tournament_stage_state') then
    create type public.tournament_stage_state as enum (
      'pending',
      'active',
      'completed'
    );
  end if;
end $$;

-- 2. Stage Table
create table public.tournament_stages (
  stage_id               uuid primary key default gen_random_uuid(),
  tournament_id          uuid not null references public.tournaments(tournament_id) on delete cascade,
  sequence               integer not null check (sequence > 0),
  name                   text not null check (length(trim(name)) > 0),
  competition_format     public.tournament_stage_format not null,
  state                  public.tournament_stage_state not null default 'pending',
  competition_config     jsonb not null default '{}'::jsonb,
  sport_rules_override   jsonb not null default '{}'::jsonb,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  constraint uq_tournament_stages_tournament_sequence unique (tournament_id, sequence),
  constraint uq_tournament_stages_stage_tournament unique (stage_id, tournament_id)
);

comment on table public.tournament_stages is
  'Canonical first-class competition stages partitioned by format and sequence within a tournament.';

-- 3. Indexes
create index idx_tournament_stages_lookup
  on public.tournament_stages (tournament_id, sequence);

-- 4. Triggers
create trigger trg_tournament_stages_set_updated_at
  before update on public.tournament_stages
  for each row execute function public.set_updated_at();

-- 5. RLS
alter table public.tournament_stages enable row level security;

create policy "tournament_stages_read"
  on public.tournament_stages
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_stages.tournament_id
        and (
          t.privacy = 'public'
          or t.owner_user_id = (select auth.uid())
          or is_tournament_organizer(t.tournament_id)
        )
    )
  );

create policy "tournament_stages_insert"
  on public.tournament_stages
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_stages.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or can('tournament', t.tournament_id, 'tournament.structure.manage')
        )
    )
  );

create policy "tournament_stages_update"
  on public.tournament_stages
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_stages.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or can('tournament', t.tournament_id, 'tournament.structure.manage')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_stages.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or can('tournament', t.tournament_id, 'tournament.structure.manage')
        )
    )
  );

create policy "tournament_stages_delete"
  on public.tournament_stages
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_stages.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or can('tournament', t.tournament_id, 'tournament.structure.manage')
        )
    )
  );
