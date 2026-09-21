-- =============================================================================
-- Migration: 20260101000812_chat_changes.sql
-- =============================================================================

-- 0812 · chat_changes — durable mutation ledger for catch-up recovery

-- -----------------------------------------------------------------------------
-- Prerequisites
-- -----------------------------------------------------------------------------

create sequence if not exists public.chat_changes_seq;

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table if not exists public.chat_changes (
  change_seq  bigint primary key default nextval('public.chat_changes_seq'),
  channel_id  uuid not null
    references public.chat_channels (channel_id)
    on delete cascade,
  entity_type text not null check (
    entity_type in ('message', 'reaction', 'receipt', 'member', 'policy')
  ),
  entity_id   text not null,
  operation   text not null check (operation in ('insert', 'update', 'delete')),
  actor_id    uuid
    references public.profiles (user_id)
    on delete set null,
  payload     jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

create index if not exists chat_changes_channel_seq_idx
  on public.chat_changes (
    channel_id,
    change_seq
  );

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

alter table public.chat_changes enable row level security;
