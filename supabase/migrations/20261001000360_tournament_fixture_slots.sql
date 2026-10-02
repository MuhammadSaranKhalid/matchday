-- Migration: 20261001000360_tournament_fixture_slots.sql
-- Description: Phase 4 canonical fixture slots with typed source references and cross-tournament referential integrity.

-- 1. Side and Source Type Enums
do $$
begin
  if not exists (select 1 from pg_type where typname = 'fixture_slot_side') then
    create type public.fixture_slot_side as enum ('A', 'B');
  end if;

  if not exists (select 1 from pg_type where typname = 'fixture_slot_source_type') then
    create type public.fixture_slot_source_type as enum (
      'entry',
      'seed',
      'fixture_winner',
      'fixture_loser',
      'group_rank',
      'stage_rank',
      'bye'
    );
  end if;
end $$;

-- 2. Fixture Slots Table
create table public.tournament_fixture_slots (
  fixture_slot_id    uuid primary key default gen_random_uuid(),
  fixture_id         uuid not null,
  tournament_id      uuid not null,
  stage_id           uuid not null,
  side               public.fixture_slot_side not null,
  source_type        public.fixture_slot_source_type not null,
  source_entry_id    uuid references public.tournament_entries(entry_id) on delete restrict,
  source_fixture_id  uuid references public.tournament_fixtures(fixture_id) on delete restrict,
  source_group_id    uuid references public.tournament_groups(group_id) on delete restrict,
  source_stage_id    uuid references public.tournament_stages(stage_id) on delete restrict,
  source_seed        integer check (source_seed is null or source_seed > 0),
  source_rank        integer check (source_rank is null or source_rank > 0),
  resolved_entry_id  uuid references public.tournament_entries(entry_id) on delete set null,
  resolved_at        timestamptz,
  resolution_reason  text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  constraint fk_fixture_slots_fixture_tournament foreign key (fixture_id, tournament_id)
    references public.tournament_fixtures(fixture_id, tournament_id) on delete cascade,
  constraint fk_fixture_slots_fixture_stage foreign key (fixture_id, stage_id)
    references public.tournament_fixtures(fixture_id, stage_id) on delete cascade,
  constraint uq_fixture_slots_fixture_side unique (fixture_id, side),
  constraint chk_fixture_slots_no_self_ref check (source_fixture_id is null or source_fixture_id <> fixture_id),
  constraint chk_fixture_slot_source_shape check (
    (source_type = 'entry' and source_entry_id is not null and source_fixture_id is null and source_group_id is null and source_stage_id is null and source_seed is null and source_rank is null)
    or
    (source_type = 'seed' and source_seed is not null and source_entry_id is null and source_fixture_id is null and source_group_id is null and source_stage_id is null and source_rank is null)
    or
    (source_type = 'fixture_winner' and source_fixture_id is not null and source_entry_id is null and source_group_id is null and source_stage_id is null and source_seed is null and source_rank is null)
    or
    (source_type = 'fixture_loser' and source_fixture_id is not null and source_entry_id is null and source_group_id is null and source_stage_id is null and source_seed is null and source_rank is null)
    or
    (source_type = 'group_rank' and source_group_id is not null and source_rank is not null and source_entry_id is null and source_fixture_id is null and source_stage_id is null and source_seed is null)
    or
    (source_type = 'stage_rank' and source_stage_id is not null and source_rank is not null and source_entry_id is null and source_fixture_id is null and source_group_id is null and source_seed is null)
    or
    (source_type = 'bye' and source_entry_id is null and source_fixture_id is null and source_group_id is null and source_stage_id is null and source_seed is null and source_rank is null)
  )
);

comment on table public.tournament_fixture_slots is
  'Competitive side slots (A and B) of a tournament fixture governed by typed source references and symbolic qualification.';

-- 3. Indexes
create index idx_fixture_slots_fixture
  on public.tournament_fixture_slots (fixture_id, side);

create index idx_fixture_slots_source_fixture
  on public.tournament_fixture_slots (source_fixture_id)
  where source_fixture_id is not null;

create index idx_fixture_slots_source_entry
  on public.tournament_fixture_slots (source_entry_id)
  where source_entry_id is not null;

create index idx_fixture_slots_source_group
  on public.tournament_fixture_slots (source_group_id)
  where source_group_id is not null;

create index idx_fixture_slots_source_stage
  on public.tournament_fixture_slots (source_stage_id)
  where source_stage_id is not null;

create index idx_fixture_slots_resolved_entry
  on public.tournament_fixture_slots (resolved_entry_id)
  where resolved_entry_id is not null;

-- 4. Cross-Tournament & Structural Scope Referential Integrity Trigger
create or replace function public.enforce_fixture_slot_integrity()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_target_tournament_id uuid;
  v_target_stage_seq     integer;
  v_src_stage_id         uuid;
  v_src_stage_seq        integer;
begin
  -- 1. Source Entry Scope
  if new.source_entry_id is not null then
    select tournament_id into v_target_tournament_id
    from public.tournament_entries
    where entry_id = new.source_entry_id;

    if v_target_tournament_id is distinct from new.tournament_id then
      raise exception 'Cross-tournament source entry reference is prohibited' using errcode = '22000';
    end if;

    if new.source_type = 'entry' then
      if not exists (
        select 1
        from public.tournament_stage_entries
        where stage_id = new.stage_id and entry_id = new.source_entry_id
      ) then
        raise exception 'Source entry must belong to target stage' using errcode = '22000';
      end if;

      if new.resolved_entry_id is not null and new.resolved_entry_id <> new.source_entry_id then
        raise exception 'Resolved entry must match source entry for entry source type' using errcode = '22000';
      end if;
    end if;
  end if;

  -- 2. Resolved Entry Scope
  if new.resolved_entry_id is not null then
    select tournament_id into v_target_tournament_id
    from public.tournament_entries
    where entry_id = new.resolved_entry_id;

    if v_target_tournament_id is distinct from new.tournament_id then
      raise exception 'Cross-tournament resolved entry reference is prohibited' using errcode = '22000';
    end if;

    if not exists (
      select 1
      from public.tournament_stage_entries
      where stage_id = new.stage_id and entry_id = new.resolved_entry_id
    ) then
      raise exception 'Resolved entry must belong to target stage' using errcode = '22000';
    end if;
  end if;

  -- 3. Source Fixture Scope (Must be same stage and same tournament)
  if new.source_fixture_id is not null then
    select tournament_id, stage_id
    into v_target_tournament_id, v_src_stage_id
    from public.tournament_fixtures
    where fixture_id = new.source_fixture_id;

    if v_target_tournament_id is distinct from new.tournament_id then
      raise exception 'Cross-tournament source fixture reference is prohibited' using errcode = '22000';
    end if;

    if v_src_stage_id is distinct from new.stage_id then
      raise exception 'Source fixture must belong to the same stage as the target fixture' using errcode = '22000';
    end if;
  end if;

  -- 4. Source Group Scope (Must precede target stage sequence)
  if new.source_group_id is not null then
    select g.tournament_id, s.sequence
    into v_target_tournament_id, v_src_stage_seq
    from public.tournament_groups g
    join public.tournament_stages s on s.stage_id = g.stage_id
    where g.group_id = new.source_group_id;

    if v_target_tournament_id is distinct from new.tournament_id then
      raise exception 'Cross-tournament source group reference is prohibited' using errcode = '22000';
    end if;

    select sequence into v_target_stage_seq
    from public.tournament_stages
    where stage_id = new.stage_id;

    if v_src_stage_seq >= v_target_stage_seq then
      raise exception 'Source group must belong to a stage preceding the target stage' using errcode = '22000';
    end if;
  end if;

  -- 5. Source Stage Scope (Must precede target stage sequence)
  if new.source_stage_id is not null then
    select tournament_id, sequence
    into v_target_tournament_id, v_src_stage_seq
    from public.tournament_stages
    where stage_id = new.source_stage_id;

    if v_target_tournament_id is distinct from new.tournament_id then
      raise exception 'Cross-tournament source stage reference is prohibited' using errcode = '22000';
    end if;

    select sequence into v_target_stage_seq
    from public.tournament_stages
    where stage_id = new.stage_id;

    if v_src_stage_seq >= v_target_stage_seq then
      raise exception 'Source stage must precede the target stage' using errcode = '22000';
    end if;
  end if;

  return new;
end;
$$;

revoke execute on function public.enforce_fixture_slot_integrity() from public;

create trigger trg_fixture_slot_integrity
  before insert or update on public.tournament_fixture_slots
  for each row execute function public.enforce_fixture_slot_integrity();

create or replace function public.enforce_fixture_slot_published_draw_protection()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status        public.tournament_draw_revision_status;
  v_target_status public.tournament_draw_revision_status;
begin
  if tg_op = 'INSERT' then
    select r.status into v_status
    from public.tournament_fixtures f
    join public.tournament_draw_revisions r on r.draw_revision_id = f.draw_revision_id
    where f.fixture_id = new.fixture_id;

    if v_status in ('published', 'superseded') then
      raise exception 'Cannot add fixture slot to a published or superseded draw revision'
        using errcode = '22000';
    end if;
    return new;
  end if;

  if tg_op = 'DELETE' then
    select r.status into v_status
    from public.tournament_fixtures f
    join public.tournament_draw_revisions r on r.draw_revision_id = f.draw_revision_id
    where f.fixture_id = old.fixture_id;

    if v_status in ('published', 'superseded') then
      raise exception 'Cannot delete fixture slot belonging to a published or superseded draw revision'
        using errcode = '22000';
    end if;
    return old;
  end if;

  if tg_op = 'UPDATE' then
    select r.status into v_status
    from public.tournament_fixtures f
    join public.tournament_draw_revisions r on r.draw_revision_id = f.draw_revision_id
    where f.fixture_id = old.fixture_id;

    if v_status in ('published', 'superseded') then
      if new.fixture_id <> old.fixture_id
         or new.stage_id <> old.stage_id
         or new.tournament_id <> old.tournament_id
         or new.side <> old.side
         or new.source_type <> old.source_type
         or new.source_entry_id is distinct from old.source_entry_id
         or new.source_fixture_id is distinct from old.source_fixture_id
         or new.source_group_id is distinct from old.source_group_id
         or new.source_stage_id is distinct from old.source_stage_id
         or new.source_seed is distinct from old.source_seed
         or new.source_rank is distinct from old.source_rank then
        raise exception 'Cannot alter topology of a fixture slot belonging to a published or superseded draw revision'
          using errcode = '22000';
      end if;
    end if;

    if new.fixture_id <> old.fixture_id then
      select r.status into v_target_status
      from public.tournament_fixtures f
      join public.tournament_draw_revisions r on r.draw_revision_id = f.draw_revision_id
      where f.fixture_id = new.fixture_id;

      if v_target_status in ('published', 'superseded') then
        raise exception 'Cannot move fixture slot into a published or superseded draw revision'
          using errcode = '22000';
      end if;
    end if;

    return new;
  end if;

  return new;
end;
$$;

revoke execute on function public.enforce_fixture_slot_published_draw_protection() from public;

create trigger trg_fixture_slots_draw_revision_published_protection
  before insert or update or delete on public.tournament_fixture_slots
  for each row execute function public.enforce_fixture_slot_published_draw_protection();

create trigger trg_tournament_fixture_slots_set_updated_at
  before update on public.tournament_fixture_slots
  for each row execute function public.set_updated_at();

-- 5. RLS
alter table public.tournament_fixture_slots enable row level security;

-- Phase 4.1: Direct client mutation (INSERT, UPDATE, DELETE) is denied.
-- Mutations are command-owned (Phase 5 tournament-action, Phase 8/10 progression engines).
-- Staff/organizers may view fixture slots; safe public read models will be introduced in Phase 12.
create policy "tournament_fixture_slots_read_staff"
  on public.tournament_fixture_slots
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_fixture_slots.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or is_tournament_organizer(t.tournament_id)
          or can('tournament', t.tournament_id, 'tournament.view_admin')
          or can('tournament', t.tournament_id, 'tournament.fixture.schedule')
          or can('tournament', t.tournament_id, 'tournament.draw.manage')
        )
    )
  );
