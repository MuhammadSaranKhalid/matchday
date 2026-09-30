-- Matchday V1: Step 3A durable media dispatch contract.
-- Atomically create outbox intent with uploaded status.

-- 1. Extend public.post_media with execution generation and attempt token
alter table public.post_media
  add column if not exists processing_generation integer not null default 0,
  add column if not exists processing_token uuid null;

-- Backfill non-pending media to generation 1
update public.post_media
set processing_generation = 1
where status <> 'pending_upload' and processing_generation = 0;

alter table public.post_media
  drop constraint if exists chk_post_media_generation,
  add constraint chk_post_media_generation
    check (processing_generation >= 0);

alter table public.post_media
  drop constraint if exists chk_post_media_status_generation,
  add constraint chk_post_media_status_generation
    check (
      (status = 'pending_upload' and processing_generation = 0) or
      (status <> 'pending_upload' and processing_generation >= 1)
    );

-- 2. Create the private media processing outbox
create table if not exists private.media_processing_outbox (
  media_id uuid not null references public.post_media(media_id) on delete cascade,
  generation integer not null check (generation >= 1),
  available_at timestamptz not null default now(),
  lease_owner uuid null,
  lease_expires_at timestamptz null,
  dispatch_attempts integer not null default 0 check (dispatch_attempts >= 0),
  last_dispatch_error text null,
  dispatched_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (media_id, generation)
);

create index if not exists idx_media_processing_outbox_pending
  on private.media_processing_outbox (available_at, media_id)
  where dispatched_at is null;

drop trigger if exists media_processing_outbox_set_updated_at on private.media_processing_outbox;
create trigger media_processing_outbox_set_updated_at
  before update on private.media_processing_outbox
  for each row execute function public.set_updated_at();

-- 3. Permissions
revoke all on table private.media_processing_outbox from public, anon, authenticated;
grant usage on schema private to service_role;
grant select, insert, update, delete on table private.media_processing_outbox to service_role;
