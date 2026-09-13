-- =============================================================================
-- 0570 · notification engine — render_template, notify(), audience resolvers
-- =============================================================================
-- Design + decision log: docs/notifications-design.md
--
-- DECLARES NO TABLES. This is an integration file (§12.0 rule 1): it must
-- follow BOTH sides of several relationships —
--   0212 team_authorization  (team_members_with, the permission-aware audience)
--   0491 notification_types  (the catalogue it renders from)
--   0500 notifications       (the table it writes)
--   0501/0502 preferences + mutes (the suppression it consults)
--   0560 follows             (the follower audience)
-- so it cannot live in any one of their files.
--
-- ONE ENTRY POINT. Every notification in the app goes through notify(). Before
-- this, each feature hand-wrote its own INSERT, which is how 10 of the 20 old
-- enum values ended up with no writer at all and how two triggers came to
-- disagree about payload shape.
--
-- -----------------------------------------------------------------------------
-- THE TEMPLATE VOCABULARY — what a catalogue template may reference
-- -----------------------------------------------------------------------------
-- Resolved BY THE ENGINE from ids (a template may always use these):
--   {{actor_name}}        p_actor_id  → profiles.display_name   (→ 'Someone')
--   {{actor_username}}    p_actor_id  → profiles.username       (→ '')
--   {{team_name}}         payload.team_id          → teams.team_name
--   {{opponent_name}}     payload.opponent_team_id → teams.team_name
--   {{tournament_name}}   payload.tournament_id    → tournaments.tournament_name
--   {{role_name}}         payload.role_key         → roles.name
--
-- Supplied BY THE CALLER in payload, passed through verbatim:
--   {{team_id}} {{match_id}} {{request_id}} {{post_id}} {{chat_id}}
--   {{chat_name}} {{message_preview}} {{milestone_text}} …
--   (chat_name is caller-supplied because `chats` has no name column — a team
--    chat is named for its team, a DM for the other person, and only the
--    calling trigger knows which.)
--
-- Filled at COLLAPSE time, for body_template_grouped only:
--   {{others}}            how many further actors beyond the named one
--
-- EVERY resolved key always gets a value (with a fallback), so a template can
-- never render a literal `{{team_name}}` onto someone's lock screen because a
-- lookup missed. A genuinely misspelled placeholder is stripped to '' by
-- render_template and caught at CI by the catalogue test — not by failing the
-- business transaction that triggered it.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- render_template — {{key}} interpolation.
--
-- IMMUTABLE and pure: it does no lookups. All resolution happens once, up
-- front, in _notify_vars(), so no notification type ever needs its own SQL.
--
-- Unmatched `{{…}}` placeholders are stripped rather than left visible. A
-- leftover is a catalogue bug; shipping the raw braces to a user is worse than
-- shipping a slightly terse sentence, and the catalogue test is where that bug
-- is supposed to be caught.
-- -----------------------------------------------------------------------------
create or replace function public.render_template(p_tmpl text, p_vars jsonb)
returns text
language plpgsql
immutable
set search_path = public, pg_temp
as $$
declare
  v_out text := p_tmpl;
  v_key text;
  v_val text;
begin
  if p_tmpl is null then
    return null;
  end if;

  for v_key, v_val in
    select e.k,
           case jsonb_typeof(e.v)
             when 'string' then e.v #>> '{}'
             when 'null'   then ''
             else e.v::text
           end
      from jsonb_each(p_vars) as e(k, v)
  loop
    v_out := replace(v_out, '{{' || v_key || '}}', coalesce(v_val, ''));
  end loop;

  -- Strip anything the vocabulary did not cover, then tidy the double spaces
  -- and stray leading/trailing punctuation a removal can leave behind.
  v_out := regexp_replace(v_out, '\{\{[a-z_]+\}\}', '', 'g');
  v_out := btrim(regexp_replace(v_out, '\s+', ' ', 'g'));
  return v_out;
end;
$$;

revoke all on function public.render_template(text, jsonb) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- _notify_vars — resolve ids to names ONCE, then hand render_template a flat
-- bag of scalars. Everything already in the payload passes through, so
-- `{{request_id}}` in a route works with no extra code.
--
-- SECURITY DEFINER because it reads profiles / teams / tournaments on behalf of
-- a caller who may not be able to see them (a notification about a private team
-- still needs the team's name in its body).
-- -----------------------------------------------------------------------------
create or replace function public._notify_vars(p_payload jsonb, p_actor_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v jsonb := coalesce(p_payload, '{}'::jsonb);
begin
  v := v || jsonb_build_object(
    'actor_name', coalesce(
      (select p.display_name from public.profiles p where p.user_id = p_actor_id),
      'Someone'),
    'actor_username', coalesce(
      (select p.username from public.profiles p where p.user_id = p_actor_id),
      ''),
    'team_name', coalesce(
      (select t.team_name from public.teams t
        where t.team_id = (v->>'team_id')::uuid),
      'a team'),
    'opponent_name', coalesce(
      (select t.team_name from public.teams t
        where t.team_id = (v->>'opponent_team_id')::uuid),
      'The other team'),
    'tournament_name', coalesce(
      (select tn.tournament_name from public.tournaments tn
        where tn.tournament_id = (v->>'tournament_id')::uuid),
      'the tournament'),
    'role_name', coalesce(
      (select r.name from public.roles r
        where r.scope = 'team' and r.key = v->>'role_key'),
      'a member')
  );
  return v;
exception
  -- A malformed uuid in the payload must not take down the business write.
  when invalid_text_representation then
    return coalesce(p_payload, '{}'::jsonb)
           || jsonb_build_object('actor_name', 'Someone');
end;
$$;

revoke all on function public._notify_vars(jsonb, uuid) from public, anon, authenticated;

-- Delivery is defined in 0910 after device_tokens. PL/pgSQL resolves the
-- dependency when a producer runs, after all migrations have been applied.

-- =============================================================================
-- notify() — the only way a notification is ever created.
-- =============================================================================
-- Order of operations, and why it is this order:
--
--   0. VALIDATE the type key FIRST. A typo'd or retired key RAISES. This
--      mirrors can()'s discipline in 0212: validate before any short-circuit,
--      because a silent no-op is how a notification quietly stops existing and
--      nobody finds out for a month.
--   1. Drop the actor. Nobody is told about their own action.
--   2. Drop muted recipients (0502).
--   3. Gate the in-app row on the category preference (0501). `inapp` is the
--      BASE channel: if a user has switched the category off in-app there is
--      nothing to show and nothing to push, so no row is written at all.
--      `push` is gated separately below — off means the row still lands in the
--      inbox, it just does not buzz.
--   4. Render from the catalogue templates.
--   5. INSERT … SELECT — ONE statement for the whole audience, however large.
--      ON CONFLICT folds a repeat into the existing unread row.
--   6. Hand the push-eligible ids to the delivery seam.
--
-- SECURITY DEFINER: callers are ordinary triggers running as whoever performed
-- the action, and notifications has no INSERT policy by design.
-- =============================================================================
create or replace function public.notify(
  p_recipients uuid[],
  p_type_key   text,
  p_payload    jsonb default '{}'::jsonb,
  p_actor_id   uuid  default null,
  p_scope      text  default null,
  p_entity_id  uuid  default null
)
returns setof uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_type         public.notification_types%rowtype;
  v_icon_path    text;
  v_recipient    uuid;
  v_vars         jsonb;
  v_title        text;
  v_body         text;
  v_route        text;
  v_collapse     text;
  v_inapp_def    boolean;
  v_push_def     boolean;
  v_all_ids      uuid[];
  v_push_ids     uuid[];
begin
  -- 0. Validate before anything else. Fail closed and loud.
  select * into v_type
    from public.notification_types
   where key = p_type_key and is_active;
  if not found then
    raise exception
      'notify(): unknown or inactive notification type "%"', p_type_key
      using errcode = '22023';
  end if;

  if p_recipients is null or cardinality(p_recipients) = 0 then
    return;
  end if;

  v_vars     := public._notify_vars(p_payload, p_actor_id);
  v_title    := public.render_template(v_type.title_template,    v_vars);
  v_body     := public.render_template(v_type.body_template,     v_vars);
  v_route    := public.render_template(v_type.route_template,    v_vars);
  v_collapse := public.render_template(v_type.collapse_template, v_vars);

  select storage_path into strict v_icon_path from public.notification_icons where key = v_type.icon;

  -- Serialize only competing groups. Sorted recipient locks avoid deadlocks
  -- for overlapping fan-outs. Expiry releases the unique key without marking
  -- historical notifications read or discarding their contents.
  if nullif(v_collapse, '') is not null then
    for v_recipient in select distinct id from unnest(p_recipients) r(id)
      where id is not null order by id
    loop
      perform pg_advisory_xact_lock(hashtextextended(v_recipient::text || ':' || v_collapse, 0));
    end loop;
    update public.notifications set collapse_key = null
      where recipient_id = any(p_recipients) and collapse_key = v_collapse
        and not is_read and collapse_until <= now();
  end if;

  v_inapp_def := 'inapp' = any(v_type.default_channels);
  v_push_def  := 'push'  = any(v_type.default_channels);

  with targets as (
    select distinct r.id as recipient_id
      from unnest(p_recipients) as r(id)
     where r.id is not null
       -- 1. never notify the actor about their own action
       and (p_actor_id is null or r.id <> p_actor_id)
       -- 2. entity mute
       and (not v_type.user_configurable or not exists (
         select 1
           from public.notification_mutes m
          where m.user_id   = r.id
            and p_scope     is not null
            and m.scope     = p_scope
            and m.entity_id = p_entity_id
            and (m.muted_until is null or m.muted_until > now())
       )
       )
       -- 3. in-app category preference; absent row ⇒ the type's default
       and (not v_type.user_configurable or coalesce(
         (select pp.enabled
            from public.notification_preferences pp
           where pp.user_id  = r.id
             and pp.category = v_type.category
             and pp.channel  = 'inapp'),
         v_inapp_def
       ))
  ),
  ins as (
    insert into public.notifications (
      recipient_id, type_key, title, body, route, tier, icon, icon_path, tone,
      actor_id, entity_scope, entity_id, payload, collapse_key, collapse_until
    )
    select t.recipient_id, v_type.key, v_title, v_body, v_route,
           -- Presentation is snapshotted with rendered copy.
           v_type.tier, v_type.icon, v_icon_path, v_type.tone,
           p_actor_id, p_scope, p_entity_id, coalesce(p_payload, '{}'::jsonb),
           nullif(v_collapse, ''), now() + v_type.collapse_window
      from targets t
    on conflict (recipient_id, collapse_key)
      where collapse_key is not null and is_read = false
    do update set
      group_count = public.notifications.group_count + 1,
      -- Re-render the summary line with the NEW count. group_count is still
      -- the old value here, and "Ali and 1 other" is exactly old-count others.
      body = coalesce(
               public.render_template(
                 v_type.body_template_grouped,
                 v_vars || jsonb_build_object(
                   -- {{count}} is the NEW total and is what grouped copy should
                   -- normally use: a grouped body only ever renders at 2+, so
                   -- "3 people liked your post" is grammatical at every value.
                   -- {{others}} (the count EXCLUDING the named actor) is kept
                   -- for phrasings that name someone, but it needs the template
                   -- to handle "1 other" vs "2 others" itself.
                   'count',  public.notifications.group_count + 1,
                   'others', public.notifications.group_count)),
               excluded.body),
      icon       = excluded.icon,
      icon_path  = excluded.icon_path,
      tone       = excluded.tone,
      tier       = excluded.tier,
      title      = excluded.title,
      route      = excluded.route,
      actor_id   = excluded.actor_id,
      payload    = excluded.payload,
      updated_at = now()
    returning notification_id, recipient_id
  )
  select array_agg(i.notification_id),
         array_agg(i.notification_id)
           filter (where case when v_type.user_configurable then coalesce(pp.enabled, v_push_def) else v_push_def end)
    into v_all_ids, v_push_ids
    from ins i
    left join public.notification_preferences pp
      on  pp.user_id  = i.recipient_id
      and pp.category = v_type.category
      and pp.channel  = 'push';

  if v_all_ids is null then
    return;
  end if;

  insert into public.notification_deliveries
    (notification_id, revision, device_key, channel, status, attempts)
  select n.notification_id, n.group_count, '', 'push', 'skipped_pref', 0
    from public.notifications n where n.notification_id = any(v_all_ids)
      and not (n.notification_id = any(coalesce(v_push_ids, array[]::uuid[])))
  on conflict do nothing;

  if v_push_ids is not null and cardinality(v_push_ids) > 0 then
    perform public._notify_deliver(v_push_ids, v_type.queue_name);
  end if;

  return query select unnest(v_all_ids);
end;
$$;

revoke all on function public.notify(uuid[], text, jsonb, uuid, text, uuid)
  from public, anon, authenticated;

-- Convenience wrapper for the overwhelmingly common single-recipient case.
create or replace function public.notify_one(
  p_recipient uuid,
  p_type_key  text,
  p_payload   jsonb default '{}'::jsonb,
  p_actor_id  uuid  default null,
  p_scope     text  default null,
  p_entity_id uuid  default null
)
returns uuid
language sql
security definer
set search_path = public, pg_temp
as $$
  select public.notify(array[p_recipient], p_type_key, p_payload,
                       p_actor_id, p_scope, p_entity_id)
   limit 1;
$$;

revoke all on function public.notify_one(uuid, text, jsonb, uuid, text, uuid)
  from public, anon, authenticated;

-- =============================================================================
-- Audience resolvers — "who should be told".
--
-- Thin on purpose. The interesting one already existed: team_members_with()
-- (0212) is commented in its own file as "the notification AUDIENCE", and it
-- asks the PERMISSION MATRIX rather than hardcoding a role ladder. If captains
-- gain team.challenge.send tomorrow, the challenge notification reaches them
-- with no change here. Do not reintroduce a hardcoded "role >= manager".
-- =============================================================================

-- Everyone on the roster with a real account.
create or replace function public.audience_team_members(p_team_id uuid)
returns setof uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select tm.user_id
    from public.team_members tm
   where tm.team_id = p_team_id
     and tm.status  = 'active'
     and tm.user_id is not null;
$$;

revoke all on function public.audience_team_members(uuid) from public, anon, authenticated;

-- Followers of any followable entity. `follows` is already polymorphic over
-- user / team / tournament, so this needs no new machinery.
--
-- Suppression is centralized in notification_mutes and notify().
create or replace function public.audience_followers(
  p_target_type public.follow_target_type,
  p_target_id   uuid
)
returns setof uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select f.follower_id
    from public.follows f
   where f.target_type = p_target_type
     and f.target_id   = p_target_id
     and f.status      = 'active';
$$;

revoke all on function public.audience_followers(public.follow_target_type, uuid)
  from public, anon, authenticated;

-- Both sides of a match, roster-wide.
create or replace function public.audience_match_sides(p_match_id uuid)
returns setof uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select distinct tm.user_id
    from public.matches m
    join public.team_members tm
      on tm.team_id in (m.team_a_id, m.team_b_id)
   where m.match_id = p_match_id
     and tm.status  = 'active'
     and tm.user_id is not null;
$$;

revoke all on function public.audience_match_sides(uuid) from public, anon, authenticated;

-- NOT HERE: audience_chat_members.
--
-- `chat_members` is declared in 0801, AFTER this file. These resolvers are
-- `language sql`, so unlike plpgsql their bodies are validated at CREATE time
-- (§12.0) — which is the good outcome: `supabase db reset` refuses the
-- migration rather than letting it compile and fail at runtime months later.
-- Switching it to plpgsql would silence the error without fixing the ordering,
-- so it stays out.
--
-- Nothing needs it yet — chat notifications are not wired (the chat.* catalogue
-- keys exist with no producer). It lands with that work, in a file numbered
-- after 0801.
