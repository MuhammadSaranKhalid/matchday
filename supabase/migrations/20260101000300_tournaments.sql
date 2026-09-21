-- Migration file: 20260101000300_tournaments.sql

-- 0300 · tournaments
-- Spec §3.3, §3.4, §3.5, §3.11, §3.15. Feature 3 (Tournament Structure).
--
-- A tournament is a brackets-of-matches container. Knockout / round-robin /
-- league structures are first-class today; group_knockout (v1.1) and
-- double_elimination (v1.2) are reserved enum values.
--
-- Lifecycle (`status`):
--   draft         organizer is still setting it up; only org-side reads
--   registration  open for team registration via tournament_teams (0310)
--   upcoming      registration closed, fixtures generated (matches in 0400)
--   live          first ball bowled
--   completed     final result submitted; awards may follow
--   cancelled     organizer pulled the plug pre-tournament
--   abandoned     started but couldn't finish
--
-- format / rules (jsonb):
--   These are intentionally schemaless. Match-format defaults (§3.4) live
--   in `format`; tournament rules (§3.5: powerplay, gender restriction,
--   tie-breaker order, etc.) in `rules`. Reads always pull the full row,
--   so query patterns don't pressure us to promote keys to columns.
--
-- Privacy:
--   - public  (default) — readable by everyone.
--   - private          — only organizers see drafts; tournament detail is
--                        manager-of-registered-team or organizer.
--   Spec §3.15 RLS pattern.
--
-- Storage: tournament-banners + tournament-logos buckets, both keyed by
-- <tournament_id>/<filename>. Organizer-only write.
-- Enums moved to 20260101000000_shared_helpers.sql (the enum catalogue),
-- 2026-09-06 — one enum, one definition, declared before anything uses it.
-- tournaments table.

-- Section: Tables and constraints

create table public.tournaments(
  tournament_id         uuid primary key default gen_random_uuid(),
  tournament_name       text not null check (length(tournament_name) between 3 and 100),
  tournament_type       public.tournament_type not null,
  banner_image_url      text,
  logo_url              text,
  sport_id              text not null default 'cricket' references public.sports(sport_id),
  description           text check (description is null or length(description) <= 1000),
  format                jsonb not null default '{}'::jsonb,
  rules                 jsonb not null default '{}'::jsonb,
  start_date            date,
  end_date              date,
  registration_deadline date,
  -- Free-form list of grounds being used: [{"name":"...", "city":"..."}, ...].
  venues                jsonb not null default '[]'::jsonb,
  prize_details         text check (prize_details is null or length(prize_details) <= 500),
  entry_fee             numeric(10, 2) check (entry_fee is null or entry_fee >= 0),
  max_teams             integer check (max_teams is null or max_teams between 2 and 256),
  min_teams             integer check (min_teams is null or min_teams >= 2),
  -- Nullable + ON DELETE SET NULL so a self-service account deletion
  -- (delete_user RPC in 0700) anonymises the creator without orphaning
  -- the tournament. Same posture as matches.created_by (0400).
  created_by            uuid references public.profiles(user_id) on delete set null,
  organizers            uuid[] not null default '{}',
  -- Per-match scorer assignment lives in match_officials (0407) — a
  -- tournament-level scorer set has no live consumer in the current
  -- schema. If a tournament-wide default ever ships, model it as a
  -- separate tournament_officials table mirroring 0407.
  status                public.tournament_status not null default 'draft',
  privacy               public.tournament_privacy not null default 'public',
  -- Per-tournament award winners (best batter / bowler / player of the
  -- tournament …), written by the leaderboard RPCs in 20260905000000.
  awards                jsonb not null default '{}'::jsonb,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  constraint min_le_max_teams check (min_teams is null or max_teams is null or min_teams <= max_teams),
  constraint end_after_start check (start_date is null or end_date is null or end_date >= start_date),
  constraint deadline_before_start check (registration_deadline is null or start_date is null or registration_deadline <= start_date)
);

-- Section: Indexes

create index tournaments_creator on public.tournaments(created_by);

create index tournaments_organizers_gin on public.tournaments using gin(organizers);

create index tournaments_status on public.tournaments(status);

create index tournaments_start_date on public.tournaments(start_date);

create index tournaments_sport_id on public.tournaments(sport_id);

-- Section: Triggers

create trigger tournaments_set_updated_at
  before update on public.tournaments for each row
  execute function public.set_updated_at();

create trigger tournaments_sport_immutable
  before update of sport_id on public.tournaments for each row
  execute function public.prevent_sport_reassignment();

-- Section: Dependency-ordered operations

-- Tournaments
do $$
begin
  if not exists(
    select
      1
    from
      pg_constraint
    where
      conrelid = 'public.tournaments'::regclass
      and conname = 'tournaments_sport_id_fkey') then
  alter table public.tournaments
    add constraint tournaments_sport_id_fkey foreign key(sport_id) references public.sports(sport_id) on update restrict on delete restrict;
end if;
end
$$;

-- Section: Functions

-- is_tournament_organizer — universal RLS predicate. Same pattern as
-- is_team_manager (0200): SECURITY DEFINER + stable, used by every
-- tournament-touching policy / RPC.
create or replace function public.is_tournament_organizer(
  p_tournament_id uuid
)
  returns boolean
  language sql
  stable
  security definer
  set search_path = public, pg_temp
  as $$
  select
    exists(
      select
        1
      from
        public.tournaments t
      where
        t.tournament_id = p_tournament_id
        and(t.created_by = auth.uid()
          or auth.uid() = any(t.organizers)));
$$;

revoke all on function public.is_tournament_organizer(uuid) from public;

grant execute on function public.is_tournament_organizer(uuid) to authenticated;

-- Section: Enable row-level security

-- RLS — drafts visible only to creator/organizers; otherwise public read for
-- public tournaments. Updates by organizers; only creator can delete.
alter table public.tournaments enable row level security;

-- Section: Policies

create policy "tournaments_read_visible" on public.tournaments
  for select to anon, authenticated
  using (privacy = 'public'
    or (
      select
        auth.uid()) = created_by
        or (
          select
            auth.uid()) = any (organizers));

create policy "tournaments_insert_self_creator" on public.tournaments
  for insert to authenticated
  with check ((
    select
      auth.uid()) = created_by);

create policy "tournaments_update_organizers" on public.tournaments
  for update to authenticated
  using ((
    select
      auth.uid()) = created_by
      or (
        select
          auth.uid()) = any (organizers))
  with check ((
    select
      auth.uid()) = created_by
      or (
        select
          auth.uid()) = any (organizers));

create policy "tournaments_delete_creator" on public.tournaments
  for delete to authenticated
  using ((
    select
      auth.uid()) = created_by);

-- Section: Integrations

-- Storage buckets: tournament-banners (10 MB cap) + tournament-logos (5 MB).
-- Public read; organizer-only write under <tournament_id>/.
insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values
  ('tournament-banners', 'tournament-banners', true, 10 * 1024 * 1024, array['image/jpeg', 'image/png', 'image/webp']),
('tournament-logos', 'tournament-logos', true, 5 * 1024 * 1024, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id)
  do nothing;

-- Section: Policies (continued)

create policy "tournament_banners_read_public" on storage.objects
  for select
  using (bucket_id = 'tournament-banners');

create policy "tournament_banners_write_organizer" on storage.objects
  for all to authenticated
  using (bucket_id = 'tournament-banners'
    and public.is_tournament_organizer(((storage.foldername(name))[1])::uuid))
  with check (bucket_id = 'tournament-banners'
  and public.is_tournament_organizer(((storage.foldername(name))[1])::uuid));

create policy "tournament_logos_read_public" on storage.objects
  for select
  using (bucket_id = 'tournament-logos');

create policy "tournament_logos_write_organizer" on storage.objects
  for all to authenticated
  using (bucket_id = 'tournament-logos'
    and public.is_tournament_organizer(((storage.foldername(name))[1])::uuid))
  with check (bucket_id = 'tournament-logos'
  and public.is_tournament_organizer(((storage.foldername(name))[1])::uuid));

