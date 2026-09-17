-- =============================================================================
-- Fix accept_team_invite and accept_team_join_request to align with the
-- 2026-09-11 role rewrite (team_member_roles table instead of team_members.role column).
-- =============================================================================

-- 1. accept_team_invite
create or replace function public.accept_team_invite(p_invite_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid           uuid := auth.uid();
  v_team_id       uuid;
  v_invitee_id    uuid;
  v_role          text;
  v_jersey        integer;
  v_invited_by    uuid;
  v_membership_id uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  select team_id, invitee_id, role, jersey_number, invited_by
    into v_team_id, v_invitee_id, v_role, v_jersey, v_invited_by
    from public.team_invites
   where invite_id = p_invite_id and status = 'pending'
   for update;
  if v_team_id is null then
    raise exception 'Invite not found or not pending'
      using errcode = 'P0002';
  end if;
  if v_invitee_id <> v_uid then
    raise exception 'Only the invitee can accept this invite'
      using errcode = '42501';
  end if;

  -- Set initial role for the trigger team_members_assign_initial_role
  perform set_config('matchday.initial_role', coalesce(v_role, 'player'), true);

  insert into public.team_members
       (team_id, user_id, jersey_number, added_by)
  values (v_team_id, v_invitee_id, v_jersey, v_invited_by)
  returning membership_id into v_membership_id;

  -- If the invite was for 'captain', ensure they also hold 'player' role
  if v_role = 'captain' then
    perform public._attach_role(v_membership_id, 'player', v_invited_by);
  end if;

  update public.team_invites
     set status     = 'approved',
         decided_by = v_uid,
         decided_at = now()
   where invite_id = p_invite_id;

  return v_membership_id;
end;
$$;

revoke all on function public.accept_team_invite(uuid) from public;
grant execute on function public.accept_team_invite(uuid) to authenticated;

-- 2. accept_team_join_request
create or replace function public.accept_team_join_request(
  p_request_id uuid,
  p_jersey_number integer default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid           uuid := auth.uid();
  v_team_id       uuid;
  v_player_id     uuid;
  v_role          text;
  v_membership_id uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select team_id, player_id, role
    into v_team_id, v_player_id, v_role
    from public.team_join_requests
   where request_id = p_request_id and status = 'pending'
   for update;

  if v_team_id is null then
    raise exception 'Join request not found or not pending' using errcode = 'P0002';
  end if;

  if not public.is_team_manager(v_team_id) then
    raise exception 'Only team managers can approve join requests' using errcode = '42501';
  end if;

  perform set_config('matchday.initial_role', coalesce(v_role, 'player'), true);

  insert into public.team_members (team_id, user_id, jersey_number, added_by)
  values (v_team_id, v_player_id, p_jersey_number, v_uid)
  returning membership_id into v_membership_id;

  if v_role = 'captain' then
    perform public._attach_role(v_membership_id, 'player', v_uid);
  end if;

  update public.team_join_requests
     set status = 'approved',
         decided_by = v_uid,
         decided_at = now()
   where request_id = p_request_id;

  return v_membership_id;
end;
$$;

revoke all on function public.accept_team_join_request(uuid, integer) from public;
grant execute on function public.accept_team_join_request(uuid, integer) to authenticated;
