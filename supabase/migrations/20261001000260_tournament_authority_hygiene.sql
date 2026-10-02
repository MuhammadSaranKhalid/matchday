-- Migration: 20261001000260_tournament_authority_hygiene.sql
-- Description: Phase 3.2 pre-flight hygiene: drop unreachable owner_user_id IS NULL fallbacks, rename stale organizer policies, and add candidate key for composite FK integrity.

-- 1. public.tournaments: remove dead fallback and rename policies
drop policy if exists "tournaments_update_organizers" on public.tournaments;
drop policy if exists "tournaments_update_authorized" on public.tournaments;

create policy "tournaments_update_authorized"
  on public.tournaments
  for update
  to authenticated
  using (
    owner_user_id = (select auth.uid())
    or can('tournament', tournament_id, 'tournament.edit')
  )
  with check (
    owner_user_id = (select auth.uid())
    or can('tournament', tournament_id, 'tournament.edit')
  );

drop policy if exists "tournaments_delete_creator" on public.tournaments;
drop policy if exists "tournaments_delete_owner" on public.tournaments;

create policy "tournaments_delete_owner"
  on public.tournaments
  for delete
  to authenticated
  using (
    owner_user_id = (select auth.uid())
  );

-- 2. public.tournament_grounds: rename organizer policy to staff policy
drop policy if exists "tournament_grounds_write_organizer" on public.tournament_grounds;
drop policy if exists "tournament_grounds_write_staff" on public.tournament_grounds;

create policy "tournament_grounds_write_staff"
  on public.tournament_grounds
  for all
  to authenticated
  using (
    is_tournament_organizer(tournament_id)
  )
  with check (
    is_tournament_organizer(tournament_id)
  );

-- 3. public.match_officials: rename organizers policy to authorized policy
drop policy if exists "match_officials_write_organizers" on public.match_officials;
drop policy if exists "match_officials_write_authorized" on public.match_officials;

create policy "match_officials_write_authorized"
  on public.match_officials
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.matches m
      where m.match_id = match_officials.match_id
        and case
          when m.tournament_id is not null then
            is_tournament_organizer(m.tournament_id)
          else
            exists (
              select 1
              from public.match_teams mt
              where mt.match_id = m.match_id
                and mt.team_id is not null
                and can('team', mt.team_id, 'match.official.assign')
            )
        end
    )
  )
  with check (
    exists (
      select 1
      from public.matches m
      where m.match_id = match_officials.match_id
        and case
          when m.tournament_id is not null then
            is_tournament_organizer(m.tournament_id)
          else
            exists (
              select 1
              from public.match_teams mt
              where mt.match_id = m.match_id
                and mt.team_id is not null
                and can('team', mt.team_id, 'match.official.assign')
            )
        end
    )
    and (
      role = 'scorer'
      or exists (
        select 1
        from public.matches m
        where m.match_id = match_officials.match_id
          and m.tournament_id is not null
      )
    )
  );

-- 4. Candidate key for composite foreign keys to guarantee cross-table tournament scope
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.tournament_entries'::regclass
      and conname = 'idx_tournament_entries_entry_tournament_unique'
  ) then
    alter table public.tournament_entries
      add constraint idx_tournament_entries_entry_tournament_unique unique (entry_id, tournament_id);
  end if;
end $$;
