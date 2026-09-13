-- =============================================================================
-- 0810 · Realtime Authorization (RLS on realtime.messages)
-- =============================================================================
-- Foundation for the Broadcast-everywhere model. Every realtime channel in
-- the app ships private (`{ private: true }`), which means Supabase Realtime
-- evaluates RLS on `realtime.messages` before allowing a join. Without this
-- migration, no private channel join succeeds.
--
-- Topic naming convention (locked):
--   user:<user_id>:notifications   - own-user fan-out (notifications,
--                                    chat_updated badges, match_request
--                                    & match_request_decision events)
--   chat:<chat_id>:messages        - hot chat message stream (one channel per chat)
--   chat:<chat_id>:typing          - typing indicators (clients publish directly)
--   match:<match_id>:balls         - live ball-by-ball feed for spectators
--   match:<match_id>:state         - score / status updates
--   tournament:<tournament_id>:standings - live standings reorder
--   post:<post_id>:comments        - live comment thread under a post
--
-- Read policy: a user may JOIN a topic only if they're entitled to it.
-- Send policy: a user may PUBLISH only to chat:<id>:typing channels of chats
-- they belong to; all other publishes are server-side via SECURITY DEFINER
-- trigger functions defined inline in each per-table migration.
--
-- Depends on `public.is_chat_member(uuid)` defined in 0801_chat_members.sql
-- — this migration is numbered 0810 to live after the full chat
-- layer (0800 chats → 0801 chat_members → 0802 messages) is in place.
-- =============================================================================

-- Supabase owns the Realtime schema; only authorization policies are managed here.
--
-- VERIFIED 2026-09-12, because the policies below are worthless if it is not
-- true. This file used to `alter table realtime.messages enable row level
-- security` itself. That was removed on the grounds that Supabase provisions
-- it — and after a clean `supabase db reset`:
--
--   select relrowsecurity from pg_class
--    where oid = 'realtime.messages'::regclass;   -- => t
--
-- RLS is on, so the policies below are enforced. Re-check this after any
-- Supabase CLI/platform upgrade: `advisors.sql` CANNOT catch a regression here,
-- because check 0013 only scans the `public` schema. If it ever comes back
-- `f`, every broadcast authorization policy in this file is silently inert and
-- the enable must be restored.
--
-- The `grant insert on realtime.messages to postgres, service_role` was removed
-- in the same change. Nothing in the repo inserts into that table directly —
-- tournament_standings (0320), notifications (0500), comments (0520) and
-- match_realtime_and_security (0820) all publish via `realtime.send()`, which
-- is SECURITY DEFINER and owned by the Realtime role.

-- -----------------------------------------------------------------------------
-- _try_topic_uuid — extract a UUID at the given split position without
-- raising on malformed input. A bare `::uuid` cast on `split_part(...)`
-- throws on garbage (and any unauthenticated client can probe channels
-- with garbage topics), so the regex pre-check turns failures into a
-- clean NULL that downstream membership checks reject quietly.
-- -----------------------------------------------------------------------------
create or replace function public._try_topic_uuid(p_topic text, p_pos int)
returns uuid
language sql
immutable
set search_path = public, pg_temp
as $$
  select case
    when split_part(p_topic, ':', p_pos)
         ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    then split_part(p_topic, ':', p_pos)::uuid
    else null
  end;
$$;

grant execute on function public._try_topic_uuid(text, int) to authenticated, anon;


-- -----------------------------------------------------------------------------
-- READ policy — controls who can SUBSCRIBE (channel.join) to which topics.
-- -----------------------------------------------------------------------------
-- realtime.topic() returns the topic the caller is trying to join.
-- We parse it with split_part (cheaper and index-friendly vs regex).
--
-- Performance notes (per Supabase Realtime Authorization docs):
--   * `(select realtime.topic())` and `(select auth.uid())` are wrapped in
--     SELECT so PG evaluates them once per query plan rather than once per row.
--   * `extension = 'broadcast'` short-circuits the policy for presence joins
--     (we don't use Presence yet; if added later, presence will need its own
--     policy with `extension = 'presence'`).
--   * Chained OR is short-circuited per-row; the cheapest predicates come
--     first (string compares before subqueries like is_chat_member).
drop policy if exists "realtime_join_authorized" on realtime.messages;

create policy "realtime_join_authorized"
  on realtime.messages
  for select
  to authenticated
  using (
    realtime.messages.extension = 'broadcast'
    and (
      -- Own user channels: user:<auth.uid()>:notifications | :match_challenges
      (
        split_part((select realtime.topic()), ':', 1) = 'user'
        and split_part((select realtime.topic()), ':', 2) = (select auth.uid())::text
      )
      -- Match channels: match:<match_id>:balls | :state  (open to all authed
      -- users for v1; tighten with an is_match_visible() helper once match
      -- visibility model lands).
      or (
        split_part((select realtime.topic()), ':', 1) = 'match'
      )
      -- Tournament channels: tournament:<id>:standings  (public for v1).
      or (
        split_part((select realtime.topic()), ':', 1) = 'tournament'
      )
      -- Post channels: post:<post_id>:comments  (any authed user who can read
      -- the post — RLS on the underlying posts table handles content visibility;
      -- we don't re-check it here so the cost stays O(1) per join).
      or (
        split_part((select realtime.topic()), ':', 1) = 'post'
      )
      -- Chat channels: chat:<chat_id>:messages | :typing  (membership required;
      -- last in the OR chain so the cheaper prefix checks above can short-circuit).
      or (
        split_part((select realtime.topic()), ':', 1) = 'chat'
        and public.is_chat_member(
          public._try_topic_uuid((select realtime.topic()), 2)
        )
      )
    )
  );


-- -----------------------------------------------------------------------------
-- WRITE policy — controls who can PUBLISH to a topic from the client.
-- -----------------------------------------------------------------------------
-- Clients only ever publish to chat typing channels. Message bodies, ball
-- events, and notifications are published server-side via trigger functions
-- running as SECURITY DEFINER, which bypass this policy.
drop policy if exists "realtime_send_typing_self" on realtime.messages;

create policy "realtime_send_typing_self"
  on realtime.messages
  for insert
  to authenticated
  with check (
    realtime.messages.extension = 'broadcast'
    and split_part((select realtime.topic()), ':', 1) = 'chat'
    and split_part((select realtime.topic()), ':', 3) = 'typing'
    and public.is_chat_member(
      public._try_topic_uuid((select realtime.topic()), 2)
    )
  );


-- -----------------------------------------------------------------------------
-- Grants. Trigger functions run as SECURITY DEFINER (postgres role) so they
-- bypass RLS; service_role is granted as well for Edge Function publishes.
-- -----------------------------------------------------------------------------
-- Server broadcasts use realtime.send(); no grants on managed Realtime tables.

-- -----------------------------------------------------------------------------
-- Supabase Realtime Table Publications
-- -----------------------------------------------------------------------------
do $$
begin
  alter publication supabase_realtime add table public.teams;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.team_members;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.unclaimed_players;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.posts;
exception when duplicate_object then null;
end $$;

