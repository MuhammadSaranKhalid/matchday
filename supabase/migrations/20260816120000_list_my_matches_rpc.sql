-- =============================================================================
-- Migration: list_my_matches RPC
-- Returns only the matches the calling user participates in:
--   • Created by the user
--   • Teams the user is a roster member of
--   • Teams the user owns or manages
--   • Matches where the user is an official
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
   where m.created_by = auth.uid()
      or m.team_a_captain = auth.uid()
      or m.team_b_captain = auth.uid()
      or exists (
        select 1 from public.team_members tm
         where tm.team_id in (m.team_a_id, m.team_b_id)
           and tm.user_id = auth.uid()
           and tm.status = 'active'
      )
      or exists (
        select 1 from public.teams t
         where t.team_id in (m.team_a_id, m.team_b_id)
           and (t.owner_id = auth.uid() or auth.uid() = any(t.managers))
      )
      or exists (
        select 1 from public.match_officials mo
         where mo.match_id = m.match_id
           and mo.user_id = auth.uid()
      )
   order by coalesce(m.scheduled_start_time, m.created_at) desc;
$$;

revoke all on function public.list_my_matches() from public;
grant execute on function public.list_my_matches() to authenticated;
