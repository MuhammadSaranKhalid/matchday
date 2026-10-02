-- Migration: 20261001000340_tournament_draw_revisions.sql
-- Description: Phase 4 canonical tournament draw revisions (versioned, auditable, immutable history).

-- 1. Status Enum
do $$
begin
  if not exists (select 1 from pg_type where typname = 'tournament_draw_revision_status') then
    create type public.tournament_draw_revision_status as enum (
      'draft',
      'published',
      'superseded'
    );
  end if;
end $$;

-- 2. Draw Revisions Table
create table public.tournament_draw_revisions (
  draw_revision_id        uuid primary key default gen_random_uuid(),
  stage_id                uuid not null,
  tournament_id           uuid not null,
  revision_number         integer not null check (revision_number > 0),
  status                  public.tournament_draw_revision_status not null default 'draft',
  based_on_entry_revision integer not null check (based_on_entry_revision >= 0),
  plan_snapshot           jsonb not null default '{}'::jsonb,
  revision_reason         text,
  created_by              uuid references public.profiles(user_id) on delete set null,
  created_at              timestamptz not null default now(),
  published_by             uuid references public.profiles(user_id) on delete set null,
  published_at            timestamptz,
  constraint fk_draw_revisions_stage_tournament foreign key (stage_id, tournament_id)
    references public.tournament_stages(stage_id, tournament_id) on delete cascade,
  constraint uq_draw_revisions_stage_revision unique (stage_id, revision_number),
  constraint uq_draw_revisions_id_stage unique (draw_revision_id, stage_id),
  constraint uq_draw_revisions_id_tournament unique (draw_revision_id, tournament_id)
);

comment on table public.tournament_draw_revisions is
  'Versioned, auditable draw revisions for a tournament stage representing frozen structural plans.';

-- 3. Indexes
create index idx_draw_revisions_lookup
  on public.tournament_draw_revisions (stage_id, revision_number);

-- 4. Immutability Trigger
create or replace function public.enforce_draw_revision_immutability()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'DELETE' then
    if old.status in ('published', 'superseded') then
      raise exception 'Published or superseded draw revisions cannot be deleted'
        using errcode = '22000';
    end if;
    return old;
  end if;

  if tg_op = 'UPDATE' then
    if old.status in ('published', 'superseded') then
      if old.status = 'published' and new.status = 'superseded' then
        if new.revision_number <> old.revision_number
           or new.stage_id <> old.stage_id
           or new.tournament_id <> old.tournament_id
           or new.based_on_entry_revision <> old.based_on_entry_revision
           or new.plan_snapshot <> old.plan_snapshot
           or new.published_at <> old.published_at
           or new.published_by is distinct from old.published_by then
          raise exception 'Immutable fields of published draw revision cannot be updated'
            using errcode = '22000';
        end if;
        return new;
      else
        raise exception 'Published or superseded draw revisions are immutable'
          using errcode = '22000';
      end if;
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_draw_revision_immutability
  before update or delete on public.tournament_draw_revisions
  for each row execute function public.enforce_draw_revision_immutability();

-- 5. RLS
alter table public.tournament_draw_revisions enable row level security;

create policy "tournament_draw_revisions_read"
  on public.tournament_draw_revisions
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_draw_revisions.tournament_id
        and (
          (t.privacy = 'public' and tournament_draw_revisions.status = 'published')
          or t.owner_user_id = (select auth.uid())
          or is_tournament_organizer(t.tournament_id)
        )
    )
  );

create policy "tournament_draw_revisions_insert"
  on public.tournament_draw_revisions
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_draw_revisions.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or can('tournament', t.tournament_id, 'tournament.draw.manage')
        )
    )
  );

create policy "tournament_draw_revisions_update"
  on public.tournament_draw_revisions
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_draw_revisions.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or can('tournament', t.tournament_id, 'tournament.draw.manage')
          or can('tournament', t.tournament_id, 'tournament.draw.publish')
        )
    )
  )
  with check (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_draw_revisions.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or can('tournament', t.tournament_id, 'tournament.draw.manage')
          or can('tournament', t.tournament_id, 'tournament.draw.publish')
        )
    )
  );

create policy "tournament_draw_revisions_delete"
  on public.tournament_draw_revisions
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.tournaments t
      where t.tournament_id = tournament_draw_revisions.tournament_id
        and (
          t.owner_user_id = (select auth.uid())
          or can('tournament', t.tournament_id, 'tournament.draw.manage')
        )
    )
  );
