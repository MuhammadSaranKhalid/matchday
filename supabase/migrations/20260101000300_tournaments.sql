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

create or replace function public.tournament_record_payment(
  p_registration_id uuid,
  p_amount_paid numeric,
  p_channel text default null,
  p_reference text default null
)
  returns void
  language plpgsql
  security definer
  set search_path = public, pg_temp
  as $$
declare
  v_tournament_id uuid;
  v_entry_fee numeric;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated'
      using errcode = '28000';
  end if;
  select
    tt.tournament_id
  into
    v_tournament_id
  from
    public.tournament_teams tt
  where
    tt.registration_id = p_registration_id;
  if not found then
    raise exception 'Registration not found'
      using errcode = 'P0002';
  end if;
  if not public.is_tournament_organizer(v_tournament_id) then
    raise exception 'Only tournament organizers can record payments'
      using errcode = '42501';
  end if;
  if p_amount_paid is null or p_amount_paid < 0 then
    raise exception 'Amount must be zero or more'
      using errcode = '22023';
  end if;
  select
    coalesce(t.entry_fee, 0)
  into
    v_entry_fee
  from
    public.tournaments t
  where
    t.tournament_id = v_tournament_id;
  -- Overpayment is a data-entry slip, not a business case worth modelling.
  if v_entry_fee > 0 and p_amount_paid > v_entry_fee then
    raise exception 'Amount exceeds the entry fee of %', v_entry_fee
      using errcode = '22023';
  end if;
  update
    public.tournament_teams
  set
    amount_paid = p_amount_paid,
    payment_channel = p_channel,
    payment_reference = nullif(btrim(coalesce(p_reference, '')), ''), payment_recorded_at = now(), payment_recorded_by = auth.uid(),
    -- Keep the legacy label in step so the registrations tab's "Paid"
    -- chip and the ledger never disagree.
    payment_status = case when v_entry_fee > 0
      and p_amount_paid >= v_entry_fee then
      'paid'
    when p_amount_paid > 0 then
      'partial'
    else
      'unpaid'
    end
    where
      registration_id = p_registration_id;
end;
$$;

revoke all on function public.tournament_record_payment(uuid, numeric, text, text) from public;

grant execute on function public.tournament_record_payment(uuid, numeric, text, text) to authenticated;

-- 3. The ledger itself (artboard 24c).
-- One call returns every approved team's line plus the tournament's entry fee,
-- so the client sums expected/collected/outstanding without a second query.
create or replace function public.tournament_fee_ledger(
  p_tournament_id uuid
)
  returns table(
    registration_id uuid,
    team_id uuid,
    team_name text,
    team_monogram text,
    team_logo_url text,
    entry_fee numeric,
    amount_paid numeric,
    payment_channel text,
    payment_reference text,
    payment_recorded_at timestamptz,
    recorded_by_name text,
    status text)
  language sql
  security definer stable
  set search_path = public,
  pg_temp
  as $$
  select
    tt.registration_id,
    tt.team_id,
    tm.team_name,
    tm.logo_monogram,
    tm.logo_url,
    coalesce(t.entry_fee, 0),
    tt.amount_paid,
    tt.payment_channel,
    tt.payment_reference,
    tt.payment_recorded_at,
    pr.display_name,
    tt.status::text
  from
    public.tournament_teams tt
    join public.tournaments t on t.tournament_id = tt.tournament_id
    join public.teams tm on tm.team_id = tt.team_id
    left join public.profiles pr on pr.user_id = tt.payment_recorded_by
  where
    tt.tournament_id = p_tournament_id
    and tt.status = 'approved'
    -- The ledger names who paid what. Organisers only.
    and public.is_tournament_organizer(p_tournament_id)
  order by
    tm.team_name;
$$;

revoke all on function public.tournament_fee_ledger(uuid) from public;

grant execute on function public.tournament_fee_ledger(uuid) to authenticated;

-- 4. Match officials — read (artboard 27j).
-- match_officials (20260830000000) already models the roles; nothing read them
-- back except the scorer join on the live board. The Officials screen needs
-- every role for one fixture, with the club each official belongs to so the
-- "both umpires must be from neutral clubs" rule can be shown, not just stated.
create or replace function public.tournament_match_officials(
  p_match_id uuid
)
  returns table(
    user_id uuid,
    display_name text,
    username text,
    avatar_url text,
    role text,
    assigned_at timestamptz,
    club_name text,
    is_neutral boolean)
  language sql
  security definer stable
  set search_path = public,
  pg_temp
  as $$
  select
    mo.user_id,
    pr.display_name,
    pr.username,
    pr.profile_photo_url,
    mo.role,
    mo.assigned_at,
    -- The first team this person owns or manages reads as "their club".
    -- 2026-09-10: these ask "which teams does THIS person run?", so they read
    -- the ladder directly rather than via is_team_manager(), which answers
    -- only for auth.uid().
(
      select
        t.team_name
      from
        public.teams t
      where
        public._user_team_can(mo.user_id, t.team_id, 'team.roster.write')
      order by
        t.created_at
      limit 1),
  -- Neutral = not attached to either side of THIS fixture.
  not(public._user_team_can(mo.user_id, m.team_a_id, 'team.roster.write')
    or public._user_team_can(mo.user_id, m.team_b_id, 'team.roster.write'))
from
  public.match_officials mo
  join public.matches m on m.match_id = mo.match_id
  join public.profiles pr on pr.user_id = mo.user_id
where
  mo.match_id = p_match_id
order by
  case mo.role
  when 'scorer' then
    1
  when 'umpire_main' then
    2
  when 'umpire_leg' then
    3
  when 'umpire_third' then
    4
  else
    5
  end;
$$;

revoke all on function public.tournament_match_officials(uuid) from public;

grant execute on function public.tournament_match_officials(uuid) to authenticated;

-- 5. Assign / remove an official (artboard 27j).
-- tournament_assign_scorer (20260830000000) handles role='scorer' and carries
-- extra semantics (it clears a stale scorer, guards a live match). This is its
-- sibling for the umpire roles, which have no such lifecycle: an umpire may be
-- swapped at any point before the result is final.
create or replace function public.tournament_assign_official(
  p_match_id uuid,
  p_user_id uuid,
  p_role text
)
  returns void
  language plpgsql
  security definer
  set search_path = public, pg_temp
  as $$
declare
  v_match public.matches;
begin
  if p_role not in ('umpire_main', 'umpire_leg', 'umpire_third', 'referee') then
    raise exception 'Use tournament_assign_scorer for the scorer role'
      using errcode = '22023';
  end if;
  v_match := public._require_match_organizer(p_match_id);
  if v_match.status in ('completed', 'abandoned', 'walkover') then
    raise exception 'This match is already finished'
      using errcode = '22023';
  end if;
  -- One person per role: replace whoever held it.
  delete from public.match_officials
  where match_id = p_match_id
    and role = p_role;
  -- ...and never let one person hold two roles in the same fixture.
  delete from public.match_officials
  where match_id = p_match_id
    and user_id = p_user_id
    and role <> 'scorer';
  insert into public.match_officials(match_id, user_id, role, assigned_by)
    values (p_match_id, p_user_id, p_role, auth.uid());
end;
$$;

revoke all on function public.tournament_assign_official(uuid, uuid, text) from public;

grant execute on function public.tournament_assign_official(uuid, uuid, text) to authenticated;

create or replace function public.tournament_remove_official(
  p_match_id uuid,
  p_role text
)
  returns void
  language plpgsql
  security definer
  set search_path = public, pg_temp
  as $$
begin
  perform
    public._require_match_organizer(p_match_id);
  if p_role not in('umpire_main', 'umpire_leg', 'umpire_third', 'referee') then
    raise exception 'Use tournament_assign_scorer to change the scorer'
      using errcode = '22023';
  end if;
  delete from public.match_officials
  where match_id = p_match_id
    and role = p_role;
end;
$$;

revoke all on function public.tournament_remove_official(uuid, text) from public;

grant execute on function public.tournament_remove_official(uuid, text) to authenticated;

-- 6. Official candidates for one fixture (artboard 27j, "Assign umpire 2").
-- tournament_scorer_candidates answers "who is at this cup". This answers
-- "who may officiate THIS match", which is a different question: it carries
-- the neutrality flag, the matches-officiated count the picker sorts on, and
-- a note when the person is already booked on another fixture that day.
create or replace function public.tournament_official_candidates(
  p_tournament_id uuid,
  p_match_id uuid
)
  returns table(
    user_id uuid,
    display_name text,
    username text,
    avatar_url text,
    club_name text,
    is_neutral boolean,
    matches_officiated integer,
    busy_on text)
  language sql
  security definer stable
  set search_path = public,
  pg_temp
  as $$
  with target as(
    select
      m.match_id,
      m.team_a_id,
      m.team_b_id,
      m.scheduled_start_time
    from
      public.matches m
    where
      m.match_id = p_match_id
),
people as(
  select
    t.created_by as uid
  from
    public.tournaments t
  where
    t.tournament_id = p_tournament_id
    and t.created_by is not null
  union
  select
    unnest(t.organizers)
  from
    public.tournaments t
  where
    t.tournament_id = p_tournament_id
  union
  -- 2026-09-10: was owner_id UNION unnest(managers); one set now.
  select
    public.team_staff_ids(tt.team_id)
  from
    public.tournament_teams tt
  where
    tt.tournament_id = p_tournament_id
    and tt.status = 'approved'
)
select distinct on(pr.user_id)
  pr.user_id,
  pr.display_name,
  pr.username,
  pr.profile_photo_url,
(
    select
      t.team_name
    from
      public.teams t
    where
      public._user_team_can(pr.user_id, t.team_id, 'team.roster.write')
    order by
      t.created_at
    limit 1),
not exists(
  select
    1
  from
    target tg
  where
    public._user_team_can(pr.user_id, tg.team_a_id, 'team.roster.write')
    or public._user_team_can(pr.user_id, tg.team_b_id, 'team.roster.write')),
(
  select
    count(*)::integer
  from
    public.match_officials mo2
  where
    mo2.user_id = pr.user_id
    and mo2.role <> 'scorer'),
-- "Also on Match 6" — a clash within 4 hours of this fixture's start.
(
  select
    coalesce(m2.round, 'another match')
  from public.match_officials mo3
  join public.matches m2 on m2.match_id = mo3.match_id, target tg
where
  mo3.user_id = pr.user_id
  and m2.match_id <> tg.match_id
  and m2.scheduled_start_time between tg.scheduled_start_time - interval '4 hours' and tg.scheduled_start_time + interval '4 hours' limit 1)
from
  people p
  join public.profiles pr on pr.user_id = p.uid
where
  p.uid is not null
  and public.is_tournament_organizer(p_tournament_id)
order by
  pr.user_id,
  pr.display_name;
$$;

revoke all on function public.tournament_official_candidates(uuid, uuid) from public;

grant execute on function public.tournament_official_candidates(uuid, uuid) to authenticated;

-- 7. Auto-assign scorers (artboard 27k, the banner's "Auto-assign >").
-- The organiser is usually scoring, not holding a phone (27f). On matchday
-- morning four fixtures with no scorer is a queue of four sheets; this collapses
-- it to one tap. The rule is deliberately dull and explainable: walk the
-- unscored fixtures oldest-first and give each one an organiser who is not
-- already scoring a fixture that overlaps it. Anything it cannot fill is left
-- alone and reported, so the banner still shows the honest remainder.
create or replace function public.tournament_auto_assign_scorers(
  p_tournament_id uuid
)
  returns integer
  language plpgsql
  security definer
  set search_path = public, pg_temp
  as $$
declare
  v_match record;
  v_person uuid;
  v_filled integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated'
      using errcode = '28000';
  end if;
  if not public.is_tournament_organizer(p_tournament_id) then
    raise exception 'Only tournament organizers can assign scorers'
      using errcode = '42501';
  end if;
  for v_match in
  select
    m.match_id,
    m.scheduled_start_time
  from
    public.matches m
  where
    m.tournament_id = p_tournament_id
    and m.status in ('scheduled', 'toss')
    and not exists (
      select
        1
      from
        public.match_officials mo
      where
        mo.match_id = m.match_id
        and mo.role = 'scorer')
  order by
    m.scheduled_start_time loop
      select
        c.user_id
      into
        v_person
      from
        public.tournament_scorer_candidates(p_tournament_id) c
where
  not exists (
    -- Free at this hour: no other fixture within a 4-hour window.
    select
      1
    from
      public.match_officials mo
      join public.matches m2 on m2.match_id = mo.match_id
    where
      mo.user_id = c.user_id
        and mo.role = 'scorer'
        and m2.scheduled_start_time between v_match.scheduled_start_time - interval '4 hours' and v_match.scheduled_start_time + interval '4 hours')
    limit 1;
      if v_person is not null then
        insert into public.match_officials(match_id, user_id, role, assigned_by)
          values (v_match.match_id, v_person, 'scorer', auth.uid())
        on conflict
          do nothing;
        v_filled := v_filled + 1;
      end if;
      v_person := null;
    end loop;
  return v_filled;
end;
$$;

revoke all on function public.tournament_auto_assign_scorers(uuid) from public;

grant execute on function public.tournament_auto_assign_scorers(uuid) to authenticated;

-- 8. Revised match conditions — rain (artboards 27m, 28b).
-- ⚠️  READ THE BANNER AT THE TOP OF THIS FILE. Every number below arrives as a
-- parameter, already computed by the Dart engine. This function does no
-- cricket arithmetic — it writes down what the organiser read back to the
-- captains, and stamps who decided it and when.
-- matches.revised_conditions is declared inline in
-- 20260101000400_matches.sql (folded there 2026-09-06).
-- Tournament revise match conditions and trigger super over RPCs
-- have been moved to TypeScript Edge Functions (cricket-match-action) executing direct SQL.

