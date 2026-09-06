-- =============================================================================
-- 0410 · match_officials — per-match scorer / umpire assignment
-- =============================================================================
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
-- =============================================================================

-- Shape mirrors the table already deployed (see the drift note above): no
-- created_at/updated_at, and the umpire roles split by position.
create table if not exists public.match_officials (
  match_id    uuid not null references public.matches(match_id) on delete cascade,
  user_id     uuid not null references public.profiles(user_id) on delete cascade,
  role        text not null
                check (role in ('scorer', 'umpire_main', 'umpire_leg',
                                'umpire_third', 'referee')),
  assigned_at timestamptz not null default now(),
  assigned_by uuid references public.profiles(user_id) on delete set null,

  primary key (match_id, user_id, role)
);

create index if not exists match_officials_user
  on public.match_officials (user_id);

alter table public.match_officials enable row level security;

-- Read: anyone who can already see the match's tournament, plus the official
-- themselves. Kept permissive on select because a scorer's name is shown on
-- the public Live Ops and fixture surfaces.
drop policy if exists "match_officials_read" on public.match_officials;
create policy "match_officials_read"
  on public.match_officials for select
  to authenticated
  using (true);

-- Write: organisers of the match's tournament only. Assignment is an
-- organiser act; a scorer cannot appoint themselves.
drop policy if exists "match_officials_write_organizers" on public.match_officials;
create policy "match_officials_write_organizers"
  on public.match_officials for all
  to authenticated
  using (
    exists (
      select 1 from public.matches m
       where m.match_id = match_officials.match_id
         and m.tournament_id is not null
         and public.is_tournament_organizer(m.tournament_id)
    )
  )
  with check (
    exists (
      select 1 from public.matches m
       where m.match_id = match_officials.match_id
         and m.tournament_id is not null
         and public.is_tournament_organizer(m.tournament_id)
    )
  );

-- -----------------------------------------------------------------------------
-- Foreign-key indexes (Supabase advisor 0001_unindexed_foreign_keys)
-- -----------------------------------------------------------------------------
-- Postgres does NOT index the referencing side of a foreign key for you. Every
-- one of these columns points at a parent that gets deleted or updated
-- (profiles on account deletion, matches/teams on cascade), and without an
-- index each such statement seq-scans this table once per affected parent row.
-- They are also the columns joined on when reading.

create index if not exists idx_match_officials_assigned_by
  on public.match_officials (assigned_by);
