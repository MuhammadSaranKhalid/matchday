-- Enforce that `added_by` is always set on team_members + unclaimed_players.
--
-- Originally both columns were nullable and the seed (plus some legacy rows)
-- left team_members.added_by null on 41/86 rows. The roster read then crashed
-- the app ("Null is not a subtype of String") because the DTO models added_by
-- as a guaranteed value. We make the invariant real in the schema instead of
-- loosening the model: backfill from the owning team, then NOT NULL.

-- Backfill team_members.added_by from the owning team where it was never set.
-- The owner_id always exists in profiles (added_by → profiles FK), so this holds.
update public.team_members m
set added_by = t.owner_id
from public.teams t
where t.team_id = m.team_id
  and m.added_by is null;

alter table public.team_members
  alter column added_by set not null;

-- unclaimed_players.added_by has no null rows (the app always sets it on
-- insert); enforce the same invariant for consistency.
alter table public.unclaimed_players
  alter column added_by set not null;
