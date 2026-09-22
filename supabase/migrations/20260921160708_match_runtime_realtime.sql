-- Migration: match_runtime_realtime
-- Canonical match participants, versioned runtime state, and Match Room read.

create type public.match_player_source as enum (
  'team_snapshot',
  'tournament_squad',
  'match_added'
);

alter table public.match_players
  add column source public.match_player_source not null default 'team_snapshot',
  add column added_by uuid references public.profiles(user_id) on delete set null,
  add column added_at timestamptz not null default now(),
  add column creation_idempotency_key text;

-- Provenance did not exist before this migration. Treat existing rows as
-- match-local conservatively: incorrectly deleting a guest/substitute is
-- irreversible, while retaining a roster player is harmless. New rows are
-- assigned an exact source by the materializer below.
update public.match_players
set source = 'match_added';

create unique index match_players_creation_idempotency
  on public.match_players (match_id, creation_idempotency_key)
  where creation_idempotency_key is not null;

alter table public.cricket_matches
  add column state_revision bigint not null default 0 check (state_revision >= 0),
  add column roster_frozen_at timestamptz;

comment on column public.match_players.source is
  'Where this match-local participant came from. match_added never implies permanent team membership.';

comment on column public.cricket_matches.state_revision is
  'Monotonic revision for ordering Match Room snapshots and realtime invalidations.';

comment on column public.cricket_matches.roster_frozen_at is
  'Stops automatic team-roster synchronization when the toss is committed.';

-- The chat sync trigger predated the current registration enum and compared
-- enum values to removed labels (`registered`, `confirmed`, `active`). Any
-- tournament-team insert therefore failed before participant materialization
-- could inspect the approved squad.
create or replace function public.sync_tournament_team_chat()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_channel_id uuid;
  v_member record;
begin
  if new.status <> 'approved' then
    return new;
  end if;

  select cc.channel_id
    into v_channel_id
  from public.chat_channels cc
  where cc.tournament_id = new.tournament_id
    and cc.context_type = 'tournament'
    and cc.purpose = 'main'
  limit 1;

  if v_channel_id is null then
    return new;
  end if;

  for v_member in
    select tm.user_id
    from public.team_members tm
    where tm.team_id = new.team_id
      and tm.status = 'active'
      and tm.user_id is not null
  loop
    insert into public.channel_members (
      channel_id,
      user_id,
      role,
      status,
      joined_at
    )
    values (
      v_channel_id,
      v_member.user_id,
      'member',
      'active',
      clock_timestamp()
    )
    on conflict (channel_id, user_id) do update
      set status = 'active',
          left_at = null,
          updated_at = clock_timestamp();
  end loop;

  return new;
end;
$$;

create or replace function public.sync_match_participants(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match public.matches%rowtype;
  v_cricket public.cricket_matches%rowtype;
  v_side text;
  v_team_id uuid;
begin
  select m.*
    into v_match
  from public.matches m
  where m.match_id = p_match_id
  for update;

  if not found then
    raise exception 'Match not found' using errcode = 'P0002';
  end if;

  select cm.*
    into v_cricket
  from public.cricket_matches cm
  where cm.match_id = p_match_id
  for update;

  -- Match slots are created before the sport extension. The cricket insert
  -- trigger calls this function again once the extension exists.
  if not found then
    return;
  end if;

  if v_cricket.roster_frozen_at is not null then
    return;
  end if;

  foreach v_side in array array['team_a', 'team_b'] loop
    select mt.team_id
      into v_team_id
    from public.match_teams mt
    where mt.match_id = p_match_id
      and mt.team_side = v_side;

    if v_team_id is null then
      delete from public.match_players mp
      where mp.match_id = p_match_id
        and mp.team_side = v_side
        and mp.source <> 'match_added';
      continue;
    end if;

    -- Refresh snapshots without changing their stable match_player_id.
    update public.match_players mp
    set display_name = coalesce(pr.display_name, up.display_name, mp.display_name),
        jersey_number = tm.jersey_number,
        source = 'team_snapshot'::public.match_player_source
    from public.team_members tm
    left join public.profiles pr on pr.user_id = tm.user_id
    left join public.unclaimed_players up on up.unclaimed_id = tm.unclaimed_id
    where mp.match_id = p_match_id
      and mp.team_side = v_side
      and mp.source <> 'match_added'
      and v_match.tournament_id is null
      and tm.team_id = v_team_id
      and tm.status = 'active'
      and tm.in_squad
      and mp.user_id is not distinct from tm.user_id
      and mp.unclaimed_id is not distinct from tm.unclaimed_id
      ;

    insert into public.match_players (
      match_id,
      team_side,
      user_id,
      unclaimed_id,
      display_name,
      jersey_number,
      source,
      added_by
    )
    select
      p_match_id,
      v_side,
      tm.user_id,
      tm.unclaimed_id,
      coalesce(pr.display_name, up.display_name, 'Player'),
      tm.jersey_number,
      'team_snapshot'::public.match_player_source,
      auth.uid()
    from public.team_members tm
    left join public.profiles pr on pr.user_id = tm.user_id
    left join public.unclaimed_players up on up.unclaimed_id = tm.unclaimed_id
    where tm.team_id = v_team_id
      and v_match.tournament_id is null
      and tm.status = 'active'
      and tm.in_squad
    on conflict do nothing;

    -- Tournament registration is the frozen identity source. Team membership
    -- is consulted only for optional jersey metadata; changing or removing a
    -- member from the mutable roster cannot remove them from this match.
    update public.match_players mp
    set display_name = coalesce(pr.display_name, up.display_name, mp.display_name),
        source = 'tournament_squad'::public.match_player_source
    from public.tournament_teams tt
    cross join lateral unnest(tt.squad) registered(person_id)
    left join public.profiles pr on pr.user_id = registered.person_id
    left join public.unclaimed_players up on up.unclaimed_id = registered.person_id
    where v_match.tournament_id is not null
      and tt.tournament_id = v_match.tournament_id
      and tt.team_id = v_team_id
      and tt.status = 'approved'
      and mp.match_id = p_match_id
      and mp.team_side = v_side
      and mp.source <> 'match_added'
      and (
        mp.user_id = registered.person_id
        or mp.unclaimed_id = registered.person_id
      );

    insert into public.match_players (
      match_id, team_side, user_id, unclaimed_id, display_name,
      jersey_number, source, added_by
    )
    select
      p_match_id,
      v_side,
      case when pr.user_id is not null then registered.person_id end,
      case when pr.user_id is null then up.unclaimed_id end,
      coalesce(pr.display_name, up.display_name, 'Player'),
      tm.jersey_number,
      'tournament_squad'::public.match_player_source,
      auth.uid()
    from public.tournament_teams tt
    cross join lateral unnest(tt.squad) registered(person_id)
    left join public.profiles pr on pr.user_id = registered.person_id
    left join public.unclaimed_players up on up.unclaimed_id = registered.person_id
    left join public.team_members tm
      on tm.team_id = v_team_id
     and (tm.user_id = registered.person_id or tm.unclaimed_id = registered.person_id)
    where v_match.tournament_id is not null
      and tt.tournament_id = v_match.tournament_id
      and tt.team_id = v_team_id
      and tt.status = 'approved'
      and (pr.user_id is not null or up.unclaimed_id is not null)
    on conflict do nothing;

    insert into public.cricket_match_players (match_player_id, match_id, is_captain)
    select
      mp.match_player_id,
      mp.match_id,
      coalesce(mp.user_id = public._team_current_captain(v_team_id), false)
    from public.match_players mp
    where mp.match_id = p_match_id
      and mp.team_side = v_side
    on conflict (match_player_id) do nothing;

    -- Before freeze, remove only obsolete automatic snapshots that are not
    -- referenced by any historical or live cricket record.
    delete from public.match_players mp
    where mp.match_id = p_match_id
      and mp.team_side = v_side
      and v_match.tournament_id is null
      and mp.source <> 'match_added'
      and not exists (
        select 1
        from public.team_members tm
        where tm.team_id = v_team_id
          and tm.status = 'active'
          and tm.in_squad
          and tm.user_id is not distinct from mp.user_id
          and tm.unclaimed_id is not distinct from mp.unclaimed_id
          and (
            v_match.tournament_id is null
            or exists (
              select 1
              from public.tournament_teams tt
              where tt.tournament_id = v_match.tournament_id
                and tt.team_id = v_team_id
                and tt.status = 'approved'
                and (
                  tm.user_id = any(tt.squad)
                  or tm.unclaimed_id = any(tt.squad)
                )
            )
          )
      )
      and not exists (
        select 1 from public.cricket_match_innings_state s
        where mp.match_player_id in (s.striker_id, s.non_striker_id, s.bowler_id)
      )
      and not exists (
        select 1 from public.cricket_match_deliveries d
        where mp.match_player_id in (d.striker_id, d.non_striker_id, d.bowler_id, d.fielder_id)
      )
      and not exists (
        select 1 from public.cricket_match_wickets w
        where mp.match_player_id in (
          w.player_out_id,
          w.credited_bowler_id,
          w.primary_fielder_id,
          w.assisted_fielder_id
        )
      )
      and not exists (
        select 1 from public.cricket_matches cm
        where cm.player_of_the_match_id = mp.match_player_id
      );
  end loop;
end;
$$;

revoke all on function public.sync_match_participants(uuid) from public, anon, authenticated;
grant execute on function public.sync_match_participants(uuid) to service_role;

create or replace function public.sync_match_participants_on_cricket_create()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.sync_match_participants(new.match_id);
  return new;
end;
$$;

revoke all on function public.sync_match_participants_on_cricket_create()
  from public, anon, authenticated;

create constraint trigger cricket_matches_materialize_participants
after insert on public.cricket_matches
deferrable initially deferred
for each row execute function public.sync_match_participants_on_cricket_create();

create or replace function public.sync_scheduled_matches_for_team_member()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_team_id uuid := coalesce(new.team_id, old.team_id);
  v_match_id uuid;
begin
  for v_match_id in
    select m.match_id
    from public.matches m
    join public.match_teams mt on mt.match_id = m.match_id
    join public.cricket_matches cm on cm.match_id = m.match_id
    where mt.team_id = v_team_id
      and m.tournament_id is null
      and m.status = 'scheduled'
      and cm.roster_frozen_at is null
  loop
    perform public.sync_match_participants(v_match_id);
  end loop;

  return coalesce(new, old);
end;
$$;

revoke all on function public.sync_scheduled_matches_for_team_member()
  from public, anon, authenticated;

create trigger team_members_sync_scheduled_matches
after insert or update of status, in_squad, jersey_number or delete
on public.team_members
for each row execute function public.sync_scheduled_matches_for_team_member();

create or replace function public.sync_match_participants_on_team_resolution()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.team_id is distinct from old.team_id then
    perform public.sync_match_participants(new.match_id);
  end if;
  return new;
end;
$$;

revoke all on function public.sync_match_participants_on_team_resolution()
  from public, anon, authenticated;

create trigger match_teams_sync_participants
after update of team_id on public.match_teams
for each row execute function public.sync_match_participants_on_team_resolution();

create or replace function public.get_match_room_snapshot(p_match_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'match', to_jsonb(d),
    'revision', cm.state_revision,
    'participants', coalesce((
      select jsonb_agg(
        to_jsonb(mp)
        || jsonb_build_object(
          'cricket', to_jsonb(cmp),
          'profile', to_jsonb(pr),
          'unclaimed', to_jsonb(up)
        )
        order by mp.team_side, cmp.batting_order nulls last, mp.display_name
      )
      from public.match_players mp
      left join public.cricket_match_players cmp
        on cmp.match_player_id = mp.match_player_id
      left join public.profiles pr on pr.user_id = mp.user_id
      left join public.unclaimed_players up on up.unclaimed_id = mp.unclaimed_id
      where mp.match_id = p_match_id
    ), '[]'::jsonb),
    'innings', (
      select to_jsonb(s)
      from public.cricket_match_innings_state s
      where s.match_id = p_match_id
      order by s.innings_number desc
      limit 1
    ),
    'scorer_lease', (
      select to_jsonb(sl)
      from public.match_scorer_leases sl
      where sl.match_id = p_match_id
        and sl.lease_expires_at > now()
    ),
    'capabilities', jsonb_build_object(
      'can_record_toss', coalesce(public.can('match', p_match_id, 'cricket.match.setup'), false),
      'can_setup_innings', coalesce(public.can('match', p_match_id, 'match.score'), false),
      'can_add_participant', coalesce(public.can('match', p_match_id, 'match.score'), false),
      'can_score', coalesce(public.can_score_innings(p_match_id, coalesce((
        select max(s.innings_number)::integer
        from public.cricket_match_innings_state s
        where s.match_id = p_match_id
      ), 1)), false)
    ),
    'server_time', now()
  )
  from public.cricket_match_details d
  join public.cricket_matches cm on cm.match_id = d.match_id
  where d.match_id = p_match_id;
$$;

revoke all on function public.get_match_room_snapshot(uuid) from public, anon;
grant execute on function public.get_match_room_snapshot(uuid) to authenticated, service_role;

-- Repair existing scheduled fixtures without disturbing live/history rows.
do $$
declare
  v_match_id uuid;
begin
  for v_match_id in
    select m.match_id
    from public.matches m
    join public.cricket_matches cm on cm.match_id = m.match_id
    where m.status = 'scheduled'
      and cm.roster_frozen_at is null
  loop
    perform public.sync_match_participants(v_match_id);
  end loop;
end;
$$;
