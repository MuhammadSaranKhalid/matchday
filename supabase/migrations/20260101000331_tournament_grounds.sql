-- =============================================================================
-- 0331 · tournament_grounds — grounds assigned to each tournament
-- =============================================================================

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
  to anon, authenticated
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
