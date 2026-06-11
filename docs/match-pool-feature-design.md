# Open Match Pool — Design Document

> **Status:** Draft for review · **Date:** 2026-06-11 · **Scope:** v1 = browsable, geo-scoped pool of open match challenges (cricket teams looking for a match).
> **Owner:** @MuhammadSaranKhalid
>
> This document is the single source of truth for the open-match-pool feature.
> It is written to be reviewed end-to-end and have gaps surfaced. Each major
> decision carries its rationale so reviewers can challenge the *reasoning*, not just
> the conclusion. Nothing here has been built yet.
>
> ⚠️ **Three forks are still pending your confirmation** ([§4 Decisions log](#4-decisions-log)
> and [§23 Open questions](#23-open-questions-for-review)). I've written this doc against
> my **recommended** defaults so it reads as a complete plan, but the three rows in §4
> tagged **PENDING** can flip the response model, the listing's location source, and the
> scoping shape — confirm or override those before this becomes tickets.

---

## Table of contents

1. [Problem statement](#1-problem-statement)
2. [Goals & non-goals](#2-goals--non-goals)
3. [The core insight: it's a discovery surface, not a new subsystem](#3-the-core-insight-its-a-discovery-surface-not-a-new-subsystem)
4. [Decisions log](#4-decisions-log)
5. [Current state of the codebase](#5-current-state-of-the-codebase)
6. [Architecture overview](#6-architecture-overview)
7. [Data model & schema changes](#7-data-model--schema-changes)
8. [Listing location acquisition](#8-listing-location-acquisition)
9. [The discovery service (edge function)](#9-the-discovery-service-edge-function)
10. [Filters & ranking](#10-filters--ranking)
11. [Geo model (reused from team search)](#11-geo-model-reused-from-team-search)
12. [Response & accept flow](#12-response--accept-flow)
13. [Notifications wiring](#13-notifications-wiring)
14. [Visibility & RLS policy](#14-visibility--rls-policy)
15. [Flutter layers (clean architecture)](#15-flutter-layers-clean-architecture)
16. [Presentation & UX](#16-presentation--ux)
17. [Security & privacy](#17-security--privacy)
18. [Performance & scale](#18-performance--scale)
19. [Edge cases catalogue](#19-edge-cases-catalogue)
20. [Build plan (5 slices)](#20-build-plan-5-slices)
21. [Test plan](#21-test-plan)
22. [Out of scope / future work](#22-out-of-scope--future-work)
23. [Open questions for review](#23-open-questions-for-review)
24. [References](#24-references)

---

## 1. Problem statement

Today, a team can only get a match by **directly targeting** another team — by going to
their profile or searching the team and sending a match request. That works when the
asker knows whom they want to play, but it fails the more common case for amateur
cricket:

> *"We're up for a match this weekend in our area — who's around and wants in?"*

There's no place to **post that openness and have nearby teams find it**. The user
described it perfectly: an **open pool** where any team can post a "looking for a match"
listing, and other teams browsing the pool see the listings — **filtered to their own
area** ("Lahore opens the pool, sees Lahore listings"). The same shape works at every
granularity — a Karachi-side team sees Karachi listings; a village team sees village
listings.

The feature is fundamentally **discovery + geographic scoping**, applied to *match
intents* instead of *teams*.

---

## 2. Goals & non-goals

### Goals (v1)

- A team can **post an open challenge** (no specific opponent) carrying their preferred
  date, format, and a brief note.
- Other teams can **browse the pool**, scoped by location, with filters (format, date,
  ball type).
- A team can **respond** to an open challenge; the poster reviews responders and
  **picks one**, which materializes the actual `matches` row via the existing accept
  flow.
- Notifications fire on response (to the poster) and on selection (to the responder).
- Listings expire automatically; only `pending` + non-expired listings appear in the pool.
- Reuse the existing match-request entity, accept flow, and notifications path — minimum
  net-new surface.

### Non-goals (v1)

- **Tournament invites** (different shape: knockout slots, organizer-driven).
- **Saved searches / push for new listings nearby** ("alert me when a Lahore T20
  appears") — natural follow-up.
- **Skill/competitiveness levels, ratings, or matchmaking algorithms.**
- **Cross-region or cross-country pools** (country-bounded by default).
- **Public/anonymous responding** — only authenticated team managers can respond.
- **In-pool chat/negotiation** beyond the existing counter mechanism.

---

## 3. The core insight: it's a discovery surface, not a new subsystem

The codebase audit revealed something crucial: **your data model already supports open
challenges**. `match_requests.to_team_id` is **nullable**, and `NULL = open challenge`.
The existing `sendMatchChallenge(toTeamId: null)` creates one, and
`acceptMatchChallenge(... toTeamId: <accepter's team>)` materializes the actual `matches`
row. The send → accept → match flow is **already wired** for open requests
([`match_requests_remote_datasource.dart:32`](../lib/features/matches/data/datasources/match_requests_remote_datasource.dart#L32),
[`matches_repository.dart:76`](../lib/features/matches/domain/repositories/matches_repository.dart#L76)).

What's missing is exactly the two things the user described:

1. **It's not browsable.** Today open challenges are reachable *only* via a 6-digit share
   code (in-person flow). RLS hides them from everyone else, and the insert-notification
   trigger explicitly skips open requests ([`20260101000600_match_requests.sql:840`](../supabase/migrations/20260101000600_match_requests.sql)).
2. **It's not location-scoped.** `match_requests` has no location at all — only a
   free-text `proposed_venue`.

So the pool is **(a) a location on the listing + (b) a discovery query + (c) a visibility
change + (d) a "respond" path on top of the existing send/accept/notify machinery**. The
big subsystems (entity, accept, materialization, notifications broadcast) are reuse.

This also makes the geo half **the same model as team search** — list open challenges
where `ST_DWithin(location_point, my_center, radius)` + city facet + filters. The pool
and search share the geo backbone; every step of the geo foundation serves both.

---

## 4. Decisions log

| # | Decision | Choice | Rationale |
|---|---|---|---|
| D1 ⚠️ **PENDING** | Response model when a team wants in on an open listing | **Poster picks from responders** (interested teams "apply"; poster reviews and confirms one → match materializes) | Open boards attract spam under "first-come accept"; poster control + fairer matchmaking. Adds a small responses sub-structure but reuses the existing `acceptMatchChallenge(toTeamId, toTeamXi)` for materialization. |
| D2 ⚠️ **PENDING** | Listing's location source | **Posting team's home location** (inherit `teams.location_point` at insert time) | Single source of truth, consistent with team search, zero extra UI per listing. Matches the user's "where we usually play" framing. **Requires teams to have coordinates** (depends on team-search Slice 1). |
| D3 ⚠️ **PENDING** | Geographic scoping for the viewer | **Both — near-me proximity + city facet** | Exact reuse of the team-search model. Robust for villages (proximity) and intuitive for cities (facet chips from own data). |
| D4 | Visibility model | Open + active listings **world-readable** in RLS; discovery scoped via `list-open-challenges` edge fn | Mirrors the matches table pattern (world-readable + edge-fn scoping per the `list-my-matches` precedent). An open challenge is a *public board posting* by intent. |
| D5 | Where the discovery query runs | **Edge function** `list-open-challenges` (promote to RPC later) | Dev-phase convention — iterate query shape without a migration per change. |
| D6 | Notifications | Reuse the existing `notifications` broadcast (`user:<uid>:notifications`); add a new type `open_challenge_response` | Per the project convention: never add request-shaped tables to `supabase_realtime`. Existing decision-notification path covers acceptance/decline. |
| D7 | Listings carry **structured** location | `{city, district, province, postcode, lat, lng, country_code}` jsonb + generated `geography(point, 4326)` + GiST | Same shape and infrastructure as `profiles.location` and `teams.location`. Enables future hierarchy/PIN-based discovery for free. |
| D8 | Lifecycle | Reuse `proposal_expires_at` (existing 48 h timer); listings auto-leave the pool when status flips to `accepted`/`expired`/`cancelled` | Existing fields already model the lifecycle correctly. |
| D9 | Max active listings per team | 1 active open listing per team at a time (v1) | Reduces spam/list clutter; teams can post a fresh one when the previous resolves or expires. Tunable later. |
| D10 | IA placement — **decided 2026-06-11** | **The pool lives in the repurposed Matches tab** (primary sub-tab), which sits in the **center slot** of the final nav order **Home · Search · Matches · Messages · Pavilion**. The Matches tab is kept, not hidden; its mock Live/Upcoming/Recent content ships later as real public match browsing. Team search gets its own Search tab at slot 2 (the Profile tab is removed — see search doc D9); own profile moves behind the header avatar; Pavilion takes the rightmost "me" slot. | The pool is match-flavored discovery, so it belongs in Matches; the center slot is the prime thumb-reach/showcase position and goes to the app's killer feature. This gives the currently-unused tab a real purpose and avoids nav churn. Search and pool each get tab-level prominence as the app's core discovery loops. |

Decisions tagged **PENDING** are mirrored in [§23 Open questions](#23-open-questions-for-review).

---

## 5. Current state of the codebase

### What already exists ✅

- **Open challenge as data:** `match_requests.to_team_id` nullable;
  `NULL = open challenge` ([`match_request.dart:1-152`](../lib/features/matches/domain/entities/match_request.dart),
  [`20260101000600_match_requests.sql:70-156`](../supabase/migrations/20260101000600_match_requests.sql)).
- **Send flow:** `sendMatchChallenge(toTeamId: null, ...)` creates an open challenge
  ([`match_requests_remote_datasource.dart:32`](../lib/features/matches/data/datasources/match_requests_remote_datasource.dart#L32)).
  Edge function `send-match-request` mints a unique 6-digit code, mirrors validation,
  idempotent ([`supabase/functions/send-match-request/index.ts`](../supabase/functions/send-match-request/index.ts)).
- **Accept flow:** `acceptMatchChallenge(requestId, toTeamId, toTeamXi, ...)`
  materializes a `matches` row from the request's coalesced terms
  ([`matches_repository.dart:76`](../lib/features/matches/domain/repositories/matches_repository.dart#L76);
  RPC `accept_match_request` in migration 0600 lines 473–486).
- **Lifecycle timers:** `proposal_expires_at` (48 h), `counter_expires_at` (24 h),
  `code_expires_at` (24 h).
- **Counter / decline mechanics:** rich, with reason codes
  (`decline_reason: roster | format | busy | venue | no_interest | other`) and decision
  notes.
- **Notifications broadcast:** `user:<uid>:notifications` channel; two SECURITY DEFINER
  triggers (`notify_on_match_request_insert`, `notify_on_match_request_decision`) write to
  `notifications` and the trigger publishes to broadcast
  ([`notifications_remote_datasource.dart:38-98`](../lib/features/notifications/data/datasources/notifications_remote_datasource.dart#L38)).
- **Matches list scoping via edge fn:** the `list-my-matches` precedent — matches table is
  world-readable, scoping happens in the edge function. Same pattern we'll mirror for
  pool discovery ([`supabase/functions/list-my-matches/index.ts`](../supabase/functions/list-my-matches/index.ts)).
- **Geo capture pipeline** (just delivered in Slice 0 of search): clean `city` + structured
  `district`/`province`/`postcode` on profiles. Same shape will land on
  `match_requests.location`.
- **Realtime authorization** for broadcast channels ([`20260101000810_realtime_authorization.sql`](../supabase/migrations/20260101000810_realtime_authorization.sql)).

### What is missing ❌

- **`match_requests` has no location** — only a free-text `proposed_venue`. No
  `location_point`, no GiST index, nothing to anchor a pool to "Lahore."
- **No browsable view of open requests.** RLS allows only managers of either team to
  read; the insert-notification trigger explicitly **skips** open requests (line ~840 of
  the migration), so today an open challenge is genuinely invisible except via the
  6-digit code.
- **No "response" entity** distinct from accept. The current accept flow is the only
  pathway to surface an interested team — and it materializes the match in one shot. For
  a poster-picks model (D1) we need a lightweight "expressions of interest" sub-table.
- **No `open_challenge_response` notification type.** The two existing types are
  `match_request` (targeted insert) and `match_request_decision` (accept/decline).
- **No teams coordinates yet** (D2 dependency). `teams.location` exists as jsonb but
  carries only `city` today — same legacy bug the search-feature Slice 0 fixed for
  profiles. Slice 1 of team search will populate teams with coordinates; the pool depends
  on that step before listings can be located by inheriting team home.

---

## 6. Architecture overview

```
              ┌──────────────────────────────────────────────────────────┐
              │  Flutter — matches feature (clean architecture)           │
              │                                                           │
  Pool tab ─► │  OpenChallengePoolController                              │
              │    ├─ ref: locationRepository (device GPS for "near me") │
              │    └─ MatchesRepository.listOpenChallenges(...)           │
              │                              .respondToOpenChallenge(...)│
              │                              .listResponses(requestId)   │
              │                              .acceptOpenChallenge(       │
              │                                 requestId, responseId)   │
              └────────────┬─────────────────────────────────────────────┘
                           │ functions.invoke
                           ▼
              ┌──────────────────────────────────────────────────────────┐
              │  Edge functions                                           │
              │   list-open-challenges    (mode-select: q? center?       │
              │                            country? format? date?)        │
              │   respond-to-open-challenge   (new)                       │
              │   accept-match-request     (existing — picks a response)  │
              └────────────┬─────────────────────────────────────────────┘
                           │
                           ▼
              ┌──────────────────────────────────────────────────────────┐
              │  Postgres + PostGIS                                       │
              │   match_requests.location_point  (GiST geography)         │
              │   match_request_responses        (NEW table, D1)          │
              │   matches  (materialised on accept — existing)            │
              │   notify_on_*  triggers → notifications  broadcast        │
              └──────────────────────────────────────────────────────────┘

  Geo capture (autocomplete + GPS) is used ONLY in team-create (Slice 1 of
  search) for the team's home location; the pool inherits that location and
  never calls Google Places at browse-time.
```

The pool **never** calls Google Places at browse-time — listings inherit their location
from the posting team's home location (D2), so discovery is a pure Postgres query.

---

## 7. Data model & schema changes

> ⚠️ **Schema DDL must be applied to the correct deployed Supabase project** (per the
> prior 0511-on-wrong-project incident). Verify the project before applying.

### 7.1 Add structured location to `match_requests`

```sql
-- Extend the existing match_requests table.
alter table public.match_requests
  add column location jsonb,                                   -- nullable; null = "no location yet"
  add column location_point geography(point, 4326) generated always as (
    case
      when location ? 'lat' and location ? 'lng' then
        st_setsrid(
          st_makepoint(
            (location->>'lng')::double precision,
            (location->>'lat')::double precision
          ),
          4326
        )::geography
      else null
    end
  ) stored;

-- GiST for proximity; partial index on the hot set (only open + active listings).
create index match_requests_open_loc_gist
  on public.match_requests using gist (location_point)
  where to_team_id is null
    and status in ('pending', 'countered');

-- B-tree on city for cheap facets (mirrors teams_city).
create index match_requests_open_city
  on public.match_requests ((location->>'city'))
  where to_team_id is null
    and status in ('pending', 'countered');
```

`location` shape is identical to `profiles.location` / `teams.location` post-Slice 0:
```jsonc
{
  "label": "Gulberg III, Lahore",   // display string (full/human)
  "city":  "Lahore",                 // locality only — facet key
  "district": "Lahore",              // optional, admin_2 (future hierarchy)
  "province": "Punjab",              // optional, admin_1 (future hierarchy)
  "postcode": "54000",               // optional, postal_code (future PIN search)
  "place_id": "ChIJ...",             // optional Google Places id (provenance)
  "lat": 31.5204, "lng": 74.3587,    // drive location_point
  "country_code": "PK"               // ISO 3166-1 alpha-2 (coarse bound)
}
```

### 7.2 Populate listing location from the posting team (D2)

Per **D2** (posting team's home location), populate `match_requests.location` via a
`BEFORE INSERT` trigger that copies from the team:

```sql
create or replace function public.set_match_request_location_from_team()
returns trigger language plpgsql security definer as $$
declare
  team_loc jsonb;
begin
  -- Only populate for open challenges (to_team_id is null) and only when the
  -- caller didn't supply a location explicitly (future override).
  if NEW.location is null and NEW.from_team_id is not null then
    select location into team_loc from public.teams where team_id = NEW.from_team_id;
    if team_loc is not null then
      NEW.location := team_loc;
    end if;
  end if;
  return NEW;
end;
$$;

create trigger match_requests_set_location
  before insert on public.match_requests
  for each row execute function public.set_match_request_location_from_team();
```

> **Dependency:** this only meaningfully populates `lat`/`lng` once **team-search
> Slice 1** lands and teams have coordinates. Pool design and schema can proceed in
> parallel, but discovery returns empty rows until then.

### 7.3 New table `match_request_responses` (D1 — poster picks)

```sql
create type public.match_response_status as enum (
  'pending',   -- responder expressed interest, awaiting poster's pick
  'withdrawn', -- responder pulled back
  'declined',  -- poster passed on this responder
  'chosen'     -- poster picked this responder → match materialised
);

create table public.match_request_responses (
  response_id        uuid primary key default gen_random_uuid(),
  request_id         uuid not null references public.match_requests(request_id)
                          on delete cascade,
  responder_team_id  uuid not null references public.teams(team_id)
                          on delete cascade,
  responder_xi       uuid[] not null default '{}',
  responder_keeper_id uuid references public.profiles(user_id)
                          on delete set null,
  responded_by       uuid references public.profiles(user_id) on delete set null,
  message            text check (message is null or length(message) <= 500),
  status             public.match_response_status not null default 'pending',
  decided_at         timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),

  -- A team responds to a given listing at most once.
  unique (request_id, responder_team_id)
);

create index match_request_responses_by_request
  on public.match_request_responses (request_id, status, created_at desc);

create index match_request_responses_by_responder
  on public.match_request_responses (responder_team_id, status, created_at desc);

create trigger match_request_responses_updated_at
  before update on public.match_request_responses
  for each row execute function public.set_updated_at();
```

### 7.4 One-active-listing-per-team constraint (D9)

A team has at most one active open listing:

```sql
create unique index match_requests_one_active_open_per_team
  on public.match_requests (from_team_id)
  where to_team_id is null
    and status in ('pending', 'countered');
```

A new `sendMatchChallenge(toTeamId: null, ...)` while an active open listing exists →
returns the existing one (idempotent per existing edge-fn behaviour) or surfaces a
validation error. We'll keep the existing idempotency.

---

## 8. Listing location acquisition

**Per D2:** the listing inherits the posting team's `teams.location` at insert time, via
the trigger in §7.2. No new UI on the listing-create flow for location.

**The end-to-end chain:**

```
team-create (search Slice 1)  →  teams.location_point populated
                                       │
                                       ▼
sendMatchChallenge(toTeamId: null)  →  trigger copies team.location into match_request.location
                                       │
                                       ▼
location_point generated column       →  GiST index sees the listing
                                       │
                                       ▼
list-open-challenges (edge fn)         →  ST_DWithin returns it to nearby teams
```

A team without coordinates yet still produces a listing (location null) — but it won't
appear in proximity-scoped browse (only in a hypothetical "show all unscoped" mode, which
v1 doesn't ship). This is the same null-coord behaviour as team search, and a strong
motivator for completing search Slice 1 alongside the pool.

> If you flip D2 to **Per-listing location**, the listing form acquires a "Where do you
> want to play?" field (reusing the existing `location/` autocomplete) and the trigger
> respects a caller-provided `location`.

---

## 9. The discovery service (edge function)

A `list-open-challenges` edge function. Mirrors `list-my-matches` for shape and the
`search-teams` design from the team-search doc for the geo query.

### 9.1 Request / response contract

```jsonc
// POST /functions/v1/list-open-challenges
{
  "lat":         31.52,         // optional; with lng → search center
  "lng":         74.36,         // optional
  "radiusKm":    100,           // optional, default 100 (coarse candidate bound)
  "scaleKm":     15,            // optional, default 15 (decay half-scale)
  "countryCode": "PK",          // optional; default = caller's profile country
  "format":      "t20",         // optional: 'limited' | 't20' | 'practice' | etc.
  "ballType":    "tape",        // optional: 'leather' | 'tape' | 'tennis'
  "dateFrom":    "2026-06-14",  // optional ISO; filter by proposed_start_time
  "dateTo":      "2026-06-16",  // optional
  "city":        "Lahore",      // optional, exact-locality filter (facet)
  "limit":       50,            // optional, default 50, max 100
  "offset":      0
}

// → 200
[
  {
    "request_id":          "uuid",
    "from_team_id":        "uuid",
    "from_team_name":      "Lahore Tigers XI",
    "from_team_logo_url":  "https://...",
    "city":                "Lahore",
    "proposed_start_time": "2026-06-15T14:00:00Z",
    "proposed_venue":      "Model Town Ground",
    "proposed_format":     { "oversPerInnings": 20, "playersPerTeam": 11, "ballType": "tape", ... },
    "message":             "Friendly game this Saturday",
    "players_per_side":    11,
    "proposal_expires_at": "2026-06-12T14:00:00Z",
    "distance_km":         2.3,
    "score":               0.78,
    "response_count":      4         // count of pending responses; null/0 for viewer to know if it's hot
  }
]
```

### 9.2 SQL (executed in the edge function)

```sql
-- :lat, :lng, :radius_m, :scale_km, :country, :format, :ball_type, :date_from,
-- :date_to, :city, :limit, :offset bound by the edge fn.
-- :center := case when :lat is not null and :lng is not null
--                 then st_setsrid(st_makepoint(:lng, :lat), 4326)::geography end
with response_counts as (
  select request_id, count(*)::int as n
  from public.match_request_responses
  where status = 'pending'
  group by request_id
)
select
  r.request_id,
  r.from_team_id,
  t.team_name           as from_team_name,
  t.logo_url            as from_team_logo_url,
  r.location->>'city'   as city,
  r.proposed_start_time,
  r.proposed_venue,
  r.proposed_format,
  r.message,
  r.players_per_side,
  r.proposal_expires_at,
  case when :center is not null and r.location_point is not null
       then st_distance(r.location_point, :center) / 1000.0 end as distance_km,
  coalesce(rc.n, 0)     as response_count,
  -- Score: distance decay + recency boost. No text relevance in pool v1.
  (
      0.7 * coalesce(
              1.0 / (1.0 + (st_distance(r.location_point, :center) / 1000.0) / :scale_km),
              0)
    + 0.3 * (1.0 / (1.0 + extract(epoch from (now() - r.created_at)) / 86400.0))
  ) as score
from public.match_requests r
join public.teams t on t.team_id = r.from_team_id
left join response_counts rc on rc.request_id = r.request_id
where r.to_team_id is null                                 -- open challenges only
  and r.status = 'pending'                                 -- active
  and r.proposal_expires_at > now()                        -- not expired
  and (:country   is null or r.location->>'country_code' = :country)
  and (:city      is null or r.location->>'city' = :city)
  and (:format    is null or r.proposed_format->>'__name'  = :format)
  and (:ball_type is null or r.proposed_format->>'ballType' = :ball_type)
  and (:date_from is null or r.proposed_start_time >= :date_from)
  and (:date_to   is null or r.proposed_start_time <  :date_to)
  and (:center    is null or r.location_point is null
       or st_dwithin(r.location_point, :center, :radius_m))
  and (r.from_team_id <> any(:my_team_ids))                -- exclude own listings
order by score desc, r.created_at desc
limit :limit offset :offset;
```

`:my_team_ids` comes from the calling user's owned/managed teams (resolved server-side
from the auth token) — the viewer never sees their own open listings.

### 9.3 Place facets (city chips)

A second tiny query, exposed as `mode: "facets"` on the same edge function (twin of the
team-search facets):

```sql
select
  location->>'city' as city,
  count(*) as listing_count
from public.match_requests
where to_team_id is null
  and status = 'pending'
  and proposal_expires_at > now()
  and location ? 'city'
  and (:country is null or location->>'country_code' = :country)
group by location->>'city'
order by listing_count desc
limit 100;
```

Same "facet from our own data" principle as team search — every chip is guaranteed to
have listings.

---

## 10. Filters & ranking

Filters (UI surface; all optional, all server-side):

| Filter | Effect |
|---|---|
| Location | `near me` GPS / `city` chip / "everywhere in my country" |
| Date range | `proposed_start_time` inside `[dateFrom, dateTo]` |
| Format | `t20`, `limited`, `practice`, etc. (match the `proposed_format` payload) |
| Ball type | `leather` / `tape` / `tennis` |
| Players per side | range 5–15 |

Ranking blend (no text relevance in pool v1 — there's no free-text search):

```
decay  = 1 / (1 + km / scale_km)                  -- 0..1; 0 when no center/point
recent = 1 / (1 + ageDays)                         -- 0..1
score  = 0.7 * decay + 0.3 * recent
```

When no center is supplied (viewer hasn't shared location or chosen a city), score
collapses to `0.3 * recent` and listings are ordered by recency — still useful.

---

## 11. Geo model (reused from team search)

Identical to [§3 of the team-search doc](search-feature-design.md#3-the-core-insight-coordinates-over-names):
- `geography(point, 4326)` generated from `lat`/`lng`.
- `ST_DWithin` for proximity, GiST-indexed.
- `location->>'city'` for facets, B-tree-indexed.
- Distance returned as `km`, ranked by a **decay**, not a hard cutoff.
- Centroid precision is coarse on purpose; never promise "2.3 km away" — show coarse
  bands.
- Country-code default bounds the result set to the caller's country to avoid PK↔IN
  noise.

The single difference: the pool replaces team-search's *trigram relevance* with a
*recency boost* (there's no name to fuzzy-match in pool v1).

---

## 12. Response & accept flow

**Per D1 (poster picks from responders).**

```
1. team A posts open listing      → sendMatchChallenge(toTeamId: null, ...)
                                    → match_requests row inserted; trigger copies team A's location.
                                    → broadcasts to A's managers (existing "your request was posted").

2. team B browses pool             → list-open-challenges → sees A's listing.
3. team B taps "Respond"           → respond-to-open-challenge edge fn
                                    → inserts match_request_responses row (status='pending')
                                    → notification → team A's managers: "B responded to your listing"
                                       (new notification type: open_challenge_response).

4. team A views responders         → listResponsesForChallenge(requestId)
                                    → sees B, C, D each with their XI + message.

5. team A picks team B             → acceptOpenChallenge(requestId, responseId=B's)
                                    → existing acceptMatchChallenge RPC runs, materialising matches row;
                                    → sets the chosen response to status='chosen';
                                    → flips other pending responses to status='declined';
                                    → notifications:
                                       - team B: match_request_decision (ACCEPTED + matchId)
                                       - teams C/D: match_request_decision (DECLINED — soft).
```

### 12.1 Repository contract additions

```dart
abstract class MatchesRepository {
  // ...existing...

  Future<Either<Failure, List<OpenChallenge>>> listOpenChallenges({
    double? lat,
    double? lng,
    double? radiusKm,
    String? countryCode,
    String? format,
    String? ballType,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? city,
    int limit,
    int offset,
  });

  Future<Either<Failure, List<PoolPlaceFacet>>> openChallengeFacets({String? countryCode});

  Future<Either<Failure, MatchRequestResponseId>> respondToOpenChallenge({
    required MatchRequestId requestId,
    required TeamId responderTeamId,
    required List<String> responderXi,
    String? responderKeeperId,
    String? message,
  });

  Future<Either<Failure, List<ChallengeResponse>>> listResponses(MatchRequestId requestId);

  /// Wraps the existing acceptMatchChallenge — the response carries the
  /// responder's teamId + XI, which the existing RPC already accepts.
  Future<Either<Failure, MatchId>> acceptOpenChallenge({
    required MatchRequestId requestId,
    required MatchRequestResponseId responseId,
  });

  Future<Either<Failure, Unit>> withdrawResponse(MatchRequestResponseId id);
}
```

### 12.2 The `acceptOpenChallenge` server flow

```
acceptOpenChallenge(requestId, responseId)
  ├─ load response → (responder_team_id, responder_xi, responder_keeper_id)
  ├─ acceptMatchChallenge_existing(
  │     requestId,
  │     toTeamId      = response.responder_team_id,
  │     toTeamXi      = response.responder_xi,
  │     toTeamKeeperId = response.responder_keeper_id
  │  )                                                    ⇒ materialises matches row
  ├─ update match_request_responses set status='chosen', decided_at=now() where response_id = $1
  └─ update match_request_responses
       set status='declined', decided_at=now()
       where request_id = $1 and status='pending' and response_id != $1
```

A single Postgres function (SECURITY DEFINER) or an edge function that orchestrates it.
We'll start as an edge function `accept-open-challenge` per the dev-phase convention.

---

## 13. Notifications wiring

Mirrors the existing convention — **never** add new request-shaped tables to
`supabase_realtime`. Everything rides on the `notifications` table + the
`user:<uid>:notifications` broadcast.

### 13.1 New notification types

| Type | Tier | Urgency | When | Recipient |
|---|---|---|---|---|
| `open_challenge_response` | `NOW` | true | A team responds to your open listing | Managers of the poster team |
| `open_challenge_response_withdrawn` | `WEEK` | false | A responder withdraws their interest | Managers of the poster team |
| `match_request_decision` (existing) | `WEEK` | false | Poster picks → acceptance/decline notifications | Responder + other responders |

### 13.2 New broadcast trigger

```sql
create or replace function public.notify_on_open_challenge_response()
returns trigger language plpgsql security definer as $$
declare
  poster_managers uuid[];
  poster_team_id uuid;
begin
  -- only fire for fresh pending responses
  if NEW.status <> 'pending' or (TG_OP = 'UPDATE' and OLD.status = 'pending') then
    return NEW;
  end if;

  select from_team_id into poster_team_id
  from public.match_requests where request_id = NEW.request_id;

  select array(
    select unnest(managers || array[owner_id])
    from public.teams where team_id = poster_team_id and owner_id is not null
  ) into poster_managers;

  insert into public.notifications (recipient_id, type, urgent, payload, ...)
  select unnest(poster_managers),
         'open_challenge_response',
         true,
         jsonb_build_object(
           'request_id', NEW.request_id,
           'response_id', NEW.response_id,
           'responder_team_id', NEW.responder_team_id,
           'actor_id', NEW.responded_by
         );
  return NEW;
end;
$$;

create trigger match_request_responses_notify_insert
  after insert on public.match_request_responses
  for each row execute function public.notify_on_open_challenge_response();
```

A symmetric trigger fires on `responder_team` when the poster picks (`status='chosen'`)
or declines (`status='declined'`) — and can simply reuse the existing
`match_request_decision` type since acceptance materialises a real match.

---

## 14. Visibility & RLS policy

Today, open `match_requests` are visible **only** to managers of either team (and only
via the `find_match_request_by_code` SECURITY DEFINER RPC for code-based discovery). For
the pool, open + active listings need to be browsable by anyone authenticated.

**Per D4 — match the matches-table pattern:**

```sql
-- Relaxed read: open + active listings are world-readable.
create policy match_requests_open_world_readable
  on public.match_requests for select
  to authenticated
  using (
    to_team_id is null
    and status = 'pending'
    and proposal_expires_at > now()
  );

-- Existing manager-side read policy still applies for closed/non-open requests.
```

The discovery edge function (`list-open-challenges`) does the proximity/filter scoping;
the RLS policy makes the rows reachable but doesn't enforce proximity — it can't,
proximity is computed per-call. This is exactly the matches-table model
(`list-my-matches` does the user scoping in the edge fn over a world-readable matches
table).

**`match_request_responses` RLS:** poster of the parent request + responder team
managers can read; only responder team managers can insert/update their own response;
only the poster can flip status to `chosen`/`declined` (via the `accept-open-challenge`
SECURITY DEFINER edge fn).

> **Security caveat:** an open challenge is *by intent* a public-board posting; the
> poster's team identity and proposed terms become world-readable while the listing is
> active. No PII (no phone numbers, emails) — only team identity and match terms.

---

## 15. Flutter layers (clean architecture)

Standard matches-feature layering; online-only; controllers call repositories directly.

```
lib/features/matches/
├── domain/
│   ├── entities/
│   │   ├── open_challenge.dart       # MatchRequest + distance_km + from_team summary + response_count
│   │   ├── challenge_response.dart   # match_request_responses row
│   │   └── pool_place_facet.dart     # {city, listingCount}
│   └── repositories/
│       └── matches_repository.dart   # + listOpenChallenges / openChallengeFacets
│                                     # + respondToOpenChallenge / listResponses
│                                     # + acceptOpenChallenge / withdrawResponse
├── data/
│   ├── models/  …_dto.dart
│   ├── datasources/
│   │   └── open_challenges_remote_datasource.dart   # functions.invoke('list-open-challenges'|...)
│   └── repositories/
│       └── matches_repository_impl.dart             # exception → Failure
└── presentation/
    ├── state/
    │   ├── open_challenge_pool_state.dart           # filters + AsyncValue<List<OpenChallenge>>
    │   └── challenge_responses_state.dart           # for a single listing's response inbox
    ├── controllers/
    │   ├── open_challenge_pool_controller.dart      # debounced filters + GPS + facets
    │   └── challenge_responses_controller.dart      # poster's inbox: load, accept, decline
    ├── screens/
    │   ├── open_challenge_pool_screen.dart          # browse the pool
    │   ├── open_challenge_compose_screen.dart       # post a new listing (mostly existing send flow)
    │   └── challenge_responses_screen.dart          # poster's inbox for a listing
    └── providers/  …
```

Reuse: device GPS via `lib/features/location/` (presentation→provider seam, §6.6).

---

## 16. Presentation & UX

### Pool browse screen

- **Header:** "Looking for a match" + a "Post a listing" CTA (if user has at least one
  team).
- **Location chip row** at the top: "Near me · Lahore · Karachi · …" (facets), with a
  GPS toggle and a country override.
- **Filter sheet:** date range, format, ball type, players-per-side.
- **List:** virtualised listing cards — team avatar/name · proposed format · proposed
  start time · distance band · response count · primary action "Respond".

### Respond flow

- Tap "Respond" → modal: pick responder team (if user manages multiple) → pencil-in XI
  (reuses existing send-request XI picker UI) → optional message → submit.
- After submit: "Your interest sent to <Team>" + a "Withdraw" affordance on the listing
  card.

### Poster inbox

- Per-listing screen showing all responses (team summaries + XI + message).
- Single "Pick this team" action per response → confirmation → calls
  `acceptOpenChallenge` → match materialises → other responders auto-declined → routes
  user to the match screen.

### Empty / sparse states

- "No listings within 25 km" → expand to 50/100 km, or "Be the first — post your listing."
- Mirrors the team-search sparse-area pattern; same auto-expanding radius.

### Pool entry point in the v2 IA — DECIDED 2026-06-11 (D10)

The pool lives in the **repurposed Matches tab** as its primary sub-tab (working label:
"Pool" / "Looking for a match"). The Matches tab sits in the **center slot** of the
final nav order — **Home · Search · Matches · Messages · Pavilion** — the prime
thumb-reach + showcase position, deliberately given to the app's killer feature (see
search doc D9 for the full ordering rationale).

The Matches tab is kept in the nav — its current mock-only `MatchesV2Screen` content
(Live/Upcoming/Recent/Browse) is replaced; the Live/Recent slots return later when real
public match browsing ships. Team search lives in its own Search tab at slot 2 (the
Profile tab is removed; Pavilion takes the rightmost "me" slot), so the two discovery
surfaces are siblings in the nav and share the geo UI components (facet chips, near-me
toggle, radius expansion, sparse-area empty states).

---

## 17. Security & privacy

- **Service-role edge function = SQL enforces scoping.** `list-open-challenges` runs
  with service role and bypasses RLS, so the WHERE clause itself **must** enforce
  `to_team_id is null and status='pending' and proposal_expires_at > now()`. Forgetting
  any of these would leak closed/decided requests into discovery.
- **Self-listing exclusion** in SQL via `from_team_id <> any(:my_team_ids)`.
- **Spam guardrails:**
  - One active open listing per team (D9; unique partial index, §7.4).
  - 48 h proposal expiry (existing).
  - 500-char limit on `message` (existing).
  - A response is unique per (request, responder_team) — same team can't spam-respond.
- **Public posting acknowledgement.** A first-time poster sees a one-time confirmation
  that the listing is public to nearby teams. Carefully word it so the social contract
  is clear.
- **Reporting / hide.** v1: a viewer can hide a listing locally (client-side
  filter). Reporting + moderation tools are follow-up.

---

## 18. Performance & scale

- **Index usage:** the partial GiST `match_requests_open_loc_gist` keeps the spatial
  index to the *active open* hot set — orders of magnitude smaller than the full
  request history.
- **Sub-millisecond proximity** is well-established at billions of rows for `ST_DWithin`
  + GiST; the pool's hot set will sit in the tens of thousands at most for years.
- **Pagination:** top-N by score; cap at ~100; offset within the cap; "refine your
  search" past that. Same pattern as team search.
- **`response_count`** subquery is a single grouped-aggregate; tiny.
- **Notification fan-out:** at most `len(team.managers) + 1` rows per response/decision.
  Bounded.

---

## 19. Edge cases catalogue

| # | Case | Handling |
|---|---|---|
| E1 | Poster team has no coordinates yet | Listing's `location_point` is null → invisible to proximity, but still appears under "everywhere in my country" / city filter if `location.city` is present. Strong motivator for search Slice 1. |
| E2 | Responder withdraws after acceptance | Acceptance materialises immediately; withdrawal is allowed only while response is `pending`. |
| E3 | Poster never picks; proposal expires | Listing flips to `expired` (existing 48 h timer); all pending responses notified with `match_request_decision` (declined, reason `expired`). |
| E4 | Poster picks → responder team's XI no longer valid | Existing `acceptMatchChallenge` validates XI server-side; surfaces a validation failure → poster can pick another. |
| E5 | Two managers of the responder team both tap "Respond" | Unique `(request_id, responder_team_id)` constraint — the second tap returns the existing response (idempotent client-side wrapping). |
| E6 | Cross-border noise | Country bound defaults to caller's country; "everywhere in my country" is explicit. |
| E7 | Listing too far in the future | `dateFrom`/`dateTo` filter handles browse; the 48 h proposal expiry caps how stale a listing can sit. |
| E8 | Many responses on a single listing | UI surfaces top-N (newest first) with pagination; no algorithmic ranking among responders v1. |
| E9 | Poster team itself becomes inactive | `teams.status = 'inactive'` → listing should be auto-cancelled (a separate maintenance job; v2). |
| E10 | Slot already accepted while a responder was reading | `acceptMatchChallenge` is atomic; subsequent accepts on the same request fail cleanly; the responder sees "this listing has been filled." |

---

## 20. Build plan (5 slices)

Each slice is independently reviewable.

### Slice A — Schema foundation
- Add `location` + `location_point` + GiST partial index to `match_requests` (§7.1).
- `BEFORE INSERT` trigger to copy from team (§7.2).
- New `match_request_responses` table + indexes (§7.3).
- One-active-open-per-team unique partial index (§7.4).
- New notification type `open_challenge_response`.
- Verifiable with pure SQL.

### Slice B — Discovery service
- `list-open-challenges` edge function + facets (§9).
- Visibility/RLS change (§14).
- Verifiable with `curl` / `functions.invoke`.

### Slice C — Response flow
- `respond-to-open-challenge` edge function + `match_request_responses` insert.
- `notify_on_open_challenge_response` trigger (§13.2).
- `withdraw-response` edge function.
- Verifiable end-to-end via SQL + functions.

### Slice D — Accept-from-pool
- `accept-open-challenge` edge function — wraps existing
  `acceptMatchChallenge` with the response's team/XI; cascades pending responses to
  declined (§12.2).
- Wired into the existing `match_request_decision` notifications path for responders.

### Slice E — Flutter pool UI
- Domain/data/presentation layers (§15).
- Pool browse screen, respond modal, poster inbox screen (§16).
- IA wiring **decided (D10)**: replace the mock `MatchesV2Screen` body with the real pool
  as the Matches tab's primary sub-tab.

**Hard dependency:** Slice E (and the practical utility of all earlier slices) needs
**team-search Slice 1** to land first — teams must have coordinates for listings to be
locatable. Slices A–D can be designed and built in parallel with search Slice 1, but the
feature only feels usable once both are live.

---

## 21. Test plan

Per the project's pyramid:

- **SQL-level seed + assert.** Seed teams across Lahore, Gujranwala, and a village; post
  open challenges; assert:
  - proximity ordering correct (Lahore listings ranked highest for a Lahore viewer);
  - listings expired (`proposal_expires_at < now()`) NOT returned;
  - non-open requests (`to_team_id is not null`) NOT returned;
  - self-listings excluded;
  - city facet counts match seed.
- **Edge function tests** for `list-open-challenges` mode/filter combinations.
- **Repository test** — exception → `Failure` translation for the new methods.
- **Controller test** — pool controller debounces filters, near-me reads GPS provider;
  responder controller submits/withdraws; poster controller accepts and the chosen
  response leads to a materialised match.
- **Integration smoke** — post → respond → accept → match exists, notifications fire,
  other responders flipped to declined.

---

## 22. Out of scope / future work

- **Push notifications "new listing in your area"** — saved-search / area-watch.
- **Search-within-pool** (free-text on listing message or team name).
- **Skill / level matching** — rating-based opponents.
- **Recurring listings** (e.g. "every weekend until matched").
- **In-pool counter-proposals** — today's counter mechanism is targeted; a pool-style
  counter would add complexity.
- **Reporting / moderation** of abusive listings.
- **Promote `list-open-challenges` from edge function to RPC** once stable (D5).
- **Auto-cancel listings when poster team becomes inactive** (E9).

---

## 23. Open questions for review

The three rows tagged **PENDING** in §4 are the genuine forks. They were posed inline in
the design discussion but not yet confirmed — please choose before this becomes tickets:

1. **Response model (D1).** Poster picks from responders **(default in this doc)** /
   first-come accept / hybrid interest queue?
2. **Listing location (D2).** Inherit from posting team **(default)** / per-listing /
   both (team default, editable)?
3. **Scoping (D3).** Near-me + city facet **(default)** / proximity only / facet only?

Other open items:

4. **IA placement of the pool entry point.** ✅ **DECIDED 2026-06-11 (D10):** the pool is
   the primary sub-tab of the repurposed Matches tab; team search gets its own Search tab
   (replacing Profile). See [§16](#16-presentation--ux) and the search doc D9.
5. **Default display radius.** 25 km proposed (same as search) — right for rural PK/IN
   or wider?
6. **Verified-team boost** in ranking — tie-breaker only, or weighted term in `score`?
7. **Public-posting confirmation** wording on a first-time post.
8. **Listing cap.** D9 caps to 1 active open listing per team; raise to N? Same number
   across all teams or scaled by verified status?

---

## 24. References

- [Search feature design doc](search-feature-design.md) — the geo foundation and team-search query patterns the pool reuses.
- [Supabase — PostGIS geo queries](https://supabase.com/docs/guides/database/extensions/postgis)
- [PostGIS — ST_DWithin](https://postgis.net/docs/ST_DWithin.html)
- [PostGIS — KNN distance operator `<->`](https://postgis.net/docs/geometry_distance_knn.html)
- Existing in-repo:
  - `lib/features/matches/domain/entities/match_request.dart`
  - `lib/features/matches/domain/repositories/matches_repository.dart`
  - `lib/features/matches/data/datasources/match_requests_remote_datasource.dart`
  - `supabase/migrations/20260101000600_match_requests.sql`
  - `supabase/functions/send-match-request/index.ts`
  - `supabase/functions/list-my-matches/index.ts`
  - `lib/features/notifications/data/datasources/notifications_remote_datasource.dart`
