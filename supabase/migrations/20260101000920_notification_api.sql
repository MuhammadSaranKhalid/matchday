-- Migration file: 20260101000920_notification_api.sql

-- 0920 · notification client API
-- Design + decision log: docs/notifications-design.md
--
-- DECLARES NO TABLES. The three RPCs the Flutter client is allowed to call.
--
-- All three are SECURITY INVOKER, not DEFINER. That is the whole security
-- model here: each one runs as the caller, so the recipient-only RLS on
-- `notifications` and the self-only policies on `notification_preferences` /
-- `notification_mutes` (0500/0501/0502) do the filtering. A DEFINER function
-- would have to re-implement those checks by hand, and a missed `where` clause
-- would then read straight past RLS. The `(select auth.uid())` calls below are
-- for correctness of the query, not for authorization.
--
-- Every function is revoked from public/anon and granted only to
-- `authenticated` (advisors 0028/0029): Postgres grants EXECUTE to PUBLIC on
-- every new function, and `anon` holds PUBLIC.
-- list_notifications — the inbox, newest first.
--
-- KEYSET pagination on the composite `(created_at, notification_id)`, not
-- OFFSET. Two reasons, both load-bearing:
--   1. OFFSET re-scans and discards every skipped row, so page N costs O(N).
--   2. More importantly it is WRONG here — notifications arrive while the user
--      is scrolling, which shifts every subsequent offset and makes rows repeat
--      or vanish. A cursor names a position, not a count.
-- notification_id breaks ties: `created_at` is not unique, and a fan-out writes
-- many rows in one statement with an identical timestamp.
--
-- The limit is clamped rather than trusted; the caller is a client.

-- Section: Functions

create or replace function public.list_notifications(
  p_before_created timestamptz default null,
  p_before_id uuid default null,
  p_limit int default 40
)
  returns setof public.notifications
  language sql
  stable
  security invoker
  set search_path = public, pg_temp
  as $$
  select
    n.*
  from
    public.notifications n
  where
    n.recipient_id =(
      select
        auth.uid())
    and(p_before_created is null
      or(n.created_at,
        n.notification_id) <(p_before_created,
        p_before_id))
  order by
    n.created_at desc,
    n.notification_id desc
  limit greatest(1, least(p_limit, 100));
$$;

revoke all on function public.list_notifications(timestamptz, uuid, int) from public, anon;

grant execute on function public.list_notifications(timestamptz, uuid, int) to authenticated;

-- set_follow_notifications — the bell on a followed profile/team/tournament.
--
-- It writes `notification_mutes`, the SAME fact the notification settings
-- screen writes. That is the point: `follows.notifications_enabled` used to be
-- a second column answering "is this muted?", and two sources of truth for one
-- question is the defect the roles redesign removed when it deleted
-- `teams.owner_id`. The source schema drops that column; a data-preserving
-- hosted rollout must first migrate its `false` values into permanent mutes.
--
-- The follow-exists guard is not decoration. Without it this is an unbounded
-- write primitive: any authenticated user could insert arbitrary
-- (scope, entity_id) mute rows for themselves, since `notification_mutes` has
-- no FK on entity_id (it is polymorphic). Requiring a follow keeps the table
-- bounded by things the user actually has a relationship with.
--
-- ON CONFLICT … SET muted_until = null upgrades an existing snooze to a
-- permanent mute rather than failing or silently leaving the timer in place.
create or replace function public.set_follow_notifications(
  p_scope text,
  p_entity_id uuid,
  p_enabled boolean
)
  returns void
  language plpgsql
  security invoker
  set search_path = public, pg_temp
  as $$
begin
  if not exists(
    select
      1
    from
      public.follows
    where
      follower_id =(
        select
          auth.uid())
        and target_type::text = p_scope
        and target_id = p_entity_id) then
    raise exception 'Follow this entity to change notifications'
    using errcode = 'P0002';
end if;
  if p_enabled then
    delete from public.notification_mutes
    where user_id =(
        select
          auth.uid())
      and scope = p_scope
      and entity_id = p_entity_id;
  else
    insert into public.notification_mutes(user_id, scope, entity_id)
      values((
          select
            auth.uid()),
          p_scope,
          p_entity_id)
    on conflict(user_id,
      scope,
      entity_id)
      do update set
        muted_until = null;
  end if;
end;
$$;

revoke all on function public.set_follow_notifications(text, uuid, boolean) from public, anon;

grant execute on function public.set_follow_notifications(text, uuid, boolean) to authenticated;

-- notification_settings — one row per category, with the CURRENT effective
-- value of each channel.
--
-- The client cannot compute this itself, because "no preference row" does not
-- mean "off" — it means "use the type defaults" (0501). So the coalesce chain
-- is: the user's explicit row, else whether ANY active type in that category
-- ships that channel by default, else true.
--
-- bool_or over the category's active types is deliberate: a category is shown
-- as on if anything in it would send, which matches what the toggle actually
-- controls. Retiring the last type in a category (is_active = false) therefore
-- shows it as off rather than lying.
--
-- Two separate LEFT JOINs rather than one on `channel in (...)`: a single join
-- would multiply rows per category and break the aggregate.
create or replace function public.notification_settings()
  returns jsonb
  language sql
  stable
  security invoker
  set search_path = public, pg_temp
  as $$
  select
    coalesce(jsonb_agg(jsonb_build_object('category', c.key, 'name', c.name, 'description', c.description, 'inapp', coalesce(pi.enabled,(
              select
                bool_or('inapp' = any(t.default_channels))
              from public.notification_types t
              where
                t.category = c.key
                and t.is_active), true), 'push', coalesce(pp.enabled,(
                select
                  bool_or('push' = any(t.default_channels))
                from public.notification_types t
                where
                  t.category = c.key
                  and t.is_active), true))
          order by c.sort_order), '[]'::jsonb)
  from
    public.notification_categories c
  left join public.notification_preferences pi on pi.category = c.key
    and pi.channel = 'inapp'
    and pi.user_id =(
      select
        auth.uid())
    left join public.notification_preferences pp on pp.category = c.key
      and pp.channel = 'push'
      and pp.user_id =(
        select
          auth.uid());
$$;

revoke all on function public.notification_settings() from public, anon;

grant execute on function public.notification_settings() to authenticated;
