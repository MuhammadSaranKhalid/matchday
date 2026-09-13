-- =============================================================================
-- 0500 · notifications — the per-user inbox
-- =============================================================================
-- Design + decision log: docs/notifications-design.md
--
-- REWRITTEN 2026-09-12. What changed and why:
--
--   `type` was a `notification_type` ENUM. It is now `type_key text`
--   referencing the notification_types CATALOGUE (0491). An enum forced a
--   migration per type AND forced exhaustive switches in Dart, which is why
--   adding one notification used to cost a migration, an edge-function
--   redeploy and an app-store release. Same move as roles in 0201.
--
--   `title` / `body` / `route` are NEW and are RENDERED AT WRITE TIME by
--   notify() (0570). This is the load-bearing decision of the whole redesign:
--   because the row carries its own copy, `send-push` sends what the row says
--   and Flutter renders what the row says. NEITHER NEEDS TO KNOW THE TYPE
--   EXISTS — so an app build shipped today correctly renders a notification
--   type invented next month. Previously the copy was written twice, in two
--   languages, and had already drifted.
--
--   The trade-off is accepted deliberately: a team that renames itself shows
--   its old name in an old notification. That also makes the row an immutable
--   record of what was actually said, which is the more honest artefact.
--
--   `collapse_key` + `group_count` coalesce repeats. 50 likes used to be 50
--   rows and 50 pushes.
--
--   `actor_id` is promoted out of payload (every type has a "who"), and
--   `entity_scope` + `entity_id` say what the notification is ABOUT, so the
--   mute lookup in 0502 is a join rather than a dig through payload jsonb.
--
-- Writes:
--   Clients NEVER insert here; there is no insert policy. Every row comes from
--   public.notify() (0570), which is SECURITY DEFINER. Triggers no longer hand-
--   write INSERT statements — that is what allowed 10 of the old 20 enum values
--   to exist with no writer at all, and two triggers to disagree about payload
--   shape.
--
-- Reads / acks:
--   Recipient-only read; recipient may flip is_read and delete their own rows.
--   Realtime broadcast is on, so the bell badge updates live.
-- =============================================================================

create table public.notifications (
  notification_id  uuid primary key default gen_random_uuid(),
  recipient_id     uuid not null
                       references public.profiles(user_id) on delete cascade,

  -- The catalogue row this was produced from. ON UPDATE CASCADE so a type can
  -- be renamed in the catalogue without orphaning history; RESTRICT on delete
  -- because deleting a type that has been sent would erase the inbox. Retiring
  -- a type is `is_active = false`, not a DELETE.
  type_key         text not null
                       references public.notification_types(key)
                       on update cascade on delete restrict,

  -- Rendered at write time from the catalogue's templates. See the header.
  title            text not null,
  body             text not null,
  -- NULL = no deep link for this type; the client falls back to /notifications.
  route            text,

  -- Presentation snapshots preserve what was shown. Custom Broadcast payloads
  -- can join catalogue data; copying is a deliberate history policy.
  tier             text not null default 'fyi'
                       check (tier in ('now', 'week', 'fyi')),
  icon             text not null default 'bell',
  icon_path        text not null default 'v1/bell.svg',
  tone             text not null default 'neutral'
                       check (tone in ('neutral', 'brand', 'success', 'warning', 'achievement', 'danger')),

  -- Who did it. NULL for system-generated notices with no human actor.
  actor_id         uuid references public.profiles(user_id) on delete set null,

  -- What it is ABOUT. Drives the mute join in notify(); mirrors the scope
  -- vocabulary used by can() and notification_mutes.
  entity_scope     text check (entity_scope in ('team', 'match', 'tournament',
                                                'post', 'chat', 'user')),
  entity_id        uuid,

  payload          jsonb not null default '{}'::jsonb,

  -- Coalescing. Rendered from notification_types.collapse_template; NULL means
  -- this type never collapses.
  collapse_key     text,
  collapse_until   timestamptz,
  group_count      integer not null default 1 check (group_count >= 1),

  is_read          boolean not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),

  -- entity_scope and entity_id are one fact in two columns; neither is useful
  -- alone and a half-set pair would silently never match a mute.
  constraint notifications_entity_complete
    check ((entity_scope is null) = (entity_id is null))
);

create index notifications_recipient_created
  on public.notifications (recipient_id, created_at desc, notification_id desc);

-- Partial index used by the unread badge counter (no full-table scan).
create index notifications_recipient_unread
  on public.notifications (recipient_id, created_at desc)
  where is_read = false;

-- Advisor 0001 — index every FK column. recipient_id is covered above.
create index notifications_type_key on public.notifications (type_key);
create index notifications_actor    on public.notifications (actor_id);

-- THE COLLAPSE KEY. Unique per (recipient, key) only while UNREAD: once you
-- have read "3 people liked your post", the next like must start a fresh row
-- rather than silently incrementing something you already dismissed.
create unique index notifications_collapse
  on public.notifications (recipient_id, collapse_key)
  where collapse_key is not null and is_read = false;

create trigger notifications_set_updated_at
  before update on public.notifications
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- RLS — recipient-only read / update / delete. No INSERT policy: every write
-- must come from public.notify(), which is SECURITY DEFINER.
-- -----------------------------------------------------------------------------
alter table public.notifications enable row level security;

create policy "notifications_read_self"
  on public.notifications for select
  to authenticated
  using ((select auth.uid()) = recipient_id);

create policy "notifications_update_self"
  on public.notifications for update
  to authenticated
  using ((select auth.uid()) = recipient_id)
  with check ((select auth.uid()) = recipient_id);

create policy "notifications_delete_self"
  on public.notifications for delete
  to authenticated
  using ((select auth.uid()) = recipient_id);

-- =============================================================================
-- Realtime — Broadcast on every insert / read-state change.
-- =============================================================================
-- Topic: user:<recipient_id>:notifications
-- Events: 'notification' (new) | 'notification_updated' (is_read flip).
--
-- This is what keeps the FOREGROUND case instant. Push delivery is queued
-- (0910) and therefore up to one cron interval behind; a connected client
-- never waits for it, because the row itself arrives here immediately. The two
-- paths are deliberate duplicates covering different device states.
--
-- `to_jsonb(new)` now carries the rendered title/body/route, so the realtime
-- payload is self-describing for the same reason the row is.
-- =============================================================================
create or replace function public.broadcast_new_notification()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform realtime.send(
    to_jsonb(new),
    'notification',
    'user:' || new.recipient_id::text || ':notifications',
    true
  );
  return null;
end;
$$;

revoke all on function public.broadcast_new_notification() from public;

drop trigger if exists notifications_after_insert_broadcast on public.notifications;

create trigger notifications_after_insert_broadcast
  after insert on public.notifications
  for each row execute function public.broadcast_new_notification();

-- A collapse UPDATE (group_count bumped) must reach the client too, otherwise
-- "and 4 others" never updates on a screen that is already open.
create or replace function public.broadcast_notification_updated()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform realtime.send(
    to_jsonb(new),
    'notification_updated',
    'user:' || new.recipient_id::text || ':notifications',
    true
  );
  return null;
end;
$$;

revoke all on function public.broadcast_notification_updated() from public;

drop trigger if exists notifications_after_update_broadcast on public.notifications;

create trigger notifications_after_update_broadcast
  after update on public.notifications
  for each row
  when (old.is_read     is distinct from new.is_read
     or old.group_count is distinct from new.group_count)
  execute function public.broadcast_notification_updated();

-- RLS scopes rows; column grants restrict acknowledgement to the read flag.
revoke all on public.notifications from anon, authenticated;
grant select, delete on public.notifications to authenticated;
grant update (is_read) on public.notifications to authenticated;
grant all on public.notifications to service_role;

create or replace function public.broadcast_notification_deleted()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  perform realtime.send(jsonb_build_object('notification_id', old.notification_id),
    'notification_deleted', 'user:' || old.recipient_id::text || ':notifications', true);
  return null;
end;
$$;
revoke all on function public.broadcast_notification_deleted() from public, anon, authenticated;
create trigger notifications_after_delete_broadcast after delete on public.notifications
for each row execute function public.broadcast_notification_deleted();
