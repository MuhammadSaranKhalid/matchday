-- Matchday V1: Cleanup V2 outbox, generation, and recovery artifacts.
-- Keep the simple authoritative lifecycle:
-- pending_upload -> uploaded -> processing -> ready / failed

-- 1. Drop outbox table and triggers
drop trigger if exists media_processing_outbox_set_updated_at on private.media_processing_outbox;
drop table if exists private.media_processing_outbox cascade;

-- 2. Drop generation constraints and columns from post_media
alter table public.post_media
  drop constraint if exists chk_post_media_status_generation,
  drop constraint if exists chk_post_media_generation;

alter table public.post_media
  drop column if exists processing_token,
  drop column if exists processing_generation;

-- 3. Drop unused stale recovery routine (deferred to V2)
drop function if exists private.recover_stale_post_media(timestamptz, integer);
