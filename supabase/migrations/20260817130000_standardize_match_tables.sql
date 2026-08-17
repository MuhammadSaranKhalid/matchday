-- =============================================================================
-- Migration: Standardize Match Domain Tables
-- =============================================================================
-- Renames core match domain tables to clean, standardized, industry-aligned names:
--   1. public.match_requests   -> public.match_challenges
--   2. public.balls            -> public.match_deliveries
--   3. public.format_presets   -> public.match_format_presets
--
-- Preserves backwards compatibility by providing view aliases where appropriate.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Standardize format_presets -> match_format_presets
-- -----------------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_tables where schemaname = 'public' and tablename = 'format_presets') then
    alter table public.format_presets rename to match_format_presets;
  end if;
end $$;

-- Backward compatibility view
create or replace view public.format_presets as
  select * from public.match_format_presets;

-- -----------------------------------------------------------------------------
-- 2. Standardize match_requests -> match_challenges
-- -----------------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_tables where schemaname = 'public' and tablename = 'match_requests') then
    alter table public.match_requests rename to match_challenges;
  end if;
end $$;

-- Backward compatibility view
create or replace view public.match_requests as
  select * from public.match_challenges;

-- -----------------------------------------------------------------------------
-- 3. Standardize balls -> match_deliveries
-- -----------------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_tables where schemaname = 'public' and tablename = 'balls') then
    alter table public.balls rename to match_deliveries;
  end if;
end $$;

-- Backward compatibility view
create or replace view public.balls as
  select * from public.match_deliveries;

-- -----------------------------------------------------------------------------
-- Refresh RLS Policies on Standardized Tables
-- -----------------------------------------------------------------------------
alter table public.match_format_presets enable row level security;
alter table public.match_challenges enable row level security;
alter table public.match_deliveries enable row level security;

-- Format Presets: Public read
drop policy if exists "format_presets_read_all" on public.match_format_presets;
drop policy if exists "match_format_presets_read_all" on public.match_format_presets;
create policy "match_format_presets_read_all"
  on public.match_format_presets
  for select
  to authenticated, anon
  using (true);

-- Match Challenges: Read policy
drop policy if exists "match_requests_read_team_managers" on public.match_challenges;
drop policy if exists "match_challenges_select" on public.match_challenges;
create policy "match_challenges_select"
  on public.match_challenges
  for select
  to authenticated
  using (
    public.is_team_manager(from_team_id)
    or (to_team_id is not null and public.is_team_manager(to_team_id))
    or (to_team_id is null and status = 'pending')
  );

-- Match Deliveries: Read policy
drop policy if exists "balls_select" on public.match_deliveries;
drop policy if exists "match_deliveries_select" on public.match_deliveries;
create policy "match_deliveries_select"
  on public.match_deliveries
  for select
  to authenticated, anon
  using (true);

-- Match Deliveries: Scorer write policy
drop policy if exists "balls_insert" on public.match_deliveries;
drop policy if exists "match_deliveries_insert" on public.match_deliveries;
create policy "match_deliveries_insert"
  on public.match_deliveries
  for insert
  to authenticated
  with check (public._can_score_match(match_id));
