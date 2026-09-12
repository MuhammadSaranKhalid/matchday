# Team authorization — roles, permissions and grants as data

**Status:** accepted and implemented 2026-09-11. Supersedes the single-column
role ladder of 2026-09-10, which in turn superseded the `managers uuid[]` model.

**Scope:** teams and matches. Tournaments still use `created_by` +
`organizers uuid[]` + `is_tournament_organizer()` — see §10.

---

## 1 · The two problems this replaces

### 1.1 The modelling error: a person is more than one thing

`team_members.role` was a single column, so **an owner could not also be the
captain**. That is the normal case in mohalla cricket, not an exception.

Setting `role='captain'` on the owner would stop them being the owner, trip the
one-owner index and strand the team. The fallback
`_team_current_captain = coalesce(captain row, teams.owner_id)` hid this rather
than fixing it: the team page showed **no captain**, and because no
`role='captain'` row existed, the one-captain index never fired — so somebody
*else* could be marked captain too, giving two captains in reality and one in
the index. A **manager** who captained had no fallback at all and simply could
not be represented.

### 1.2 The policy was code, in two places

Authority was `role >= 'manager'` compiled into ~45 SQL call sites and 14 Dart
getters. Letting captains send challenges meant editing a migration, editing
Dart, and shipping — with the two free to drift.

And `match_officials.scorer` sat **outside** it entirely, as a special case
inside `_can_score_innings`. A second authorization system, which is exactly
what the previous pass existed to remove.

---

## 2 · The shape

```
roles                     what a person can BE           (rows, not an enum)
role_exclusion_sets       "at most N of these roles      (NIST Static
role_exclusion_members     per member"                    Separation of Duty)
permissions               what can be DONE
permission_scopes         …and on which kind of entity
role_permissions          THE MATRIX — globally, or overridden per team
grants                    a permission handed to ONE person on ONE resource
team_member_roles         who holds what                 (pure many-to-many)

can(scope, entity, permission)     the only question anyone asks
```

Each catalogue table has its own migration, from `20260101000201_roles.sql`
through `20260101000207_grants.sql`. Memberships live in
`20260101000210_team_members.sql`, assignments in
`20260101000211_team_member_roles.sql`, and `can()`, shared predicates, RPCs
and dependent policies in `20260101000212_team_authorization.sql`. That
zero-table integration file follows both memberships and assignments so its
SQL functions and policies have all their dependencies at CREATE time.

---

## 3 · A member holds any number of roles

`team_member_roles` is a plain junction. **Roles combine freely; exclusivity is
the declared exception**, expressed as data:

> **NIST SSD** — "a collection of pairs of a role set and an associated
> cardinality … the cardinality of its subsets that cannot have common users."

One rule is seeded: `{owner, manager, player}`, max 1. `captain` is in no set.

```
Saran   → owner            runs the club
        → captain          …and leads the eleven      ← impossible before
        → coach            …and any future role, freely
Rizwan  → player
        → captain          a plain player captains the side
```

An earlier draft gave each role a `category` column (`authority` / `matchday`)
and enforced `unique (membership_id, category)`. That bakes a taxonomy into the
schema and caps a member at two roles; `category` was only ever the special case
*set = {owner, manager, player}, N = 1*. What survives of it is
`roles.display_group`, a nullable label for grouping the permissions grid, which
**carries no rule**.

### Two rules that look alike and are not

| rule | scope | enforced by | race-free |
|---|---|---|---|
| at most one of these roles per **member** | separation of duty | trigger + `FOR UPDATE` on the membership | no — but locked |
| at most one holder of this role per **team** (owner, captain) | cardinality | `unique (team_id, scope, role_key) where is_singleton` | **yes** |

`is_singleton` and `team_id` are denormalised onto the junction *on purpose*: a
partial-index predicate must be IMMUTABLE and cannot read `roles`. Composite FKs
keep both honest — a row that lies about `is_singleton`, or whose `team_id`
disagrees with its membership, is rejected `23503`. Verified live on PG17.

> `membership_id` deliberately carries **no FK of its own**. The composite
> `(membership_id, team_id)` already enforces existence, agreement and the
> cascade; a second single-column FK made PostgREST ambiguous (`PGRST201`) when
> embedding roles into a roster query.

### Creation assigns exactly one role

There is no universal "everyone starts as `player`" trigger — that would make
`create_owner_membership` produce `player + owner` and violate the exclusion set
on the very first team. Instead the creating path *declares its intent* through
a transaction-local setting, and one trigger attaches exactly that role:

| path | initial role |
|---|---|
| `create_owner_membership` (AFTER INSERT on `teams`) | `owner` |
| `add_team_member()` | as asked (default `player`) |
| `add_unclaimed_team_member()` | `player` — the only role `allows_unclaimed` |
| a direct insert (seeds, superuser) | `player` |

---

## 4 · Ownership has one home

```
teams.created_by   immutable history: who made this team. NEVER authorization.
the `owner` role   canonical. Who runs it, right now.
```

`teams.owner_id` is gone. Keeping it alongside an `owner` role would be the same
two-sources-of-truth defect this redesign exists to remove. Consequences:

- `teams_insert_self_owner` checks `created_by` (a value must exist at INSERT
  time, before any membership row can).
- `_team_current_captain` falls back to **the holder of the `owner` role**, not
  `created_by` — a creator may have left.
- `chats.sql` (team chat's first admin) and `teams_search.sql` (geo backfill
  from the creator's profile) are genuine *creator* semantics and read
  `created_by`; they are more correct for it.
- `delete_user` succession promotes the longest-tenured manager into the `owner`
  role and archives a team that has none. `created_by` is untouched.

**Exactly one owner.** `is_singleton` prevents a *second*; nothing prevents
*zero*, so `revoke_team_role` refuses `owner` outright. Ownership moves only via
`transfer_team_ownership()` or the succession path above.

---

## 5 · Permissions, and the scope trap

A permission is **not bound to one entity type**. `match.score` is legitimately
held either through a team role (the batting side's captain) or through a direct
grant on one match (a nominated scorer). So `permissions` has no `scope` column;
`permission_scopes` lists the entity types each may be *evaluated against*:

```
match.score   → team     held via a team role
match.score   → match    held via a grant on ONE match
team.disband  → team
```

Both `role_permissions` and `grants` carry an FK to `(permission_key, scope)`,
which makes **scope coherence structural** rather than a rule someone has to
remember. This is what resolves the contradiction between scope validation and
the scoring model — an earlier draft had both and they were mutually exclusive.

`resource` and `action` are load-bearing, not decoration: they are the rows and
columns of the permissions grid a team owner will eventually edit.

### The 15 keys

`team.roster.write` · `team.roster.role` · `team.staff.appoint`† ·
`team.invite` · `team.profile.write` · `team.post` · `team.challenge.send` ·
`team.tournament.enter` · `team.contact.view` · `team.transfer`† ·
`team.disband`† · `team.permissions.manage`† · `match.lineup.set` ·
`match.score` · `match.official.assign`

† `min_rank 40` — owner only. Editing a team's matrix is itself a permission.

---

## 6 · The matrix, and per-team overrides

`team_id IS NULL` rows are the shared default. A team's rows are **deltas**, so
a team that changes one thing need not restate the rest:

```
effective(team, role) = team row if present, else global row, else deny
```

```
team_id   role_key  permission_key       granted
NULL      manager   team.challenge.send  true     ← default, every team
lions     captain   team.challenge.send  true     ← Lyari Lions only
kings     manager   team.post            false    ← Kings revoked it
```

`unique nulls not distinct` (PG15+; this project is PG17) keeps exactly one
global row per combination — without it Postgres treats every NULL as distinct
and duplicate globals would be allowed.

**There is no inheritance.** A manager holding `match.score` holds it because a
row says so, not because rank 30 > 20. The seeded matrix therefore repeats
itself, which is the right trade for a screen whose whole job is to show what is
true: every tick is a fact, never an implication.

`role_permissions` is **user-writable**, which it was not before, so it carries
real RLS — global rows readable by all and writable by nobody; team rows
readable by that team and writable only by `team.permissions.manage`.

---

## 7 · `can()` — order matters

```
can(scope, entity, permission)
  0. VALIDATE (permission, scope) is registered   → else FALSE, fail closed
  1. a live direct grant, of a direct_grantable key
  2. the owner short-circuit
  3. role-derived: union over the member's roles of effective(entity, role)
```

**Step 0 is not optional.** With the owner short-circuit first, a typo'd or
wrong-scope key — `can('team', t, 'team.disbnad')` — returns TRUE for every
owner. A misspelling must silently DENY, never silently GRANT.

`stable` + `security definer` + `set search_path = public, pg_temp`, with
`revoke all … from public` at the declaration site. These matter more here than
anywhere else in the schema: `can()` **is** the RLS boundary.

Every policy wraps it as `(select can(...))` — advisor 0003 — so it is an
InitPlan evaluated **once per statement, not once per row**.

> Anon never calls it. The anon-facing read policies are split by role and use
> only the `privacy = 'public'` branch, so no `SECURITY DEFINER` function is
> reachable by `anon` (advisor 0028/0029, enforced by the last-migration sweep).

### Direct grants are delegation, not a back door

`min_rank` floors the *role* path. A direct grant has no role, so
`permissions.direct_grantable` gates it — `match.score` and
`match.official.assign` are grantable; `team.disband`, `team.transfer`,
`team.permissions.manage` and `team.staff.appoint` are not. Enforced twice: a
trigger rejects a non-grantable key at write time, and `can()` re-checks at read
time so clearing the flag revokes existing grants immediately.

### Scoring stops being a special case

```sql
_can_score_innings =
     (match_type = 'practice' and created_by = auth.uid())
  or can('team',  batting_team_id, 'match.score')
  or can('match', match_id,        'match.score')
```

The practice branch must survive: a practice match has no opposition to hand
control to at the innings break, so its creator scores both innings.

`match_officials` keeps its rows (the record of who officiated, shown on the
scorecard, and it covers umpires who need no permission); a trigger mirrors
`role='scorer'` into `grants`. That is what finally makes the organiser
console's offer to "revoke scoring rights or take over the match" true.

---

## 8 · Role mutation

`grant_team_role(membership_id, role_key)` /
`revoke_team_role(membership_id, role_key)` — roles are added and removed
individually, not swapped within a slot.

- **Granting a role that shares an exclusion set with one they hold REPLACES
  it.** Making someone a manager is exactly making them stop being a player.
  Doing it inside the RPC matters: the two statements must be one transaction,
  and leaving that to every call site is how you get a half-promoted member.
- **Revoking someone's last role leaves them a `player`**, not roleless. "Un-
  captain them" never means "remove them from the team".
- The invariant uses the member's **max rank** across their roles: you may never
  grant a role at or above your own rank, nor act on a member whose max rank is
  at or above yours.

`team_members` INSERT is RPC-only; `team_member_roles` writes are RPC-only.

---

## 9 · Client model

`myTeamPermissionsProvider` is **not built yet** — that is Step 3. Today the
client still asks for roles (`myTeamRolesProvider`) and gates on them.

- `TeamMember.roles` is a `Set<String>` of role **keys**, not an enum. Roles are
  rows now, so a closed enum cannot enumerate them: the moment someone inserts
  "Coach", `MemberRole.fromWire` would coerce it to `player` and the roster
  would lie. `MemberRole` survives for the four the UI reasons about;
  `topRole` picks the highest for a single chip.
- `Team.createdBy` replaces `Team.ownerId`, and is display/history only.
- **Supabase realtime cannot join.** `listMembers()` embeds
  `team_member_roles(role_key)`, but `watchMembers()` cannot — so roles have
  their own stream (`watchMemberRoles()`) and are stitched in the repository,
  the same shape `watchMyTeams` already uses for teams + members.

**Role is for display; permissions are for authorization.** Keep the role for
the C badge, the managers list and roster chips. Everything that gates an action
moves to the permission set in Step 3.

---

## 10 · Follow-up

- **Step 2** — replace the ~45 `is_team_manager` / `is_team_captain` call sites
  with the specific key that fits, one feature at a time. Those two are **shims
  over `can()`** today, which is what let the schema land without touching them.
- **Step 3** — `my_team_permissions()` RPC and `myTeamPermissionsProvider`;
  `TeamRelationship` drops its `can*` getters.
- **Step 4** — delete the shims.
- **The permissions screen** — a team owner tuning their own matrix. Schema and
  `can()` support it already; what is left is UI writing `role_permissions` rows
  with `team_id` set, gated on `team.permissions.manage`. The grid's rows and
  columns come from `permissions.resource` / `.action`.
- **Tournaments** reuse the catalogue and `can()` at `scope='tournament'`, but
  **do** need their own role-assignment relation: `team_member_roles` is keyed
  on a team membership and has nowhere to hang a tournament role. An earlier
  draft claimed "no new tables"; that was wrong and is withdrawn.
- **Clubs** (`docs/club-feature-design.md`) become a third scope.
- **Per-team custom roles** if teams ask. The `roles` PK gains a nullable
  `team_id`; nothing else in the engine changes.
