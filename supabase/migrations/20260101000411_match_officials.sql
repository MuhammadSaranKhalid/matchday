-- =============================================================================
-- Migration: 20260101000411_match_officials.sql
-- =============================================================================

-- 0411 · match_officials — per-match scorer / umpire assignment
-- Its own migration, per the one-table-one-migration convention, and numbered
-- 0410 so it lands immediately after matches (0400).
--
-- It used to be created inside 20260830000000_tournament_live_ops.sql, which
-- runs LONG after 20260816120000_list_my_matches_rpc.sql — and that RPC joins
-- match_officials. Because list_my_matches is `language sql`, Postgres checks
-- its body at CREATE time, so a clean `supabase db reset` failed there with
-- "relation public.match_officials does not exist". Nothing caught it because
-- the deployed database had the table already, having acquired it out of band.
--
-- Splitting the table out of the ops migration is what fixes the ordering: the
-- table is defined once, before anything reads it, and tournament_live_ops
-- keeps only the RPCs that write it.
--
-- is_tournament_organizer() (used by the write policy) comes from 0300.
-- Shape mirrors the table already deployed (see the drift note above): no
-- created_at/updated_at, and the umpire roles split by position.

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table if not exists public.match_officials (
  match_id    uuid not null
    references public.matches (match_id)
    on delete cascade,
  user_id     uuid not null
    references public.profiles (user_id)
    on delete cascade,
  role        text not null check (
    role in ('scorer', 'umpire_main', 'umpire_leg', 'umpire_third', 'referee')
  ),
  assigned_at timestamptz not null default now(),
  assigned_by uuid
    references public.profiles (user_id)
    on delete set null,
  primary key (match_id, user_id, role)
);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

create index if not exists match_officials_user
  on public.match_officials (user_id);

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

alter table public.match_officials enable row level security;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

-- Read: anyone who can already see the match's tournament, plus the official
-- themselves. Kept permissive on select because a scorer's name is shown on
-- the public Live Ops and fixture surfaces.
drop policy if exists "match_officials_read" on public.match_officials;

create policy "match_officials_read"
  on public.match_officials
  for select
  to authenticated
  using (true);

-- Write: whoever runs the fixture. Assignment is always someone else's act —
-- a scorer cannot appoint themselves.
--
--   * tournament match → an organiser of that tournament (as before);
--   * casual match     → a captain/manager/owner of either side.
--
-- The casual branch was added 2026-09-10 with the scoring-delegation rule
-- (docs/team-roles-design.md §5). Until then match_officials could only be
-- written by tournament organisers AND the row granted nothing anyway —
-- `_can_score_innings` never consulted this table, so the organiser console's
-- offer to "revoke scoring rights or take over the match" was inert. Both
-- halves are now real: this policy writes the row, and `_can_score_innings`
-- honours it.
--
-- ONE permissive policy per (table, command, role) — Supabase advisor 0006 —
-- so the two cases are branches of a single expression, not two policies.
drop policy if exists "match_officials_write_organizers" on public.match_officials;

create policy "match_officials_write_organizers"
  on public.match_officials
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.matches m
      where m.match_id = match_officials.match_id
        and (
          case
            when m.tournament_id is not null then public.is_tournament_organizer(
              m.tournament_id
            )
            else exists (
              select 1
              from public.match_teams mt
              where mt.match_id = m.match_id
                and mt.team_id is not null
                and public.can('team', mt.team_id, 'match.official.assign')
            )
          end
        )
    )
  )
  with check (
    exists (
      select 1
      from public.matches m
      where m.match_id = match_officials.match_id
        and (
          case
            when m.tournament_id is not null then public.is_tournament_organizer(
              m.tournament_id
            )
            else exists (
              select 1
              from public.match_teams mt
              where mt.match_id = m.match_id
                and mt.team_id is not null
                and public.can('team', mt.team_id, 'match.official.assign')
            )
          end
        )
    )
    -- A captain may hand out scoring, not umpiring: neutral officials on a
    -- casual match would be self-appointed by one of the two sides.
    and (
      match_officials.role = 'scorer'
      or exists (
        select 1
        from public.matches m
        where m.match_id = match_officials.match_id and m.tournament_id is not null
      )
    )
  );

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- The scorer appointment IS an authorization grant (2026-09-11)
-- match_officials keeps its rows: they are the record of who officiated, shown
-- on the scorecard, and they cover umpires and referees who need no permission
-- at all. But a `scorer` row has to actually GRANT something.
--
-- Until now it granted nothing — `_can_score_innings` never consulted this
-- table — while the organiser console offered to "revoke scoring rights or take
-- over the match at any time". This trigger makes the offer true by mirroring
-- the appointment into `grants`, which is the one place the engine looks.
--
-- The mirror is one-directional on purpose: match_officials is the editable
-- record, grants is derived. Deleting the official removes the grant.
create or replace function public.mirror_scorer_grant()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'DELETE' then
    if old.role = 'scorer' then
      delete from public.grants
      where
        subject_id = old.user_id
        and scope = 'match'
        and entity_id = old.match_id
        and permission_key = 'match.score';
    end if;
    return old;
  end if;
  if new.role = 'scorer' then
    insert into public.grants (subject_id, scope, entity_id, permission_key, granted_by)
    values (new.user_id, 'match', new.match_id, 'match.score', new.assigned_by)
    on conflict (subject_id, scope, entity_id, permission_key) do nothing;
  end if;
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger match_officials_mirror_scorer
  after insert or update or delete on public.match_officials
  for each row
  execute function public.mirror_scorer_grant();

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

-- Foreign-key indexes (Supabase advisor 0001_unindexed_foreign_keys)
-- Postgres does NOT index the referencing side of a foreign key for you. Every
-- one of these columns points at a parent that gets deleted or updated
-- (profiles on account deletion, matches/teams on cascade), and without an
-- index each such statement seq-scans this table once per affected parent row.
-- They are also the columns joined on when reading.
create index if not exists idx_match_officials_assigned_by
  on public.match_officials (
    assigned_by
  );
