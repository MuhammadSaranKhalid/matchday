-- =============================================================================
-- Migration: 20260101000490_notification_categories.sql
-- =============================================================================

-- 0490 · notification_categories — the preference grouping
-- Design + decision log: docs/notifications-design.md
--
-- Six rows. They exist for exactly two reasons:
--
--   1. They are the unit a USER toggles. Per-type switches were rejected: the
--      settings screen would then grow with every type added, which fights the
--      whole point of making types data. A user says "no tournament pushes",
--      not "no tournament.registration.declined pushes".
--
--   2. They are the first segment of every notification type key, enforced by
--      a CHECK on notification_types. `team.join.requested` IS in the `team`
--      category — the prefix cannot drift from the column, because it is not
--      allowed to be a separate fact.
--
-- Keys are SINGULAR (`team`, not `teams`) because the key is a prefix of a
-- type key, and `team.join.requested` reads correctly while
-- `teams.join.requested` does not. `name` carries the plural for display.
--
-- Declared before notification_types (0491) because that table FKs to this
-- one, and before notifications (0500) which FKs to the types. Nothing here
-- depends on anything, which is why it can be first.

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.notification_categories (
  key         text primary key check (key ~ '^[a-z]+$'),
  name        text not null,
  description text,
  sort_order  integer not null default 0
);

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

-- RLS — world-readable catalogue, writable only by migrations / service_role.
-- Same posture as public.roles (0201): the client needs to render a settings
-- screen from this, and there is nothing private in it.
alter table public.notification_categories enable row level security;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

create policy "notification_categories_read_all"
  on public.notification_categories
  for select
  to anon, authenticated
  using (true);

-- -----------------------------------------------------------------------------
-- Data changes
-- -----------------------------------------------------------------------------

-- The catalogue.
insert into public.notification_categories (key, name, description, sort_order)
values
  ('match', 'Matches', 'Challenges, toss, start and results', 10),
  ('team', 'Teams', 'Invites, join requests, roles and posts', 20),
  ('tournament', 'Tournaments', 'Registrations, fixtures and announcements', 30),
  ('chat', 'Messages', 'Direct messages and team chat', 40),
  ('social', 'Social', 'Follows, likes, comments and mentions', 50),
  ('system', 'System', 'Milestones and account notices', 60);

-- -----------------------------------------------------------------------------
-- Permissions
-- -----------------------------------------------------------------------------

revoke all on public.notification_categories from anon, authenticated;

grant select on public.notification_categories to anon, authenticated;

grant all on public.notification_categories to service_role;
