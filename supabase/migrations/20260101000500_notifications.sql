-- =============================================================================
-- 0500 · notifications
-- =============================================================================
-- Spec §6.10, §8.2.6. Per-user inbox written by SECURITY DEFINER triggers
-- across the codebase (likes, comments, follows, mentions, match requests,
-- claim decisions, etc.).
--
-- Schema:
--   payload jsonb is intentionally schemaless — every notification type
--   carries its own keys (post_id, actor_id, comment_id, match_id, ...).
--   The taxonomy lives in the `notification_type` enum below; later
--   migrations extend it via `alter type ... add value if not exists`
--   when new event sources land (e.g. match_challenges in 0600).
--
-- Writes:
--   Clients NEVER insert into this table directly. Every notification is
--   produced by a trigger somewhere else — on post_likes, comments, follows,
--   match_challenges, claim_requests, etc. Each of those trigger functions is
--   SECURITY DEFINER so it can write here even when the actor wouldn't
--   otherwise satisfy the recipient-only RLS.
--
-- Reads / acks:
--   Recipient-only read; recipient can mark `is_read = true` and delete
--   their own rows. Realtime is on so the bell badge updates live.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- notification_type — initial taxonomy. v1.1+ values are reserved here so the
-- shipping triggers can write them without a follow-up migration:
--   stat_milestone     → milestone-post auto-generation
-- v0600 will append match_request / match_request_decision.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- notifications table.
-- -----------------------------------------------------------------------------
create table public.notifications (
  notification_id  uuid primary key default gen_random_uuid(),
  recipient_id     uuid not null
                       references public.profiles(user_id) on delete cascade,
  type             public.notification_type not null,
  payload          jsonb not null default '{}'::jsonb,
  is_read          boolean not null default false,
  created_at       timestamptz not null default now()
);

create index notifications_recipient_created
  on public.notifications (recipient_id, created_at desc);
-- Partial index used by the unread badge counter (no full-table scan).
create index notifications_recipient_unread
  on public.notifications (recipient_id, created_at desc)
  where is_read = false;

-- -----------------------------------------------------------------------------
-- RLS — recipient-only read / update / delete. No insert policy: every write
-- must come from a SECURITY DEFINER trigger.
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
-- Match-request notifications also flow through here — the inbox screen
-- listens on this single channel and filters by `notification.type`.
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

-- Read-state ping so a user reading on one device clears the badge on
-- their other devices.
create or replace function public.broadcast_notification_updated()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform realtime.send(
    jsonb_build_object(
      'notification_id', new.notification_id,
      'recipient_id',    new.recipient_id,
      'is_read',         new.is_read
    ),
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
  when (old.is_read is distinct from new.is_read)
  execute function public.broadcast_notification_updated();
