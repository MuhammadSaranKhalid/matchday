-- =============================================================================
-- Migration: 20260101000804_channel_policies.sql
-- =============================================================================

-- 0804 · channel_policies — channel configuration & moderation rules

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.channel_policies (
  channel_id                uuid primary key
    references public.chat_channels (channel_id)
    on delete cascade,
  posting_mode              public.chat_posting_mode not null default 'members',
  reactions_enabled         boolean not null default true,
  replies_enabled           boolean not null default true,
  media_enabled             boolean not null default true,
  read_receipts_enabled     boolean not null default true,
  delivery_receipts_enabled boolean not null default true,
  max_message_length        integer not null default 4000,
  slow_mode_seconds         integer not null default 0,
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now(),
  constraint channel_policy_lengths
    check (
      max_message_length between 1 and 20000
      and slow_mode_seconds between 0 and 86400
    )
);

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger channel_policies_set_updated_at
  before update on public.channel_policies
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

alter table public.channel_policies enable row level security;
