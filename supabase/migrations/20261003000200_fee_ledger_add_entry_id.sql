-- Phase 6.1 — expose entry_id explicitly on tournament_fee_ledger
--
-- The Flutter client previously sent registrationId to the old
-- tournament_record_payment RPC.  The NestJS RecordEntryPayment command
-- is scoped to entryId, so Flutter must now send entryId.  The ledger
-- RPC was previously aliasing entry_id as registration_id; this migration
-- adds entry_id as a distinct output column so the DTO can surface both.
--
-- This is a backwards-compatible change: the existing registration_id
-- column keeps the same coalesce expression for any in-flight clients.

drop function if exists public.tournament_fee_ledger(uuid);

create or replace function public.tournament_fee_ledger(
  p_tournament_id uuid
)
returns table (
  entry_id            uuid,
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
language plpgsql
security definer
stable
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  if not (
    public.can('tournament', p_tournament_id, 'tournament.finance.view')
    or public.is_tournament_organizer(p_tournament_id)
  ) then
    raise exception 'Only tournament organizers can view fee ledger' using errcode = '42501';
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
    left join public.profiles pr on pr.user_id = p.recorded_by
    where p.tournament_id = p_tournament_id
      and not p.is_void
    order by p.entry_id, p.recorded_at desc
  )
  select
    te.entry_id                                         as entry_id,
    coalesce(te.registration_id, te.entry_id)           as registration_id,
    te.team_id,
    tm.team_name,
    tm.logo_monogram                                    as team_monogram,
    tm.logo_url                                         as team_logo_url,
    coalesce(t.entry_fee, 0)                            as entry_fee,
    coalesce(ep.total_paid, 0)::numeric                 as amount_paid,
    lp.payment_channel                                  as payment_channel,
    lp.payment_reference                                as payment_reference,
    lp.recorded_at                                      as payment_recorded_at,
    lp.recorder_name                                    as recorded_by_name,
    te.status::text                                     as status
  from public.tournament_entries te
  join public.tournaments t on t.tournament_id = te.tournament_id
  join public.teams tm on tm.team_id = te.team_id
  left join entry_payments ep on ep.entry_id = te.entry_id
  left join latest_payments lp on lp.entry_id = te.entry_id
  where te.tournament_id = p_tournament_id
    and te.status = 'active'
  order by tm.team_name;
end;
$$;

revoke all on function public.tournament_fee_ledger(uuid) from public;
grant execute on function public.tournament_fee_ledger(uuid) to authenticated;
