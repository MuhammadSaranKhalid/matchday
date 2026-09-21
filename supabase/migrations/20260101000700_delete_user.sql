-- Migration file: 20260101000700_delete_user.sql

-- 0700 · delete_user — self-service account deletion
-- WHY THIS RPC EXISTS
-- Play Store data-safety policy (post-2024) requires every app collecting
-- PII to offer self-service account deletion. This RPC is the single
-- entry point.
--
-- THE FLOW
--   1. User taps Settings → Delete account.
--   2. Client calls public.delete_user() (this RPC).
--   3. The RPC walks every table that references the user and either
--      anonymises the row (history-preserving) or lets ON DELETE
--      cascade clean it up. Then it deletes the auth.users row, which
--      cascades into public.profiles + every per-user table that has
--      ON DELETE CASCADE on profiles.user_id.
--
-- WHAT GETS ANONYMISED, AND WHY
-- Three references to profiles cannot be cascaded because their target
-- rows are historical artefacts that must outlive the user:
--
--   * matches.created_by      — the /m/<id> spectator URL must keep
--                                working after the creator deletes
--                                their account. (FK is ON DELETE SET
--                                NULL in 0400; we also null it
--                                explicitly here as a belt-and-braces.)
--
--   * match_deliveries.recorded_by — same reasoning. The scorer's name
--                                disappears from the over-by-over feed,
--                                but the deliveries themselves remain.
--                                (FK is ON DELETE SET NULL in 0400.)
--
--   * match_players.user_id    — historical lineups (and therefore the
--                                full scorecard / stats lineage) must
--                                survive a profile delete. We promote
--                                the user's match_players rows to point
--                                at a synthetic unclaimed_players row
--                                that preserves their display name.
--                                This is the same identity-merge flow
--                                the cascade_unclaimed_claim trigger
--                                runs in the OPPOSITE direction (when
--                                an unclaimed player claims a profile).
--                                (FK is ON DELETE RESTRICT — the
--                                promotion below is mandatory.)
--
-- WHAT GETS CASCADED (no explicit action here)
-- The auth.users → profiles → ... cascade chain handles:
--   * team_members.user_id (ON DELETE CASCADE) — the user vanishes
--     from team rosters automatically.
--   * notifications, posts, comments, likes, bookmarks, follows,
--     device_tokens — all cascade off profiles.
--   * match_officials.user_id (ON DELETE CASCADE) — the user's scorer
--     / umpire assignments vanish.
--   * Captain/keeper/MOTM FKs on matches (ON DELETE SET NULL) — set
--     to null automatically.
--
-- SECURITY DEFINER + auth.uid() GATE
-- The function runs as the table owner so it can reach auth.users.
-- The first guard rejects unauthenticated callers; the body only ever
-- operates on the calling user's own data — there is no path to delete
-- another user's account. The function is granted ONLY to the
-- `authenticated` role.
-- Claim finalization
--
-- Triggered exactly once:
--
-- claimed_by_user_id: null -> user_id
--
-- It:
--   * activates player_sports
--   * merges Cricket profile details
--   * rewrites team memberships
--   * rewrites match lineup identity
--   * preserves match_player_id references where possible
--
-- Registered/self-owned Cricket values WIN over manager-entered values.

-- Section: Functions

create or replace function public.finalize_unclaimed_claim()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tm record;
  v_existing_membership uuid;

  v_mp record;
  v_existing_match_player uuid;
  v_existing_team_side text;
begin
  if old.claimed_by_user_id is not null
     or new.claimed_by_user_id is null then
    return new;
  end if;

  if not exists (
    select 1
    from public.profiles p
    where p.user_id = new.claimed_by_user_id
  ) then
    raise exception 'Claim target profile does not exist'
      using errcode = 'P0002';
  end if;


  -- ---------------------------------------------------------------------------
  -- Durable player/sport identity.
  -- ---------------------------------------------------------------------------

  insert into public.player_sports (
    user_id,
    sport_id
  )
  values (
    new.claimed_by_user_id,
    new.sport_id
  )
  on conflict (user_id, sport_id)
  do nothing;


  -- ---------------------------------------------------------------------------
  -- Optional Cricket profile attributes.
  -- Existing registered/self-owned values win.
  -- ---------------------------------------------------------------------------

  if new.sport_id = 'cricket' then

    insert into public.cricket_player_profiles as cp (
      user_id,
      sport_id,
      batting_style,
      bowling_style,
      player_role,
      preferred_ball_types,
      years_playing
    )
    select
      new.claimed_by_user_id,
      'cricket',
      cup.batting_style,
      cup.bowling_style,
      cup.player_role,
      cup.preferred_ball_types,
      cup.years_playing
    from public.cricket_unclaimed_player_profiles cup
    where cup.unclaimed_id = new.unclaimed_id

    on conflict (user_id)
    do update set
      batting_style =
        coalesce(cp.batting_style, excluded.batting_style),

      bowling_style =
        coalesce(cp.bowling_style, excluded.bowling_style),

      player_role =
        coalesce(cp.player_role, excluded.player_role),

      preferred_ball_types =
        case
          when cardinality(cp.preferred_ball_types) = 0
          then excluded.preferred_ball_types
          else cp.preferred_ball_types
        end,

      years_playing =
        coalesce(cp.years_playing, excluded.years_playing);
  end if;


  -- ---------------------------------------------------------------------------
  -- Team membership identity rewrite.
  -- ---------------------------------------------------------------------------

  for v_tm in
    select
      tm.membership_id,
      tm.team_id,
      tm.jersey_number,
      tm.in_squad
    from public.team_members tm
    where tm.unclaimed_id = new.unclaimed_id
    for update
  loop

    v_existing_membership := null;

    select tm.membership_id
      into v_existing_membership
      from public.team_members tm
     where tm.team_id = v_tm.team_id
       and tm.user_id = new.claimed_by_user_id
       and tm.status = 'active'
     order by tm.joined_at
     limit 1
     for update;

    if v_existing_membership is null then

      update public.team_members
         set user_id = new.claimed_by_user_id,
             unclaimed_id = null,
             -- A manager-entered placeholder cannot decide a signed-in user's
             -- primary team.
             is_primary = false
       where membership_id = v_tm.membership_id;

    else

      -- Remove placeholder first so active-team jersey uniqueness cannot
      -- collide while merging.
      delete from public.team_members
       where membership_id = v_tm.membership_id;

      update public.team_members
         set in_squad =
               in_squad or v_tm.in_squad,
             jersey_number =
               coalesce(jersey_number, v_tm.jersey_number)
       where membership_id = v_existing_membership;

    end if;
  end loop;


  -- ---------------------------------------------------------------------------
  -- Match participant identity rewrite.
  -- ---------------------------------------------------------------------------

  for v_mp in
    select
      mp.match_player_id,
      mp.match_id,
      mp.team_side,
      mp.jersey_number
    from public.match_players mp
    where mp.unclaimed_id = new.unclaimed_id
    for update
  loop

    v_existing_match_player := null;
    v_existing_team_side := null;

    select
      mp.match_player_id,
      mp.team_side
    into
      v_existing_match_player,
      v_existing_team_side
    from public.match_players mp
    where mp.match_id = v_mp.match_id
      and mp.user_id = new.claimed_by_user_id
    limit 1
    for update;

    if v_existing_match_player is null then

      -- Preserve match_player_id so every delivery/wicket FK remains valid.
      update public.match_players
         set user_id = new.claimed_by_user_id,
             unclaimed_id = null
       where match_player_id = v_mp.match_player_id;

    else

      if v_existing_team_side
           is distinct from v_mp.team_side then
        raise exception
          'Claim would place the same user on both sides of match %',
          v_mp.match_id
          using errcode = '23514';
      end if;


      -- -----------------------------------------------------------------------
      -- Merge Cricket participant extension BEFORE deleting the old shared row.
      -- The old cricket_match_players row would otherwise cascade away.
      -- -----------------------------------------------------------------------

      if new.sport_id = 'cricket' then

        insert into public.cricket_match_players (
          match_player_id,
          match_id,
          is_playing_xi,
          batting_order,
          is_captain,
          is_vice_captain,
          is_wicket_keeper,
          is_substitute
        )
        select
          v_existing_match_player,
          cmp.match_id,
          cmp.is_playing_xi,
          cmp.batting_order,
          cmp.is_captain,
          cmp.is_vice_captain,
          cmp.is_wicket_keeper,
          cmp.is_substitute
        from public.cricket_match_players cmp
        where cmp.match_player_id = v_mp.match_player_id

        on conflict (match_player_id)
        do update set
          is_playing_xi =
            public.cricket_match_players.is_playing_xi
            or excluded.is_playing_xi,

          batting_order =
            coalesce(
              public.cricket_match_players.batting_order,
              excluded.batting_order
            ),

          is_captain =
            public.cricket_match_players.is_captain
            or excluded.is_captain,

          is_vice_captain =
            public.cricket_match_players.is_vice_captain
            or excluded.is_vice_captain,

          is_wicket_keeper =
            public.cricket_match_players.is_wicket_keeper
            or excluded.is_wicket_keeper,

          is_substitute =
            public.cricket_match_players.is_substitute
            or excluded.is_substitute,

          updated_at = now();


        update public.cricket_matches
           set player_of_the_match_id = v_existing_match_player,
               updated_at = now()
         where player_of_the_match_id = v_mp.match_player_id;

      end if;


      -- -----------------------------------------------------------------------
      -- Repoint every shared Cricket engine FK to the surviving participant.
      -- -----------------------------------------------------------------------

      update public.cricket_match_innings_state
         set striker_id = v_existing_match_player
       where striker_id = v_mp.match_player_id;

      update public.cricket_match_innings_state
         set non_striker_id = v_existing_match_player
       where non_striker_id = v_mp.match_player_id;

      update public.cricket_match_innings_state
         set bowler_id = v_existing_match_player
       where bowler_id = v_mp.match_player_id;


      update public.cricket_match_deliveries
         set striker_id = v_existing_match_player
       where striker_id = v_mp.match_player_id;

      update public.cricket_match_deliveries
         set non_striker_id = v_existing_match_player
       where non_striker_id = v_mp.match_player_id;

      update public.cricket_match_deliveries
         set bowler_id = v_existing_match_player
       where bowler_id = v_mp.match_player_id;

      update public.cricket_match_deliveries
         set fielder_id = v_existing_match_player
       where fielder_id = v_mp.match_player_id;


      update public.cricket_match_wickets
         set player_out_id = v_existing_match_player
       where player_out_id = v_mp.match_player_id;

      update public.cricket_match_wickets
         set credited_bowler_id = v_existing_match_player
       where credited_bowler_id = v_mp.match_player_id;

      update public.cricket_match_wickets
         set primary_fielder_id = v_existing_match_player
       where primary_fielder_id = v_mp.match_player_id;

      update public.cricket_match_wickets
         set assisted_fielder_id = v_existing_match_player
       where assisted_fielder_id = v_mp.match_player_id;


      -- Shared snapshot metadata can be merged without knowing the sport.
      update public.match_players
         set jersey_number =
               coalesce(jersey_number, v_mp.jersey_number)
       where match_player_id = v_existing_match_player;


      delete from public.match_players
       where match_player_id = v_mp.match_player_id;

    end if;

  end loop;


  perform public.migrate_player_stats(
    new.unclaimed_id,
    new.claimed_by_user_id
  );

  return new;
end;
$$;

revoke all
  on function public.finalize_unclaimed_claim()
  from public, anon, authenticated;

-- Section: Triggers

drop trigger if exists unclaimed_players_finalize_claim on public.unclaimed_players;

create trigger unclaimed_players_finalize_claim
  after update of claimed_by_user_id on public.unclaimed_players for each row
  when(old.claimed_by_user_id is null and new.claimed_by_user_id is not null)
  execute function public.finalize_unclaimed_claim();

-- Section: Functions (continued)

-- 0700 · delete_user — self-service account deletion
create or replace function public.delete_user()
  returns void
  language plpgsql
  security definer
  set search_path = public, auth, pg_temp
  as $$
declare
  v_uid uuid := auth.uid();
  v_unclaimed_id uuid;
  v_sport text;
begin
  if v_uid is null then
    raise exception 'Not authenticated'
      using errcode = '28000';
  end if;
  -- ---------------------------------------------------------------------------
  -- Preserve historical match lineups.
  --
  -- A deleted user may have played several sports, so create one anonymous
  -- placeholder for each sport represented in their match history.
  -- ---------------------------------------------------------------------------
  for v_sport in select distinct
    m.sport_id
  from
    public.match_players mp
    join public.matches m on m.match_id = mp.match_id
  where
    mp.user_id = v_uid loop
      insert into public.unclaimed_players(sport_id, display_name, added_by)
        values (v_sport, 'Deleted player', null)
      returning
        unclaimed_id
      into
        v_unclaimed_id;
      update
        public.match_players mp
      set
        display_name = 'Deleted player',
        jersey_number = null,
        user_id = null,
        unclaimed_id = v_unclaimed_id
      from
        public.matches m
      where
        mp.match_id = m.match_id
        and mp.user_id = v_uid
        and m.sport_id = v_sport;
    end loop;
  -- ---------------------------------------------------------------------------
  -- Historical authored rows.
  -- ---------------------------------------------------------------------------
  update
    public.matches
  set
    created_by = null
  where
    created_by = v_uid;
  update
    public.cricket_match_deliveries
  set
    recorded_by = null
  where
    recorded_by = v_uid;
  update
    public.team_members
  set
    added_by = null
  where
    added_by = v_uid;
  update
    public.unclaimed_players
  set
    added_by = null
  where
    added_by = v_uid;
  -- ---------------------------------------------------------------------------
  -- Remove sport-specific manager-entered profile data belonging to
  -- placeholders previously claimed by this account.
  -- ---------------------------------------------------------------------------
  delete from public.cricket_unclaimed_player_profiles cup using public.unclaimed_players up
  where cup.unclaimed_id = up.unclaimed_id
    and up.claimed_by_user_id = v_uid;
  -- Claimed placeholders survive for historical/audit purposes but no longer
  -- identify the deleted user.
  update
    public.unclaimed_players
  set
    display_name = 'Deleted player',
    phone_number = null,
    email = null,
    claimed_by_user_id = null,
    claimed_at = null
  where
    claimed_by_user_id = v_uid;
  update
    public.messages
  set
    body = 'This message was deleted',
    payload = '{}'::jsonb,
    deleted_at = now()
  where
    sender_id = v_uid;
  -- Storage objects must still be removed through the authenticated deletion
  -- worker before deleting auth.users.
  if exists (
    select
      1
    from
      storage.objects o
    where
      o.owner_id = v_uid::text
      or (o.bucket_id = 'avatars'
        and split_part(o.name, '/', 1) = v_uid::text)
      or (o.bucket_id = 'post-media'
        and exists (
          select
            1
          from
            public.posts p
          where
            p.author_id = v_uid
            and p.post_id::text = split_part(o.name, '/', 1)))) then
    raise exception 'Remove uploaded files before completing account deletion';
end if;
  delete from auth.users
  where id = v_uid;
end;
$$;

revoke all on function public.delete_user() from public;

grant execute on function public.delete_user() to authenticated;

-- Dangling uuid[] cleanup on profile delete
-- Six columns hold uuid[] of profile ids with no referential integrity —
-- an array cannot carry a foreign key. Deleting a profile therefore left its
-- id behind in every one of them, and one of those arrays
-- (tournaments.organizers) is read by RLS policies to decide who may write.
-- A stale id in an authorization array is the part that actually matters.
--
-- teams.managers was the seventh and is gone (2026-09-10) — team authority
-- moved to team_members, which has a real FK and cascades on its own. What
-- replaced it here is the ownership-succession block below: a real FK cleans
-- up the row, but it cannot decide who should run the team next.
--
-- A trigger rather than more statements inside delete_user(), so it also
-- catches deletions that do not go through the RPC — an admin DELETE, or the
-- auth.users cascade.
--
-- Forward references are deliberate and safe here: the body is plpgsql, which
-- Postgres does NOT check at CREATE time, and every table named below exists
-- by the end of the migration run — which is the earliest this can ever fire.
-- (The same late-binding that hid the match_officials ordering bug is the
-- thing that makes this legal.)
create or replace function public._strip_deleted_profile_from_arrays()
  returns trigger
  language plpgsql
  security definer
  set search_path = public, pg_temp
  as $$
begin
  -- Ownership succession (rewritten 2026-09-11 for the role model).
  --
  -- A departing member's team_members row cascades on the profiles FK, taking
  -- its team_member_roles with it — so staff cleanup is automatic. What is NOT
  -- automatic is succession: `is_singleton` stops a SECOND owner but nothing
  -- stops ZERO, and a team whose only owner deleted their account would be
  -- left with nobody able to act (the owner short-circuit in can() has no one
  -- to fire for).
  --
  -- The longest-tenured remaining manager is promoted into the `owner` role.
  -- If there is no manager, the team is archived rather than left headless.
  -- teams.created_by is deliberately NOT touched — it is history, and history
  -- does not change when someone leaves.
  with orphaned as(
    select
      tm.team_id
    from
      public.team_members tm
      join public.team_member_roles tmr on tmr.membership_id = tm.membership_id
    where
      tm.user_id = old.user_id
      and tmr.role_key = 'owner'
      and tm.status = 'active'
),
successor as(
  select distinct on(o.team_id)
    o.team_id,
    tm.membership_id
  from
    orphaned o
    join public.team_members tm on tm.team_id = o.team_id
      and tm.status = 'active'
      and tm.user_id is not null
      and tm.user_id <> old.user_id
    join public.team_member_roles tmr on tmr.membership_id = tm.membership_id
      and tmr.role_key = 'manager'
    order by
      o.team_id,
      tm.joined_at asc
),
-- Drop the successor's manager row before adding owner: they are two rows in
-- the same exclusion set {owner, manager, player}, max 1.
demoted as(
  delete from public.team_member_roles tmr using successor s
where tmr.membership_id = s.membership_id
  and tmr.role_key in('manager', 'player')
returning
  tmr.membership_id
),
promoted as(
insert into public.team_member_roles(membership_id, scope, role_key, team_id, is_singleton)
  select
    s.membership_id,
    'team',
    'owner',
    s.team_id,
    true
  from
    successor s
  returning
    team_id)
update
  public.teams t
set
  status = 'archived'
where
  t.team_id in(
    select
      team_id
    from
      orphaned)
    and t.team_id not in(
      select
        team_id
      from
        promoted)
      and t.status = 'active';
  update
    public.tournaments
  set
    organizers = array_remove(organizers, old.user_id)
  where
    old.user_id = any(organizers);
  update
    public.tournament_teams
  set
    squad = array_remove(squad, old.user_id)
  where
    old.user_id = any(squad);
  update
    public.match_challenges
  set
    from_team_xi = array_remove(from_team_xi, old.user_id)
  where
    old.user_id = any(from_team_xi);
  update
    public.match_pool_applications
  set
    applicant_xi = array_remove(applicant_xi, old.user_id)
  where
    old.user_id = any(applicant_xi);
  update
    public.posts
  set
    linked_player_ids = array_remove(linked_player_ids, old.user_id)
  where
    old.user_id = any(linked_player_ids);
  update
    public.comments
  set
    mentioned_user_ids = array_remove(mentioned_user_ids, old.user_id)
  where
    old.user_id = any(mentioned_user_ids);
  return old;
end;
$$;

-- Section: Triggers (continued)

drop trigger if exists profiles_strip_from_arrays on public.profiles;

create trigger profiles_strip_from_arrays
  before delete on public.profiles for each row
  execute function public._strip_deleted_profile_from_arrays();

-- Section: Functions (continued)

-- Only the caller's own object names; bounded batches for the deletion worker.
create or replace function public.my_deletion_objects()
  returns table(
    bucket_id text,
    name text)
  language sql
  stable
  security definer
  set search_path = ''
  as $$
  select
    o.bucket_id,
    o.name
  from
    storage.objects o
  where
    auth.uid() is not null
    and(o.owner_id = auth.uid()::text
      or(o.bucket_id = 'avatars'
        and split_part(o.name, '/', 1) = auth.uid()::text)
      or(o.bucket_id = 'post-media'
        and exists(
          select
            1
          from
            public.posts p
          where
            p.author_id = auth.uid()
            and p.post_id::text = split_part(o.name, '/', 1))))
  order by
    o.bucket_id,
    o.name
  limit 100;
$$;

revoke all on function public.my_deletion_objects() from public, anon;

grant execute on function public.my_deletion_objects() to authenticated;
