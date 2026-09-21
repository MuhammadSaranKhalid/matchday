-- Migration file: 20260101000501_notification_preferences.sql

-- 0501 · notification_preferences — per-user, per-category, per-channel
-- Design + decision log: docs/notifications-design.md
--
-- Granularity is CATEGORY, not type. Per-type switches were considered and
-- rejected: the settings screen would then grow every time a type is added,
-- which defeats the point of making types data. A user's actual complaint is
-- "stop pushing me about tournaments", not "stop pushing me about
-- tournament.registration.declined". Muting one specific noisy entity is the
-- other half of that, and lives in notification_mutes (0502).
--
-- AN ABSENT ROW MEANS "USE THE TYPE'S default_channels". That is the whole
-- design of this table:
--   - a new user needs no backfill,
--   - a new CATEGORY needs no backfill,
--   - and the default can be changed later by editing notification_types,
--     which correctly leaves anyone who made an explicit choice alone.
-- Seeding a full matrix per user would have frozen every default at signup.
--
-- Rows are only ever written when the user actually flips a switch.

-- Section: Tables and constraints

create table public.notification_preferences(
  user_id    uuid not null references public.profiles(user_id) on delete cascade,
  category   text not null references public.notification_categories(key) on delete cascade,
  channel    text not null check (channel in ('inapp', 'push')),
  enabled    boolean not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, category, channel)
);

-- Section: Indexes

-- user_id is the PK's leading column, so it is already indexed.
-- Advisor 0001 — the other FK needs its own index.
create index notification_preferences_category on public.notification_preferences(category);

-- Section: Triggers

create trigger notification_preferences_set_updated_at
  before update on public.notification_preferences for each row
  execute function public.set_updated_at();

-- Section: Enable row-level security

-- RLS — a user reads and writes only their own preferences. notify() reads
-- this table from a SECURITY DEFINER function, so it is unaffected.
--
-- Separate policies per command rather than one FOR ALL: advisor 0006 counts
-- permissive policies per (table, command, role), and one-per-command keeps
-- each expression readable. Every write policy carries WITH CHECK so a user
-- cannot update a row into someone else's name.
alter table public.notification_preferences enable row level security;

-- Section: Policies

create policy "notification_preferences_select_self" on public.notification_preferences
  for select to authenticated
  using ((
    select
      auth.uid()) = user_id);

create policy "notification_preferences_insert_self" on public.notification_preferences
  for insert to authenticated
  with check ((
    select
      auth.uid()) = user_id);

create policy "notification_preferences_update_self" on public.notification_preferences
  for update to authenticated
  using ((
    select
      auth.uid()) = user_id)
  with check ((
    select
      auth.uid()) = user_id);

create policy "notification_preferences_delete_self" on public.notification_preferences
  for delete to authenticated
  using ((
    select
      auth.uid()) = user_id);

-- Section: Permissions

revoke all on public.notification_preferences from anon, authenticated;

grant select, insert, update, delete on public.notification_preferences to authenticated;

grant all on public.notification_preferences to service_role;
