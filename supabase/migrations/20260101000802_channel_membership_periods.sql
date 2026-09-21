-- Migration file: 20260101000802_channel_membership_periods.sql

-- 0802 · channel_membership_periods — historical recipient windows

-- Section: Tables and constraints

create table public.channel_membership_periods(
  period_id  uuid primary key default gen_random_uuid(),
  channel_id uuid not null references public.chat_channels(channel_id) on delete cascade,
  user_id    uuid not null references public.profiles(user_id) on delete cascade,
  joined_at  timestamptz not null,
  left_at    timestamptz,
  end_reason text,
  created_at timestamptz not null default now()
);

-- Section: Indexes

create unique index channel_membership_period_active_unique on public.channel_membership_periods(channel_id, user_id)
where
  left_at is null;

create index channel_membership_period_history_idx on public.channel_membership_periods(channel_id, joined_at, left_at);

-- Section: Enable row-level security

alter table public.channel_membership_periods enable row level security;
