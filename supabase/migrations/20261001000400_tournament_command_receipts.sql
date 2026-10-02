-- Phase 5: Technical idempotency receipts for NestJS tournament command infrastructure.
-- Private technical storage, never exposed to Data API or client roles.

create table if not exists private.tournament_command_receipts (
  command_id uuid primary key,
  actor_id uuid not null,
  action text not null,
  tournament_id uuid null references public.tournaments(tournament_id) on delete set null,
  request_fingerprint text not null,
  response_payload jsonb null,
  created_at timestamptz not null default now(),
  completed_at timestamptz not null default now()
);

create index if not exists idx_tournament_command_receipts_created_at
  on private.tournament_command_receipts (created_at desc);

create index if not exists idx_tournament_command_receipts_tournament_id
  on private.tournament_command_receipts (tournament_id)
  where tournament_id is not null;

-- Strictly private: no access for public, anon, or authenticated
revoke all on table private.tournament_command_receipts from public, anon, authenticated;
grant usage on schema private to service_role;
grant select, insert, update on table private.tournament_command_receipts to postgres, service_role;
