-- Phase 6.2.1
-- Tournament participation authorization catalogue closure.
--
-- Adds the Tournament capabilities already frozen in the Tournament
-- Architecture Standard and used by the NestJS participation command layer.
--
-- Team-side squad editing intentionally continues to use
-- team.tournament.enter for Phase 6. A separate Team squad capability
-- is deferred rather than widening the global permission-key grammar.

-- ============================================================================
-- 1. Canonical Tournament capabilities
-- ============================================================================

insert into public.permissions (
  permission_key,
  resource,
  action,
  description,
  min_rank,
  direct_grantable,
  sort_order
)
values
  (
    'tournament.payment.manage',
    'payment',
    'manage',
    'Record and void tournament entry payments',
    30,
    false,
    245
  ),
  (
    'tournament.squad.review',
    'squad',
    'review',
    'Review and freeze tournament entry squad eligibility',
    30,
    false,
    255
  )
on conflict (permission_key) do update set
  resource = excluded.resource,
  action = excluded.action,
  description = excluded.description,
  min_rank = excluded.min_rank,
  direct_grantable = excluded.direct_grantable,
  sort_order = excluded.sort_order;


-- ============================================================================
-- 2. Register Tournament scope
-- ============================================================================

insert into public.permission_scopes (
  permission_key,
  scope
)
values
  ('tournament.payment.manage', 'tournament'),
  ('tournament.squad.review', 'tournament')
on conflict (permission_key, scope) do nothing;


-- ============================================================================
-- 3. Default Tournament role bundles
-- ============================================================================
--
-- Owner receives all Tournament capabilities conceptually through root
-- authority as well, but explicit role rows keep the permission matrix
-- truthful and inspectable.
--
-- Manager receives both operational capabilities because min_rank = 30.

insert into public.role_permissions (
  team_id,
  scope,
  role_key,
  permission_key,
  granted
)
values
  (
    null,
    'tournament',
    'owner',
    'tournament.payment.manage',
    true
  ),
  (
    null,
    'tournament',
    'owner',
    'tournament.squad.review',
    true
  ),
  (
    null,
    'tournament',
    'manager',
    'tournament.payment.manage',
    true
  ),
  (
    null,
    'tournament',
    'manager',
    'tournament.squad.review',
    true
  )
on conflict (team_id, scope, role_key, permission_key)
do update set
  granted = excluded.granted;


-- ============================================================================
-- 4. Fee ledger authorization
-- ============================================================================
--
-- The previous Phase 6.1 function referenced tournament.finance.view,
-- which is not part of the canonical Tournament permission catalogue.
--
-- Financial mutation and organizer ledger access currently share the
-- canonical Tournament payment authority:
--
--   tournament.payment.manage
--
-- This can be split into read/write capabilities later if the product
-- requires delegated read-only finance access.

create or replace function public.tournament_fee_ledger(
  p_tournament_id uuid
)
returns table (
  entry_id            uuid,
  registration_id     uuid,
  team_id             uuid,
  team_name            text,
  team_monogram        text,
  team_logo_url        text,
  entry_fee            numeric,
  amount_paid          numeric,
  payment_channel      text,
  payment_reference    text,
  payment_recorded_at  timestamptz,
  recorded_by_name     text,
  status               text
)
language plpgsql
security definer
stable
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated'
      using errcode = '28000';
  end if;

  if not public.can(
    'tournament',
    p_tournament_id,
    'tournament.payment.manage'
  ) then
    raise exception 'Not authorized to view tournament fee ledger'
      using errcode = '42501';
  end if;

  return query
  with entry_payments as (
    select
      p.entry_id,
      sum(p.amount) filter (where not p.is_void) as total_paid
    from public.tournament_entry_payments p
    where p.tournament_id = p_tournament_id
    group by p.entry_id
  ),
  latest_payments as (
    select distinct on (p.entry_id)
      p.entry_id,
      p.payment_channel,
      p.payment_reference,
      p.recorded_at,
      pr.display_name as recorder_name
    from public.tournament_entry_payments p
    left join public.profiles pr
      on pr.user_id = p.recorded_by
    where p.tournament_id = p_tournament_id
      and not p.is_void
    order by
      p.entry_id,
      p.recorded_at desc
  )
  select
    te.entry_id                                       as entry_id,
    coalesce(te.registration_id, te.entry_id)         as registration_id,
    te.team_id,
    tm.team_name,
    tm.logo_monogram                                  as team_monogram,
    tm.logo_url                                       as team_logo_url,
    coalesce(t.entry_fee, 0)                          as entry_fee,
    coalesce(ep.total_paid, 0)::numeric               as amount_paid,
    lp.payment_channel                                as payment_channel,
    lp.payment_reference                              as payment_reference,
    lp.recorded_at                                    as payment_recorded_at,
    lp.recorder_name                                  as recorded_by_name,
    te.status::text                                   as status
  from public.tournament_entries te
  join public.tournaments t
    on t.tournament_id = te.tournament_id
  join public.teams tm
    on tm.team_id = te.team_id
  left join entry_payments ep
    on ep.entry_id = te.entry_id
  left join latest_payments lp
    on lp.entry_id = te.entry_id
  where te.tournament_id = p_tournament_id
    and te.status = 'active'
  order by tm.team_name;
end;
$$;

revoke all
on function public.tournament_fee_ledger(uuid)
from public;

grant execute
on function public.tournament_fee_ledger(uuid)
to authenticated;