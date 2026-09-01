-- =============================================================================
-- 20260831000000 · grounds
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
--      the clash. `tournament_ground_clashes` below is the read side of that.
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
-- 1. Surface enum.
-- -----------------------------------------------------------------------------
do $$ begin
  create type public.ground_surface as enum (
    'turf', 'matting', 'concrete', 'astro', 'other'
  );
exception when duplicate_object then null;
end $$;

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
  -- wrapper defined in 20260611000000_teams_search.
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

-- -----------------------------------------------------------------------------
-- 3. tournament_grounds — which grounds a cup uses, and in what order.
-- -----------------------------------------------------------------------------
create table if not exists public.tournament_grounds (
  tournament_id uuid not null
                   references public.tournaments(tournament_id) on delete cascade,
  ground_id     uuid not null
                   references public.grounds(ground_id) on delete restrict,
  -- Drives the G1 / G2 labels on the wizard and the Live Ops board.
  sort_order    integer not null default 0,
  created_at    timestamptz not null default now(),

  primary key (tournament_id, ground_id)
);

create index if not exists tournament_grounds_ground
  on public.tournament_grounds (ground_id);

alter table public.tournament_grounds enable row level security;

-- Visible to anyone who can see the tournament itself.
drop policy if exists "tournament_grounds_read" on public.tournament_grounds;
create policy "tournament_grounds_read"
  on public.tournament_grounds for select
  using (
    public.is_tournament_organizer(tournament_id)
    or exists (
      select 1 from public.tournaments t
       where t.tournament_id = tournament_grounds.tournament_id
         and t.privacy = 'public'
    )
  );

drop policy if exists "tournament_grounds_write_organizer"
  on public.tournament_grounds;
create policy "tournament_grounds_write_organizer"
  on public.tournament_grounds for all
  to authenticated
  using (public.is_tournament_organizer(tournament_id))
  with check (public.is_tournament_organizer(tournament_id));

-- -----------------------------------------------------------------------------
-- 4. matches.ground_id — additive, nullable.
-- -----------------------------------------------------------------------------
alter table public.matches
  add column if not exists ground_id uuid
    references public.grounds(ground_id) on delete set null;

-- The scheduler's lookup: "what else is on this ground around this time".
create index if not exists matches_ground_time
  on public.matches (ground_id, scheduled_start_time)
  where ground_id is not null;

comment on column public.matches.venue is
  'Free-text ground name. Retained for casual matches with no registered '
  'ground. Tournament fixtures should set ground_id and mirror the name here '
  'for display.';

comment on column public.matches.ground_coordinates is
  'DEPRECATED — never written. Coordinates live on grounds.location_point. '
  'Kept until a later migration drops it.';

-- -----------------------------------------------------------------------------
-- 5. Backfill.
-- -----------------------------------------------------------------------------
-- Create a ground per distinct name already listed on a tournament, attributed
-- to that tournament's creator. `venues` holds [{name, city}]; the create
-- wizard also wrote the surface/floodlight line into `city`, so it is read as
-- a note rather than guessed at.
with listed as (
  select distinct
    btrim(v->>'name')                       as name,
    nullif(btrim(v->>'city'), '')           as detail,
    t.created_by,
    t.location->>'city'                     as tournament_city
  from public.tournaments t
  cross join lateral jsonb_array_elements(
    case when jsonb_typeof(t.venues) = 'array' then t.venues else '[]'::jsonb end
  ) as v
  where btrim(coalesce(v->>'name', '')) <> ''
),
deduped as (
  -- One row per (normalised name, city) so two cups naming the same ground
  -- share it rather than each getting their own.
  select distinct on (lower(public.f_unaccent(name)), coalesce(tournament_city, ''))
    name, detail, created_by, tournament_city
  from listed
  order by lower(public.f_unaccent(name)), coalesce(tournament_city, ''), name
)
insert into public.grounds (name, location, notes, created_by)
select
  d.name,
  case
    when d.tournament_city is null then '{}'::jsonb
    else jsonb_build_object('city', d.tournament_city)
  end,
  d.detail,
  d.created_by
from deduped d
where not exists (
  select 1 from public.grounds g
   where lower(public.f_unaccent(g.name)) = lower(public.f_unaccent(d.name))
     and coalesce(g.location->>'city', '') = coalesce(d.tournament_city, '')
);

-- Link each tournament to the grounds it listed, preserving array order.
insert into public.tournament_grounds (tournament_id, ground_id, sort_order)
select
  t.tournament_id,
  g.ground_id,
  (v.ord - 1)::int
from public.tournaments t
cross join lateral jsonb_array_elements(
  case when jsonb_typeof(t.venues) = 'array' then t.venues else '[]'::jsonb end
) with ordinality as v(elem, ord)
join public.grounds g
  on lower(public.f_unaccent(g.name)) = lower(public.f_unaccent(btrim(v.elem->>'name')))
 and coalesce(g.location->>'city', '') = coalesce(t.location->>'city', '')
where btrim(coalesce(v.elem->>'name', '')) <> ''
on conflict (tournament_id, ground_id) do nothing;

-- Point existing tournament fixtures at their ground where the text matches a
-- ground now linked to that same tournament. Anything ambiguous is left alone
-- with its text intact rather than guessed at.
update public.matches m
   set ground_id = g.ground_id
  from public.tournament_grounds tg
  join public.grounds g on g.ground_id = tg.ground_id
 where m.ground_id is null
   and m.tournament_id is not null
   and tg.tournament_id = m.tournament_id
   and lower(public.f_unaccent(btrim(m.venue)))
       = lower(public.f_unaccent(g.name));

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

-- -----------------------------------------------------------------------------
-- 7. Fixture clashes on a ground (the soft check, per decision 3).
-- -----------------------------------------------------------------------------
-- Returns pairs of fixtures sharing a ground whose scheduled starts fall
-- within p_window of each other. The console shows these; nothing blocks the
-- write, so a rain reshuffle can pass through a colliding intermediate state.
create or replace function public.tournament_ground_clashes(
  p_tournament_id uuid,
  p_window        interval default interval '3 hours'
)
returns table (
  ground_id     uuid,
  ground_name   text,
  match_a_id    uuid,
  match_a_start timestamptz,
  match_b_id    uuid,
  match_b_start timestamptz,
  gap           interval
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    g.ground_id,
    g.name,
    a.match_id,
    a.scheduled_start_time,
    b.match_id,
    b.scheduled_start_time,
    b.scheduled_start_time - a.scheduled_start_time
  from public.matches a
  join public.matches b
    on b.tournament_id = a.tournament_id
   and b.ground_id = a.ground_id
   -- Ordered pair, so each clash is reported once rather than twice.
   and (a.scheduled_start_time, a.match_id) < (b.scheduled_start_time, b.match_id)
  join public.grounds g on g.ground_id = a.ground_id
  where a.tournament_id = p_tournament_id
    and a.ground_id is not null
    and a.status not in ('completed', 'abandoned', 'no_result', 'walkover')
    and b.status not in ('completed', 'abandoned', 'no_result', 'walkover')
    and b.scheduled_start_time - a.scheduled_start_time < p_window
    and public.is_tournament_organizer(p_tournament_id)
  order by g.name, a.scheduled_start_time;
$$;

revoke all on function public.tournament_ground_clashes(uuid, interval) from public;
grant execute on function public.tournament_ground_clashes(uuid, interval) to authenticated;
