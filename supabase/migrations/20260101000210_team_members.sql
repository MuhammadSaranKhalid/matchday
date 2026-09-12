-- =============================================================================
-- 0210 · team_members — membership facts
-- =============================================================================
-- Spec §2.4, §2.6, §2.9. Memberships connecting users (or unclaimed
-- placeholders) to teams — and, since 2026-09-11, the roles they hold and the
-- one function that answers every "may they?" question.
--
-- ⭐ REWRITTEN 2026-09-11. Design + decision log: docs/team-roles-design.md.
--
-- What changed and why it had to:
--
--   `team_members.role` was a SINGLE COLUMN, so a team's owner could not also
--   be recorded as its captain — setting role='captain' would stop them being
--   the owner. That is the normal case in mohalla cricket, not an exception.
--   `_team_current_captain` papered over it by falling back to the owner, which
--   meant the team page showed NO captain and the one-captain index never
--   fired, so a second captain could be added. A manager who captained had no
--   fallback at all and simply could not be represented.
--
--   Roles now live in `team_member_roles`, a pure many-to-many. A member holds
--   ANY number of roles. Exclusivity is the declared exception, as data:
--   `{owner, manager, player}` max 1 (role_exclusion_sets). `captain` is in no set, so
--   owner+captain just works.
--
-- Two rules that look alike and are not:
--   * "at most one of these roles per MEMBER"  — separation of duty, trigger.
--   * "at most one holder of this role per TEAM" — cardinality, partial index.
--   Only the second is race-free. Both are verified in the test suite.
--
-- Ownership has ONE home: the `owner` role. `teams.created_by` (renamed from
-- owner_id in 0200) is history and is never consulted for authorization.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- team_members — membership facts only.
-- -----------------------------------------------------------------------------
-- Polymorphic player reference: each row references EITHER profiles.user_id OR
-- unclaimed_players.unclaimed_id, never both, never neither (`player_ref_xor`).
--
-- What a member IS lives in team_member_roles. What is left here is: are they
-- on this team, since when, what number do they wear, do they play.
create table public.team_members (
  membership_id    uuid primary key default gen_random_uuid(),
  team_id          uuid not null
                       references public.teams(team_id) on delete cascade,
  user_id          uuid references public.profiles(user_id) on delete cascade,
  unclaimed_id     uuid references public.unclaimed_players(unclaimed_id) on delete cascade,
  jersey_number    integer
                    check (jersey_number is null or jersey_number between 0 and 999),
  -- Separates "runs the team" from "plays for the team". The club secretary who
  -- never bats is in_squad = false: authority, but not in the Squad tab, not
  -- counted against max_squad_size, not selectable in an XI.
  in_squad         boolean not null default true,
  joined_at        timestamptz not null default now(),
  left_at          timestamptz,
  status           public.member_status not null default 'active',
  is_primary       boolean not null default false,
  added_by         uuid
                       references public.profiles(user_id) on delete set null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),

  constraint player_ref_xor check (num_nonnulls(user_id, unclaimed_id) = 1),
  constraint left_at_for_inactive check (
    (status = 'active' and left_at is null)
    or (status in ('inactive', 'removed') and left_at is not null)
  ),
  constraint unclaimed_plays check (unclaimed_id is null or in_squad),

  -- Redundant given the PK, but a composite FK target must be UNIQUE. This is
  -- what lets team_member_roles carry team_id as a real column — needed for the
  -- per-team singleton index — without it being free to drift.
  unique (membership_id, team_id)
);

create unique index team_members_unique_active_user
  on public.team_members (team_id, user_id)
  where status = 'active' and user_id is not null;

create unique index team_members_unique_active_unclaimed
  on public.team_members (team_id, unclaimed_id)
  where status = 'active' and unclaimed_id is not null;

create unique index team_members_unique_jersey
  on public.team_members (team_id, jersey_number)
  where status = 'active' and jersey_number is not null;

create unique index team_members_unique_primary_per_user
  on public.team_members (user_id)
  where is_primary = true and status = 'active' and user_id is not null;

create index team_members_team       on public.team_members (team_id);
create index team_members_user       on public.team_members (user_id)
  where user_id is not null;
create index team_members_unclaimed  on public.team_members (unclaimed_id)
  where unclaimed_id is not null;
create index idx_team_members_added_by on public.team_members (added_by);

create trigger team_members_set_updated_at
  before update on public.team_members
  for each row execute function public.set_updated_at();



alter table public.team_members enable row level security;

-- Role assignment and policies depend on team_member_roles and can();
-- they are installed in 20260101000212_team_authorization.sql.
