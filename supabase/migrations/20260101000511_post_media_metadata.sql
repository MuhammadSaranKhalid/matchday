-- =============================================================================
-- 0511 · post media metadata (blurhash + dimensions)
-- =============================================================================
-- Additive, forward-only extension of 0510 (posts). The deployed `posts` table
-- only carries `media_urls text[]` (URLs, no per-image metadata). To render
-- instant blur placeholders and reserve layout space before an image loads, we
-- add a richer `media jsonb` column holding one object per image:
--
--   [{ "url": "...", "blurhash": "LEHV6n...", "width": 1080, "height": 1350 }]
--
-- The client computes blurhash + width/height locally (from the resized image)
-- and writes BOTH `media` (rich) and `media_urls` (URLs, for compat) at insert.
-- No existing rows/policies/triggers are modified — this only ADDS a column and
-- widens the content check so a photo post is valid via either column.
-- =============================================================================

alter table public.posts
  add column if not exists media jsonb not null default '[]'::jsonb;

-- Cap at 4 (matches media_urls) and require an array shape.
alter table public.posts
  drop constraint if exists posts_media_shape;
alter table public.posts
  add constraint posts_media_shape check (
    jsonb_typeof(media) = 'array' and jsonb_array_length(media) <= 4
  );

comment on column public.posts.media is
  'Per-image metadata [{url, blurhash, width, height}], max 4. Supersedes media_urls (kept in sync for compatibility).';

-- A photo post is now valid if it has at least one entry in EITHER column.
alter table public.posts drop constraint if exists post_has_content;
alter table public.posts add constraint post_has_content check (
  (post_type = 'photo'
     and (cardinality(media_urls) >= 1 or jsonb_array_length(media) >= 1))
  or (text is not null and length(trim(text)) > 0)
);
