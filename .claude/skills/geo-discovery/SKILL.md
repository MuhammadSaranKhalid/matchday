---
name: geo-discovery
description: The shared geo/discovery recipe for MatchDay - team search, the open match pool, and any future location-based feature (grounds, tournaments, players). Use whenever implementing search, proximity queries, ranking, facets, or location capture/storage, on either the SQL or Flutter side.
---

# Geo & discovery recipe

Source docs (read the relevant one before building): `docs/search-feature-design.md` (teams) and `docs/match-pool-feature-design.md` (open challenges). Decision logs (D1...D10) in those files are binding.

## Core principle
**Coordinates over names.** Every discoverable thing carries lat/lng; a place name is only a way to obtain a coordinate. This is what makes village-level discovery work when gazetteers fail.

## Storage
- `location jsonb` (locality/city, district, province, postcode, lat, lng) + generated `location_point geography(point,4326)` STORED + GiST index.
- Location capture: `city` stores the LOCALITY (not the full formatted address) - Slice 0 precedent on branch fix/location-capture-locality.
- Pool listings inherit location from the posting team via trigger; per-listing override per decision D2 (check the log).

## Querying & ranking
- Proximity: `ST_DWithin` prefilter, GiST-backed.
- Text: normalized `search_name` generated column (lower+unaccent), `word_similarity` (`<%`) so partial words match ("tigers" -> "Lahore Tigers XI"), gin_trgm_ops index.
- Team search ranking: `0.6 * text_relevance + 0.4 * distance_decay`. Never hard radius cutoff when a query is present.
- Pool ranking (no text): `0.7 * distance_decay + 0.3 * recency`.
- Facet chips come from OUR OWN tables (distinct localities/cities), never a paid places API at search time - search-time API cost must stay zero.

## Surfaces
- Edge functions: `search-teams`, `list-open-challenges` - keyset pagination, validated inputs.
- Flutter: Search tab (slot 2) hosts team search; Matches tab (center) hosts the pool. The two share geo UI components: facet chips, near-me toggle, radius expansion, sparse-area empty states - build them once, reuse.

## Dependency order
Team coordinates (search Slice 1) block everything: the pool inherits `teams.location_point`, which is NULL until teams capture coordinates. Never build a pool surface assuming populated locations without checking.

## When extending to a new entity (grounds, tournaments...)
Reuse this exact stack (jsonb + generated point + GiST + word_similarity + decay blend). If you must deviate, record a new Dn decision in the relevant design doc first (docs-keeper agent can do the bookkeeping).
