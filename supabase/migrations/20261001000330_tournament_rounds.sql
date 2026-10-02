-- Migration: 20261001000330_tournament_rounds.sql
-- Description: Phase 4 canonical tournament competition rounds.

create table public.tournament_rounds (
  round_id       uuid primary key default gen_random_uuid(),
  stage_id       uuid not null,
  tournament_id  uuid not null,
  group_id       uuid,
  round_number   integer not null check (round_number > 0),
  label          text not null check (length(trim(label)) > 0),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  constraint fk_tournament_rounds_stage_tournament foreign key (stage_id, tournament_id)
    references public.tournament_stages(stage_id, tournament_id) on delete cascade,
  constraint fk_tournament_rounds_group_stage foreign key (group_id, stage_id)
    references public.tournament_groups(group_id, stage_id) on delete set null,
  constraint uq_tournament_rounds_id_stage unique (round_id, stage_id),
  constraint uq_tournament_rounds_id_tournament unique (round_id, tournament_id)
);

comment on table public.tournament_rounds is
  'First-class competition round within a tournament stage (e.g. Round 1, Quarter-final, Semi-final, Final).';

-- Indexes
create unique index idx_rounds_stage_number
  on public.tournament_rounds (stage_id, round_number)
  where group_id is null;

create unique index idx_rounds_group_number
  on public.tournament_rounds (group_id, round_number)
  where group_id is not null;

create index idx_rounds_lookup
  on public.tournament_rounds (stage_id, round_number);

create index idx_rounds_group_id
  on public.tournament_rounds (group_id)
  where group_id is not null;

-- Triggers
create trigger trg_tournament_rounds_set_updated_at
  before update on public.tournament_rounds
  for each row execute function public.set_updated_at();

-- Published draw protection: cannot delete round if it contains fixtures in published or superseded draw revision
create or replace function public.trg_rounds_published_draw_protection()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if exists (
    select 1
    from public.tournament_fixtures f
    join public.tournament_draw_revisions dr on dr.draw_revision_id = f.draw_revision_id
    where f.round_id = old.round_id
      and dr.status in ('published', 'superseded')
  ) then
    raise exception 'Cannot delete round % containing fixtures in published or superseded draw revision', old.round_id
      using errcode = '22000';
  end if;
  return old;
end;
$$;

revoke execute on function public.trg_rounds_published_draw_protection() from public;

drop trigger if exists trg_rounds_published_draw_protection on public.tournament_rounds;
create trigger trg_rounds_published_draw_protection
  before delete on public.tournament_rounds
  for each row execute function public.trg_rounds_published_draw_protection();

-- RLS
-- Structural tables are command-owned. Direct client INSERT, UPDATE, DELETE through PostgREST are denied.
alter table public.tournament_rounds enable row level security;

create policy "tournament_rounds_read_staff"
  on public.tournament_rounds
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_rounds.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or is_tournament_organizer(t.tournament_id)
        )
    )
  );

