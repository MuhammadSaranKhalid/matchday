-- 20261001000230_tournament_entry_payments.sql
-- Canonical Tournament Entry Financial History / Ledger
-- Clean Architecture Step 6 / Phase 3

create table if not exists public.tournament_entry_payments (
  payment_id uuid primary key default gen_random_uuid(),
  entry_id uuid not null references public.tournament_entries(entry_id) on delete cascade,
  tournament_id uuid not null references public.tournaments(tournament_id) on delete cascade,
  amount numeric(12,2) not null,
  payment_channel text not null,
  payment_reference text,
  notes text,
  recorded_by uuid references public.profiles(user_id) on delete set null,
  recorded_at timestamptz not null default now(),
  is_void boolean not null default false,
  voided_at timestamptz,
  voided_by uuid references public.profiles(user_id) on delete set null,
  void_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint tournament_entry_payments_amount_check
    check (amount > 0),
  constraint tournament_entry_payments_channel_check
    check (payment_channel in ('cash', 'jazzcash', 'easypaisa', 'bank_transfer', 'other')),
  constraint tournament_entry_payments_reference_check
    check (payment_reference is null or length(payment_reference) <= 200),
  constraint tournament_entry_payments_notes_check
    check (notes is null or length(notes) <= 500),
  constraint tournament_entry_payments_void_reason_check
    check (void_reason is null or length(void_reason) <= 500),
  constraint tournament_entry_payments_void_consistency
    check (is_void = false or (voided_at is not null and voided_by is not null))
);

-- Fast lookup indexes
create index if not exists idx_tournament_entry_payments_entry
  on public.tournament_entry_payments (entry_id);

create index if not exists idx_tournament_entry_payments_tournament
  on public.tournament_entry_payments (tournament_id);

create index if not exists idx_tournament_entry_payments_recorded_by
  on public.tournament_entry_payments (recorded_by);

-- Trigger: enforce foreign-key consistency between payment and entry
create or replace function public.enforce_tournament_entry_payment_fk()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_entry_tournament_id uuid;
begin
  select tournament_id into v_entry_tournament_id
    from public.tournament_entries
   where entry_id = new.entry_id;

  if not found then
    raise exception 'Tournament entry % not found', new.entry_id
      using errcode = 'P0002';
  end if;

  if new.tournament_id is distinct from v_entry_tournament_id then
    new.tournament_id := v_entry_tournament_id;
  end if;

  return new;
end;
$$;

revoke all on function public.enforce_tournament_entry_payment_fk() from public;

drop trigger if exists trg_tournament_entry_payments_fk on public.tournament_entry_payments;
create trigger trg_tournament_entry_payments_fk
  before insert or update of entry_id, tournament_id
  on public.tournament_entry_payments
  for each row
  execute function public.enforce_tournament_entry_payment_fk();

-- Trigger: set updated_at
drop trigger if exists trg_tournament_entry_payments_set_updated_at on public.tournament_entry_payments;
create trigger trg_tournament_entry_payments_set_updated_at
  before update on public.tournament_entry_payments
  for each row
  execute function public.set_updated_at();

-- RLS Security Policies (Confidential Append-Only Financial Ledger)
alter table public.tournament_entry_payments enable row level security;

-- Read policy: Tournament Organizers with payment capability OR Team Manager of the paying entry
-- Confidential: financial records are never public
drop policy if exists "tournament_entry_payments_read" on public.tournament_entry_payments;
create policy "tournament_entry_payments_read"
  on public.tournament_entry_payments
  for select
  to authenticated
  using (
    public.can('tournament', tournament_id, 'tournament.payment.manage')
    or exists (
      select 1 from public.tournament_entries e
       where e.entry_id = tournament_entry_payments.entry_id
         and (
           public.can('team', e.team_id, 'team.tournament.enter')
           or public.is_team_manager(e.team_id)
         )
    )
  );

-- Direct mutations via Data API are prohibited; writes occur strictly through audited RPCs
drop policy if exists "tournament_entry_payments_insert" on public.tournament_entry_payments;
create policy "tournament_entry_payments_insert"
  on public.tournament_entry_payments
  for insert
  to authenticated
  with check (false);

drop policy if exists "tournament_entry_payments_update" on public.tournament_entry_payments;
create policy "tournament_entry_payments_update"
  on public.tournament_entry_payments
  for update
  to authenticated
  using (false)
  with check (false);

drop policy if exists "tournament_entry_payments_delete" on public.tournament_entry_payments;
create policy "tournament_entry_payments_delete"
  on public.tournament_entry_payments
  for delete
  to authenticated
  using (false);
