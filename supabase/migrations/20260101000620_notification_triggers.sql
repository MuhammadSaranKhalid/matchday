-- =============================================================================
-- 0575 · notification triggers — every producer, in one file
-- =============================================================================
-- Design + decision log: docs/notifications-design.md
--
-- DECLARES NO TABLES. Integration file (§12.0 rule 1).
--
-- WHY THESE MOVED HERE. Each of these triggers used to live in its source
-- table's own migration — follows_notify in 0560, team_invites_notify in 0240,
-- and so on. They all now call public.notify(), which is declared in 0570, and
-- three of their source files (0240 team_invites, 0520 comments, 0530
-- post_likes) come BEFORE that. A plpgsql body referencing a function that does
-- not exist yet compiles fine and fails at RUNTIME — exactly the trap §12.0
-- warns about, and exactly why the teams UPDATE policies were moved from 0200
-- into 0210. Same remedy: the trigger follows the thing it depends on.
--
-- The side benefit is the point. "Which events notify anybody?" was previously
-- answerable only by grepping nine migrations, which is how the old enum ended
-- up with 10 of its 20 values having no writer at all. It is now this file.
--
-- WHAT CHANGED IN THE PORT (behaviour, not just plumbing):
--
--   * `match_request_decision` was ONE type carrying `status` in its payload,
--     which the client then switched on to pick copy. It is now five distinct
--     catalogue keys (match.challenge.accepted / .declined / .countered /
--     .cancelled / .expired), so the copy is data and the client switches on
--     nothing.
--
--   * The "notify the requester, then loop the team excluding the requester and
--     the actor" dance is gone. notify() already does SELECT DISTINCT and
--     already drops the actor, so both audiences are now one array in one call.
--     The manual dedup guards it replaces were load-bearing and easy to get
--     wrong.
--
--   * Every producer now passes (scope, entity_id), which is what makes
--     "mute this team" work (0502). None of them could express that before.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- follows → social.follow
-- Team / tournament follows stay silent: the entity is not a person.
-- -----------------------------------------------------------------------------
create or replace function public.notify_on_follow()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.target_type <> 'user' then
    return new;
  end if;
  perform public.notify(
    array[new.target_id], 'social.follow',
    jsonb_build_object('actor_id', new.follower_id),
    new.follower_id, 'user', new.follower_id
  );
  return new;
end;
$$;

revoke all on function public.notify_on_follow() from public;

drop trigger if exists follows_notify on public.follows;
create trigger follows_notify
  after insert on public.follows
  for each row execute function public.notify_on_follow();

-- -----------------------------------------------------------------------------
-- post_likes → social.post.liked   (collapses per post)
-- -----------------------------------------------------------------------------
create or replace function public.notify_on_post_like()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_author_id uuid;
begin
  select author_id into v_author_id
    from public.posts where post_id = new.post_id;
  if v_author_id is null then
    return new;
  end if;
  -- notify() drops the actor, so the self-like guard is no longer duplicated
  -- here; passing the actor is what makes that happen.
  perform public.notify(
    array[v_author_id], 'social.post.liked',
    jsonb_build_object('post_id', new.post_id, 'actor_id', new.user_id),
    new.user_id, 'post', new.post_id
  );
  return new;
end;
$$;

revoke all on function public.notify_on_post_like() from public;

drop trigger if exists post_likes_notify on public.post_likes;
create trigger post_likes_notify
  after insert on public.post_likes
  for each row execute function public.notify_on_post_like();

-- -----------------------------------------------------------------------------
-- comments → social.post.commented | social.comment.replied | social.mention
-- -----------------------------------------------------------------------------
create or replace function public.notify_on_comment()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_recipient_id uuid;
  v_type_key     text;
  v_payload      jsonb;
begin
  v_payload := jsonb_build_object(
    'post_id',           new.post_id,
    'comment_id',        new.comment_id,
    'parent_comment_id', new.parent_comment_id,
    'actor_id',          new.author_id
  );

  if new.parent_comment_id is null then
    select author_id into v_recipient_id
      from public.posts where post_id = new.post_id;
    v_type_key := 'social.post.commented';
  else
    select author_id into v_recipient_id
      from public.comments where comment_id = new.parent_comment_id;
    v_type_key := 'social.comment.replied';
  end if;

  if v_recipient_id is not null then
    perform public.notify(array[v_recipient_id], v_type_key, v_payload,
                          new.author_id, 'post', new.post_id);
  end if;

  -- Mentions. Skip whoever we just notified above so a post author who is also
  -- mentioned gets one notification, not two. (notify() would dedup WITHIN a
  -- call, but these are two calls with two different types.)
  if coalesce(cardinality(new.mentioned_user_ids), 0) > 0 then
    perform public.notify(
      array(
        select m from unnest(new.mentioned_user_ids) as m
         where v_recipient_id is null or m <> v_recipient_id
      ),
      'social.mention',
      jsonb_build_object('post_id',    new.post_id,
                         'comment_id', new.comment_id,
                         'actor_id',   new.author_id),
      new.author_id, 'post', new.post_id
    );
  end if;

  return new;
end;
$$;

revoke all on function public.notify_on_comment() from public;

drop trigger if exists comments_notify on public.comments;
create trigger comments_notify
  after insert on public.comments
  for each row execute function public.notify_on_comment();

-- -----------------------------------------------------------------------------
-- team_invites → team.invitation.received
-- -----------------------------------------------------------------------------
create or replace function public.notify_on_team_invite()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.notify(
    array[new.invitee_id], 'team.invitation.received',
    jsonb_build_object('invite_id', new.invite_id,
                       'team_id',   new.team_id,
                       'actor_id',  new.invited_by),
    new.invited_by, 'team', new.team_id
  );
  return new;
end;
$$;

revoke all on function public.notify_on_team_invite() from public;

drop trigger if exists team_invites_notify on public.team_invites;
create trigger team_invites_notify
  after insert on public.team_invites
  for each row execute function public.notify_on_team_invite();

-- -----------------------------------------------------------------------------
-- match_challenges INSERT → match.challenge.received
--
-- Audience is to_team's staff. `team_staff_ids` is itself a shim over can()
-- (0212), so the audience follows the permission matrix rather than a
-- hardcoded rank.
--
-- opponent_team_id is from_team_id: the template reads from the RECIPIENT's
-- point of view ("Lahore Lions challenged you"), so the opponent is whoever
-- is not them.
-- -----------------------------------------------------------------------------
create or replace function public.notify_on_match_request_insert()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- Open requests have no recipient pool yet; they notify on accept instead.
  if new.status <> 'pending' or new.to_team_id is null then
    return new;
  end if;

  perform public.notify(
    array(select public.team_staff_ids(new.to_team_id)),
    'match.challenge.received',
    jsonb_build_object(
      'request_id',       new.request_id,
      'from_team_id',     new.from_team_id,
      'to_team_id',       new.to_team_id,
      'opponent_team_id', new.from_team_id,
      'actor_id',         new.requested_by
    ),
    new.requested_by, 'team', new.to_team_id
  );
  return new;
end;
$$;

revoke all on function public.notify_on_match_request_insert() from public;

drop trigger if exists match_challenges_notify_insert on public.match_challenges;
create trigger match_challenges_notify_insert
  after insert on public.match_challenges
  for each row execute function public.notify_on_match_request_insert();

-- -----------------------------------------------------------------------------
-- match_challenges UPDATE → match.challenge.<status>
--
--   pending   → X : the side that ASKED hears the verdict  (from_team)
--   countered → X : the side that COUNTERED hears it       (to_team)
--
-- The original requester is simply prepended to the staff array. notify() does
-- SELECT DISTINCT and drops the actor, which is what the old
-- "v_recipient <> v_actor and (old.status <> 'pending' or v_recipient <>
-- new.requested_by)" guard was hand-rolling.
-- -----------------------------------------------------------------------------
create or replace function public.notify_on_match_request_decision()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor        uuid;
  v_notify_team  uuid;
  v_opponent     uuid;
  v_recipients   uuid[];
begin
  if old.status = new.status
     or old.status not in ('pending', 'countered') then
    return new;
  end if;

  v_actor := coalesce(new.decided_by, auth.uid());

  if old.status = 'pending' then
    v_notify_team := new.from_team_id;
    v_opponent    := new.to_team_id;
  else
    v_notify_team := new.to_team_id;
    v_opponent    := new.from_team_id;
  end if;

  if v_notify_team is null then
    return new;
  end if;

  v_recipients := array(select public.team_staff_ids(v_notify_team));
  if old.status = 'pending' and new.requested_by is not null then
    v_recipients := v_recipients || new.requested_by;
  end if;

  perform public.notify(
    v_recipients,
    -- Five catalogue keys, not one type plus a status field in the payload.
    'match.challenge.' || new.status::text,
    jsonb_build_object(
      'request_id',       new.request_id,
      'from_team_id',     new.from_team_id,
      'to_team_id',       new.to_team_id,
      'opponent_team_id', v_opponent,
      'match_id',         new.match_id,
      'actor_id',         v_actor
    ),
    v_actor, 'team', v_notify_team
  );
  return new;
end;
$$;

revoke all on function public.notify_on_match_request_decision() from public;

drop trigger if exists match_challenges_notify_decision on public.match_challenges;
create trigger match_challenges_notify_decision
  after update of status on public.match_challenges
  for each row execute function public.notify_on_match_request_decision();
