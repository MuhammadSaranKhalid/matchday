-- Migration: 20261001000350_tournament_fixtures.sql
-- Description: Phase 4 canonical tournament competition fixtures (separate from sport Match execution).

-- 1. Fixture State Enum
do $$
begin
  if not exists (select 1 from pg_type where typname = 'tournament_fixture_state') then
    create type public.tournament_fixture_state as enum (
      'unresolved',
      'ready',
      'in_progress',
      'resolved',
      'voided'
    );
  end if;
end $$;

-- 2. Tournament Fixtures Table
create table public.tournament_fixtures (
  fixture_id                   uuid primary key default gen_random_uuid(),
  tournament_id                uuid not null references public.tournaments(tournament_id) on delete cascade,
  stage_id                     uuid not null,
  round_id                     uuid not null,
  draw_revision_id             uuid not null,
  fixture_number               integer not null check (fixture_number > 0),
  state                        public.tournament_fixture_state not null default 'unresolved',
  scheduled_start_time         timestamptz,
  venue_id                     uuid references public.grounds(ground_id) on delete set null,
  venue_name_fallback          text,
  competition_config_override  jsonb not null default '{}'::jsonb,
  sport_rules_override         jsonb not null default '{}'::jsonb,
  created_at                   timestamptz not null default now(),
  updated_at                   timestamptz not null default now(),
  constraint fk_fixtures_stage_tournament foreign key (stage_id, tournament_id)
    references public.tournament_stages(stage_id, tournament_id) on delete cascade,
  constraint fk_fixtures_round_stage foreign key (round_id, stage_id)
    references public.tournament_rounds(round_id, stage_id) on delete cascade,
  constraint fk_fixtures_draw_revision_stage foreign key (draw_revision_id, stage_id)
    references public.tournament_draw_revisions(draw_revision_id, stage_id) on delete restrict,
  constraint uq_fixtures_round_number unique (round_id, fixture_number),
  constraint uq_fixtures_id_stage unique (fixture_id, stage_id),
  constraint uq_fixtures_id_tournament unique (fixture_id, tournament_id)
);

comment on table public.tournament_fixtures is
  'First-class tournament contest/fixture aggregate representing competition positions prior to and separate from sport Match executions.';

-- 3. Indexes
create index idx_fixtures_lookup
  on public.tournament_fixtures (stage_id, round_id, fixture_number);

create index idx_fixtures_draw_revision
  on public.tournament_fixtures (draw_revision_id);

create index idx_fixtures_venue
  on public.tournament_fixtures (venue_id)
  where venue_id is not null;

create index idx_fixtures_tournament
  on public.tournament_fixtures (tournament_id);

-- 4. Triggers
create trigger trg_tournament_fixtures_set_updated_at
  before update on public.tournament_fixtures
  for each row execute function public.set_updated_at();

-- Published draw protection: once a draw revision is published or superseded,
-- fixtures belonging to it cannot be deleted or have their structural topology mutated.
create or replace function public.enforce_fixture_published_draw_protection()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status public.tournament_draw_revision_status;
begin
  if tg_op = 'DELETE' then
    select status into v_status
    from public.tournament_draw_revisions
    where draw_revision_id = old.draw_revision_id;

    if v_status in ('published', 'superseded') then
      raise exception 'Cannot delete fixture belonging to a published or superseded draw revision'
        using errcode = '22000';
    end if;
    return old;
  end if;

  if tg_op = 'UPDATE' then
    select status into v_status
    from public.tournament_draw_revisions
    where draw_revision_id = old.draw_revision_id;

    if v_status in ('published', 'superseded') then
      if new.stage_id <> old.stage_id
         or new.round_id <> old.round_id
         or new.draw_revision_id <> old.draw_revision_id
         or new.fixture_number <> old.fixture_number then
        raise exception 'Cannot alter topology of a fixture belonging to a published or superseded draw revision'
          using errcode = '22000';
      end if;
    end if;
    return new;
  end if;

  return new;
end;
$$;

revoke execute on function public.enforce_fixture_published_draw_protection() from public;

create trigger trg_fixtures_draw_revision_published_protection
  before update or delete on public.tournament_fixtures
  for each row execute function public.enforce_fixture_published_draw_protection();

-- 5. RLS
alter table public.tournament_fixtures enable row level security;

-- Phase 4.1: Direct client mutation (INSERT, UPDATE, DELETE) is denied.
-- Mutations are command-owned (Phase 5 tournament-action, Phase 9 scheduling commands).
-- Staff/organizers may view fixtures; safe public read models will be introduced in Phase 12.
create policy "tournament_fixtures_read_staff"
  on public.tournament_fixtures
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_fixtures.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or is_tournament_organizer(t.tournament_id)
          or can('tournament', t.tournament_id, 'tournament.view_admin')
          or can('tournament', t.tournament_id, 'tournament.fixture.schedule')
          or can('tournament', t.tournament_id, 'tournament.draw.manage')
        )
    )
  );
