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

-- Published draw & reverse reference protection:
-- 1. Cannot delete stage containing published/superseded draw revisions.
-- 2. Cannot alter structural fields (sequence, format, config, rules) if stage has published draws.
-- 3. Changing sequence must not violate upstream or downstream cross-stage qualification relationships.
create or replace function public.enforce_stage_integrity()
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
      from public.tournament_draw_revisions dr
      where dr.stage_id = old.stage_id
        and dr.status in ('published', 'superseded')
    ) then
      raise exception 'Cannot delete stage % with published or superseded draw revision', old.stage_id
        using errcode = '22000';
    end if;
    return old;
  end if;

  if tg_op = 'UPDATE' then
    if new.tournament_id <> old.tournament_id then
      raise exception 'tournament_id on tournament_stages is immutable'
        using errcode = '22000';
    end if;

    select exists (
      select 1
      from public.tournament_draw_revisions dr
      where dr.stage_id = old.stage_id
        and dr.status in ('published', 'superseded')
    ) into v_is_published;

    if v_is_published then
      if new.sequence <> old.sequence
         or new.competition_format <> old.competition_format
         or new.competition_config is distinct from old.competition_config
         or new.sport_rules_override is distinct from old.sport_rules_override then
        raise exception 'Structural fields (sequence, competition_format, competition_config, sport_rules_override) of a published stage cannot be altered'
          using errcode = '22000';
      end if;
    end if;

    if new.sequence <> old.sequence then
      -- 1. Check incoming stage entries from this stage (outgoing provenance)
      if exists (
        select 1
        from public.tournament_stage_entries se
        join public.tournament_stages src on src.stage_id = se.source_stage_id
        where se.stage_id = old.stage_id
          and src.sequence >= new.sequence
      ) then
        raise exception 'Stage sequence % violates precedence for existing incoming stage entry qualification sources', new.sequence
          using errcode = '22000';
      end if;

      -- 2. Check downstream stage entries sourcing this stage (incoming provenance)
      if exists (
        select 1
        from public.tournament_stage_entries se
        join public.tournament_stages tgt on tgt.stage_id = se.stage_id
        where se.source_stage_id = old.stage_id
          and new.sequence >= tgt.sequence
      ) then
        raise exception 'Stage sequence % violates precedence for downstream stage entries sourcing this stage', new.sequence
          using errcode = '22000';
      end if;

      -- 3. Check outgoing GROUP_RANK slots in this stage
      if exists (
        select 1
        from public.tournament_fixture_slots fs
        join public.tournament_groups g on g.group_id = fs.source_group_id
        join public.tournament_stages src on src.stage_id = g.stage_id
        where fs.stage_id = old.stage_id
          and src.sequence >= new.sequence
      ) then
        raise exception 'Stage sequence % violates precedence for fixture slots in this stage sourcing upstream groups', new.sequence
          using errcode = '22000';
      end if;

      -- 4. Check downstream GROUP_RANK slots sourcing groups in this stage
      if exists (
        select 1
        from public.tournament_fixture_slots fs
        join public.tournament_groups g on g.group_id = fs.source_group_id
        join public.tournament_stages tgt on tgt.stage_id = fs.stage_id
        where g.stage_id = old.stage_id
          and new.sequence >= tgt.sequence
      ) then
        raise exception 'Stage sequence % violates precedence for downstream fixture slots sourcing groups in this stage', new.sequence
          using errcode = '22000';
      end if;

      -- 5. Check outgoing STAGE_RANK slots in this stage
      if exists (
        select 1
        from public.tournament_fixture_slots fs
        join public.tournament_stages src on src.stage_id = fs.source_stage_id
        where fs.stage_id = old.stage_id
          and src.sequence >= new.sequence
      ) then
        raise exception 'Stage sequence % violates precedence for fixture slots in this stage sourcing upstream stages', new.sequence
          using errcode = '22000';
      end if;

      -- 6. Check downstream STAGE_RANK slots sourcing this stage
      if exists (
        select 1
        from public.tournament_fixture_slots fs
        join public.tournament_stages tgt on tgt.stage_id = fs.stage_id
        where fs.source_stage_id = old.stage_id
          and new.sequence >= tgt.sequence
      ) then
        raise exception 'Stage sequence % violates precedence for downstream fixture slots sourcing this stage', new.sequence
          using errcode = '22000';
      end if;
    end if;

    return new;
  end if;

  return null;
end;
$$;

revoke execute on function public.enforce_stage_integrity() from public;

drop trigger if exists trg_stages_published_draw_protection on public.tournament_stages;
drop trigger if exists trg_stage_integrity on public.tournament_stages;
create trigger trg_stage_integrity
  before update or delete on public.tournament_stages
  for each row execute function public.enforce_stage_integrity();

-- 5. RLS
-- Structural tables are command-owned. Direct client INSERT, UPDATE, DELETE through PostgREST are denied.
alter table public.tournament_stages enable row level security;

create policy "tournament_stages_read_staff"
  on public.tournament_stages
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_stages.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or is_tournament_organizer(t.tournament_id)
        )
    )
  );

