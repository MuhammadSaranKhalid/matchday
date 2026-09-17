-- =============================================================================
-- 0806 · messages — message storage & monotonic sequences
-- =============================================================================

create table public.messages (
  message_id          uuid primary key default gen_random_uuid(),
  message_seq         bigint generated always as identity unique,
  channel_id          uuid not null
                        references public.chat_channels(channel_id) on delete cascade,
  sender_id           uuid references public.profiles(user_id) on delete set null,
  message_type        public.chat_message_type not null default 'text',
  body                text,
  payload             jsonb not null default '{}'::jsonb,
  reply_to_message_id uuid references public.messages(message_id) on delete set null,
  version             integer not null default 1,
  counts_as_unread    boolean not null default true,

  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  edited_at           timestamptz,
  deleted_at          timestamptz,
  deleted_by          uuid references public.profiles(user_id),

  constraint message_version_positive check (version >= 1),
  constraint message_body_length check (
    body is null or char_length(body) <= 20000
  )
);

create unique index messages_channel_seq_unique
  on public.messages(channel_id, message_seq);

create index messages_channel_page_idx
  on public.messages(channel_id, message_seq desc);

create index messages_sender_idx
  on public.messages(sender_id, created_at desc);

create index messages_reply_idx
  on public.messages(reply_to_message_id)
  where reply_to_message_id is not null;

create trigger messages_set_updated_at
  before update on public.messages
  for each row execute function public.set_updated_at();

alter table public.messages enable row level security;
