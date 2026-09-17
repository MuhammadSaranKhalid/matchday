-- =============================================================================
-- 0807 · message_attachments — relational media & document metadata
-- =============================================================================

create table public.message_attachments (
  attachment_id       uuid primary key default gen_random_uuid(),
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
