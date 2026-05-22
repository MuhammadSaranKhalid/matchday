-- 002_username_index.sql — case-insensitive username uniqueness + availability RPC.

-- Uniqueness is enforced on lower(username) so "Ahmed" and "ahmed" can't both
-- exist. (The client also lowercases before saving — this is the backstop.)
create unique index profiles_username_idx on public.profiles (lower(username));

-- Called from onboarding to show the live ✓ available / ✗ taken indicator.
-- SECURITY: returns only a boolean, never leaks which usernames exist beyond
-- the yes/no the user is actively probing.
create or replace function public.check_username_available(p_username text)
returns boolean as $$
  select not exists (
    select 1 from public.profiles where lower(username) = lower(p_username)
  );
$$ language sql stable;
