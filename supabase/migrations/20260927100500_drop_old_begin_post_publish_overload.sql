-- Migration: drop_old_begin_post_publish_overload
-- Drops the old legacy 11-argument overload of begin_post_publish that used p_media_items.

drop function if exists public.begin_post_publish(
  public.post_publisher_type,
  uuid,
  public.post_kind,
  text,
  integer,
  uuid,
  uuid,
  uuid,
  uuid[],
  public.post_visibility,
  jsonb
);
