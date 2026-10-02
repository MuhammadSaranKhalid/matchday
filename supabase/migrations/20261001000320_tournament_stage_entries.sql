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
  source_stage_id      uuid references public.tournament_stages(stage_id) on delete set null,
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

create index idx_stage_entries_entry_lookup
  on public.tournament_stage_entries (entry_id);

-- Enforce Active Tournament Entry on creation
create or replace function public.enforce_stage_entry_active_entry()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_entry_status public.tournament_entry_status;
begin
  select status into v_entry_status
  from public.tournament_entries
  where entry_id = new.entry_id;

  if v_entry_status is null or v_entry_status <> 'active' then
    raise exception 'Cannot create stage entry for non-active tournament entry'
      using errcode = '22000';
  end if;
  return new;
end;
$$;

create trigger trg_stage_entry_active_entry
  before insert on public.tournament_stage_entries
  for each row execute function public.enforce_stage_entry_active_entry();

create trigger trg_tournament_stage_entries_set_updated_at
  before update on public.tournament_stage_entries
  for each row execute function public.set_updated_at();

-- RLS
alter table public.tournament_stage_entries enable row level security;

create policy "tournament_stage_entries_read"
  on public.tournament_stage_entries
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_stage_entries.tournament_id
        and (
          t.privacy = 'public'
          or t.owner_user_id = (select auth.uid())
          or is_tournament_organizer(t.tournament_id)
        )
    )
  );

create policy "tournament_stage_entries_insert"
  on public.tournament_stage_entries
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_stage_entries.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or can('tournament', t.tournament_id, 'tournament.structure.manage')
        )
    )
  );

create policy "tournament_stage_entries_update"
  on public.tournament_stage_entries
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_stage_entries.tournament_id
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
      where t.tournament_id = tournament_stage_entries.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or can('tournament', t.tournament_id, 'tournament.structure.manage')
        )
    )
  );

create policy "tournament_stage_entries_delete"
  on public.tournament_stage_entries
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_stage_entries.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or can('tournament', t.tournament_id, 'tournament.structure.manage')
        )
    )
  );
