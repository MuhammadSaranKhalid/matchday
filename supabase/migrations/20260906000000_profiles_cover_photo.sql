-- =============================================================================
-- 20260906000000 · profiles_cover_photo
-- =============================================================================
-- Adds `profiles.cover_photo_url`.
--
-- The column has been read by the client since the profile header was built:
-- `ProfileDto` maps `@JsonKey(name: 'cover_photo_url')` and `Profile.coverUrl`
-- feeds the header's banner. Reads survived because PostgREST simply returns
-- no such key and the DTO decodes it as null — so the header has silently
-- rendered its empty state for every user, and nothing failed loudly.
--
-- The edit screen (artboard 1a) makes the cover editable, and a write cannot
-- be silent: updating a column that does not exist fails with
--   PGRST204  Could not find the 'cover_photo_url' column of 'profiles'
--             in the schema cache
--
-- The value is a public URL into the existing `avatars` bucket, stored under
-- the same `<user_id>/` folder its RLS already keys on (`cover_<ts>.jpg`), so
-- no new bucket or storage policy is required.
-- =============================================================================

alter table public.profiles
  add column if not exists cover_photo_url text;

comment on column public.profiles.cover_photo_url is
  'Public URL of the profile cover image in the `avatars` bucket '
  '(<user_id>/cover_<ts>.jpg). Null renders the generative placeholder.';
