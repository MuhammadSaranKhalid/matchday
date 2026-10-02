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

create index idx_fixture_slots_resolved_entry
  on public.tournament_fixture_slots (resolved_entry_id)
  where resolved_entry_id is not null;

-- 4. Cross-Tournament Referential Integrity Trigger
create or replace function public.enforce_fixture_slot_integrity()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_target_tournament_id uuid;
begin
  if new.source_entry_id is not null then
    select tournament_id into v_target_tournament_id
    from public.tournament_entries
    where entry_id = new.source_entry_id;
    if v_target_tournament_id is distinct from new.tournament_id then
      raise exception 'Cross-tournament source entry reference is prohibited' using errcode = '22000';
    end if;
  end if;

  if new.source_fixture_id is not null then
    select tournament_id into v_target_tournament_id
    from public.tournament_fixtures
    where fixture_id = new.source_fixture_id;
    if v_target_tournament_id is distinct from new.tournament_id then
      raise exception 'Cross-tournament source fixture reference is prohibited' using errcode = '22000';
    end if;
  end if;

  if new.source_group_id is not null then
    select tournament_id into v_target_tournament_id
    from public.tournament_groups
    where group_id = new.source_group_id;
    if v_target_tournament_id is distinct from new.tournament_id then
      raise exception 'Cross-tournament source group reference is prohibited' using errcode = '22000';
    end if;
  end if;

  if new.source_stage_id is not null then
    select tournament_id into v_target_tournament_id
    from public.tournament_stages
    where stage_id = new.source_stage_id;
    if v_target_tournament_id is distinct from new.tournament_id then
      raise exception 'Cross-tournament source stage reference is prohibited' using errcode = '22000';
    end if;
  end if;

  if new.resolved_entry_id is not null then
    select tournament_id into v_target_tournament_id
    from public.tournament_entries
    where entry_id = new.resolved_entry_id;
    if v_target_tournament_id is distinct from new.tournament_id then
      raise exception 'Cross-tournament resolved entry reference is prohibited' using errcode = '22000';
    end if;
  end if;

  return new;
end;
$$;

create trigger trg_fixture_slot_integrity
  before insert or update on public.tournament_fixture_slots
  for each row execute function public.enforce_fixture_slot_integrity();

create trigger trg_tournament_fixture_slots_set_updated_at
  before update on public.tournament_fixture_slots
  for each row execute function public.set_updated_at();

-- 5. RLS
alter table public.tournament_fixture_slots enable row level security;

create policy "tournament_fixture_slots_read"
  on public.tournament_fixture_slots
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_fixture_slots.tournament_id
        and (
          t.privacy = 'public'
          or t.owner_user_id = (select auth.uid())
          or is_tournament_organizer(t.tournament_id)
        )
    )
  );

create policy "tournament_fixture_slots_insert"
  on public.tournament_fixture_slots
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_fixture_slots.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or can('tournament', t.tournament_id, 'tournament.draw.manage')
        )
    )
  );

create policy "tournament_fixture_slots_update"
  on public.tournament_fixture_slots
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_fixture_slots.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or can('tournament', t.tournament_id, 'tournament.draw.manage')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_fixture_slots.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or can('tournament', t.tournament_id, 'tournament.draw.manage')
        )
    )
  );

create policy "tournament_fixture_slots_delete"
  on public.tournament_fixture_slots
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_fixture_slots.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or can('tournament', t.tournament_id, 'tournament.draw.manage')
        )
    )
  );
