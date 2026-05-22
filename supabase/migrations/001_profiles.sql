-- 001_profiles.sql — user profile table + auto-provision trigger.
--
-- A profiles row is created automatically by the handle_new_user trigger the
-- moment an auth.users row appears (email OTP or Google). Onboarding (Feature 2)
-- then UPDATEs that row with username/display_name/location/player_profile.
-- The Flutter client never INSERTs into profiles.

create table public.profiles (
  user_id           uuid primary key references auth.users(id) on delete cascade,
  username          text unique,
  display_name      text,
  profile_photo_url text,
  bio               text,
  date_of_birth     date,
  gender            text check (gender in ('male','female','other','prefer_not_to_say')),
  location          jsonb,
  player_profile    jsonb,
  account_status    text default 'active' check (account_status in ('active','suspended','deleted')),
  created_at        timestamptz default now(),
  last_active_at    timestamptz default now()
);

alter table public.profiles enable row level security;

-- Profiles are publicly readable (teams need to find players) but only the
-- owner may update their own row.
create policy profiles_select_public on public.profiles
  for select using (true);

create policy profiles_update_own on public.profiles
  for update using (auth.uid() = user_id);

-- Auto-provision a profile row on signup. Seeds display_name from the OAuth
-- full_name when present, else the email local-part. username stays null until
-- onboarding, which is exactly the signal the router's onboarding gate reads.
create or replace function public.handle_new_user() returns trigger as $$
begin
  insert into public.profiles (user_id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)));
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
