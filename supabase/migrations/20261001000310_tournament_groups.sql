-- Migration: 20261001000310_tournament_groups.sql
-- Description: Phase 4 canonical tournament groups (stage-scoped partitions).

create table public.tournament_groups (
  group_id       uuid primary key default gen_random_uuid(),
  stage_id       uuid not null,
  tournament_id  uuid not null,
  sequence       integer not null check (sequence > 0),
  name           text not null check (length(trim(name)) > 0),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  constraint fk_tournament_groups_stage_tournament foreign key (stage_id, tournament_id)
    references public.tournament_stages(stage_id, tournament_id) on delete cascade,
  constraint uq_tournament_groups_stage_sequence unique (stage_id, sequence),
  constraint uq_tournament_groups_stage_name unique (stage_id, name),
  constraint uq_tournament_groups_group_stage unique (group_id, stage_id),
  constraint uq_tournament_groups_group_tournament unique (group_id, tournament_id)
);

comment on table public.tournament_groups is
  'First-class groups partitioned within a specific tournament stage (e.g. Group A, Group B).';

-- Indexes
create index idx_tournament_groups_lookup
  on public.tournament_groups (stage_id, sequence);

-- Triggers
create trigger trg_tournament_groups_set_updated_at
  before update on public.tournament_groups
  for each row execute function public.set_updated_at();

-- Published draw & structural integrity protection for tournament_groups
create or replace function public.enforce_group_integrity()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_is_published boolean;
begin
  if tg_op = 'DELETE' then
    if exists (
      select 1
      from public.tournament_fixtures f
      join public.tournament_draw_revisions dr on dr.draw_revision_id = f.draw_revision_id
      where dr.status in ('published', 'superseded')
        and exists (
          select 1
          from public.tournament_rounds r
          where r.round_id = f.round_id and r.group_id = old.group_id
        )
    ) or exists (
      select 1
      from public.tournament_fixture_slots fs
      join public.tournament_fixtures f on f.fixture_id = fs.fixture_id
      join public.tournament_draw_revisions dr on dr.draw_revision_id = f.draw_revision_id
      where dr.status in ('published', 'superseded')
        and fs.source_group_id = old.group_id
    ) or exists (
      select 1
      from public.tournament_draw_revisions dr
      where dr.stage_id = old.stage_id
        and dr.status in ('published', 'superseded')
    ) then
      raise exception 'Cannot delete group % referenced by published or superseded draw revision', old.group_id
        using errcode = '22000';
    end if;
    return old;
  end if;

  if tg_op = 'UPDATE' then
    if new.stage_id <> old.stage_id or new.tournament_id <> old.tournament_id then
      raise exception 'stage_id and tournament_id on tournament_groups are immutable'
        using errcode = '22000';
    end if;

    select exists (
      select 1
      from public.tournament_draw_revisions dr
      where dr.stage_id = old.stage_id
        and dr.status in ('published', 'superseded')
    ) into v_is_published;

    if v_is_published then
      if new.sequence <> old.sequence then
        raise exception 'Cannot alter sequence of a group in a published stage'
          using errcode = '22000';
      end if;
    end if;

    return new;
  end if;

  return null;
end;
$$;

revoke execute on function public.enforce_group_integrity() from public;

drop trigger if exists trg_groups_published_draw_protection on public.tournament_groups;
drop trigger if exists trg_groups_integrity on public.tournament_groups;
create trigger trg_groups_integrity
  before update or delete on public.tournament_groups
  for each row execute function public.enforce_group_integrity();

-- RLS
-- Structural tables are command-owned. Direct client INSERT, UPDATE, DELETE through PostgREST are denied.
alter table public.tournament_groups enable row level security;

create policy "tournament_groups_read_staff"
  on public.tournament_groups
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_groups.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or is_tournament_organizer(t.tournament_id)
        )
    )
  );

