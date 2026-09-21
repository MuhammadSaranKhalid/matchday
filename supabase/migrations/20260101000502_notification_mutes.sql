-- Migration file: 20260101000502_notification_mutes.sql

-- 0502 · notification_mutes — "stop telling me about THIS one"
-- Design + decision log: docs/notifications-design.md
--
-- The other half of preferences (0501). Category toggles answer "what kinds of
-- thing"; this answers "which specific thing". One noisy tournament is the
-- realistic uninstall driver, and no category switch can express "everything
-- except that one".
--
-- ONE SOURCE OF TRUTH, DELIBERATELY.
--   `follows` already carried `notifications_enabled` and `status = 'muted'`,
--   which expressed exactly this — but only for entities you FOLLOW, and never
--   for a team you are a member of or a match you are playing in. Two columns
--   answering "is this muted?" is the same defect that got `teams.owner_id`
--   deleted in the roles redesign.
--
--   The follow bell now reads/writes this table. The canonical follows schema
--   no longer has notifications_enabled; a hosted upgrade must first migrate
--   existing false values into permanent mutes (see docs/notifications-design.md).
--
--   `follows.status` keeps its own job (whether the follow edge itself is
--   active), which is a different fact and stays.
--
-- `scope` intentionally mirrors the scope vocabulary used by can() and by
-- notifications.entity_scope, so a mute lookup is a plain join on
-- (scope, entity_id) rather than digging through payload jsonb. That is why
-- notifications carries those two columns at all.
--
-- No FK on entity_id: it is polymorphic across teams / matches / tournaments /
-- posts / chats / profiles, the same problem `follows` has. Orphans are
-- harmless here (a mute for a deleted team is never consulted again), so the
-- follows cleanup-trigger machinery is not warranted.

-- Section: Tables and constraints

create table public.notification_mutes(
  user_id     uuid not null references public.profiles(user_id) on delete cascade,
  scope       text not null check (scope in ('team', 'match', 'tournament', 'post', 'chat', 'user')),
  entity_id   uuid not null,
  -- NULL = muted forever. A timestamp = "snooze", which is what the UI's
  -- "mute for 8 hours" offers. notify() compares against now(), so an expired
  -- row simply stops matching; a nightly sweep is not required.
  muted_until timestamptz,
  created_at  timestamptz not null default now(),
  primary key (user_id, scope, entity_id)
);

-- Section: Indexes

-- The lookup notify() actually makes is "is THIS user muting THIS entity",
-- which the PK serves. This index serves the reverse question the UI asks:
-- "how many people muted this tournament" / cleanup by entity.
create index notification_mutes_entity on public.notification_mutes(scope, entity_id);

-- Section: Enable row-level security

-- RLS — a user reads and writes only their own mutes.
alter table public.notification_mutes enable row level security;

-- Section: Policies

create policy "notification_mutes_select_self" on public.notification_mutes
  for select to authenticated
  using ((
    select
      auth.uid()) = user_id);

create policy "notification_mutes_insert_self" on public.notification_mutes
  for insert to authenticated
  with check ((
    select
      auth.uid()) = user_id);

create policy "notification_mutes_update_self" on public.notification_mutes
  for update to authenticated
  using ((
    select
      auth.uid()) = user_id)
  with check ((
    select
      auth.uid()) = user_id);

create policy "notification_mutes_delete_self" on public.notification_mutes
  for delete to authenticated
  using ((
    select
      auth.uid()) = user_id);

-- Section: Permissions

revoke all on public.notification_mutes from anon, authenticated;

grant select, insert, update, delete on public.notification_mutes to authenticated;

grant all on public.notification_mutes to service_role;
