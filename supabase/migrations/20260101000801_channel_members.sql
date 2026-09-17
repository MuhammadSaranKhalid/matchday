-- =============================================================================
-- 0801 · channel_members — conversation membership & horizons
-- =============================================================================

create table public.channel_members (
  channel_id                 uuid not null
                               references public.chat_channels(channel_id) on delete cascade,
  user_id                    uuid not null
                               references public.profiles(user_id) on delete cascade,
  role                       public.chat_member_role not null default 'member',
  status                     public.chat_member_status not null default 'active',

  invited_by                 uuid references public.profiles(user_id) on delete set null,
  invited_at                 timestamptz,
  responded_at               timestamptz,
  joined_at                  timestamptz,
  left_at                    timestamptz,
  request_retry_after        timestamptz,

  last_delivered_message_seq bigint,
  last_delivered_at          timestamptz,
  last_read_message_seq      bigint,
  last_read_at               timestamptz,

  notifications_muted_until  timestamptz,
  archived_at                timestamptz,
  pinned_at                  timestamptz,

  created_at                 timestamptz not null default now(),
  updated_at                 timestamptz not null default now(),

  primary key (channel_id, user_id)
);

create index channel_members_user_inbox_idx
  on public.channel_members(user_id, status, archived_at, pinned_at);

create index channel_members_channel_status_idx
  on public.channel_members(channel_id, status);

create trigger channel_members_set_updated_at
  before update on public.channel_members
  for each row execute function public.set_updated_at();

alter table public.channel_members enable row level security;
