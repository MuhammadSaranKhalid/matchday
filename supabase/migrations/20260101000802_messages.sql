-- =============================================================================
-- 0802 · messages, attachments, reactions, and sync events
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. messages
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 2. message_attachments
-- -----------------------------------------------------------------------------
create table public.message_attachments (
  attachment_id       uuid primary key,
  message_id          uuid not null
                        references public.messages(message_id) on delete cascade,
  storage_path        text not null,
  mime_type           text not null,
  file_name           text,
  size_bytes          bigint,
  width               integer,
  height              integer,
  duration_ms         bigint,
  created_at          timestamptz not null default now()
);

create index message_attachments_message_idx
  on public.message_attachments(message_id);

alter table public.message_attachments enable row level security;

-- -----------------------------------------------------------------------------
-- 3. message_reactions
-- -----------------------------------------------------------------------------
create table public.message_reactions (
  message_id          uuid not null
                        references public.messages(message_id) on delete cascade,
  user_id             uuid not null
                        references public.profiles(user_id) on delete cascade,
  reaction            text not null,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  removed_at          timestamptz,
  primary key (message_id, user_id, reaction),
  constraint reaction_length check (char_length(reaction) between 1 and 32)
);

create index message_reactions_message_idx
  on public.message_reactions(message_id)
  where removed_at is null;

create trigger message_reactions_set_updated_at
  before update on public.message_reactions
  for each row execute function public.set_updated_at();

alter table public.message_reactions enable row level security;

-- -----------------------------------------------------------------------------
-- 4. message_user_state (delete for me)
-- -----------------------------------------------------------------------------
create table public.message_user_state (
  message_id          uuid not null
                        references public.messages(message_id) on delete cascade,
  user_id             uuid not null
                        references public.profiles(user_id) on delete cascade,
  hidden_at           timestamptz,
  primary key (message_id, user_id)
);

alter table public.message_user_state enable row level security;

-- -----------------------------------------------------------------------------
-- 5. private.chat_sync_events
-- -----------------------------------------------------------------------------
create table if not exists private.chat_sync_events (
  event_seq           bigint generated always as identity primary key,
  event_id            uuid not null default gen_random_uuid() unique,
  channel_id          uuid,
  actor_id            uuid,
  event_type          text not null,
  entity_type         text not null,
  entity_id           uuid,
  entity_version      integer,
  payload             jsonb not null default '{}'::jsonb,
  created_at          timestamptz not null default now(),
  published_at        timestamptz,
  publish_attempts    integer not null default 0
);

-- -----------------------------------------------------------------------------
-- 6. RLS Policies
-- -----------------------------------------------------------------------------
-- messages RLS
create policy "messages_read_for_members"
  on public.messages for select
  to authenticated
  using (public.is_chat_member(channel_id));

-- message_attachments RLS
create policy "message_attachments_read_for_members"
  on public.message_attachments for select
  to authenticated
  using (
    exists (
      select 1 from public.messages m
       where m.message_id = message_attachments.message_id
         and public.is_chat_member(m.channel_id)
    )
  );

-- message_reactions RLS
create policy "message_reactions_read_for_members"
  on public.message_reactions for select
  to authenticated
  using (
    exists (
      select 1 from public.messages m
       where m.message_id = message_reactions.message_id
         and public.is_chat_member(m.channel_id)
    )
  );

-- message_user_state RLS
create policy "message_user_state_read_self"
  on public.message_user_state for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy "message_user_state_write_self"
  on public.message_user_state for all
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
