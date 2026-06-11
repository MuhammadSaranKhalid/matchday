# Team Search & Discovery — Design Document

> **Status:** Draft for review · **Date:** 2026-06-10 · **Scope:** v1 = teams only
> **Owner:** @MuhammadSaranKhalid
>
> This document is the single source of truth for the team search/discovery feature.
> It is written to be reviewed end-to-end and to have gaps surfaced. Each major
> decision carries its rationale so reviewers can challenge the *reasoning*, not just
> the conclusion. Nothing here has been built yet.

---

## Table of contents

1. [Problem statement](#1-problem-statement)
2. [Goals & non-goals](#2-goals--non-goals)
3. [The core insight: coordinates over names](#3-the-core-insight-coordinates-over-names)
4. [Decisions log](#4-decisions-log)
5. [Current state of the codebase](#5-current-state-of-the-codebase)
6. [Architecture overview](#6-architecture-overview)
7. [Data model & schema changes](#7-data-model--schema-changes)
8. [Coordinate acquisition (create flow + backfill)](#8-coordinate-acquisition-create-flow--backfill)
9. [The search service (edge function)](#9-the-search-service-edge-function)
10. [Text matching deep dive](#10-text-matching-deep-dive)
11. [Ranking & relevance](#11-ranking--relevance)
12. [Geo model & precision realities](#12-geo-model--precision-realities)
13. [Place facets](#13-place-facets)
14. [Flutter layers (clean architecture)](#14-flutter-layers-clean-architecture)
15. [Presentation & UX](#15-presentation--ux)
16. [Security & privacy](#16-security--privacy)
17. [Performance & scale](#17-performance--scale)
18. [Edge cases catalogue](#18-edge-cases-catalogue)
19. [Build plan (3 slices)](#19-build-plan-3-slices)
20. [Test plan](#20-test-plan)
21. [Out of scope / future work](#21-out-of-scope--future-work)
22. [Open questions for review](#22-open-questions-for-review)
23. [References](#23-references)

---

## 1. Problem statement

A user opens the app and wants to **find teams**. Two real situations drive the design:

- **City user (Lahore).** Wants to browse/filter the teams in their city, or search a
  team by name.
- **Village user (e.g. Hair & Munjirwali).** Physically in a small village; wants the
  teams *right there*, even though the place may not exist in any global gazetteer.

The app is built for cricket across **Pakistan, India, and other cricket-playing
regions**, so search must scale to millions of users and tens of thousands of teams,
and must degrade gracefully in **sparse rural areas** where only a handful of teams
exist nearby.

"Search by team name" is the easy 20%. The hard 80% is **fine-grained geography** and
**matching the messy way people actually type names**.

---

## 2. Goals & non-goals

### Goals (v1)

- Find a team by **name** with typo/spelling tolerance.
- Find teams **near me** (device GPS).
- Find teams **in/near a place** chosen from a filter list.
- Feel correct in **dense cities** *and* **sparse villages**.
- Reuse the geo capture (Google Places + GPS) the app already has.
- Scale to PK + IN volumes without re-architecting.

### Non-goals (v1) — see [§21](#21-out-of-scope--future-work)

- Searching **players/profiles**, **tournaments**, or **matches** (same infra later).
- **Native-script** search (Urdu/Hindi script input). v1 is **English / Latin** only.
- Saved searches, search history, "teams near you" push notifications.
- Likes/relevance personalization, ML ranking.

---

## 3. The core insight: coordinates over names

The two user situations *feel* identical but are **architecturally opposite**:

- **Name-based place filtering breaks at village granularity.** Google's `(regions)`
  gazetteer may not contain a small village; and when it does, two users label the
  same place differently ("Munjianwali" vs "Munjir Wali" vs the nearest town). Keying
  teams by a place *string* makes those teams unfindable.
- **Coordinate-based proximity never breaks.** If every team has a `lat`/`lng`, then
  "teams within N km of *this point*" works whether or not the place has a canonical
  name. The math does not care whether Google has heard of the village.

**Design principle:** lead with **coordinates + PostGIS proximity**; treat a place
*name* only as a way to obtain a coordinate, never as the key we match on. This is the
canonical Supabase pattern (`ST_DWithin` on a `geography` point + GiST index) and it
scales to billions of rows at sub-millisecond latency (see [§23](#23-references)).

---

## 4. Decisions log

| # | Decision | Choice | Rationale |
|---|---|---|---|
| D1 | How a team gets its `lat`/`lng` | **Prefill from creator's profile location, editable** in team-create | Every team gets a coordinate for free; creator can correct it to where the team actually plays. |
| D2 | v1 scope | **Teams only** | Prove the pattern end-to-end; profiles/tournaments reuse it later. |
| D3 | Script coverage | **English / Latin only** (normalized trigram, no transliteration) | Overwhelming majority of typed input is Latin; trigram absorbs spelling variation; native-script is a conscious later milestone. |
| D4 | Place filter source | **Facet from our own teams** (not Google Places at search time) | Zero API cost at search time; every place shown has teams; handles villages for free because it is *our* data. |
| D5 | Ranking | **Weighted blend** (relevance × distance decay), not lexicographic sort | Lexicographic "similarity desc, distance asc" is visibly wrong (far-but-exact beats near-but-close). |
| D6 | Where search runs | **Edge function** (`search-teams`), promote to RPC later | Dev-phase convention: iterate server logic without a migration per change. |
| D7 | Location capture richness | **Capture rich, display flat** — extract `city` (locality) + `district` + `province` + `postcode` from `addressComponents`; v1 facet UI groups by `city` only | All are in the same response at zero extra cost; enables hierarchical + PIN-code browsing later with no re-capture. Fixes the "full address stored in `city`" bug ([§8.0](#80-location-capture-correctness-prerequisite)). |
| D8 | Cleaning existing dirty `city` rows | **Fix forward only** — no backfill; dirty rows self-clean when the user next saves their profile / edits the team | Dev dataset is tiny/throwaway; a backfill script isn't worth it. Legacy rows show messy facets until re-saved. |
| D9 | Surface placement (IA) — **decided 2026-06-11** | **Dedicated Search tab in the bottom nav, replacing the Profile tab.** Final nav order: **Home · Search · Matches · Messages · Pavilion**. Plus a **header search icon** on the main tabs as a one-tap shortcut to the same screen. | Discovery is the app's core loop and deserves tab-level prominence; the old nav over-weighted "me" (Pavilion + Profile). Order follows tab-bar research: priority reads left→right (Home anchor leftmost, Search second — X's placement), the **center slot is the prime thumb-reach/showcase position** and goes to the Matches tab (open match pool — the killer feature), and the **rightmost slot is the conventional "me" zone** → Pavilion (which absorbs the profile/workspace role). Own profile stays one tap away via the **header avatar** (and via Pavilion); the `/profile` route is retained for deep links. The Search tab hosts team search v1 and grows into unified search (players/tournaments) later. Swipe adjacency (`SwipeableBranchView`) reads as the user journey: feed → discover teams → find a match → talk → my workspace. |

Decisions that remain **open** are in [§22](#22-open-questions-for-review).

---

## 5. Current state of the codebase

The geo foundation was scaffolded and **never wired**. Audit findings:

### What already exists ✅

- **`teams.location jsonb`** — shape `{ city, place_id?, lat?, lng?, country_code? }`
  (same as `profiles.location`).
  [`supabase/migrations/20260101000200_teams.sql:63`](../supabase/migrations/20260101000200_teams.sql)
- **`teams.location_point geography(point,4326)`** — a **generated** column auto-computed
  from `lat`/`lng`. Lines 64–76 of the same migration.
- **`teams_location_point`** GiST (spatial) index + **`teams_name_trgm`** GIN trigram
  index on `team_name` (lines 109–110) — both present, both **unused by any code**.
- Extensions `postgis` + `pg_trgm` enabled
  ([`20260101000000_shared_helpers.sql`](../supabase/migrations/20260101000000_shared_helpers.sql)).
- Full geo capture pipeline in [`lib/features/location/`](../lib/features/location/):
  Google Places (New) autocomplete + place details, Google Geocoding (forward/reverse),
  device GPS via `geolocator`. Produces a `GeoPlace { label, source, placeId, latitude,
  longitude, countryCode }`.
- Onboarding already writes `{ city, place_id?, lat?, lng?, country_code? }` into
  `profiles.location`.

### What is missing ❌

- **Teams never receive a coordinate.** `createTeam` writes only `city`:
  [`teams_remote_datasource.dart:74`](../lib/features/teams/data/datasources/teams_remote_datasource.dart#L74)
  → `'location': {if (payload['city'] != null) 'city': payload['city']}`. So
  `location_point` is `NULL` for every existing team and proximity search returns
  nothing.
- **No search/filter query exists anywhere.** Every read is a bare `.select()`; all
  filtering happens **in-memory** in the repository (by `ownerId`, `name`, `id`).
  [`teams_repository_impl.dart`](../lib/features/teams/data/repositories/teams_repository_impl.dart),
  [`teams_list_controller.dart:207`](../lib/features/teams/presentation/controllers/teams_list_controller.dart#L207).
- No normalized search column; the existing trigram index is on raw `team_name` (case-
  and accent-sensitive).
- **`location.city` stores the full formatted address, not the locality** — a pre-existing
  capture bug ([§8.0](#80-location-capture-correctness-prerequisite)) that breaks faceting until fixed.

### `unaffected` enums (for reference)

`team_privacy` (default `public`) and `team_status` (default `active`) already exist;
discovery filters on these literal values.

---

## 6. Architecture overview

```
                         ┌─────────────────────────────────────────┐
                         │  Flutter — teams feature (clean arch)    │
                         │                                          │
  search box ─┐          │  TeamSearchController (debounced)        │
  near-me  ───┼────────► │    ├─ ref: location/ device GPS          │
  place chip ─┘          │    └─ TeamsRepository.searchTeams(...)   │
                         │            │  .teamPlaceFacets(...)      │
                         └────────────┼─────────────────────────────┘
                                      │ functions.invoke
                                      ▼
                         ┌─────────────────────────────────────────┐
                         │  Edge function: search-teams             │
                         │   mode-select (q? center? country?)      │
                         │   parameterized SQL (service role)       │
                         └────────────┼─────────────────────────────┘
                                      │
                                      ▼
                         ┌─────────────────────────────────────────┐
                         │  Postgres + PostGIS                      │
                         │   teams.search_name  (GIN trigram)       │
                         │   teams.location_point (GiST geography)  │
                         │   word_similarity() + ST_DWithin()       │
                         └─────────────────────────────────────────┘

  Google Places / GPS are used ONLY at team-create (capture) and at near-me
  (device GPS). They are NOT called during search — place filters come from
  faceting our own teams table.
```

---

## 7. Data model & schema changes

Adding a generated column + index is **schema DDL**, which is a legitimate migration
(the "edge-functions-not-migrations" dev rule governs server *logic*, not schema).

> ⚠️ **Apply to the correct deployed Supabase project.** A prior migration (0511) was
> applied to the wrong project because MCP pointed elsewhere. Confirm the project before
> applying.

```sql
-- (a) Immutable unaccent wrapper.
-- Single-arg unaccent() is only STABLE, so it cannot be used in a generated
-- column or an index expression. The two-arg form is IMMUTABLE; wrap it.
create extension if not exists unaccent;

create or replace function public.f_unaccent(text)
  returns text
  language sql
  immutable
  parallel safe
  strict
as $$ select public.unaccent('public.unaccent', $1) $$;

-- (b) Normalized, generated search column on teams.
-- lower + accent-fold so "Tigers-XI", "tigers xi", "Tigers XI" collapse to one form.
alter table public.teams
  add column search_name text
  generated always as (lower(public.f_unaccent(team_name))) stored;

-- (c) Partial trigram index on the hot set only (keeps the index small).
create index teams_search_trgm
  on public.teams using gin (search_name gin_trgm_ops)
  where status = 'active' and privacy = 'public';
```

**No change needed** to `location`, `location_point`, the GiST index, or the trigram
extension — they already exist. The legacy `teams_name_trgm` index on raw `team_name`
can be dropped once `search_name` is in use (optional cleanup).

### `location` jsonb contract (extended shape)

`city` now holds the **locality only** (not the full address — see [§8.0](#80-location-capture-correctness-prerequisite)).
`label` carries the human display string; `district`/`province` are captured for future
hierarchical facets. Same shape on `profiles.location` and `teams.location`.

```jsonc
{
  "label":        "Gulberg III, Lahore",  // display string (full/human) — NEW
  "city":         "Lahore",               // LOCALITY only — facet key + null-coord net
  "district":     "Lahore",               // optional, admin_area_level_2 — NEW (future hierarchy)
  "province":     "Punjab",               // optional, admin_area_level_1 — NEW (future hierarchy)
  "postcode":     "54000",                // optional, postal_code — NEW (future PIN-code search, esp. India)
  "place_id":     "ChIJ...",              // optional (Google Places id, provenance)
  "lat":          31.5204,                // optional → drives location_point
  "lng":          74.3587,                // optional → drives location_point
  "country_code": "PK"                    // optional (coarse bound, ISO 3166-1 alpha-2)
}
```

---

## 8. Coordinate acquisition (create flow + backfill)

> Covers a pre-existing **location-capture bug** (§8.0) that must be fixed first, then the
> create-flow coordinate write (§8.1) and the optional coordinate backfill (§8.2).

### 8.0 Location-capture correctness (prerequisite)

**Bug (pre-existing, independent of search).** The capture pipeline extracts only
**country** and **coordinates** from Google's `addressComponents`; `city` is set to the
display `label` — which on the GPS and typed-text paths is the **entire formatted
address**. Real example stored today:

```jsonc
{ "city": "12-A Street 1, Block-E-II … Lahore, 54000, Pakistan", "place_id": "ChIJ…",
  "lat": 31.5074, "lng": 74.3369, "country_code": "PK" }   // ❌ city = whole address
```

Origin:
- `label = displayName.text ?? formattedAddress` — [`geo_place_dto.dart:23`](../lib/features/location/data/models/geo_place_dto.dart#L23)
- GPS → `label = formatted_address` — [`places_remote_datasource.dart:128`](../lib/features/location/data/datasources/places_remote_datasource.dart#L128)
- then `city: place.label` — [`onboarding_controller.dart:208`](../lib/features/onboarding/presentation/controllers/onboarding_controller.dart#L208) (also :173, :348)

**Why it matters for search.** Faceting ([§13](#13-place-facets)) groups by
`location->>'city'`. If `city` is a full address, every team becomes its own unique "city"
and the facet chips collapse to garbage.

**Fix.** Add locality extraction mirroring the existing `_countryFromComponents`, with a
**fallback chain** (villages often have no `locality`):

```dart
// locality → postal_town → sublocality → admin_area_level_3 → admin_area_level_2
static String? _localityFromComponents(List<dynamic>? components) {
  if (components == null) return null;
  const priority = ['locality','postal_town','sublocality',
                    'administrative_area_level_3','administrative_area_level_2'];
  for (final type in priority) {
    for (final c in components.cast<Map<String, dynamic>>()) {
      final types = (c['types'] as List?)?.cast<String>() ?? const [];
      if (types.contains(type)) return c['longText'] ?? c['shortText'];
    }
  }
  return null;
}
```

`GeoPlace`/`GeoPlaceDto` gain `city` (locality), `district` (admin_2), `province`
(admin_1), and `postcode` (postal_code), kept **separate from `label`** (display).
Onboarding writes `city: place.city` (not `place.label`). Each field maps to its own
component type: `locality` (with the fallback chain above) for `city`,
`administrative_area_level_2`/`_1` for district/province, `postal_code` for postcode.

**Fetch-path reality (verified against `places_remote_datasource.dart`).** Three sources,
two response shapes — so two parser variants are needed and one path needs a signature
change:

| Path | API | Components in response? | Notes |
|---|---|---|---|
| Autocomplete ([:28](../lib/features/location/data/datasources/places_remote_datasource.dart#L28)) | Places (New) | **No** — predictions only (placeId + text) | Components arrive only after the pick, via Details. |
| Place Details ([:64](../lib/features/location/data/datasources/places_remote_datasource.dart#L64)) | Places (New) | **Yes** — `addressComponents` is **already in the field mask** ([:76](../lib/features/location/data/datasources/places_remote_datasource.dart#L76)) | True zero-cost: no billing/field-mask change, just parse. Fields `longText`/`shortText`/`types`. |
| Forward geocode ([:85](../lib/features/location/data/datasources/places_remote_datasource.dart#L85)) | Geocoding | **Yes** — `address_components` | Fields `long_name`/`short_name`/`types`. |
| Reverse geocode / GPS ([:107](../lib/features/location/data/datasources/places_remote_datasource.dart#L107)) | Geocoding | **In the response but discarded** — method returns only `(label, countryCode)` | ⚠️ Needs a **signature change** to surface city/district/province/postcode (return a `GeoPlaceDto` like the other paths). |

**Response schemas (confirmed against Google's docs — see [§23](#23-references)).**
- **Places API (New) `AddressComponent`:** `{ longText, shortText, types[], languageCode }`.
- **Geocoding API `address_component`:** `{ long_name, short_name, types[] }`.
- The **`types` strings are identical across both APIs** (`locality`,
  `administrative_area_level_1`/`_2`, `postal_code`, `postal_town`, `sublocality`,
  `country`) — only the text accessor differs. So the **fallback-chain type list is shared**;
  the two parsers differ by one line (which key to read).
- **Type semantics:** `locality` = city/town; `administrative_area_level_2` ≈ district;
  `administrative_area_level_1` ≈ province/state; `postal_code` = postal/PIN. ⚠️ Google's
  admin-level → local-term mapping is **country-dependent** (in some PK cases level_2 is a
  "division"), so `district`/`province` are best-effort approximations.
- **Billing:** `addressComponents` is the **Essentials** SKU; our Details field mask
  already includes `displayName` (**Pro** SKU), so the call is already Pro-billed and
  parsing `addressComponents` adds **zero** cost — confirmed, not assumed.

Implications for Slice 0:
- **Two extractors** sharing one type-priority list, mirroring the existing
  `_countryFromComponents` (Places-New `shortText`/`longText`) vs
  `_countryFromGeocodeComponents` (Geocoding `short_name`/`long_name`) split. The
  `_localityFromComponents` above is the Places-New variant; the snake_case sibling reads
  the same `types` but `long_name`/`short_name`.
- **`postcode` availability:** `(regions)` Details picks usually **omit** `postal_code`
  (postal codes attach to addresses, not whole localities); precise forward/reverse
  geocodes usually include it — hence nullable.

**Per-field availability from a reverse-geocode (GPS path), confirmed against Google's
reverse-geocoding docs.** Google warns reverse geocoding "is an estimate" and components
can be missing for remote `latlng`, so several fields are best-effort:

| Stored field | Source | Reliability |
|---|---|---|
| `lat` / `lng` | **device GPS (input)** — *not* the geocode | always |
| `label` (`formatted_address`) | geocode | reliable (results non-empty) |
| `place_id` | geocode | reliable |
| `country_code` (`country`) | component | ~always |
| `province` (`administrative_area_level_1`) | component | usually present |
| `district` (`administrative_area_level_2`) | component | usually, not guaranteed |
| `city` (`locality`) | component | urban: yes · rural: may be absent → fallback chain |
| `postcode` (`postal_code`) | component | often · rural: may be absent |

So one reverse-geocode populates **most** of the jsonb, but `city`/`district`/`postcode`
are nullable and the **coordinate stays the key** — the [§3](#3-the-core-insight-coordinates-over-names)
principle re-confirmed at capture time. `results` are ordered most-specific →
least-specific; we read `results.first` for the richest components but set `city` from the
`locality` **component**, *not* `formatted_address` (that mis-assignment is the original bug).

**Existing dirty rows: fix-forward only (D8).** No backfill script — rows self-clean when
the user next saves their profile / edits the team. The dev dataset is throwaway.

### 8.1 Team-create change

Add a **"Where does your team play?"** field to the team-create wizard:

- **Prefill** from `myProfileProvider`'s location (`label`, `city`, `district`, `province`,
  `postcode`, `lat`, `lng`, `place_id`, `country_code`). The prefilled `city` is clean only
  for profiles saved after the §8.0 fix (D8 fix-forward).
- **Editable** via the existing `location/` Places autocomplete + "use my location"
  button (no new geo code — reuse the feature through the presentation→provider seam).
- On submit, send the **full** location jsonb (currently only `city` is sent):

```dart
// teams_remote_datasource.dart — createTeam payload (replaces line 74)
'location': {
  if (payload['label'] != null)        'label':        payload['label'],
  if (payload['city'] != null)         'city':         payload['city'],      // locality only
  if (payload['district'] != null)     'district':     payload['district'],
  if (payload['province'] != null)     'province':     payload['province'],
  if (payload['postcode'] != null)     'postcode':     payload['postcode'],
  if (payload['place_id'] != null)     'place_id':     payload['place_id'],
  if (payload['lat'] != null)          'lat':          payload['lat'],
  if (payload['lng'] != null)          'lng':          payload['lng'],
  if (payload['country_code'] != null) 'country_code': payload['country_code'],
},
```

Once `lat`/`lng` are present, `location_point` self-populates via the generated column
and the GiST index picks it up.

> **Note on the team-create state/DTO:** `TeamDto`/`Team` currently extract only `city`
> from `location`. The create *write path* must carry `lat`/`lng`/`place_id`/
> `country_code` through the team-create controller/state → datasource payload. The read
> entity does not need lat/lng for display (distance comes from the search query), so the
> entity change is minimal.

### 8.2 Backfill existing teams (one-off SQL)

```sql
update public.teams t
set location = t.location
  || jsonb_build_object(
       'lat',          p.location->'lat',
       'lng',          p.location->'lng',
       'place_id',     p.location->'place_id',
       'country_code', p.location->'country_code')
from public.profiles p
where t.owner_id = p.user_id
  and not (t.location ? 'lat')   -- don't clobber teams that already have coords
  and p.location ? 'lat';        -- only when the owner actually has coords
```

This makes current teams searchable by proximity immediately. Teams whose owner has no
coordinate (or no owner) stay findable by **name** via the city-string net ([§10.3](#103-the-null-coordinate-safety-net)).

> Per **D8 (fix-forward)** this backfills *coordinates* only — it does **not** clean a
> team's `city` string. Under a strict fix-forward stance this backfill is itself optional
> (existing teams become proximity-searchable when their owner re-saves). Run it only if
> you want existing teams searchable without waiting for re-saves.

---

## 9. The search service (edge function)

A `search-teams` edge function. PostGIS proximity cannot be expressed through the
PostgREST query builder, so a function is required; the edge function lets us iterate the
SQL without a migration per change (promote to an RPC when the shape settles).

### 9.1 Behavior modes

The function selects behavior from which inputs are present:

| Inputs present | Mode | Hard filter | Ranking |
|---|---|---|---|
| `q` only | name search | name predicate | relevance |
| `center` only | near-me browse | `ST_DWithin(radius)` | distance decay |
| `q` + `center` | local search | name predicate (**radius = boost, not cutoff**) | blend |
| neither | browse | none | verified + recent |

**Critical nuance:** the radius is a **hard filter only in near-me browse**. When a text
query is present, distance only *boosts* ranking — searching "tigers" near Lahore surfaces
Lahore Tigers first but still finds Tigers anywhere.

### 9.2 Request / response contract

```jsonc
// POST /functions/v1/search-teams
{
  "q":           "tigers",   // optional, trimmed; null/empty → no name predicate
  "lat":         31.52,      // optional; with lng → search center
  "lng":         74.36,      // optional
  "radiusKm":    100,        // optional, default 100 (coarse candidate bound)
  "scaleKm":     15,         // optional, default 15 (decay half-scale)
  "countryCode": "PK",       // optional, default = caller's profile country
  "limit":       50,         // optional, default 50, max 100
  "offset":      0           // optional, default 0
}

// → 200
[
  {
    "team_id":     "uuid",
    "team_name":   "Lahore Tigers XI",
    "logo_url":    "https://...",
    "city":        "Lahore",
    "is_verified": true,
    "distance_km": 2.3,        // null when no center / no team point
    "score":       0.78
  }
]
```

### 9.3 SQL

```sql
-- :q, :lat, :lng, :radius_m, :scale_km, :country, :limit, :offset are bound params.
-- :center := case when :lat is not null and :lng is not null
--                 then st_setsrid(st_makepoint(:lng, :lat), 4326)::geography end
select
  t.team_id,
  t.team_name,
  t.logo_url,
  t.location->>'city' as city,
  t.is_verified,
  case when :center is not null and t.location_point is not null
       then st_distance(t.location_point, :center) / 1000.0
  end as distance_km,
  (
      0.6 * coalesce(word_similarity(:q, t.search_name), 0)                 -- relevance
    + 0.4 * coalesce(
        1.0 / (1.0 + (st_distance(t.location_point, :center) / 1000.0) / :scale_km),
        0)                                                                  -- decay
  ) as score
from public.teams t
where t.status = 'active'
  and t.privacy = 'public'
  and (:country is null or t.location->>'country_code' = :country)
  and case
        when :q is not null then                       -- NAME MODES: distance is a boost
          ( t.search_name ilike :q || '%'              --   prefix fast-path
            or :q <% t.search_name                     --   fuzzy word match (word_similarity)
            or (t.location->>'city') ilike '%' || :q || '%' )  -- city net (null-coord teams)
        when :center is not null then                  -- NEAR-ME BROWSE: hard radius
          ( t.location_point is not null
            and st_dwithin(t.location_point, :center, :radius_m) )
        else true                                      -- BROWSE ALL
      end
order by score desc, t.is_verified desc, t.updated_at desc, t.team_name asc
limit :limit offset :offset;
```

The two deliberate choices baked in are explained in [§10](#10-text-matching-deep-dive)
(`<%` not `%`; the city-string net) and [§11](#11-ranking--relevance) (the blend).

---

## 10. Text matching deep dive

### 10.1 Use `word_similarity` (`<%`), not `similarity` (`%`)

Naïve trigram has a trap. A user typing **"tigers"** wanting **"Lahore Tigers XI"**:

- `similarity('tigers','Lahore Tigers XI')` is **low** — the long name's many non-matching
  trigrams *dilute* the score below the default 0.3 threshold, so the team **doesn't show**.
- `word_similarity('tigers','Lahore Tigers XI')` is **high** — it is "the greatest
  similarity between the query and any *substring* of the target" ([pg_trgm docs](https://www.postgresql.org/docs/current/pgtrgm.html)).

So name search uses the **`<%` operator** (word_similarity, default threshold 0.6). A
plain `ilike 'q%'` prefix fast-path is kept so "lah" instantly surfaces "Lahore…" before
fuzzy matching runs.

Thresholds (tunable per request via `set_limit`/GUCs if needed):

| Operator | Function | Default threshold |
|---|---|---|
| `%`   | `similarity`              | 0.3 |
| `<%`  | `word_similarity`         | 0.6 |
| `<<%` | `strict_word_similarity`  | 0.5 |

### 10.2 Normalize at write time

`search_name = lower(f_unaccent(team_name))` (generated column, [§7](#7-data-model--schema-changes)).
The query is normalized the same way, so case and stray diacritics never cause misses.
Spelling tolerance ("Gujranwala" vs "Gujjranwala") comes from **trigram**, not unaccent —
they share most trigrams and match under `<%`.

### 10.3 The null-coordinate safety net

Teams without `lat`/`lng` are invisible to proximity by definition. The `(location->>'city')
ilike '%q%'` clause in the name modes ensures such teams are still findable by **name/city**.
This is the graceful degradation that keeps pre-backfill and owner-less teams discoverable.

### 10.4 What English-only buys us

No romanization column, no transliteration service, no `daitch_mokotoff` phonetic
indexing. Postgres's `soundex`/`metaphone`/`dmetaphone` do **not** work with multibyte
UTF-8 and are English-tuned anyway ([fuzzystrmatch docs](https://www.postgresql.org/docs/current/fuzzystrmatch.html)),
so avoiding native script for v1 sidesteps that entire complexity. Native-script search is
a conscious later milestone ([§21](#21-out-of-scope--future-work)).

---

## 11. Ranking & relevance

Lexicographic `ORDER BY similarity DESC, distance ASC` is **wrong**: a team 80 km away at
0.91 beats a team 2 km away at 0.89. Geo+text ranking uses a **weighted score with
distance decay**, grounded in Tobler's first law ("near things are more related than
distant things") — see [ephemeral.cx](https://ephemeral.cx/2023/03/geographically-ranked-postgres-full-text-search/),
[Neon geospatial search](https://neon.com/guides/geospatial-search).

Both signals normalized to 0–1, then blended:

```
relevance = word_similarity(q, search_name)            -- 0..1 (0 when no query)
decay     = 1 / (1 + (distance_km / scale_km))         -- 0..1 (0 when no center/point)
score     = 0.6 * relevance + 0.4 * decay
```

| Situation | Effective score | Behavior |
|---|---|---|
| name + location | `0.6·rel + 0.4·decay` | relevance leads; distance breaks ties sanely |
| location only | `0.4·decay` (rel = 0) | pure "near me" |
| name only | `0.6·rel` (decay = 0) | pure relevance |
| neither | 0 for all | falls to tie-breakers |

**Tie-breakers** (after `score`): `is_verified DESC`, then `updated_at DESC` (recent
activity), then `team_name ASC`.

**Why a decay curve, not a hard cutoff:** in sparse villages a hard 25 km radius yields an
empty list at 25.1 km and a wall of equals beyond. Decay ranks the nearest teams sensibly
no matter how far the closest one is. `ST_DWithin` is kept only as a **coarse** candidate
bound (100 km, index-backed) in near-me browse.

**Tuning knobs** (all server-side, no client change): `w_rel`/`w_geo` weights,
`scale_km`, the `<%` threshold, the coarse `radius_m`.

---

## 12. Geo model & precision realities

- **Centroid precision is coarse on purpose.** Places `(regions)` autocomplete returns a
  *centroid*, so every team whose creator picked "Lahore" shares the **identical** point.
  Intra-city distance is then 0 and ranking there falls to relevance/verified/activity.
  GPS capture gives a precise point. **Do not promise "2.3 km away" accuracy** — show
  coarse bands ("in Lahore" / "~15 km") in the UI. (`distance_km` is returned for sorting
  + banding, not for literal display.)
- **Null coordinates will be common.** Any creator who skipped onboarding geo → no team
  point → proximity-invisible, name-findable. Backfill shrinks but won't zero this.
- **Mixed precision is fine** for bucketing "near me"; we are ranking, not navigating.
- **SRID 4326 / geography** ⇒ `ST_DWithin` distances are in **meters**; `radiusKm` is
  converted to meters in the function.

---

## 13. Place facets

The place filter chips come from **our own data**, not Google Places:

```sql
select
  location->>'city'                 as city,
  avg((location->>'lat')::float8)   as lat,
  avg((location->>'lng')::float8)   as lng,
  count(*)                          as team_count
from public.teams
where status = 'active'
  and privacy = 'public'
  and location ? 'city'
  and (:country is null or location->>'country_code' = :country)
group by location->>'city'
order by team_count desc
limit 100;
```

→ chips like **Lahore (42) · Gujranwala (11) · Munjirwali (3)**. Tapping a chip feeds its
`avg(lat/lng)` as the search center.

**Why this wins:** zero API cost at search time; every chip is guaranteed non-empty; the
village appears because *we* have teams there (Google's gazetteer is irrelevant). Exposed
as `mode: "facets"` on the same edge function or a sibling `team-place-facets`.

**City quality:** with locality extraction ([§8.0](#80-location-capture-correctness-prerequisite))
`city` is the canonical locality, so facets group cleanly. Residual variance is minor.
`district`/`province` are captured too (D7), so **hierarchical facets** (Province →
District → City) are available later with no re-capture ([§21](#21-out-of-scope--future-work)).
Legacy rows captured before the §8.0 fix may still carry a full-address `city` until
re-saved (D8).

---

## 14. Flutter layers (clean architecture)

Follows the teams-feature layering; no use-case layer (controllers call the repository
directly); online-only.

```
lib/features/teams/
├── domain/
│   ├── entities/
│   │   ├── team_search_result.dart      # Team team; double? distanceKm; double score
│   │   └── place_facet.dart             # String city; double? lat; double? lng; int teamCount
│   └── repositories/
│       └── teams_repository.dart        # + searchTeams(...) ; + teamPlaceFacets(...)
├── data/
│   ├── models/
│   │   ├── team_search_result_dto.dart  # fromJson + toEntity
│   │   └── place_facet_dto.dart
│   ├── datasources/
│   │   └── teams_remote_datasource.dart # functions.invoke('search-teams' | 'team-place-facets')
│   └── repositories/
│       └── teams_repository_impl.dart   # exception → Failure translation
└── presentation/
    ├── state/team_search_state.dart     # query, selectedFacet?, nearMe, radiusKm, AsyncValue<List<TeamSearchResult>>
    ├── controllers/team_search_controller.dart
    ├── screens/team_search_screen.dart
    └── providers/team_search_providers.dart  # facets FutureProvider keyed by country
```

### Repository contract additions

```dart
abstract class TeamsRepository {
  // ...existing...

  Future<Either<Failure, List<TeamSearchResult>>> searchTeams({
    String? query,
    double? lat,
    double? lng,
    double? radiusKm,
    String? countryCode,
    int limit,
    int offset,
  });

  Future<Either<Failure, List<PlaceFacet>>> teamPlaceFacets({String? countryCode});
}
```

### Controller sketch

```dart
@riverpod
class TeamSearchController extends _$TeamSearchController {
  Timer? _debounce;

  @override
  TeamSearchState build() => const TeamSearchState.initial();

  void setQuery(String q) {
    state = state.copyWith(query: q);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _run);
  }

  Future<void> toggleNearMe() async { /* read device GPS via location/ provider, then _run */ }
  Future<void> selectPlace(PlaceFacet f) async { /* set center = facet lat/lng, then _run */ }
  Future<void> expandRadius() async { /* radiusKm *= 2, then _run */ }
  Future<void> loadMore() async { /* offset += limit, append */ }

  Future<void> _run() async {
    state = state.copyWith(results: const AsyncLoading());
    final res = await ref.read(teamsRepositoryProvider).searchTeams(/* ... */);
    state = res.fold(
      (f) => state.copyWith(results: AsyncError(f, StackTrace.current)),
      (list) => state.copyWith(results: AsyncData(list)),
    );
  }
}
```

(Follows the project convention: stateful controller returns `Future<void>` and carries
error in state.)

---

## 15. Presentation & UX

### Surface composition

- **Search box** (debounced ~300 ms) → name search.
- **"Near me" toggle/button** → device GPS → center.
- **Place facet chips** (horizontal, from [§13](#13-place-facets)) → tap sets center.
- **Results list** — virtualized `ListView.builder`, reuse the existing team card; show a
  coarse distance band when a center is set.

### States

| State | UI |
|---|---|
| Initial (no input) | Browse: verified/recent teams + facet chips |
| Loading | Skeleton/shimmer rows |
| Results | List + "load more" until the top-N cap |
| Empty (sparse area) | "No teams within X km — expand to {2X} km" CTA + "Be the first — create a team" |
| Error | Inline retry |

### Sparse-area behavior

Default radius 25 km (display) / 100 km (coarse candidate bound). If results are thin,
offer **one-tap radius expansion** (25 → 50 → 100). This is the village-user path.

### Surface placement — DECIDED 2026-06-11 (D9)

Team search gets a **dedicated Search tab** in the bottom nav, **replacing the Profile
tab**. Final nav order: **Home · Search · Matches · Messages · Pavilion**.

Ordering rationale (per tab-bar UX research + Instagram/X conventions):
- **Home (1)** — universal leftmost anchor; default landing route.
- **Search (2)** — priority reads left→right; discovery is the #2 intent after the feed
  (X's search placement). Adjacent to Home for a natural feed→explore swipe.
- **Matches / pool (3, center)** — the center is the prime thumb-reach + showcase slot;
  the open match pool is the app's killer differentiator and gets it.
- **Messages (4)** — retention-important but secondary to discovery.
- **Pavilion (5, rightmost)** — the conventional "me" zone (profile sits far-right in
  Instagram/X/TikTok); Pavilion absorbs the profile/workspace role.

In addition, a **search icon in the V2 header** (next to the bell, mirroring the
`onBell` pattern) on the main tabs pushes the same search screen full-screen — serving
the "look a team up from anywhere" intent.

Profile reachability is preserved: the **header avatar** opens the user's own profile
(`/profile`), and Pavilion continues to cover the "me" workspace. The `/profile` route
and `ProfileScreen` are unchanged — only the nav branch is swapped.

Router/shell impact: the `/profile` `StatefulShellBranch` is replaced by a `/search`
branch, and the branch list is **reordered** to Home · Search · Matches · Messages ·
Pavilion (branch order must match `AppShell._tabs` and the `SwipeableBranchView`
PageView order); `V2Tab.profile` → `V2Tab.search` in `AppShell._tabs` and `V2BottomNav`;
the header avatar gains an `onTap` → `/profile`.

---

## 16. Security & privacy

- **Service-role edge function bypasses RLS.** Therefore the SQL itself is the *only*
  access control: it **must** enforce `status='active' AND privacy='public'`. RLS will not
  save us here — this is the security boundary to verify in review.
- **Discovery shows public teams only.** Private teams never surface in search, even to
  their own members (a member reaches a private team through their own teams list, not
  discovery).
- **No PII in results.** Results expose team-level public fields only (name, logo, city,
  verified, distance). No owner/member identity is returned by search.
- **Country bounding** defaults to the caller's profile `country_code` to avoid
  cross-border noise (PK ↔ IN), overridable.

---

## 17. Performance & scale

- **Index usage.** Two indexes serve the query:
  - *name-only / global search* → GIN trigram on `search_name` drives.
  - *near-me browse* → GiST on `location_point` drives (`ST_DWithin` bounds candidates),
    then in-set filtering.
  PostGIS KNN/`ST_DWithin` benchmarks sub-millisecond even at billions of rows
  ([Alibaba](https://www.alibabacloud.com/blog/postgresql-nearest-neighbor-query-performance-on-billions-of-geolocation-records_597015),
  [Crunchy Data](https://www.crunchydata.com/blog/a-deep-dive-into-postgis-nearest-neighbor-search)).
- **Partial index** `WHERE status='active' AND privacy='public'` keeps the trigram index
  to the hot, discoverable set.
- **Generated-column write cost** is negligible at the app's write volume (a team is
  created rarely; `search_name` and `location_point` recompute only on write).
- **Pagination = top-N, not infinite.** A blended `score` cannot be keyset-paginated
  cleanly, and discovery is not a feed. Cap at the top ~50–100 by score, offset within the
  cap, "refine your search" past that. Keyset on `(score, team_id)` is a later option if
  needed.
- **Facet query** is a grouped scan over the hot set, `LIMIT 100`; cache client-side per
  country (it changes slowly).

---

## 18. Edge cases catalogue

| # | Case | Handling |
|---|---|---|
| E1 | Team with no `lat`/`lng` | Proximity-invisible; name/city-findable via the city net ([§10.3](#103-the-null-coordinate-safety-net)). |
| E2 | Owner-less team (owner deleted) | Backfill skips it; still name-findable. |
| E3 | Creator has no coordinate | Team created without a point → E1. |
| E4 | Two teams identical centroid (same city) | Distance 0 for both; ranked by relevance/verified/activity. |
| E5 | Sparse village (0–2 nearby) | Radius expansion CTA + "be the first". |
| E6 | Cross-border noise (PK/IN) | Country bound defaults to caller's country. |
| E7 | Long team name diluting `similarity` | Solved by `word_similarity` (`<%`). |
| E8 | Case / accent variance | Normalized `search_name`. |
| E9 | Private team | Excluded by the SQL privacy filter. |
| E10 | Empty/whitespace query | Trimmed to null → browse or near-me mode. |
| E11 | City-string fragmentation in facets | Resolved by locality extraction ([§8.0](#80-location-capture-correctness-prerequisite)); residual variance minor. Legacy pre-fix rows self-clean on re-save (D8). |
| E12 | Team relocates | Location editable in team settings (reuse the same widget) — not built in v1, noted. |
| E13 | Pagination past the cap | "Refine your search" prompt. |

---

## 19. Build plan (3 slices)

Each slice is independently reviewable / shippable.

### Slice 0 — Location-capture fix (prerequisite) — ✅ IMPLEMENTED (branch `fix/location-capture-locality`)
- **Root (`location/` feature):** added `city`/`district`/`province`/`postcode` to
  `GeoPlace` + `GeoPlaceDto`; extract from components (one shared type-priority list, two
  accessors); `reverseGeocode` now returns a `GeoPlaceDto?` — it previously dropped
  components, returning only `(label, countryCode)` ([§8.0](#80-location-capture-correctness-prerequisite)).
- **Onboarding write path** fully threaded: `onboarding_controller` (3 capture sites +
  draft + submit) → `ProfileSlice` → `completeOnboarding` (domain contract → impl →
  datasource payload). Primary path — all new users get a clean `city` + structured fields.
- **Profile-edit** does NOT re-dirty `city` (free-text field seeded from the clean value;
  `_useGps` is a mock stub with no autocomplete). It does not yet round-trip
  district/province/postcode, so an edit drops them — **deferred** to the ticket that wires
  real location capture into the edit screen (a blind merge would risk contradictory admin
  fields on a free-text city change).
- Regression test: `useMyLocation stores the locality in city, not the full address`.
- No backfill (D8 fix-forward). Independently valuable — also fixes profile display showing
  full addresses.

### Slice 1 — Data foundation
- Migration: `unaccent` ext + `f_unaccent` + `search_name` generated column + partial
  trigram index ([§7](#7-data-model--schema-changes)).
- Team-create writes the full `location` jsonb; add the "where you play" capture
  (prefill-from-creator, editable) ([§8.1](#81-team-create-change)).
- Backfill existing teams from owner profile ([§8.2](#82-backfill-existing-teams-one-off-sql)).
- **Verifiable with pure SQL — no UI.**

### Slice 2 — Search service
- `search-teams` edge function: mode-select + parameterized SQL ([§9](#9-the-search-service-edge-function)).
- Facets (`mode:"facets"` or sibling function) ([§13](#13-place-facets)).
- **Verifiable with `curl` / `functions.invoke`.**

### Slice 3 — Search surface (Flutter)
- Domain/data/presentation layers ([§14](#14-flutter-layers-clean-architecture)).
- Screen + IA wiring ([§15](#15-presentation--ux)) — placement **decided (D9)**:
  - swap the `/profile` shell branch for `/search` and **reorder branches** to
    Home · Search · Matches · Messages · Pavilion (keep `AppShell._tabs` +
    `SwipeableBranchView` in sync);
  - `V2Tab.profile` → `V2Tab.search`;
  - header avatar `onTap` → `/profile`;
  - header search icon on main tabs → push the search screen (root navigator,
    mirroring `_openBell`).

---

## 20. Test plan

Per the project's test pyramid (use-case-less → controller + repository + SQL):

- **SQL-level (seed + assert).** Seed teams across Lahore, Gujranwala, and a village.
  Assert:
  - near-me ordering by distance;
  - fuzzy name ("tigrs" → "…Tigers…", "gujjranwala" → "Gujranwala");
  - prefix fast-path ("lah" → "Lahore…");
  - null-coord team findable by name but absent from pure near-me browse;
  - private/inactive teams never returned.
- **Repository test.** Exception → `Failure` translation for `searchTeams`/`teamPlaceFacets`.
- **Controller test.** Debounce coalescing; near-me toggle reads GPS provider; results
  state transitions (loading → data/error); `loadMore` appends; `expandRadius` re-queries.
- **Edge function test.** Mode selection from input combinations; privacy filter present;
  `limit` cap enforced.

---

## 21. Out of scope / future work

- **Native-script search** (Urdu/Hindi). Would add a romanize-on-write pipeline
  (transliteration library) feeding `search_name`, or a query-time expansion. Conscious
  v1 omission ([D3](#4-decisions-log)).
- **Players / tournaments / matches search.** `profiles` and `tournaments` already have
  the same `location_point` infra; the edge-function + SQL pattern generalizes. Likely a
  tabbed unified search later.
- **Hierarchical facets** (Province → District → City) using the `district`/`province`
  already captured at write time (D7) — no re-capture needed.
- **PIN/postcode-based discovery** using the `postcode` captured at write time (D7) —
  particularly useful in India where PIN codes are user-salient. No re-capture needed.
- **City-string canonicalization** for any residual facet variance (E11).
- **"Teams near you" push** (new team created nearby) — piggyback the notifications
  broadcast, per existing convention.
- **Saved searches / history / personalized ranking.**
- **Keyset pagination** if discovery result sets grow past the top-N cap.
- **Team location editing** in team settings (E12).
- **Promote `search-teams` from edge function to RPC** once stable ([D6](#4-decisions-log)).

---

## 22. Open questions for review

1. **Surface placement.** ✅ **DECIDED 2026-06-11 (D9):** dedicated Search tab replacing
   the Profile tab + header search icon shortcut; own profile moves behind the header
   avatar. See [§15](#15-presentation--ux).
2. **Default display radius.** 25 km proposed — is that right for rural PK/IN, or should
   it start wider (e.g. 50 km) given sparsity?
3. **Ranking weights.** `w_rel 0.6 / w_geo 0.4` and `scale_km 15` are starting points —
   acceptable to tune post-launch from real usage?
4. **Verified boost.** Should `is_verified` be a tie-breaker only (current proposal) or a
   weighted term in `score`?
5. **Facets scope.** Cap at top-100 cities — enough, or do we need search-within-facets
   (type-ahead over our own place list) for dense countries?
6. **Country default.** Derive from caller's profile vs always require explicit — what if
   the user has no country on their profile?
7. **Drop legacy index.** OK to drop `teams_name_trgm` (raw name) once `search_name` is
   live?

---

## 23. References

- [Supabase — PostGIS geo queries](https://supabase.com/docs/guides/database/extensions/postgis)
- [PostgreSQL — pg_trgm (similarity / word_similarity / thresholds)](https://www.postgresql.org/docs/current/pgtrgm.html)
- [PostgreSQL — fuzzystrmatch (multibyte/non-English limits)](https://www.postgresql.org/docs/current/fuzzystrmatch.html)
- [PostgreSQL — unaccent](https://www.postgresql.org/docs/current/unaccent.html)
- [Crunchy Data — A deep dive into PostGIS nearest-neighbor search](https://www.crunchydata.com/blog/a-deep-dive-into-postgis-nearest-neighbor-search)
- [Alibaba Cloud — PostgreSQL nearest-neighbor on billions of geo records](https://www.alibabacloud.com/blog/postgresql-nearest-neighbor-query-performance-on-billions-of-geolocation-records_597015)
- [ephemeral.cx — Geographically ranked Postgres full-text search](https://ephemeral.cx/2023/03/geographically-ranked-postgres-full-text-search/)
- [Neon — Geospatial search guide](https://neon.com/guides/geospatial-search)
- [PostGIS — ST_DWithin](https://postgis.net/docs/ST_DWithin.html)
- [PostGIS — KNN distance operator `<->`](https://postgis.net/docs/geometry_distance_knn.html)
- [Google — Place Details (New): field masks & SKUs](https://developers.google.com/maps/documentation/places/web-service/place-details)
- [Google — Places (New) `AddressComponent` reference](https://developers.google.com/maps/documentation/places/web-service/reference/rest/v1/places)
- [Google — Geocoding API response (`address_components`, types)](https://developers.google.com/maps/documentation/geocoding/requests-geocoding)
- [Google — Reverse Geocoding (response example + "estimate" caveat)](https://developers.google.com/maps/documentation/geocoding/requests-reverse-geocoding)
```
