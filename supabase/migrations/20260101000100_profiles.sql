-- =============================================================================
-- Migration: 20260101000100_profiles.sql
-- =============================================================================

-- 0100 · profiles
-- Spec §1, §1.3, §1.7, §1.11, §8.2.1.
--
-- Identity row attached 1:1 to auth.users. The on_auth_user_created trigger
-- inserts a profile shell when Supabase Auth creates the user; onboarding
-- UI then UPDATES it with username + display_name + location.
--
-- Flow at signup:
--   1. Client calls supabase.auth.signUp() / signInWithOtp().
--   2. auth.users row is inserted by Supabase.
--   3. AFTER-INSERT trigger handle_new_auth_user() fires (SECURITY DEFINER)
--      and creates public.profiles with username from raw_user_meta_data
--      (NULL until onboarding) plus whatever identity the provider gave us.
--   4. Onboarding screen UPDATEs the row with the real values.
--
-- Identity keys in raw_user_meta_data (verified against a live Google sign-in
-- 2026-09-09, and mirrored in auth.identities.identity_data):
--   Google via signInWithIdToken → full_name, name, avatar_url, picture,
--     email, email_verified, phone_verified, iss, sub, provider_id.
--     It does NOT send `display_name` — reading only that key is why every
--     Google account used to land as "New User" with a null photo.
--   Email OTP → nothing; the seeds set `display_name` explicitly.
-- So display_name resolves full_name → name → display_name → 'New User', and
-- the photo resolves avatar_url → picture. full_name/avatar_url are the pair
-- Supabase normalises across providers; name/picture are the raw OIDC claims
-- kept as fallbacks for providers that only emit those. The Dart onboarding
-- prefill (onboarding_controller.dart) reads the same full_name/avatar_url.
--
-- This is presentation data the user can overwrite during onboarding. It is
-- never used for authorization — raw_user_meta_data is user-writable via
-- auth.updateUser(), so nothing may trust it as a claim.
--
-- Username rules (§1.7):
--   - Lowercase letters, digits, underscore. 3–20 chars.
--   - Globally unique (NULLs distinct, so unset profiles don't collide).
--   - Once set, can be changed at most once per 30 days. Enforced by the
--     enforce_username_cooldown() BEFORE-UPDATE trigger.
--
-- Location (§1.3):
--   Stored as flexible jsonb. lat/lng (when present) auto-projected onto
--   `location_point` (PostGIS) via a generated column for spatial indexes.
--
-- Discoverability (§7.9):
--   Boolean flags inside `discoverability` jsonb — appear_in_rankings,
--   appear_in_search, appear_in_suggestions, show_location_publicly. Default
--   on; user can toggle them in settings later.
--
-- Storage:
--   The `avatars` bucket lives here too (profiles.profile_photo_url stores
--   the public URL into it). Folder convention: <user_id>/<filename>.
-- Enums moved to 20260101000000_shared_helpers.sql (the enum catalogue),
-- 2026-09-06 — one enum, one definition, declared before anything uses it.
-- profiles table.

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.profiles (
  user_id             uuid primary key
    references auth.users (id)
    on delete cascade,
  -- Nullable until onboarding sets it. NULLs are distinct under the unique
  -- constraint so newly-created shells don't collide with each other.
  username            text unique
    check (username is null or username ~ '^[a-z0-9_]{3,20}$'),
  display_name        text not null check (length(display_name) between 1 and 80),
  profile_photo_url   text,
  -- Public URL of the profile cover image in the `avatars` bucket
  -- (<user_id>/cover_<ts>.jpg). Null renders the generative placeholder.
  cover_photo_url     text,
  date_of_birth       date,
  gender              public.user_gender,
  bio                 text check (bio is null or length(bio) <= 200),
  -- Location: flexible jsonb keyed by country / province / city / area /
  -- lat / lng. lat+lng are optional but trigger the PostGIS projection.
  location            jsonb not null default '{}'::jsonb,
  location_point      geography(point, 4326) generated always as (
    case
      when location ? 'lat'
      and location ? 'lng' then st_setsrid(
        st_makepoint(
          (location ->> 'lng')::double precision,
          (location ->> 'lat')::double precision
        ),
        4326
      )::geography
      else null
    end
  ) stored,
  -- Discoverability flags (§7.9). Defaults match spec defaults.
  discoverability     jsonb not null default jsonb_build_object(
    'appear_in_rankings',
    true,
    'appear_in_search',
    true,
    'appear_in_suggestions',
    true,
    'show_location_publicly',
    true
  ),
  is_verified         boolean not null default false,
  account_status      public.account_status not null default 'active',
  -- Stamped on the first real username pick. Stays NULL while onboarding
  -- is incomplete (username itself is still NULL).
  username_changed_at timestamptz,
  -- Source of truth for "has the user finished onboarding". Stamped on
  -- the welcome step's "Open feed" CTA. Until set, the router redirects
  -- the user back to /onboarding on every cold-start so they can finish.
  -- The flow persists step-0 fields (display_name, username, location.city)
  -- the moment the user taps Continue, so we can't use the old
  -- "username + city present" heuristic — those are set mid-flow.
  onboarded_at        timestamptz,
  last_active_at      timestamptz not null default now(),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  -- Normalised display_name + username for trigram search. GENERATED — never
  -- write it. f_unaccent() is declared in 0000_shared_helpers so this column
  -- can be declared here rather than bolted on by a later ALTER.
  search_name         text generated always as (
    lower(
      public.f_unaccent(coalesce(display_name, '') || ' ' || coalesce(username, ''))
    )
  ) stored
);

comment on column public.profiles.location is
  'jsonb with keys: country, province, city, area, lat, lng. lat/lng optional.';

comment on column public.profiles.username_changed_at is
  'Username cannot be changed for 30 days after this timestamp (spec §1.7).';

comment on column public.profiles.onboarded_at is
  'Stamped when the user finishes onboarding (welcome step). NULL = onboarding incomplete; router will redirect to /onboarding.';

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

create index profiles_username_trgm
  on public.profiles using gin (
    username gin_trgm_ops
  );

create index profiles_location_point
  on public.profiles using gist (location_point);

create index profiles_city
  on public.profiles ((location ->> 'city'));

create index profiles_last_active
  on public.profiles (last_active_at desc);

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- Username 30-day no-change enforcement. Skipped on the first real pick —
-- when old.username is NULL (onboarding incomplete), the change is free; we
-- still stamp username_changed_at so subsequent changes are throttled.
create or replace function public.enforce_username_cooldown()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if
    new.username is distinct from old.username
    and old.username is not null
    and old.username_changed_at is not null
    and old.username_changed_at > now() - interval '30 days'
  then
    raise exception 'Username can be changed only once every 30 days.'
      using errcode = 'check_violation';
  end if;
  if new.username is distinct from old.username then
    new.username_changed_at = now();
  end if;
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger profiles_enforce_username_cooldown
  before update on public.profiles
  for each row
  execute function public.enforce_username_cooldown();

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- Auth integration — auto-create the profile shell on signup.
-- SECURITY DEFINER so the trigger can write to public.profiles regardless of
-- the RLS context of the inserting service.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles
    (user_id, username, display_name, profile_photo_url, location)
  values
    (
      new.id,
      new.raw_user_meta_data ->> 'username',
      -- Truncated to the column's 80-char check. A raise here would abort the
      -- auth.users INSERT and surface as "Database error saving new user", so
      -- the trigger must not be able to reject a name a provider hands us.
      left(
        coalesce(
          nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
          nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
          nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
          'New User'
        ),
        80
      ),
      coalesce(
        nullif(trim(new.raw_user_meta_data ->> 'avatar_url'), ''),
        nullif(trim(new.raw_user_meta_data ->> 'picture'), '')
      ),
      coalesce(new.raw_user_meta_data -> 'location', '{}'::jsonb)
    )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_auth_user();

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

-- RLS — public read of active profiles; owner-only write.
-- INSERT is locked at the policy level: only the auth trigger writes here.
alter table public.profiles enable row level security;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

create policy "profiles_read_public"
  on public.profiles
  for select
  to anon, authenticated
  using (account_status = 'active');

create policy "profiles_update_self"
  on public.profiles
  for update
  to authenticated
  using (
    (
      select
        auth.uid()
    ) = user_id
  )
  with check (
    (
      select
        auth.uid()
    ) = user_id
  );

create policy "profiles_delete_self"
  on public.profiles
  for delete
  to authenticated
  using (
    (
      select
        auth.uid()
    ) = user_id
  );

-- -----------------------------------------------------------------------------
-- Integrations
-- -----------------------------------------------------------------------------

-- Storage bucket: avatars
-- Public-read; uploads restricted to <auth.uid()>/<filename>.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'avatars',
    'avatars',
    true,
    5 * 1024 * 1024, -- 5 MB cap
    array['image/jpeg', 'image/png', 'image/webp']
  )
on conflict (id) do nothing;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

create policy "avatars_read_public"
  on storage.objects
  for select
  using (bucket_id = 'avatars');

create policy "avatars_insert_own_folder"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (
      select
        auth.uid()
    )::text
  );

create policy "avatars_update_own_folder"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (
      select
        auth.uid()
    )::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (
      select
        auth.uid()
    )::text
  );

create policy "avatars_delete_own_folder"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (
      select
        auth.uid()
    )::text
  );

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

create index if not exists profiles_search_trgm
  on public.profiles using gin (
    search_name gin_trgm_ops
  )
  where
    account_status = 'active'
    and coalesce((discoverability ->> 'appear_in_search')::boolean, true);
