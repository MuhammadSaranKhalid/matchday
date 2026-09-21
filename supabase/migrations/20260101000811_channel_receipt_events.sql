-- Migration file: 20260101000811_channel_receipt_events.sql

-- 0811 · channel_receipt_events — delivery & read horizon advancement history

-- Section: Tables and constraints

create table if not exists public.channel_receipt_events(
  event_id            uuid primary key default gen_random_uuid(),
  channel_id          uuid not null references public.chat_channels(channel_id) on delete cascade,
  user_id             uuid not null references public.profiles(user_id) on delete cascade,
  receipt_type        text not null check (receipt_type in ('delivered', 'read')),
  through_message_seq bigint not null,
  created_at          timestamptz not null default now()
);

-- Section: Indexes

create index if not exists channel_receipt_events_channel_user_idx on public.channel_receipt_events(channel_id, user_id, receipt_type, through_message_seq desc);

-- Section: Enable row-level security

alter table public.channel_receipt_events enable row level security;
