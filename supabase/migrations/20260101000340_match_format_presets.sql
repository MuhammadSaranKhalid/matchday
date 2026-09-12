-- =============================================================================
-- 0340 · match_format_presets
-- =============================================================================
-- System match-format catalog and its compatibility view.
-- Spec: docs/matches-schema-architecture.md

-- This is reference data used by the format picker. Its final schema lives
-- here with its eight system presets, indexes, RLS and compatibility view.
-- The superseded preset_id/rules_config shape and late conditional rebuild
-- were consolidated into this declaration.

drop view if exists public.format_presets cascade;

drop table if exists public.match_format_presets cascade;

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

-- The compatibility view follows the table's RLS policy.
create or replace view public.format_presets
  with (security_invoker = on) as
  select * from public.match_format_presets;

-- -----------------------------------------------------------------------------
-- Read access.
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
-- The system catalog.
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

-- Index the profile FK for account deletion and joins (Supabase advisor 0001).
create index if not exists idx_match_format_presets_created_by
  on public.match_format_presets (created_by);
