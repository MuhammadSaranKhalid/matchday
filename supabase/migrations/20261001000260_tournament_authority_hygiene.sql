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

-- 5. Canonical Entry Set Revision (database-maintained, positive, monotonic)
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'tournaments'
      and column_name = 'entry_revision'
  ) then
    alter table public.tournaments
      add column entry_revision integer not null default 1 check (entry_revision > 0);
  end if;
end $$;

create or replace function public.trg_tournament_entries_entry_revision()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if (tg_op = 'INSERT') then
    if new.status = 'active' then
      update public.tournaments
         set entry_revision = entry_revision + 1
       where tournament_id = new.tournament_id;
    end if;
    return new;
  elsif (tg_op = 'UPDATE') then
    if (old.status = 'active' or new.status = 'active') and (old.status is distinct from new.status) then
      update public.tournaments
         set entry_revision = entry_revision + 1
       where tournament_id = new.tournament_id;
    end if;
    return new;
  elsif (tg_op = 'DELETE') then
    if old.status = 'active' then
      update public.tournaments
         set entry_revision = entry_revision + 1
       where tournament_id = old.tournament_id;
    end if;
    return old;
  end if;
  return null;
end;
$$;

revoke execute on function public.trg_tournament_entries_entry_revision() from public;

drop trigger if exists trg_tournament_entries_entry_revision on public.tournament_entries;
create trigger trg_tournament_entries_entry_revision
  after insert or update or delete on public.tournament_entries
  for each row execute function public.trg_tournament_entries_entry_revision();

-- Protect entry_revision from manual direct client mutation
create or replace function public.trg_tournaments_entry_revision_protect()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if old.entry_revision is distinct from new.entry_revision then
    if pg_trigger_depth() <= 1 then
      raise exception 'tournaments.entry_revision is maintained by the database and cannot be modified directly'
        using errcode = '22000';
    end if;
  end if;
  return new;
end;
$$;

revoke execute on function public.trg_tournaments_entry_revision_protect() from public;

drop trigger if exists trg_tournaments_entry_revision_protect on public.tournaments;
create trigger trg_tournaments_entry_revision_protect
  before update on public.tournaments
  for each row execute function public.trg_tournaments_entry_revision_protect();

-- Enable direct grants for tournament management capabilities
update public.permissions
set direct_grantable = true
where permission_key in (
  'tournament.draw.manage',
  'tournament.draw.publish',
  'tournament.fixture.schedule'
);

