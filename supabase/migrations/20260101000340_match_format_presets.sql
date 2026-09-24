-- =============================================================================
-- Migration: 20260101000340_match_format_presets.sql
-- =============================================================================

-- 0340 · match_format_presets
-- System match-format catalog.
-- Spec: docs/database/CRICKET_FORMATS.md
-- This is reference data used by the format picker.

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.match_format_presets (
  id                   text primary key,
  label                text not null,
  sport_id             text not null default 'cricket'
    references public.sports (sport_id),
  sort_order           integer not null default 0,
  config               jsonb not null,
  is_active            boolean not null default true,
  -- System presets ship with the app and must not be edited away by a
  -- user; anything a captain saves later is is_system = false.
  is_system            boolean not null default false,
  created_by           uuid
    references public.profiles (user_id)
    on delete set null,
  created_at           timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

-- Read access.
-- A public catalog: readable by anyone, written only by migrations.
alter table public.match_format_presets enable row level security;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

drop policy if exists "match_format_presets_read_all" on public.match_format_presets;

create policy "match_format_presets_read_all"
  on public.match_format_presets
  for select
  to anon, authenticated
  using (true);

-- -----------------------------------------------------------------------------
-- Permissions
-- -----------------------------------------------------------------------------

grant select on public.match_format_presets to anon, authenticated;

-- -----------------------------------------------------------------------------
-- Dependency-ordered operations
-- -----------------------------------------------------------------------------

-- Match format presets
do $$
begin
  if not exists(
    select
      1
    from
      pg_constraint
    where
      conrelid = 'public.match_format_presets'::regclass
      and conname = 'match_format_presets_sport_id_fkey') then
  alter table public.match_format_presets
    add constraint match_format_presets_sport_id_fkey foreign key(sport_id) references public.sports(sport_id) on update restrict on delete restrict;
end if;
end
$$;

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

create index if not exists match_format_presets_sport_id
  on public.match_format_presets (
    sport_id
  );

comment on column public.match_format_presets.sport_id is
  'Sport whose match rules this preset represents.';

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger match_format_presets_sport_immutable
  before update of sport_id on public.match_format_presets
  for each row
  execute function public.prevent_sport_reassignment();

-- -----------------------------------------------------------------------------
-- Data changes
-- -----------------------------------------------------------------------------

-- Delete discontinued / unsupported catalog rows
delete from public.match_format_presets
where id in ('odi', 'list_a', 'hundred', 'super8', 'tape', 'box');

-- Final V1 limited-overs system catalog:
insert into public.match_format_presets
  (id, label, sort_order, config, is_active, is_system)
values
  (
    't20',
    'T20',
    10,
    '{"overs_per_innings": 20, "players_per_team": 11, "balls_per_over": 6, "innings_per_side": 1, "max_overs_per_bowler": 4}'::jsonb,
    true,
    true
  ),
  (
    't10',
    'T10',
    20,
    '{"overs_per_innings": 10, "players_per_team": 11, "balls_per_over": 6, "innings_per_side": 1, "max_overs_per_bowler": 2}'::jsonb,
    true,
    true
  ),
  (
    'quick_6',
    '6 Over',
    30,
    '{"overs_per_innings": 6, "players_per_team": 8, "balls_per_over": 6, "innings_per_side": 1, "max_overs_per_bowler": 2}'::jsonb,
    true,
    true
  ),
  (
    'quick_8',
    '8 Over',
    40,
    '{"overs_per_innings": 8, "players_per_team": 8, "balls_per_over": 6, "innings_per_side": 1, "max_overs_per_bowler": 2}'::jsonb,
    true,
    true
  ),
  (
    'over_30',
    '30 Over',
    50,
    '{"overs_per_innings": 30, "players_per_team": 11, "balls_per_over": 6, "innings_per_side": 1, "max_overs_per_bowler": 6}'::jsonb,
    true,
    true
  ),
  (
    'over_40',
    '40 Over',
    60,
    '{"overs_per_innings": 40, "players_per_team": 11, "balls_per_over": 6, "innings_per_side": 1, "max_overs_per_bowler": 8}'::jsonb,
    true,
    true
  ),
  (
    'over_45',
    '45 Over',
    70,
    '{"overs_per_innings": 45, "players_per_team": 11, "balls_per_over": 6, "innings_per_side": 1, "max_overs_per_bowler": 9}'::jsonb,
    true,
    true
  ),
  (
    'over_50',
    '50 Over',
    80,
    '{"overs_per_innings": 50, "players_per_team": 11, "balls_per_over": 6, "innings_per_side": 1, "max_overs_per_bowler": 10}'::jsonb,
    true,
    true
  ),
  (
    'custom',
    'Custom',
    90,
    '{"overs_per_innings": 12, "players_per_team": 11, "balls_per_over": 6, "innings_per_side": 1, "max_overs_per_bowler": 3}'::jsonb,
    true,
    true
  )
on conflict (id) do update
  set
    label = excluded.label,
    sort_order = excluded.sort_order,
    config = excluded.config,
    is_active = excluded.is_active,
    is_system = excluded.is_system;

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

-- The picker reads active presets in display order.
create index if not exists idx_match_format_presets_active_order
  on public.match_format_presets (
    sport_id,
    sort_order
  )
  where is_active;

-- Index the profile FK for account deletion and joins (Supabase advisor 0001).
create index if not exists idx_match_format_presets_created_by
  on public.match_format_presets (
    created_by
  );
