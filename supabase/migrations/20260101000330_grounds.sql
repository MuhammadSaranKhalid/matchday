-- =============================================================================
-- 0330 · grounds
-- =============================================================================
-- Promotes a ground from a string to a row.
--
-- Until now a ground was `tournaments.venues` (a jsonb array of {name, city})
-- plus `matches.venue` (free text), joined by convention — the two had to
-- agree by spelling. The cost was already visible in the client, where
-- MatchDto recovered structure by splitting the text on a separator:
--
--     final parts = venue!.split(' · ');   // "<ground> · <city>"
--
-- and in `matches.ground_coordinates`, a column added for this purpose in
-- 0400 that nothing ever wrote.
--
-- Three decisions this encodes:
--
--   1. Grounds are GLOBAL, not per-tournament. A ground is a physical place
--      that hosts many cups and many friendlies. A per-tournament list means
--      every organiser retypes it and "what is on at Model Town on Saturday"
--      is unanswerable. `tournament_grounds` links a cup to the grounds it
--      uses and carries the G1/G2 label the create wizard shows.
--
--   2. `matches.venue` STAYS. Casual cricket legitimately happens at "the
--      park behind the school", and forcing every match through a registered
--      ground would either block that or fill the table with junk. Instead
--      `matches.ground_id` is added alongside, nullable: tournament fixtures
--      set it, casual matches may keep the text.
--
--   3. Double-booking is NOT a database constraint. An exclusion constraint
--      over (ground, time range) is expressible, but a rain reshuffle has to
--      pass through intermediate states where two fixtures briefly collide;
--      a hard constraint would fail those writes in an order-dependent way.
--      The check belongs in the fixture generator, which can warn and show
--      the clash. `tournament_ground_clashes` in tournament_live_ops is the
--      read side of that.
--
-- Insert rights are deliberately broad — any authenticated user may create a
-- ground, not only tournament organisers. If only the create wizard could,
-- casual matches would keep using free text and the table would never
-- accumulate, which is the entire point of making it global. Duplicates are
-- managed the way team search already manages them: a trigram index so the
-- picker can offer "did you mean …" before a new row is created. Edits stay
-- with whoever created the row until there is a moderation story.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Surface types are declared in shared_helpers.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 2. grounds.
-- -----------------------------------------------------------------------------
create table if not exists public.grounds (
  ground_id        uuid primary key default gen_random_uuid(),
  name             text not null check (length(btrim(name)) between 2 and 80),

  -- Same shape as teams.location / profiles.location: {city, lat, lng,
  -- place_id, country_code}. The generated point is what proximity reads.
  location         jsonb not null default '{}'::jsonb,
  location_point   geography(point, 4326) generated always as (
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
                    ) stored,

  -- The "Turf · floodlights" line the create wizard collects and previously
  -- discarded into free text.
  surface          public.ground_surface,
  has_floodlights  boolean not null default false,
  notes            text check (notes is null or length(notes) <= 300),

  -- Normalised for trigram search. f_unaccent is the IMMUTABLE two-arg
  -- wrapper defined in 20260101000000_shared_helpers.
  search_name      text generated always as (
                      lower(public.f_unaccent(name))
                    ) stored,

  created_by       uuid references public.profiles(user_id) on delete set null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index if not exists grounds_city
  on public.grounds ((location->>'city'));
create index if not exists grounds_location_point
  on public.grounds using gist (location_point);
create index if not exists grounds_search_trgm
  on public.grounds using gin (search_name gin_trgm_ops);
create index if not exists grounds_created_by
  on public.grounds (created_by);

drop trigger if exists grounds_set_updated_at on public.grounds;
create trigger grounds_set_updated_at
  before update on public.grounds
  for each row execute function public.set_updated_at();

alter table public.grounds enable row level security;

-- A ground is a public place; everyone can see it.
drop policy if exists "grounds_read_public" on public.grounds;
create policy "grounds_read_public"
  on public.grounds for select
  to anon, authenticated
  using (true);

drop policy if exists "grounds_insert_authenticated" on public.grounds;
create policy "grounds_insert_authenticated"
  on public.grounds for insert
  to authenticated
  with check ((select auth.uid()) = created_by);

-- Only the creator may correct a ground. Broad edit rights on a shared row
-- invite vandalism, and there is no moderation queue yet.
drop policy if exists "grounds_update_creator" on public.grounds;
create policy "grounds_update_creator"
  on public.grounds for update
  to authenticated
  using ((select auth.uid()) = created_by)
  with check ((select auth.uid()) = created_by);

drop policy if exists "grounds_delete_creator" on public.grounds;
create policy "grounds_delete_creator"
  on public.grounds for delete
  to authenticated
  using ((select auth.uid()) = created_by);

-- -- -----------------------------------------------------------------------------
-- -- 4. matches.ground_id — additive, nullable.
-- -- -----------------------------------------------------------------------------
-- -- matches.ground_id and its index are declared in 20260101000400_matches.sql.
-- -- This file was renumbered from 20260831000000 to 20260101000330 on 2026-09-06
-- -- so that it runs BEFORE matches, which lets that FK be an inline column
-- -- reference instead of a late ALTER. grounds depends only on profiles (0100)
-- -- and tournaments (0300), so nothing else moves.

-- -- (matches.ground_coordinates carried a 'DEPRECATED — never written' comment
-- --  here. It was dropped at the source on 2026-09-06; coordinates live on
-- --  grounds.location_point and only there.)

-- -- -----------------------------------------------------------------------------
-- -- 5. Backfill.
-- -- -----------------------------------------------------------------------------
-- -- Create a ground per distinct name already listed on a tournament, attributed
-- -- to that tournament's creator. `venues` holds [{name, city}]; the create
-- -- wizard also wrote the surface/floodlight line into `city`, so it is read as
-- -- a note rather than guessed at.
-- with listed as (
--   select distinct
--     btrim(v->>'name')                       as name,
--     nullif(btrim(v->>'city'), '')           as detail,
--     t.created_by,
--     t.location->>'city'                     as tournament_city
--   from public.tournaments t
--   cross join lateral jsonb_array_elements(
--     case when jsonb_typeof(t.venues) = 'array' then t.venues else '[]'::jsonb end
--   ) as v
--   where btrim(coalesce(v->>'name', '')) <> ''
-- ),
-- deduped as (
--   -- One row per (normalised name, city) so two cups naming the same ground
--   -- share it rather than each getting their own.
--   select distinct on (lower(public.f_unaccent(name)), coalesce(tournament_city, ''))
--     name, detail, created_by, tournament_city
--   from listed
--   order by lower(public.f_unaccent(name)), coalesce(tournament_city, ''), name
-- )
-- insert into public.grounds (name, location, notes, created_by)
-- select
--   d.name,
--   case
--     when d.tournament_city is null then '{}'::jsonb
--     else jsonb_build_object('city', d.tournament_city)
--   end,
--   d.detail,
--   d.created_by
-- from deduped d
-- where not exists (
--   select 1 from public.grounds g
--    where lower(public.f_unaccent(g.name)) = lower(public.f_unaccent(d.name))
--      and coalesce(g.location->>'city', '') = coalesce(d.tournament_city, '')
-- );

-- -----------------------------------------------------------------------------
-- 6. Ground search for the picker (the "did you mean …" step).
-- -----------------------------------------------------------------------------
-- Ranked by trigram similarity, then by proximity when the caller supplies a
-- coordinate. Mirrors the ranking recipe used by team search: never a hard
-- radius cutoff, just a distance tie-break.
create or replace function public.search_grounds(
  p_query text default null,
  p_lat   double precision default null,
  p_lng   double precision default null,
  p_limit integer default 12
)
returns table (
  ground_id       uuid,
  name            text,
  city            text,
  surface         text,
  has_floodlights boolean,
  distance_km     double precision,
  match_score     real
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with origin as (
    select case
             when p_lat is null or p_lng is null then null
             else st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography
           end as pt
  )
  select
    g.ground_id,
    g.name,
    g.location->>'city',
    g.surface::text,
    g.has_floodlights,
    case
      when o.pt is null or g.location_point is null then null
      else st_distance(g.location_point, o.pt) / 1000.0
    end,
    case
      when p_query is null or btrim(p_query) = '' then 1.0::real
      else word_similarity(lower(public.f_unaccent(p_query)), g.search_name)
    end
  from public.grounds g
  cross join origin o
  where
    p_query is null
    or btrim(p_query) = ''
    or lower(public.f_unaccent(p_query)) <% g.search_name
  order by
    -- Strongest name match first; with no query every row scores equally and
    -- the distance tie-break below becomes the real ordering.
    case
      when p_query is null or btrim(p_query) = '' then 0::real
      else word_similarity(lower(public.f_unaccent(p_query)), g.search_name)
    end desc,
    case
      when o.pt is null or g.location_point is null then null
      else st_distance(g.location_point, o.pt)
    end asc nulls last,
    g.name asc
  limit greatest(1, least(coalesce(p_limit, 12), 50));
$$;

revoke all on function public.search_grounds(text, double precision, double precision, integer) from public;
grant execute on function public.search_grounds(text, double precision, double precision, integer) to authenticated;
