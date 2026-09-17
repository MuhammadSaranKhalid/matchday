-- =============================================================================
-- 0810 · chat_sync_events — internal sync events
-- =============================================================================

create schema if not exists private;

create table if not exists private.chat_sync_events (
  event_seq           bigint generated always as identity primary key,
  event_id            uuid not null default gen_random_uuid() unique,
  channel_id          uuid,
  actor_id            uuid,
  event_type          text not null,
  entity_type         text not null,
  entity_id           uuid,
  entity_version      integer,
  payload             jsonb not null default '{}'::jsonb,
  created_at          timestamptz not null default now(),
  published_at        timestamptz,
  publish_attempts    integer not null default 0
);
