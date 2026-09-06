-- =============================================================================
-- Migration: list_my_matches RPC
-- =============================================================================
-- `matches` is world-readable at the RLS layer (matches_read_all USING (true))
-- so spectators can browse any fixture. An unfiltered select therefore returns
-- the ENTIRE table; "my matches" has to be scoped explicitly, and this is that
-- scope.
--
-- A match is mine when:
--   • I created it, or I am a named captain on it
--   • a team I'm an ACTIVE roster member of is playing
--   • a team I own or manage is playing  (owner_id / managers — creating a team
--     does not enrol you in its roster, so this clause is load-bearing: the
--     REQUESTING manager of a friendly is neither created_by nor a team_member)
--   • I am named in the XI (match_players)
--   • I am an assigned official — scorer / umpire (match_officials)
--
-- 2026-09-06: this logic also existed as the `list-my-matches` EDGE FUNCTION,
-- whose own header called itself a dev-phase stopgap to be "promoted to a SQL
-- function once the schema settles". Both were live and the client called the
-- RPC with the function as a fallback — and they had already drifted:
--   • the function omitted `tm.status = 'active'`, so removed team members kept
--     seeing the team's matches;
--   • the function matched on match_players (named in the XI) while the RPC
--     matched on match_officials (assigned umpire/scorer) — neither had both;
--   • they ordered differently, so the same user got a different list depending
--     on which path answered.
-- The union of the two participant clauses is the correct definition and is
-- what this function now implements. The edge function is deleted.
-- =============================================================================

create or replace function public.list_my_matches()
returns setof public.matches
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select m.*
    from public.matches m
   where m.created_by = (select auth.uid())
      or m.team_a_captain = (select auth.uid())
      or m.team_b_captain = (select auth.uid())
      or exists (
        select 1 from public.team_members tm
         where tm.team_id in (m.team_a_id, m.team_b_id)
           and tm.user_id = (select auth.uid())
           and tm.status = 'active'
      )
      or exists (
        select 1 from public.teams t
         where t.team_id in (m.team_a_id, m.team_b_id)
           and (t.owner_id = (select auth.uid()) or (select auth.uid()) = any(t.managers))
      )
      or exists (
        select 1 from public.match_players mp
         where mp.match_id = m.match_id
           and mp.user_id = (select auth.uid())
      )
      or exists (
        select 1 from public.match_officials mo
         where mo.match_id = m.match_id
           and mo.user_id = (select auth.uid())
      )
   order by coalesce(m.scheduled_start_time, m.created_at) desc;
$$;

revoke all on function public.list_my_matches() from public;
grant execute on function public.list_my_matches() to authenticated;
