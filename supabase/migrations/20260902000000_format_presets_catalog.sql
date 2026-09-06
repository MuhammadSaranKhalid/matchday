-- =============================================================================
-- 20260902000000 · format_presets_catalog
-- =============================================================================
-- Captures a schema change that was only ever applied by hand.
--
-- 20260101000400 created `match_format_presets` as
--   (preset_id, name, match_format, description, rules_config, is_active, …)
-- but the app reads it as
--   (id, label, sort_order, config, default_scoring_mode, is_active, …)
-- — see FormatPresetsRemoteDataSource + FormatPresetDto, which select
-- `is_active`, order by `sort_order`, and parse `config` as the same open
-- jsonb shape `matches.format` uses.
--
-- The reworked table exists on the dev machine but in no migration, so every
-- other environment still has the 0400 shape. There the match-setup format
-- step orders by a column that does not exist, PostgREST answers 400, and the
-- picker cannot load. The catalog is also empty, so even a successful read
-- would render nothing.
--
-- This migration makes the committed schema the one the app actually talks to,
-- and seeds the eight system presets. It is written to be a no-op where the
-- reworked shape is already present.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Reshape, but only where the old shape is still in place.
-- -----------------------------------------------------------------------------
-- The catalog is reference data with no inbound foreign keys, so replacing it
-- outright is safe; the seed below restores its contents either way.
do $$
begin
  if not exists (
    select 1 from information_schema.columns
     where table_schema = 'public'
       and table_name   = 'match_format_presets'
       and column_name  = 'id'
  ) then
    drop view if exists public.format_presets;
    drop table if exists public.match_format_presets;

    create table public.match_format_presets (
      id                   text primary key,
      label                text not null,
      sort_order           integer not null default 0,
      config               jsonb not null,
      is_active            boolean not null default true,
      -- System presets ship with the app and must not be edited away by a
      -- user; anything a captain saves later is is_system = false.
      is_system            boolean not null default false,
      created_by           uuid references public.profiles(user_id) on delete set null,
      default_scoring_mode public.scoring_mode not null default 'live_ball_by_ball',
      created_at           timestamptz not null default now()
    );
  end if;
end
$$;

-- -----------------------------------------------------------------------------
-- 2. The view the 0400 migration introduced, rebuilt over the new shape.
-- -----------------------------------------------------------------------------
-- security_invoker so the view respects match_format_presets' RLS rather than
-- running as its owner (Supabase advisor 0010). `create or replace view` does
-- NOT inherit the options of the view it replaces, so this has to be restated
-- here as well as at the original declaration in 0400.
create or replace view public.format_presets
  with (security_invoker = on) as
  select * from public.match_format_presets;

-- -----------------------------------------------------------------------------
-- 3. Read access.
-- -----------------------------------------------------------------------------
-- A public catalog: readable by anyone, written only by migrations.
alter table public.match_format_presets enable row level security;

drop policy if exists "match_format_presets_read_all" on public.match_format_presets;
create policy "match_format_presets_read_all"
  on public.match_format_presets for select
  to anon, authenticated
  using (true);

grant select on public.match_format_presets to anon, authenticated;
grant select on public.format_presets       to anon, authenticated;

-- -----------------------------------------------------------------------------
-- 4. The system catalog.
-- -----------------------------------------------------------------------------
-- `config` is the same open jsonb the match aggregate uses, so a key absent
-- here means "take the engine default" rather than "zero".
insert into public.match_format_presets
  (id, label, sort_order, config, is_active, is_system, default_scoring_mode)
values
  ('t20',     'T20',         1, '{"players_per_team": 11, "overs_per_innings": 20, "max_overs_per_bowler": 4}'::jsonb,  true, true, 'live_ball_by_ball'),
  ('t10',     'T10',         2, '{"players_per_team": 11, "overs_per_innings": 10, "max_overs_per_bowler": 2}'::jsonb,  true, true, 'live_ball_by_ball'),
  ('odi',     'ODI',         3, '{"players_per_team": 11, "overs_per_innings": 50, "max_overs_per_bowler": 10}'::jsonb, true, true, 'live_ball_by_ball'),
  ('list_a',  'List A',      4, '{"players_per_team": 11, "overs_per_innings": 50, "max_overs_per_bowler": 10}'::jsonb, true, true, 'live_ball_by_ball'),
  ('hundred', 'The Hundred', 5, '{"balls_per_over": 5, "end_change_balls": 10, "players_per_team": 11, "overs_per_innings": 20, "max_overs_per_bowler": 4}'::jsonb, true, true, 'live_ball_by_ball'),
  ('super8',  '8-a-side',    6, '{"players_per_team": 8, "overs_per_innings": 20, "max_overs_per_bowler": 4}'::jsonb,   true, true, 'live_ball_by_ball'),
  ('tape',    'Tape-ball',   7, '{"ball_type": "tape", "players_per_team": 11, "overs_per_innings": 20, "max_overs_per_bowler": 4}'::jsonb, true, true, 'live_ball_by_ball'),
  ('box',     'Box cricket', 8, '{"players_per_team": 8, "overs_per_innings": 6, "max_overs_per_bowler": 2}'::jsonb,    true, true, 'post_match_scorecard')
on conflict (id) do update set
  label                = excluded.label,
  sort_order           = excluded.sort_order,
  config               = excluded.config,
  is_active            = excluded.is_active,
  is_system            = excluded.is_system,
  default_scoring_mode = excluded.default_scoring_mode;

-- The picker reads active presets in display order.
create index if not exists idx_match_format_presets_active_order
  on public.match_format_presets (sort_order)
  where is_active;

-- FK index (Supabase advisor 0001). created_by is declared on the rebuilt table
-- in this migration, not in 0400, so the index belongs here too.
create index if not exists idx_match_format_presets_created_by
  on public.match_format_presets (created_by);
