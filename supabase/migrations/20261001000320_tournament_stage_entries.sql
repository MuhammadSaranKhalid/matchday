-- Migration: 20261001000320_tournament_stage_entries.sql
-- Description: Phase 4 canonical stage participants referencing Tournament Entry.

create table public.tournament_stage_entries (
  stage_entry_id       uuid primary key default gen_random_uuid(),
  stage_id             uuid not null,
  entry_id             uuid not null,
  tournament_id        uuid not null,
  group_id             uuid,
  seed                 integer check (seed is null or seed > 0),
  status               text not null default 'active' check (status in ('active', 'withdrawn', 'eliminated', 'advanced')),
  source_stage_id      uuid,
  qualification_source jsonb,
  entered_at           timestamptz not null default now(),
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  constraint fk_stage_entries_stage_tournament foreign key (stage_id, tournament_id)
    references public.tournament_stages(stage_id, tournament_id) on delete cascade,
  constraint fk_stage_entries_entry_tournament foreign key (entry_id, tournament_id)
    references public.tournament_entries(entry_id, tournament_id) on delete restrict,
  constraint fk_stage_entries_group_stage foreign key (group_id, stage_id)
    references public.tournament_groups(group_id, stage_id) on delete set null,
  constraint fk_stage_entries_source_stage_tournament foreign key (source_stage_id, tournament_id)
    references public.tournament_stages(stage_id, tournament_id) on delete set null,
  constraint uq_stage_entries_stage_entry unique (stage_id, entry_id),
  constraint uq_stage_entries_id_stage unique (stage_entry_id, stage_id),
  constraint uq_stage_entries_id_tournament unique (stage_entry_id, tournament_id),
  constraint chk_stage_entries_source_stage check (source_stage_id is null or source_stage_id <> stage_id)
);

comment on table public.tournament_stage_entries is
  'Participant in a specific tournament stage referencing an accepted canonical Tournament Entry.';

-- Indexes
create unique index idx_stage_entries_stage_seed
  on public.tournament_stage_entries (stage_id, seed)
  where seed is not null;

create index idx_stage_entries_group_lookup
  on public.tournament_stage_entries (group_id)
  where group_id is not null;

create index idx_stage_entries_group_stage
  on public.tournament_stage_entries (group_id, stage_id)
  where group_id is not null;

create index idx_stage_entries_source_stage
  on public.tournament_stage_entries (source_stage_id)
  where source_stage_id is not null;

create index idx_stage_entries_entry_lookup
  on public.tournament_stage_entries (entry_id);

-- Enforce Active Tournament Entry on creation and reassignment, plus stage sequence precedence
create or replace function public.enforce_stage_entry_integrity()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_entry_status public.tournament_entry_status;
  v_source_seq integer;
  v_target_seq integer;
begin
  if (tg_op = 'INSERT' or old.entry_id is distinct from new.entry_id or old.tournament_id is distinct from new.tournament_id) then
    select status into v_entry_status
    from public.tournament_entries
    where entry_id = new.entry_id
      and tournament_id = new.tournament_id;

    if v_entry_status is null or v_entry_status <> 'active' then
      raise exception 'Cannot assign non-active tournament entry % to stage %', new.entry_id, new.stage_id
        using errcode = '22000';
    end if;
  end if;

  if new.source_stage_id is not null then
    select sequence into v_source_seq
    from public.tournament_stages
    where stage_id = new.source_stage_id
      and tournament_id = new.tournament_id;

    select sequence into v_target_seq
    from public.tournament_stages
    where stage_id = new.stage_id
      and tournament_id = new.tournament_id;

    if v_source_seq is null or v_target_seq is null or v_source_seq >= v_target_seq then
      raise exception 'Source stage % (sequence %) must strictly precede target stage % (sequence %)',
        new.source_stage_id, coalesce(v_source_seq, 0), new.stage_id, coalesce(v_target_seq, 0)
        using errcode = '22000';
    end if;
  end if;

  return new;
end;
$$;

revoke execute on function public.enforce_stage_entry_integrity() from public;

drop trigger if exists trg_stage_entry_active_entry on public.tournament_stage_entries;
drop trigger if exists trg_stage_entry_integrity on public.tournament_stage_entries;
create trigger trg_stage_entry_integrity
  before insert or update on public.tournament_stage_entries
  for each row execute function public.enforce_stage_entry_integrity();

-- Published draw protection: cannot delete stage entry referenced by published or superseded draw revision
create or replace function public.trg_stage_entries_published_draw_protection()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if exists (
    select 1
    from public.tournament_fixture_slots fs
    join public.tournament_fixtures f on f.fixture_id = fs.fixture_id
    join public.tournament_draw_revisions dr on dr.draw_revision_id = f.draw_revision_id
    where dr.status in ('published', 'superseded')
      and fs.stage_id = old.stage_id
      and (fs.source_entry_id = old.entry_id or fs.resolved_entry_id = old.entry_id)
  ) then
    raise exception 'Cannot delete stage entry % referenced by published or superseded draw revision', old.stage_entry_id
      using errcode = '22000';
  end if;
  return old;
end;
$$;

revoke execute on function public.trg_stage_entries_published_draw_protection() from public;

drop trigger if exists trg_stage_entries_published_draw_protection on public.tournament_stage_entries;
create trigger trg_stage_entries_published_draw_protection
  before delete on public.tournament_stage_entries
  for each row execute function public.trg_stage_entries_published_draw_protection();

create trigger trg_tournament_stage_entries_set_updated_at
  before update on public.tournament_stage_entries
  for each row execute function public.set_updated_at();

-- RLS
-- Structural tables are command-owned. Direct client INSERT, UPDATE, DELETE through PostgREST are denied.
alter table public.tournament_stage_entries enable row level security;

create policy "tournament_stage_entries_read_staff"
  on public.tournament_stage_entries
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_stage_entries.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or is_tournament_organizer(t.tournament_id)
        )
    )
  );

