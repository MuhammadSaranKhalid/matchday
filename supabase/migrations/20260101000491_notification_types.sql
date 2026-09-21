-- =============================================================================
-- Migration: 20260101000491_notification_types.sql
-- =============================================================================

-- 0491 · notification_types — THE CATALOGUE
-- Design + decision log: docs/notifications-design.md
--
-- This table is the entire point of the redesign. Notification types are ROWS,
-- not an enum, for the same reason roles became rows in 0201: adding one must
-- be an INSERT, not a schema migration plus a redeploy plus an app release.
--
-- What used to live in CODE and now lives HERE:
--   title/body        → was duplicated in send-push's pushContentFor() AND
--                       notifications_screen's _titleFor(). The two had already
--                       drifted ("New like" vs "Someone liked your post").
--   route             → was a hardcoded string in the edge function, and for
--                       9 of 11 types it was just '/notifications'.
--   icon              → was a Dart switch (_iconFor).
--   tier              → was a Dart getter switch on AppNotification.
--   queue_name        → new; see 0910. pgmq is FIFO with NO priority levels,
--                       so a 10k-follower broadcast would sit in front of an
--                       urgent match challenge. Two queues, and which one a
--                       type uses is data like everything else.
--
-- THE KEY IS HIERARCHICAL and its first segment IS the category. The CHECK
-- below enforces that, so the prefix can never drift from the column — the
-- two-sources-of-truth defect that `teams.owner_id` was deleted for.
--
-- TEMPLATES: `{{placeholder}}`. render_template() (0570) interpolates from the
-- payload AFTER notify() has enriched it with resolved names. The vocabulary
-- is deliberately small and flat — see the header of 0570. A template must
-- never reference something notify() cannot resolve, or it renders a literal
-- `{{team_name}}` to a user. The catalogue test pins this.
--
-- route_template NULL means "no deep link exists" and the client falls back to
-- /notifications. It is NOT a placeholder for laziness: social.post.* are null
-- because THERE IS NO POST DETAIL ROUTE in app_router.dart. Inventing
-- '/posts/{{post_id}}' here would ship a link that 404s. When that route is
-- built, update this template for future rows and explicitly backfill history.

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.notification_types (
  key                   text primary key check (key ~ '^[a-z]+(\.[a-z_]+){1,3}$'),
  category              text not null
    references public.notification_categories (key),
  -- Copy. Rendered at WRITE time and stored on the notification row, which is
  -- what lets both the edge function and an old app build render a type they
  -- have never heard of.
  title_template        text not null,
  body_template         text not null,
  -- Used instead of body_template once group_count > 1. Null = never collapse
  -- into a summary line even if collapse_template is set.
  body_template_grouped text,
  route_template        text,
  -- Presentation tokens, NOT Flutter symbols. The client maps token → IconData
  -- with a default, so an unknown token degrades to a bell instead of crashing
  -- an exhaustive switch.
  icon                  text not null
    references public.notification_icons (key),
  tone                  text not null default 'neutral' check (
    tone in ('neutral', 'brand', 'success', 'warning', 'achievement', 'danger')
  ),
  tier                  text not null default 'fyi'
    check (tier in ('now', 'week', 'fyi')),
  importance            text not null default 'normal' check (
    importance in ('high', 'normal', 'low')
  ),
  queue_name            text not null default 'notifications_push' check (
    queue_name in ('notifications_push', 'notifications_push_bulk')
  ),
  -- Coalescing. collapse_template renders to a key that is unique per
  -- (recipient, key) while UNREAD — 50 likes become one row with group_count
  -- 50 instead of 50 rows and 50 pushes. Null = every event is its own row.
  collapse_template     text,
  collapse_window       interval,
  default_channels      text[] not null default '{inapp,push}' check (
    default_channels <@ array['inapp', 'push']
  ),
  -- ⚠️ false = THIS TYPE IGNORES THE USER. Read before setting it.
  --
  -- It does not merely hide a settings toggle. `notify()` (0570) and
  -- `notification_push_status()` (0910) both branch on it, and when it is
  -- false they skip BOTH the category preference AND `notification_mutes` —
  -- so the notification is delivered to someone who explicitly muted that
  -- exact team, match or thread. The push default still applies; nothing else
  -- does.
  --
  -- Legitimate use is account/security/legal notices a user cannot opt out of
  -- — i.e. category 'system'. It is NOT a way to make an ordinary activity
  -- notification louder, and using it that way is indistinguishable to the
  -- user from the mute being broken.
  --
  -- NO type in this catalogue sets it false today. That is deliberate; the
  -- branch exists for a notice class the product does not have yet. If a
  -- future type needs it, consider adding
  --   check (user_configurable or category = 'system')
  -- so the rule is structural rather than a comment someone has to find.
  user_configurable     boolean not null default true,
  is_active             boolean not null default true,
  created_at            timestamptz not null default now(),
  -- The prefix IS the category. Not a convention — a constraint.
  constraint notification_types_key_matches_category
    check (split_part(key, '.', 1) = category),
  -- A grouped body without a collapse key can never render; a collapse key
  -- without a window would coalesce forever.
  constraint notification_types_collapse_coherent
    check (
      (
        collapse_template is null
        and collapse_window is null
        and body_template_grouped is null
      )
      or (
        collapse_template is not null
        and collapse_window is not null
        and collapse_window > interval '0 seconds'
      )
    )
);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

-- Advisor 0001 — index the FK column.
create index notification_types_category
  on public.notification_types (category);

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

-- RLS — world-readable catalogue (the client renders a settings screen and
-- resolves icons from it), writable only by migrations / service_role.
alter table public.notification_types enable row level security;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

create policy "notification_types_read_all"
  on public.notification_types
  for select
  to anon, authenticated
  using (true);

-- -----------------------------------------------------------------------------
-- Data changes
-- -----------------------------------------------------------------------------

-- The catalogue.
--
-- Every row that replaces one of the 14 old enum values is marked ← PORTED.
-- The rest are types the old enum DECLARED but nothing ever wrote (10 of 20),
-- plus the ones it could not express at all (role grants, officials, toss).
-- Seeding them now is deliberate: phase 6 then adds a notify() call, with no
-- migration at all.
insert into public.notification_types
  (
    key,
    category,
    title_template,
    body_template,
    body_template_grouped,
    route_template,
    icon,
    tier,
    importance,
    queue_name,
    collapse_template,
    collapse_window
  )
values
  -- ── match ───────────────────────────────────────────────────────────────────
  (
    'match.challenge.received',
    'match',
    '{{opponent_name}} challenged you',
    'Tap to accept, counter or decline',
    null,
    '/challenges/{{request_id}}',
    'bat',
    'now',
    'high',
    'notifications_push',
    null,
    null
  ), -- ← PORTED
  (
    'match.challenge.accepted',
    'match',
    'Challenge accepted',
    '{{opponent_name}} accepted your match',
    null,
    '/challenges/{{request_id}}',
    'check',
    'now',
    'high',
    'notifications_push',
    null,
    null
  ), -- ← PORTED
  (
    'match.challenge.declined',
    'match',
    'Challenge declined',
    '{{opponent_name}} declined your challenge',
    null,
    '/challenges/{{request_id}}',
    'x',
    'week',
    'normal',
    'notifications_push',
    null,
    null
  ), -- ← PORTED
  (
    'match.challenge.countered',
    'match',
    'Counter-offer',
    '{{opponent_name}} proposed new terms — tap to review',
    null,
    '/challenges/{{request_id}}',
    'bat',
    'now',
    'high',
    'notifications_push',
    null,
    null
  ), -- ← PORTED
  (
    'match.challenge.cancelled',
    'match',
    'Match cancelled',
    'Your match against {{opponent_name}} was cancelled',
    null,
    '/challenges/{{request_id}}',
    'x',
    'week',
    'normal',
    'notifications_push',
    null,
    null
  ), -- ← PORTED
  (
    'match.challenge.expired',
    'match',
    'Challenge expired',
    'Your challenge expired with no reply',
    null,
    '/challenges/{{request_id}}',
    'x',
    'week',
    'low',
    'notifications_push',
    null,
    null
  ), -- ← PORTED
  (
    'match.starting',
    'match',
    'Your match is starting',
    '{{team_name}} vs {{opponent_name}} is about to begin',
    null,
    '/matches/{{match_id}}',
    'bat',
    'now',
    'high',
    'notifications_push',
    null,
    null
  ), -- ← PORTED
  (
    'match.upcoming',
    'match',
    'Match coming up',
    '{{team_name}} vs {{opponent_name}} is scheduled soon',
    null,
    '/matches/{{match_id}}',
    'calendar',
    'week',
    'normal',
    'notifications_push',
    null,
    null
  ),
  -- Splits the old match_starting overload: tournament_live_ops was sending
  -- "your match is starting" to mean "you have been made scorer".
  (
    'match.scorer.assigned',
    'match',
    'You are scoring this match',
    'You were assigned as scorer for {{team_name}} vs {{opponent_name}}',
    null,
    '/matches/{{match_id}}',
    'bat',
    'now',
    'high',
    'notifications_push',
    null,
    null
  ),
  -- The open-match pool. Distinct from a direct challenge: nobody was picked
  -- out, a team volunteered, so the copy and the tier differ.
  (
    'match.application.received',
    'match',
    '{{opponent_name}} applied to your open match',
    'Tap to review and pick your opponent',
    '{{count}} teams applied to your open match',
    '/challenges/{{request_id}}',
    'bat',
    'now',
    'high',
    'notifications_push',
    'match.application:{{request_id}}',
    interval '12 hours'
  ), -- ← PORTED
  (
    'match.application.accepted',
    'match',
    'You got the match',
    '{{opponent_name}} accepted your application',
    null,
    '/matches/{{match_id}}',
    'check',
    'now',
    'high',
    'notifications_push',
    null,
    null
  ), -- ← PORTED
  (
    'match.official.assigned',
    'match',
    'You have been appointed',
    'You were appointed {{role_name}} for an upcoming match',
    null,
    '/matches/{{match_id}}',
    'shield',
    'week',
    'normal',
    'notifications_push',
    null,
    null
  ),
  (
    'match.completed',
    'match',
    'Result is in',
    '{{team_name}} vs {{opponent_name}} has finished',
    null,
    '/matches/{{match_id}}/summary',
    'trophy',
    'fyi',
    'low',
    'notifications_push',
    null,
    null
  ),
  -- ── team ────────────────────────────────────────────────────────────────────
  (
    'team.invitation.received',
    'team',
    'You were invited to a team',
    '{{actor_name}} invited you to join {{team_name}}',
    null,
    '/teams/{{team_id}}',
    'group',
    'week',
    'high',
    'notifications_push',
    null,
    null
  ), -- ← PORTED
  (
    'team.join.requested',
    'team',
    'New join request',
    '{{actor_name}} wants to join {{team_name}}',
    '{{count}} people want to join {{team_name}}',
    '/teams/{{team_id}}/manage',
    'person_add',
    'now',
    'normal',
    'notifications_push',
    'team.join.requested:{{team_id}}',
    interval '24 hours'
  ),
  (
    'team.join.approved',
    'team',
    'You are in',
    '{{team_name}} accepted your request to join',
    null,
    '/teams/{{team_id}}',
    'check',
    'week',
    'high',
    'notifications_push',
    null,
    null
  ),
  (
    'team.join.declined',
    'team',
    'Request declined',
    '{{team_name}} declined your request to join',
    null,
    '/teams',
    'x',
    'week',
    'normal',
    'notifications_push',
    null,
    null
  ),
  (
    'team.role.granted',
    'team',
    'New role',
    'You are now {{role_name}} of {{team_name}}',
    null,
    '/teams/{{team_id}}',
    'shield',
    'week',
    'high',
    'notifications_push',
    null,
    null
  ),
  (
    'team.claim.approved',
    'team',
    'Claim approved',
    'Your claim on a player profile in {{team_name}} was approved',
    null,
    '/teams/{{team_id}}',
    'check',
    'now',
    'high',
    'notifications_push',
    null,
    null
  ), -- ← PORTED
  (
    'team.claim.declined',
    'team',
    'Claim declined',
    'Your claim on a player profile in {{team_name}} was declined',
    null,
    '/teams/{{team_id}}',
    'x',
    'now',
    'normal',
    'notifications_push',
    null,
    null
  ), -- ← PORTED
  -- Broadcast → the bulk queue, so a big following cannot delay a challenge.
  -- route null: there is no post detail route in app_router.dart yet.
  (
    'team.post.published',
    'team',
    'New team post',
    '{{team_name}} posted an update',
    null,
    null,
    'group',
    'fyi',
    'low',
    'notifications_push_bulk',
    null,
    null
  ),
  -- ── tournament ──────────────────────────────────────────────────────────────
  (
    'tournament.registration.requested',
    'tournament',
    'New registration',
    '{{team_name}} registered for {{tournament_name}}',
    '{{count}} teams registered for {{tournament_name}}',
    '/tournaments/{{tournament_id}}/requests',
    'trophy',
    'now',
    'normal',
    'notifications_push',
    'tournament.registration:{{tournament_id}}',
    interval '12 hours'
  ),
  (
    'tournament.registration.approved',
    'tournament',
    'You are in the draw',
    '{{team_name}} was accepted into {{tournament_name}}',
    null,
    '/tournaments/{{tournament_id}}/register/status',
    'check',
    'week',
    'high',
    'notifications_push',
    null,
    null
  ),
  (
    'tournament.registration.declined',
    'tournament',
    'Registration declined',
    '{{tournament_name}} declined {{team_name}}',
    null,
    '/tournaments/{{tournament_id}}/register/status',
    'x',
    'week',
    'normal',
    'notifications_push',
    null,
    null
  ),
  -- Was riding 'tournament_post' with reason='coorganizer_added' in the payload
  -- — a type meaning "an announcement was posted" used to mean "you were given
  -- admin rights". Its own key now.
  (
    'tournament.organizer.added',
    'tournament',
    'You are now an organizer',
    'You were added as an organizer of {{tournament_name}}',
    null,
    '/tournaments/{{tournament_id}}/console',
    'shield',
    'now',
    'high',
    'notifications_push',
    null,
    null
  ), -- ← PORTED
  (
    'tournament.fixture.published',
    'tournament',
    'Fixtures are out',
    'The draw for {{tournament_name}} has been published',
    null,
    '/tournaments/{{tournament_id}}',
    'calendar',
    'week',
    'normal',
    'notifications_push_bulk',
    null,
    null
  ),
  (
    'tournament.post.published',
    'tournament',
    'Tournament update',
    '{{tournament_name}} posted an announcement',
    null,
    '/tournaments/{{tournament_id}}',
    'trophy',
    'fyi',
    'low',
    'notifications_push_bulk',
    null,
    null
  ), -- ← PORTED
  -- ── chat ────────────────────────────────────────────────────────────────────
  -- Replaces the ORPHANED handleMessagePush path in send-push: that branch
  -- expected a `messages_invoke_send_push` trigger which was never created, so
  -- chat has been pushing nothing at all.
  (
    'chat.message.received',
    'chat',
    '{{chat_name}}',
    '{{actor_name}}: {{message_preview}}',
    '{{count}} new messages',
    '/messages/{{chat_id}}',
    'message',
    'now',
    'high',
    'notifications_push',
    'chat.message:{{chat_id}}',
    interval '1 hour'
  ),
  (
    'chat.request.received',
    'chat',
    'Message request',
    '{{actor_name}} wants to message you',
    null,
    '/messages',
    'message',
    'now',
    'normal',
    'notifications_push',
    null,
    null
  ),
  -- ── social ──────────────────────────────────────────────────────────────────
  (
    'social.follow',
    'social',
    'New follower',
    '{{actor_name}} started following you',
    '{{count}} people started following you',
    '/u/{{actor_username}}',
    'person_add',
    'fyi',
    'low',
    'notifications_push',
    'social.follow',
    interval '24 hours'
  ), -- ← PORTED
  -- route null on all social.post.*: app_router.dart has NO post detail route.
  -- A new route applies to future rows; existing routes require a backfill.
  (
    'social.post.liked',
    'social',
    'New like',
    '{{actor_name}} liked your post',
    '{{count}} people liked your post',
    null,
    'heart',
    'fyi',
    'low',
    'notifications_push',
    'social.post.liked:{{post_id}}',
    interval '24 hours'
  ), -- ← PORTED
  (
    'social.post.commented',
    'social',
    'New comment',
    '{{actor_name}} commented on your post',
    '{{count}} people commented on your post',
    null,
    'comment',
    'week',
    'normal',
    'notifications_push',
    'social.post.commented:{{post_id}}',
    interval '12 hours'
  ), -- ← PORTED
  (
    'social.comment.replied',
    'social',
    'New reply',
    '{{actor_name}} replied to your comment',
    null,
    null,
    'comment',
    'week',
    'normal',
    'notifications_push',
    null,
    null
  ), -- ← PORTED
  (
    'social.mention',
    'social',
    'You were mentioned',
    '{{actor_name}} mentioned you',
    null,
    null,
    'at',
    'week',
    'normal',
    'notifications_push',
    null,
    null
  ), -- ← PORTED
  -- ── system ──────────────────────────────────────────────────────────────────
  (
    'system.stat.milestone',
    'system',
    'Career milestone',
    '{{milestone_text}}',
    null,
    '/profile',
    'star',
    'fyi',
    'low',
    'notifications_push',
    null,
    null
  );

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

create index notification_types_icon
  on public.notification_types (icon);

-- -----------------------------------------------------------------------------
-- Permissions
-- -----------------------------------------------------------------------------

revoke all on public.notification_types from anon, authenticated;

grant select on public.notification_types to anon, authenticated;

grant all on public.notification_types to service_role;

-- -----------------------------------------------------------------------------
-- Data changes
-- -----------------------------------------------------------------------------

-- Icon shape and semantic color are independent catalogue facts.
update public.notification_types
set tone = case
  when icon in ('bat', 'heart') then 'brand'
  when icon = 'check' then 'success'
  when icon in ('trophy', 'star') then 'achievement'
  else 'neutral'
end;
