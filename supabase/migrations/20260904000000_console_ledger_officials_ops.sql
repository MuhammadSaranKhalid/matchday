-- =============================================================================
-- 20260904000000 · console_ledger_officials_ops
-- =============================================================================
-- Completes section F of the Tournaments design canvas. 20260830000000 built
-- the Live Ops board and the three ops sheets (artboards 27, 28); this file
-- backs the five console surfaces that had no schema behind them at all:
--
--   24c  Payment reconciliation ledger  — partial payments, channel, reference.
--   27j  Assign umpires & scorers       — umpire rows in match_officials.
--   27k  Auto-assign scorers            — the banner's "Auto-assign >" action.
--   27L  Innings break / start 2nd inn. — read-only; no schema needed.
--   27m  Revise match conditions        — rain: revised overs + target.
--   28b  Revised target                 — same store, richer form.
--   28c  Super over trigger             — status transition + nomination note.
--
-- ⚠️  NO CRICKET ARITHMETIC LIVES HERE. Per CLAUDE.md the rules of cricket are
-- the Dart engine's alone. `tournament_revise_match_conditions` STORES the
-- organiser's decision (revised overs, the target they read back to the
-- captains, which method produced it). It does not compute the target — that
-- is `lib/features/tournaments/domain/ops/revised_target.dart`, pure Dart,
-- property-tested, shared by the sheet's live preview and this write.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Payment ledger columns (artboard 24c).
-- -----------------------------------------------------------------------------
-- `payment_status` (0310) is a free-text flag — it cannot express "5,000 of
-- 15,000 received in cash on 02 Mar". The ledger needs the amount to sum a
-- tournament's collected/outstanding totals, so the amount becomes a column
-- and payment_status stays as the derived label the older screens still read.
alter table public.tournament_teams
  add column if not exists amount_paid         numeric(12,2) not null default 0
    check (amount_paid >= 0),
  add column if not exists payment_channel     text
    check (payment_channel is null or payment_channel in
           ('cash', 'jazzcash', 'easypaisa', 'bank_transfer', 'other')),
  add column if not exists payment_reference   text
    check (payment_reference is null or length(payment_reference) <= 200),
  add column if not exists payment_recorded_at timestamptz,
  add column if not exists payment_recorded_by uuid
    references public.profiles(user_id) on delete set null;

comment on column public.tournament_teams.amount_paid is
  'Cumulative fee received for this registration, in the tournament currency. '
  'Partial payments are allowed: the ledger (artboard 24c) shows amount_paid '
  'against tournaments.entry_fee.';

-- -----------------------------------------------------------------------------
-- 2. Record an offline payment (artboard 24c, "Record offline payment" sheet).
-- -----------------------------------------------------------------------------
-- Fees are collected in cash at the ground; matchday never holds the money.
-- This is bookkeeping, so the RPC is a SET (not an increment): the sheet shows
-- the running total and the organiser confirms the new cumulative figure,
-- which makes a mistyped entry correctable by re-recording rather than by
-- posting a negative adjustment.
create or replace function public.tournament_record_payment(
  p_registration_id uuid,
  p_amount_paid     numeric,
  p_channel         text default null,
  p_reference       text default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_tournament_id uuid;
  v_entry_fee     numeric;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select tt.tournament_id into v_tournament_id
    from public.tournament_teams tt
   where tt.registration_id = p_registration_id;

  if not found then
    raise exception 'Registration not found' using errcode = 'P0002';
  end if;

  if not public.is_tournament_organizer(v_tournament_id) then
    raise exception 'Only tournament organizers can record payments'
      using errcode = '42501';
  end if;

  if p_amount_paid is null or p_amount_paid < 0 then
    raise exception 'Amount must be zero or more' using errcode = '22023';
  end if;

  select coalesce(t.entry_fee, 0) into v_entry_fee
    from public.tournaments t
   where t.tournament_id = v_tournament_id;

  -- Overpayment is a data-entry slip, not a business case worth modelling.
  if v_entry_fee > 0 and p_amount_paid > v_entry_fee then
    raise exception 'Amount exceeds the entry fee of %', v_entry_fee
      using errcode = '22023';
  end if;

  update public.tournament_teams
     set amount_paid         = p_amount_paid,
         payment_channel     = p_channel,
         payment_reference   = nullif(btrim(coalesce(p_reference, '')), ''),
         payment_recorded_at = now(),
         payment_recorded_by = auth.uid(),
         -- Keep the legacy label in step so the registrations tab's "Paid"
         -- chip and the ledger never disagree.
         payment_status      = case
                                 when v_entry_fee > 0
                                  and p_amount_paid >= v_entry_fee then 'paid'
                                 when p_amount_paid > 0            then 'partial'
                                 else 'unpaid'
                               end
   where registration_id = p_registration_id;
end;
$$;

revoke all on function public.tournament_record_payment(uuid, numeric, text, text)
  from public;
grant execute on function public.tournament_record_payment(uuid, numeric, text, text)
  to authenticated;

-- -----------------------------------------------------------------------------
-- 3. The ledger itself (artboard 24c).
-- -----------------------------------------------------------------------------
-- One call returns every approved team's line plus the tournament's entry fee,
-- so the client sums expected/collected/outstanding without a second query.
create or replace function public.tournament_fee_ledger(p_tournament_id uuid)
returns table (
  registration_id     uuid,
  team_id             uuid,
  team_name           text,
  team_monogram       text,
  team_logo_url       text,
  entry_fee           numeric,
  amount_paid         numeric,
  payment_channel     text,
  payment_reference   text,
  payment_recorded_at timestamptz,
  recorded_by_name    text,
  status              text
)
language sql
security definer
stable
set search_path = public, pg_temp
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
  from public.tournament_teams tt
  join public.tournaments t on t.tournament_id = tt.tournament_id
  join public.teams tm      on tm.team_id      = tt.team_id
  left join public.profiles pr on pr.user_id = tt.payment_recorded_by
  where tt.tournament_id = p_tournament_id
    and tt.status = 'approved'
    -- The ledger names who paid what. Organisers only.
    and public.is_tournament_organizer(p_tournament_id)
  order by tm.team_name;
$$;

revoke all on function public.tournament_fee_ledger(uuid) from public;
grant execute on function public.tournament_fee_ledger(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 4. Match officials — read (artboard 27j).
-- -----------------------------------------------------------------------------
-- match_officials (20260830000000) already models the roles; nothing read them
-- back except the scorer join on the live board. The Officials screen needs
-- every role for one fixture, with the club each official belongs to so the
-- "both umpires must be from neutral clubs" rule can be shown, not just stated.
create or replace function public.tournament_match_officials(p_match_id uuid)
returns table (
  user_id      uuid,
  display_name text,
  username     text,
  avatar_url   text,
  role         text,
  assigned_at  timestamptz,
  club_name    text,
  is_neutral   boolean
)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select
    mo.user_id,
    pr.display_name,
    pr.username,
    pr.profile_photo_url,
    mo.role,
    mo.assigned_at,
    -- The first team this person owns or manages reads as "their club".
    (select tm.team_name
       from public.teams tm
      where tm.owner_id = mo.user_id or mo.user_id = any(tm.managers)
      order by tm.created_at
      limit 1),
    -- Neutral = not attached to either side of THIS fixture.
    not exists (
      select 1
        from public.teams tm
       where tm.team_id in (m.team_a_id, m.team_b_id)
         and (tm.owner_id = mo.user_id or mo.user_id = any(tm.managers))
    )
  from public.match_officials mo
  join public.matches m  on m.match_id  = mo.match_id
  join public.profiles pr on pr.user_id = mo.user_id
  where mo.match_id = p_match_id
  order by case mo.role
             when 'scorer'       then 1
             when 'umpire_main'  then 2
             when 'umpire_leg'   then 3
             when 'umpire_third' then 4
             else 5
           end;
$$;

revoke all on function public.tournament_match_officials(uuid) from public;
grant execute on function public.tournament_match_officials(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 5. Assign / remove an official (artboard 27j).
-- -----------------------------------------------------------------------------
-- tournament_assign_scorer (20260830000000) handles role='scorer' and carries
-- extra semantics (it clears a stale scorer, guards a live match). This is its
-- sibling for the umpire roles, which have no such lifecycle: an umpire may be
-- swapped at any point before the result is final.
create or replace function public.tournament_assign_official(
  p_match_id uuid,
  p_user_id  uuid,
  p_role     text
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
    raise exception 'This match is already finished' using errcode = '22023';
  end if;

  -- One person per role: replace whoever held it.
  delete from public.match_officials
   where match_id = p_match_id and role = p_role;

  -- ...and never let one person hold two roles in the same fixture.
  delete from public.match_officials
   where match_id = p_match_id and user_id = p_user_id and role <> 'scorer';

  insert into public.match_officials (match_id, user_id, role, assigned_by)
  values (p_match_id, p_user_id, p_role, auth.uid());
end;
$$;

revoke all on function public.tournament_assign_official(uuid, uuid, text) from public;
grant execute on function public.tournament_assign_official(uuid, uuid, text)
  to authenticated;

create or replace function public.tournament_remove_official(
  p_match_id uuid,
  p_role     text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public._require_match_organizer(p_match_id);

  if p_role not in ('umpire_main', 'umpire_leg', 'umpire_third', 'referee') then
    raise exception 'Use tournament_assign_scorer to change the scorer'
      using errcode = '22023';
  end if;

  delete from public.match_officials
   where match_id = p_match_id and role = p_role;
end;
$$;

revoke all on function public.tournament_remove_official(uuid, text) from public;
grant execute on function public.tournament_remove_official(uuid, text) to authenticated;

-- -----------------------------------------------------------------------------
-- 6. Official candidates for one fixture (artboard 27j, "Assign umpire 2").
-- -----------------------------------------------------------------------------
-- tournament_scorer_candidates answers "who is at this cup". This answers
-- "who may officiate THIS match", which is a different question: it carries
-- the neutrality flag, the matches-officiated count the picker sorts on, and
-- a note when the person is already booked on another fixture that day.
create or replace function public.tournament_official_candidates(
  p_tournament_id uuid,
  p_match_id      uuid
)
returns table (
  user_id            uuid,
  display_name       text,
  username           text,
  avatar_url         text,
  club_name          text,
  is_neutral         boolean,
  matches_officiated integer,
  busy_on            text
)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  with target as (
    select m.match_id, m.team_a_id, m.team_b_id, m.scheduled_start_time
      from public.matches m
     where m.match_id = p_match_id
  ),
  people as (
    select t.created_by as uid
      from public.tournaments t
     where t.tournament_id = p_tournament_id and t.created_by is not null
    union
    select unnest(t.organizers)
      from public.tournaments t
     where t.tournament_id = p_tournament_id
    union
    select tm.owner_id
      from public.tournament_teams tt
      join public.teams tm on tm.team_id = tt.team_id
     where tt.tournament_id = p_tournament_id
       and tt.status = 'approved'
       and tm.owner_id is not null
    union
    select unnest(tm.managers)
      from public.tournament_teams tt
      join public.teams tm on tm.team_id = tt.team_id
     where tt.tournament_id = p_tournament_id
       and tt.status = 'approved'
  )
  select distinct on (pr.user_id)
    pr.user_id,
    pr.display_name,
    pr.username,
    pr.profile_photo_url,
    (select tm.team_name
       from public.teams tm
      where tm.owner_id = pr.user_id or pr.user_id = any(tm.managers)
      order by tm.created_at
      limit 1),
    not exists (
      select 1
        from public.teams tm, target tg
       where tm.team_id in (tg.team_a_id, tg.team_b_id)
         and (tm.owner_id = pr.user_id or pr.user_id = any(tm.managers))
    ),
    (select count(*)::integer
       from public.match_officials mo2
      where mo2.user_id = pr.user_id
        and mo2.role <> 'scorer'),
    -- "Also on Match 6" — a clash within 4 hours of this fixture's start.
    (select coalesce(m2.round, 'another match')
       from public.match_officials mo3
       join public.matches m2 on m2.match_id = mo3.match_id, target tg
      where mo3.user_id = pr.user_id
        and m2.match_id <> tg.match_id
        and m2.scheduled_start_time
              between tg.scheduled_start_time - interval '4 hours'
                  and tg.scheduled_start_time + interval '4 hours'
      limit 1)
  from people p
  join public.profiles pr on pr.user_id = p.uid
  where p.uid is not null
    and public.is_tournament_organizer(p_tournament_id)
  order by pr.user_id, pr.display_name;
$$;

revoke all on function public.tournament_official_candidates(uuid, uuid) from public;
grant execute on function public.tournament_official_candidates(uuid, uuid)
  to authenticated;

-- -----------------------------------------------------------------------------
-- 7. Auto-assign scorers (artboard 27k, the banner's "Auto-assign >").
-- -----------------------------------------------------------------------------
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
  v_match   record;
  v_person  uuid;
  v_filled  integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if not public.is_tournament_organizer(p_tournament_id) then
    raise exception 'Only tournament organizers can assign scorers'
      using errcode = '42501';
  end if;

  for v_match in
    select m.match_id, m.scheduled_start_time
      from public.matches m
     where m.tournament_id = p_tournament_id
       and m.status in ('scheduled', 'toss')
       and not exists (
         select 1 from public.match_officials mo
          where mo.match_id = m.match_id and mo.role = 'scorer'
       )
     order by m.scheduled_start_time
  loop
    select c.user_id into v_person
      from public.tournament_scorer_candidates(p_tournament_id) c
     where not exists (
       -- Free at this hour: no other fixture within a 4-hour window.
       select 1
         from public.match_officials mo
         join public.matches m2 on m2.match_id = mo.match_id
        where mo.user_id = c.user_id
          and mo.role = 'scorer'
          and m2.scheduled_start_time
                between v_match.scheduled_start_time - interval '4 hours'
                    and v_match.scheduled_start_time + interval '4 hours'
     )
     limit 1;

    if v_person is not null then
      insert into public.match_officials (match_id, user_id, role, assigned_by)
      values (v_match.match_id, v_person, 'scorer', auth.uid())
      on conflict do nothing;
      v_filled := v_filled + 1;
    end if;

    v_person := null;
  end loop;

  return v_filled;
end;
$$;

revoke all on function public.tournament_auto_assign_scorers(uuid) from public;
grant execute on function public.tournament_auto_assign_scorers(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 8. Revised match conditions — rain (artboards 27m, 28b).
-- -----------------------------------------------------------------------------
-- ⚠️  READ THE BANNER AT THE TOP OF THIS FILE. Every number below arrives as a
-- parameter, already computed by the Dart engine. This function does no
-- cricket arithmetic — it writes down what the organiser read back to the
-- captains, and stamps who decided it and when.
alter table public.matches
  add column if not exists revised_conditions jsonb;

comment on column public.matches.revised_conditions is
  'Audit trail for a rain-revised match (artboards 27m / 28b): the original '
  'and revised overs, the target the organiser applied, and which method '
  'produced it. Computed in the Dart engine, never in SQL.';

create or replace function public.tournament_revise_match_conditions(
  p_match_id       uuid,
  p_revised_overs  integer,
  p_bowler_quota   integer,
  p_revised_target integer default null,
  p_method         text    default 'run_rate',
  p_reason         text    default null
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match    public.matches;
  v_original integer;
begin
  if p_method not in ('run_rate', 'dls', 'custom', 'none') then
    raise exception 'Unknown target method %', p_method using errcode = '22023';
  end if;

  v_match := public._require_match_organizer(p_match_id);

  if v_match.status in ('completed', 'abandoned', 'walkover', 'no_result') then
    raise exception 'This match is already finished' using errcode = '22023';
  end if;

  -- "Minimum 5 overs per side for a result" (28b). The floor is a competition
  -- rule, not arithmetic, so it belongs to whoever guards the fixture.
  if p_revised_overs is null or p_revised_overs < 5 then
    raise exception 'A result needs at least 5 overs per side'
      using errcode = '22023';
  end if;

  v_original := coalesce((v_match.rules_config->>'max_overs')::integer, 20);

  if p_revised_overs > v_original then
    raise exception 'Overs can only be reduced, not extended'
      using errcode = '22023';
  end if;

  if p_bowler_quota is null or p_bowler_quota < 1 then
    raise exception 'Each bowler needs at least one over' using errcode = '22023';
  end if;

  update public.matches
     set rules_config = rules_config
                          || jsonb_build_object(
                               'max_overs', p_revised_overs,
                               'max_overs_per_bowler', p_bowler_quota
                             ),
         revised_conditions = jsonb_build_object(
           'applied_at',        now(),
           'applied_by',        auth.uid(),
           'original_overs',    v_original,
           'revised_overs',     p_revised_overs,
           'original_quota',    coalesce(
                                  (v_match.rules_config->>'max_overs_per_bowler')::integer,
                                  4),
           'revised_quota',     p_bowler_quota,
           'revised_target',    p_revised_target,
           'method',            p_method,
           'reason',            nullif(btrim(coalesce(p_reason, '')), '')
         )
   where match_id = p_match_id;
end;
$$;

revoke all on function public.tournament_revise_match_conditions(
  uuid, integer, integer, integer, text, text) from public;
grant execute on function public.tournament_revise_match_conditions(
  uuid, integer, integer, integer, text, text) to authenticated;

-- -----------------------------------------------------------------------------
-- 9. Super over trigger (artboard 28c).
-- -----------------------------------------------------------------------------
-- The scores are level and the engine has said so. This only moves the fixture
-- into the state the scorer console needs and records who bats first — it does
-- not decide the tie, and it does not score the over.
create or replace function public.tournament_trigger_super_over(
  p_match_id       uuid,
  p_bats_first_id  uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_match public.matches;
begin
  v_match := public._require_match_organizer(p_match_id);

  if v_match.status <> 'tied' then
    raise exception 'A super over needs a tied match' using errcode = '22023';
  end if;

  if p_bats_first_id is null
     or p_bats_first_id not in (v_match.team_a_id, v_match.team_b_id) then
    raise exception 'Choose one of the two sides to bat first'
      using errcode = '22023';
  end if;

  if not coalesce((v_match.rules_config->>'super_over_enabled')::boolean, true) then
    raise exception 'Super overs are disabled for this tournament'
      using errcode = '22023';
  end if;

  update public.matches
     set status       = 'super_over',
         -- Regulation stays untouched; the super over is a second card on the
         -- same fixture, so the tie is preserved inside result.
         result       = coalesce(result, '{}'::jsonb)
                          || jsonb_build_object(
                               'super_over', jsonb_build_object(
                                 'triggered_at',  now(),
                                 'triggered_by',  auth.uid(),
                                 'bats_first_id', p_bats_first_id
                               )
                             ),
         -- winner_id is derived from `result` by match_sync_winner_id; a tied
         -- result carries no winner_team_id, so it clears itself.
         completed_at = null
   where match_id = p_match_id;
end;
$$;

revoke all on function public.tournament_trigger_super_over(uuid, uuid) from public;
grant execute on function public.tournament_trigger_super_over(uuid, uuid)
  to authenticated;
