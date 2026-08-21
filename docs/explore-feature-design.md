# Explore — Unified Search & Discovery

> **Status:** v1 implemented · **Date:** 2026-08-21 · **Scope:** players · teams · matches
> **Design source:** Claude Design project `203134d0-ae75-441a-816f-87423102b795` (`Explore.dc.html`, 11 artboards)
> **Supersedes:** the Search tab from [search-feature-design.md](search-feature-design.md) D9

Explore replaces the teams-only Search tab with unified search across players,
teams and matches, plus a discovery state for the empty query.

---

## 1. What shipped in v1

| Artboard | State | Shipped |
|---|---|---|
| 04 | Search focused — recents + suggestions | ✅ |
| 05 | Results — grouped, counted, highlighted | ✅ |
| 06 | Results — loading over retained list | ✅ |
| 07 | Results — no results | ✅ |
| 08 | See all — single category + scope line | ✅ |
| — | Browse — live rail · recently active · players to follow | ✅ (replaces 01) |
| 01 | Browse — near-me pill, city facet chips, distance labels | ❌ deferred |
| 02 | Browse — sparse / radius widening | ❌ deferred |
| 03 | No location / permission denied | ❌ deferred |
| 09 | Location picker sheet | ❌ deferred |
| 10 | Tournaments | ❌ flagged off |
| 11 | Tier 2 (career stats, win rates) | ❌ no backend |

### 1.1 Deliberate deviations from the artboards

Everything else is a faithful port. These five differ, each because v1 has no
geo:

| Artboard | Design | v1 | Why |
|---|---|---|---|
| 05 · 06 · 07 | Status line ends `· All · Lahore` | `· ALL` only | There is no location scope to state. |
| 07 | Routes out: "Search all of Pakistan", "Turn off near me scope", "Add X as a team" | Only "Add X as a team" + "Clear the search" | The first two widen or drop a geo scope that does not exist — rendering them would be theatre. |
| 08 | Filter chips `Lahore ⌄` · `Type ⌄` · `Founded ⌄` | `Type ⌄` · `Founded ⌄` | Location is a facet; the other two are real columns (`team_type`, `founded_year`) and filter the fetched page client-side. |
| 08 | Count line `5 teams · Sorted by distance` | `… · Sorted by relevance` | Ordering is pure text relevance without coordinates. |
| 01 | Browse: `Teams near you` + distance column | `Recently active`, no distance | See E5. |

Faithful details worth not regressing: the loading state replaces the count
with **"Refreshing results…"**, dims retained rows to **0.45**, slides a
**40 %-wide red bar** along the field's bottom edge, and appends a single
**shimmering incoming row** — the list never blanks. See-all keeps Explore's
**search field** rather than a Material AppBar, with an ink `TEAMS ONLY ✕`
pill and a red `← ALL RESULTS` escape.

---

## 2. Decisions log

| # | Decision | Rationale |
|---|---|---|
| **E1** | **Ship v1 without any geo surface.** No near-me pill, no city facet chips, no distance labels. | Nothing in the app captured coordinates, so `location_point` was NULL on every row. Proximity ranking would sort an empty dimension, and the near-me prompt would spend iOS's **one-shot** location dialog for nothing. |
| **E2** | **No location step in onboarding.** | Deferred permission requests see ~28% higher grant rates and can double when delayed until value is shown; Apple HIG and Android docs both prescribe just-in-time. Onboarding is the worst possible moment. |
| **E3** | **Coordinates come from team-create instead** — a required "where do you play" field, resolved through Places autocomplete or GPS. | Capturing a team's location is a **content attribute, not a permission** — typing into an autocomplete needs no GPS grant. Teams are Explore's primary entity, so this single field unblocks near-me, facets, and the open match pool. |
| **E4** | **Capture ships even though the geo UI does not.** | Capture and display are separable. Deferring both means near-me launches into an equally empty database later. Capturing now means it launches warm. |
| **E5** | **Browse leads with live matches**, then recently-active teams, then players to follow — replacing the design's "Teams near you". | Ordering by recency is honest without coordinates. A section headed "near you" that is not sorted by distance is a lie. |
| **E6** | **Tournaments designed but not built.** | The tournament backend is complete but no client can create one, so the table is empty. A permanently-empty group teaches users the app is dead. |
| **E7** | **Results always default to ALL categories**; no pre-selected entity filter. The See-all screen states its scope in mono and offers one-tap escape. | NN/g: users overlook an active scope and conclude the app has nothing. |
| **E8** | **One `search-all` edge function**, not three parallel calls. | A unified relevance ordering across entity types cannot be done client-side. Groups are fetched concurrently *inside* the function. |
| **E9** | **Recent searches live in `WizardDrafts`**, not a new table, not the network, not a new package. | Search history is transient presentation state — the case CLAUDE.md §6.5 sanctions. `AppDatabase.clear()` wiping it on sign-out is a **privacy feature**: user B must not see user A's searches. |
| **E10** | **`profiles.search_name` + partial trigram**, mirroring teams. | `profiles` only had a raw-`username` trigram, so display names were not fuzzy-searchable at all. |
| **E11** | **Enforce `discoverability.appear_in_search`.** | The flag shipped in migration 0100 and was enforced **nowhere** — not in RLS, not in any client. Making players searchable without honouring it would have broken a promise already in the schema. |
| **E12** | **Unclaimed players are searchable**, with an `Unclaimed` badge and no contact fields. | spec.txt §3.1 "Path B: search-and-claim" needs the person to find their own record. Their `phone_number` / `email` were captured without consent and are never selected server-side. |
| **E13** | **Explore owns its own team DTO** rather than importing teams'. | CLAUDE.md §6.6 forbids reaching into another feature's `data/`. Only Domain→Domain is open, so the DTO is duplicated and maps to teams' `TeamSearchResult` entity. |

---

## 3. Architecture

```
Flutter  lib/features/explore/
  domain/entities      PlayerResult · MatchResult · ExploreResults · ExploreBrowse · ExploreCategory
  domain/repositories  ExploreRepository (search · browse)
  data/models          PlayerResultDto · MatchResultDto · TeamResultDto → teams' TeamSearchResult
  data/datasources     ExploreRemoteDataSource → functions.invoke('search-all')
  data/repositories    ExploreRepositoryImpl   ← the only exception→Failure site
  presentation         ExploreController (debounce · race-defeat · retained loading)
                       exploreBrowseProvider (async read)
                       RecentSearches (WizardDraftStore)
                       ExploreScreen · ExploreSeeAllScreen
        |
        v  search-all edge function (service role — the SQL IS the access control)
Postgres  profiles.search_name          (GIN trgm, partial: active AND appear_in_search)
          teams.search_name             (GIN trgm, partial: active AND public)
          unclaimed_players.search_name (GIN trgm, partial: unclaimed)
          matches <- joined via both teams' search_name + venue
```

**Controller shape.** `ExploreController` is a stateful `Notifier`, not an
`AsyncNotifier`, for three reasons an `AsyncValue` cannot serve: 300 ms
debounce, ticket-based race-defeat (a slow `lah` must not overwrite a fast
`lahore`), and loading that *retains* the previous list so results never blank
between keystrokes. All three are covered by tests.

Browse is a **separate async provider**, not a controller method — kicking it
off from `build()` required mutating state during build, which Riverpod
rejects outright and CLAUDE.md §10 forbids.

---

## 4. Routing

`/explore` replaces `/search` in shell branch 1; `V2Tab.search` -> `V2Tab.explore`.
- `/explore/all/:category?q=` — the See-all drill-down.
- `/explore/teams` — the legacy `TeamSearchScreen`, retained until geo capture
  lands and it can retire into Explore's teams category.

---

## 5. What v1.1 needs (in order)

1. **Backfill coordinates** once team-create has been capturing for a while.
2. **Profile edit**: replace the `useGps()` stub (which sleeps 900 ms and sets
   the literal string `'Korangi, Karachi'`) with the real `PlaceAutocompleteField`.
3. **Opportunistic capture**: persist the resolved city after a near-me grant.
4. **Turn the geo surface on**: near-me pill, facet chips, distance labels,
   sparse widening (artboards 01 · 02 · 03 · 09). The entities, DTOs and rows
   already carry `distanceKm` — the branches are in place and inert.
5. **The permission primer must run BEFORE the OS dialog.** Artboard 03's cream
   strip is drawn as a post-denial state; on iOS the system dialog can only ever
   be shown once, so the primer has to gate it, not follow it.
6. Retire `teams_remote_datasource.searchUsers()` (raw ILIKE, unranked, ignores
   `appear_in_search`, string-interpolated PostgREST filter).
7. Tournaments group, once tournament authoring exists.
8. Tier 2 cards, once a stats rollup exists.
