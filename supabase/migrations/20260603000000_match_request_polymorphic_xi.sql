-- Match Request polymorphic XI.
--
-- WHY
--   `team_members` rows reference EITHER `profiles.user_id` (claimed) OR
--   `unclaimed_players.unclaimed_id` (placeholder), XOR'd by the
--   `player_ref_xor` check. The XI a captain pencils on the Match Challenge
--   send flow can legitimately mix both — a friendly's roster routinely
--   contains placeholder names that haven't claimed their profile yet.
--
--   Two stalling artefacts in the deployed schema treat XIs as claimed-only:
--
--     1. `_validate_team_xi` (migration 0600) joins ONLY on `tm.user_id`,
--        so any unclaimed id in the picked XI raises 23514 and the send
--        edge function returns 422 invalid_xi.
--
--     2. `match_requests.from_team_keeper_id` has a hard FK to
--        `profiles(user_id)`. An unclaimed keeper id would trip the FK with
--        23503 even before `_validate_team_xi` runs.
--
--   `match_players` (migration 0405) and `accept_match_request` (0600 lines
--   547–548) already handle polymorphic refs correctly. The two artefacts
--   above are the only blockers; this migration removes both and replaces
--   the FK's defence with a trigger-level guard.
--
-- WHAT
--   1. Redefine `_validate_team_xi` to OR-match `tm.user_id`
--      or `tm.unclaimed_id`. Callers in `send_match_request` (0600 line 304),
--      `accept_match_request` (0600 lines 463–464, and the 20260529142241
--      override at lines 98–99) all benefit automatically — claimed-only
--      XIs continue to validate because the OR still matches `user_id`.
--
--   2. Drop the FK on `match_requests.from_team_keeper_id` so an unclaimed
--      keeper id is accepted at the column level.
--
--   3. Add `_validate_match_request_keeper` + a BEFORE INSERT OR UPDATE
--      trigger on `match_requests` that enforces, when the keeper is set:
--        a. keeper is one of the picked XI ids, AND
--        b. keeper is an active polymorphic team_member of `from_team_id`.
--      This preserves the FK's "is this a real team member?" guarantee
--      without forcing the value to live in `profiles`.
--
-- RISK & ROLLBACK
--   `_validate_team_xi` is widened, not narrowed — every previously-valid
--   XI is still valid. Existing rows whose keeper sat in profiles continue
--   to satisfy the new trigger because the keeper is already a real team
--   member. To roll back, restore the FK and the user_id-only join.

-- =============================================================================
-- 1. Polymorphic _validate_team_xi
-- =============================================================================
create or replace function public._validate_team_xi(p_team_id uuid, p_xi uuid[])
returns void
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_invalid uuid;
begin
  if p_xi is null or array_length(p_xi, 1) is null then
    return;
  end if;

  -- Polymorphic match: a row in p_xi is valid if it equals either the
  -- claimed `user_id` or the placeholder `unclaimed_id` on an active
  -- membership for `p_team_id`.
  select uid into v_invalid
    from unnest(p_xi) as t(uid)
   where not exists (
     select 1 from public.team_members tm
      where tm.team_id = p_team_id
        and (tm.user_id = t.uid or tm.unclaimed_id = t.uid)
        and tm.status  = 'active'
   )
   limit 1;

  if v_invalid is not null then
    raise exception 'Player % is not an active member of team %', v_invalid, p_team_id
      using errcode = '23514';
  end if;
end;
$$;

-- Grants are preserved by CREATE OR REPLACE; reasserting them anyway so a
-- reader of this file can see the access shape without paging back to 0600.
revoke all on function public._validate_team_xi(uuid, uuid[]) from public;
grant execute on function public._validate_team_xi(uuid, uuid[]) to authenticated;

-- =============================================================================
-- 2. Drop the claimed-only FK on from_team_keeper_id
-- =============================================================================
alter table public.match_requests
  drop constraint if exists match_requests_from_team_keeper_id_fkey;

-- =============================================================================
-- 3. Keeper-validation trigger
-- =============================================================================
create or replace function public._validate_match_request_keeper()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  -- Null keeper is always allowed (managers can ship a request without one
  -- and finalise on match day).
  if new.from_team_keeper_id is null then
    return new;
  end if;

  -- Keeper must appear in the picked XI. Mirrors the edge function's same
  -- check so a direct INSERT can't bypass it.
  if not (
    new.from_team_keeper_id = any(coalesce(new.from_team_xi, '{}'::uuid[]))
  ) then
    raise exception 'Wicket-keeper % is not in the picked XI',
      new.from_team_keeper_id
      using errcode = '23514';
  end if;

  -- Keeper must be a real, active member of the from-team — claimed OR
  -- unclaimed. Replaces the dropped FK's "is this person real?" guard.
  if not exists (
    select 1 from public.team_members tm
     where tm.team_id = new.from_team_id
       and (tm.user_id = new.from_team_keeper_id
            or tm.unclaimed_id = new.from_team_keeper_id)
       and tm.status = 'active'
  ) then
    raise exception 'Wicket-keeper % is not an active member of team %',
      new.from_team_keeper_id, new.from_team_id
      using errcode = '23514';
  end if;

  return new;
end;
$$;

drop trigger if exists match_requests_validate_keeper on public.match_requests;
create trigger match_requests_validate_keeper
  before insert or update of from_team_keeper_id, from_team_xi, from_team_id
       on public.match_requests
  for each row execute function public._validate_match_request_keeper();
