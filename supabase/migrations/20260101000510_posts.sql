-- =============================================================================
-- Migration: 20260101000510_posts.sql
-- =============================================================================
-- Feature 6: Matchday Feed & Posting Architecture
--
-- 1. Tables:
--    - public.posts (canonical posts with publisher context, status, and counters)
--    - public.post_media (1:N position-based media items with async lifecycle)
-- 2. Storage:
--    - post-media-staging (private staging bucket for phone uploads)
--    - post-media (public bucket for processed variants)
-- 3. Queues & Concurrency:
--    - PGMQ queues: post_media_feed, post_media_optimize
--    - private.media_worker_slots (max 4 concurrent workers)
--    - private.media_processing_jobs (canonical job ledger)
-- 4. Transactional RPCs:
--    - begin_post_publish
--    - mark_post_media_uploaded
--    - mark_media_feed_ready (service_role only)
--    - get_home_feed (consolidated keyset-paginated read projection)
--    - set_post_like & set_post_bookmark (idempotent desired-state mutations)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Posts Table
-- -----------------------------------------------------------------------------

create table public.posts (
  post_id              uuid primary key default gen_random_uuid(),
  created_by_user_id   uuid not null
    references public.profiles (user_id)
    on delete cascade,
  author_id            uuid not null
    references public.profiles (user_id)
    on delete cascade,
  author_context       public.post_author_context not null default 'personal',
  context_entity_id    uuid,
  publisher_type       public.post_publisher_type not null default 'user',
  publisher_id         uuid not null,
  post_kind            public.post_kind not null default 'standard',
  post_type            public.post_type not null,
  text                 text check (text is null or length(text) <= 2000),
  expected_media_count integer not null default 0
    check (expected_media_count >= 0 and expected_media_count <= 4),
  linked_match_id      uuid
    references public.matches (match_id)
    on delete set null,
  linked_tournament_id uuid
    references public.tournaments (tournament_id)
    on delete set null,
  linked_team_id       uuid
    references public.teams (team_id)
    on delete set null,
  linked_player_ids    uuid[] not null default '{}',
  auto_generated       boolean not null default false,
  visibility           public.post_visibility not null default 'public',
  is_pinned            boolean not null default false,
  likes_count          integer not null default 0 check (likes_count >= 0),
  comments_count       integer not null default 0 check (comments_count >= 0),
  shares_count         integer not null default 0 check (shares_count >= 0),
  status               public.post_status not null default 'active',
  created_at           timestamptz not null default now(),
  published_at         timestamptz,
  edited_at            timestamptz,
  updated_at           timestamptz not null default now(),
  constraint post_author_context_consistency
    check (
      (author_context = 'personal' and context_entity_id is null)
      or (author_context = 'team_manager' and context_entity_id is not null)
      or (author_context = 'tournament_organizer' and context_entity_id is not null)
    ),
  constraint post_has_content
    check (
      expected_media_count >= 1
      or (text is not null and length(trim(text)) > 0)
    )
);

-- -----------------------------------------------------------------------------
-- 2. Posts Indexes
-- -----------------------------------------------------------------------------

create index idx_posts_feed_keyset
  on public.posts (published_at desc, post_id desc)
  where status = 'active';

create index idx_posts_author_active
  on public.posts (created_by_user_id, published_at desc)
  where status = 'active';

create index idx_posts_publisher_active
  on public.posts (publisher_type, publisher_id, published_at desc)
  where status = 'active';

create index idx_posts_publisher_keyset
  on public.posts (publisher_type, publisher_id, published_at desc, post_id desc)
  where status = 'active';

create index idx_posts_linked_team_active
  on public.posts (linked_team_id, published_at desc)
  where status = 'active' and linked_team_id is not null;

create index idx_posts_linked_match
  on public.posts (linked_match_id)
  where linked_match_id is not null;

create index idx_posts_linked_tournament
  on public.posts (linked_tournament_id)
  where linked_tournament_id is not null;

create index idx_posts_linked_players_gin
  on public.posts using gin (linked_player_ids);

create index idx_posts_context_entity
  on public.posts (context_entity_id)
  where context_entity_id is not null;

-- Triggers on posts
create trigger posts_set_updated_at
  before update on public.posts
  for each row
  execute function public.set_updated_at();

create or replace function public.stamp_post_edited_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if
    new.text is distinct from old.text
    or new.linked_player_ids is distinct from old.linked_player_ids
  then
    new.edited_at = now();
  end if;
  return new;
end;
$$;

create trigger posts_stamp_edited_at
  before update on public.posts
  for each row
  execute function public.stamp_post_edited_at();

-- -----------------------------------------------------------------------------
-- 3. Authorization Helpers & RLS on posts
-- -----------------------------------------------------------------------------

create or replace function public.can_publish_as(
  p_publisher_type public.post_publisher_type,
  p_publisher_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case p_publisher_type
    when 'user' then
      p_publisher_id = p_user_id
    when 'team' then (
      public.can('team', p_publisher_id, 'team.post')
      or public.is_team_manager(p_publisher_id)
    )
    when 'tournament' then
      public.is_tournament_organizer(p_publisher_id)
    when 'club' then
      false
    else
      false
  end;
$$;

revoke all on function public.can_publish_as(public.post_publisher_type, uuid, uuid) from public;
grant execute on function public.can_publish_as(public.post_publisher_type, uuid, uuid) to authenticated, anon;

alter table public.posts enable row level security;

create policy "posts_read_active_or_creator"
  on public.posts
  for select
  to anon, authenticated
  using (
    status = 'active'
    or (
      (select auth.uid()) is not null
      and (select auth.uid()) = created_by_user_id
    )
  );

create policy "posts_insert_authorized_publisher"
  on public.posts
  for insert
  to authenticated
  with check (
    created_by_user_id = (select auth.uid())
    and author_id = (select auth.uid())
    and public.can_publish_as(publisher_type, publisher_id, (select auth.uid()))
  );

create policy "posts_update_authorized_publisher"
  on public.posts
  for update
  to authenticated
  using (
    (
      created_by_user_id = (select auth.uid())
      or (
        publisher_type = 'team'
        and (
          public.can('team', publisher_id, 'team.post')
          or public.is_team_manager(publisher_id)
        )
      )
      or (
        publisher_type = 'tournament'
        and public.is_tournament_organizer(publisher_id)
      )
    )
  )
  with check (
    created_by_user_id = (select auth.uid())
  );

create policy "posts_delete_authorized_publisher"
  on public.posts
  for delete
  to authenticated
  using (
    created_by_user_id = (select auth.uid())
    or (
      publisher_type = 'team'
      and (
        public.can('team', publisher_id, 'team.post')
        or public.is_team_manager(publisher_id)
      )
    )
    or (
      publisher_type = 'tournament'
      and public.is_tournament_organizer(publisher_id)
    )
  );

-- -----------------------------------------------------------------------------
-- 4. Post Media Table
-- -----------------------------------------------------------------------------

create table public.post_media (
  media_id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (post_id) on delete cascade,
  position integer not null check (position >= 0 and position < 4),
  media_type text not null default 'image' check (media_type in ('image')),
  status public.post_media_status not null default 'awaiting_upload',
  staging_path text not null unique,
  final_prefix text not null unique,
  source_width integer,
  source_height integer,
  display_width integer,
  display_height integer,
  blurhash text,
  variants jsonb not null default '{}'::jsonb,
  pipeline_version integer not null default 1,
  processing_attempts integer not null default 0,
  optimization_attempts integer not null default 0,
  feed_ready_at timestamptz,
  last_processing_error text,
  last_optimization_error text,
  created_at timestamptz not null default now(),
  processed_at timestamptz,
  optimized_at timestamptz,
  updated_at timestamptz not null default now(),
  constraint post_media_post_position_unique unique (post_id, position)
);

create index idx_post_media_post_id
  on public.post_media (post_id, position);

create index idx_post_media_status
  on public.post_media (status);

create or replace function public.touch_post_media_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger post_media_updated_at
  before update on public.post_media
  for each row execute function public.touch_post_media_updated_at();

alter table public.post_media enable row level security;

create policy "post_media_read_policy"
  on public.post_media
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.posts p
      where p.post_id = post_media.post_id
        and (
          p.status = 'active'
          or (
            (select auth.uid()) is not null
            and (select auth.uid()) = p.created_by_user_id
          )
        )
    )
  );

create policy "post_media_insert_creator"
  on public.post_media
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.posts p
      where p.post_id = post_media.post_id
        and p.created_by_user_id = (select auth.uid())
    )
  );

create policy "post_media_update_creator"
  on public.post_media
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.posts p
      where p.post_id = post_media.post_id
        and p.created_by_user_id = (select auth.uid())
    )
  );

create policy "post_media_delete_creator"
  on public.post_media
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.posts p
      where p.post_id = post_media.post_id
        and p.created_by_user_id = (select auth.uid())
    )
  );

-- -----------------------------------------------------------------------------
-- 5. Storage Buckets & Policies
-- -----------------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'post-media-staging',
  'post-media-staging',
  false,
  15728640, -- 15MB limit
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = false,
  file_size_limit = 15728640,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp'];

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'post-media',
  'post-media',
  true,
  5242880, -- 5MB limit
  array['image/jpeg', 'image/webp']
)
on conflict (id) do update set
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg', 'image/webp'];

create policy "post_media_staging_owner_insert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'post-media-staging'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "post_media_staging_owner_select"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'post-media-staging'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "post_media_staging_owner_update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'post-media-staging'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'post-media-staging'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "post_media_staging_owner_delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'post-media-staging'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "post_media_read_public"
  on storage.objects for select
  using (bucket_id = 'post-media');

-- -----------------------------------------------------------------------------
-- 6. PGMQ Queues & Worker Concurrency Slots
-- -----------------------------------------------------------------------------

do $$
begin
  perform pgmq.create('post_media_feed');
exception
  when others then null;
end $$;

do $$
begin
  perform pgmq.create('post_media_optimize');
exception
  when others then null;
end $$;

create table if not exists private.media_worker_slots (
  slot_id integer primary key,
  leased_by uuid,
  lease_until timestamptz
);

insert into private.media_worker_slots (slot_id)
values (1), (2), (3), (4)
on conflict (slot_id) do nothing;

create or replace function public.acquire_media_worker_slot(
  p_worker_id uuid,
  p_lease_seconds integer default 60
)
returns integer
language plpgsql
security definer
set search_path = private, public, pg_temp
as $$
declare
  v_slot integer;
begin
  select slot_id into v_slot
  from private.media_worker_slots
  where lease_until is null or lease_until < now()
  order by slot_id
  for update skip locked
  limit 1;

  if v_slot is null then
    return null;
  end if;

  update private.media_worker_slots
  set leased_by = p_worker_id,
      lease_until = now() + make_interval(secs => p_lease_seconds)
  where slot_id = v_slot;

  return v_slot;
end;
$$;

revoke all on function public.acquire_media_worker_slot(uuid, integer) from public, anon, authenticated;
grant execute on function public.acquire_media_worker_slot(uuid, integer) to service_role;

create or replace function public.release_media_worker_slot(
  p_slot_id integer,
  p_worker_id uuid
)
returns void
language sql
security definer
set search_path = private, public, pg_temp
as $$
  update private.media_worker_slots
  set leased_by = null,
      lease_until = null
  where slot_id = p_slot_id and leased_by = p_worker_id;
$$;

revoke all on function public.release_media_worker_slot(integer, uuid) from public, anon, authenticated;
grant execute on function public.release_media_worker_slot(integer, uuid) to service_role;

-- -----------------------------------------------------------------------------
-- 7. Canonical Media Processing Jobs Ledger
-- -----------------------------------------------------------------------------

create table if not exists private.media_processing_jobs (
  job_id uuid primary key default gen_random_uuid(),
  media_id uuid not null references public.post_media(media_id) on delete cascade,
  stage text not null check (stage in ('feed', 'optimize')),
  pipeline_version integer not null default 1,
  status text not null default 'pending' check (status in ('pending', 'dispatched', 'processing', 'succeeded', 'failed')),
  attempts integer not null default 0,
  available_at timestamptz not null default now(),
  processing_started_at timestamptz,
  completed_at timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(media_id, stage, pipeline_version)
);

create index if not exists idx_media_jobs_status_stage 
  on private.media_processing_jobs(status, stage, available_at);

create or replace function private.dispatch_media_job(
  p_job_id uuid
)
returns void
language plpgsql
security definer
set search_path = private, public, pg_temp
as $$
declare
  v_job record;
  v_queue text;
  v_payload jsonb;
begin
  select job_id, media_id, stage, pipeline_version
  into v_job
  from private.media_processing_jobs
  where job_id = p_job_id;

  if not found then
    raise exception 'Job % not found', p_job_id;
  end if;

  v_queue := case v_job.stage
    when 'feed' then 'post_media_feed'
    when 'optimize' then 'post_media_optimize'
    else null
  end;

  if v_queue is null then
    raise exception 'Invalid job stage %', v_job.stage;
  end if;

  v_payload := jsonb_build_object(
    'schemaVersion', 1,
    'jobId', v_job.job_id,
    'mediaId', v_job.media_id,
    'stage', v_job.stage,
    'pipelineVersion', v_job.pipeline_version
  );

  perform pgmq.send(v_queue, v_payload);

  update private.media_processing_jobs
  set status = 'dispatched',
      updated_at = now()
  where job_id = p_job_id;
end;
$$;

create or replace function private.wake_post_media_worker(
  p_count integer default 1
)
returns void
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_url text;
  v_secret text;
  i integer;
begin
  select decrypted_secret into v_url
  from vault.decrypted_secrets
  where name = 'vercel_media_worker_url'
  limit 1;

  select decrypted_secret into v_secret
  from vault.decrypted_secrets
  where name = 'vercel_media_worker_secret'
  limit 1;

  if v_url is null or v_secret is null then
    return;
  end if;

  for i in 1..least(greatest(p_count, 1), 4) loop
    perform net.http_post(
      url := v_url,
      headers := jsonb_build_object(
        'content-type', 'application/json',
        'x-worker-secret', v_secret
      ),
      body := '{}'::jsonb,
      timeout_milliseconds := 5000
    );
  end loop;
end;
$$;

create or replace function public.record_media_job_outcome(
  p_job_id uuid,
  p_status text,
  p_error text default null
)
returns void
language plpgsql
security definer
set search_path = private, public, pg_temp
as $$
begin
  update private.media_processing_jobs
  set status = p_status,
      completed_at = case when p_status in ('succeeded', 'failed') then now() else completed_at end,
      last_error = p_error,
      updated_at = now()
  where job_id = p_job_id;
end;
$$;

revoke all on function public.record_media_job_outcome(uuid, text, text) from public, anon, authenticated;
grant execute on function public.record_media_job_outcome(uuid, text, text) to service_role;

-- -----------------------------------------------------------------------------
-- 8. Transactional RPCs: Publishing Lifecycle
-- -----------------------------------------------------------------------------

create or replace function public.begin_post_publish(
  p_publisher_type public.post_publisher_type,
  p_publisher_id uuid,
  p_post_kind public.post_kind,
  p_text text,
  p_expected_media_count integer default 0,
  p_linked_match_id uuid default null,
  p_linked_tournament_id uuid default null,
  p_linked_team_id uuid default null,
  p_linked_player_ids uuid[] default '{}',
  p_visibility public.post_visibility default 'public',
  p_media_items jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid;
  v_post_id uuid;
  v_post_status public.post_status;
  v_published_at timestamptz;
  v_media_count integer;
  v_item jsonb;
  v_media_id uuid;
  v_position integer;
  v_staging_path text;
  v_final_prefix text;
  v_media_results jsonb := '[]'::jsonb;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Unauthenticated' using errcode = '401';
  end if;

  if not public.can_publish_as(p_publisher_type, p_publisher_id, v_user_id) then
    raise exception 'Not authorized to publish as this entity' using errcode = '403';
  end if;

  v_media_count := coalesce(p_expected_media_count, 0);
  if v_media_count < 0 or v_media_count > 4 then
    raise exception 'Media count must be between 0 and 4' using errcode = '400';
  end if;

  if v_media_count = 0 and (p_text is null or length(trim(p_text)) = 0) then
    raise exception 'Post must have either text or photos' using errcode = '400';
  end if;

  if p_text is not null and length(p_text) > 2000 then
    raise exception 'Post text cannot exceed 2000 characters' using errcode = '400';
  end if;

  if jsonb_array_length(coalesce(p_media_items, '[]'::jsonb)) <> v_media_count then
    raise exception 'Media items array must match expected_media_count' using errcode = '400';
  end if;

  v_post_id := gen_random_uuid();

  -- Text-only posts become active immediately
  if v_media_count = 0 then
    v_post_status := 'active'::public.post_status;
    v_published_at := now();
  else
    v_post_status := 'publishing'::public.post_status;
    v_published_at := null;
  end if;

  insert into public.posts (
    post_id,
    created_by_user_id,
    author_id,
    author_context,
    context_entity_id,
    publisher_type,
    publisher_id,
    post_kind,
    post_type,
    text,
    visibility,
    status,
    expected_media_count,
    linked_match_id,
    linked_tournament_id,
    linked_team_id,
    linked_player_ids,
    created_at,
    published_at,
    updated_at
  )
  values (
    v_post_id,
    v_user_id,
    v_user_id,
    case
      when p_publisher_type = 'team' then 'team_manager'::public.post_author_context
      when p_publisher_type = 'tournament' then 'tournament_organizer'::public.post_author_context
      else 'personal'::public.post_author_context
    end,
    case
      when p_publisher_type in ('team', 'tournament') then p_publisher_id
      else null
    end,
    p_publisher_type,
    p_publisher_id,
    p_post_kind,
    case when v_media_count > 0 then 'photo'::public.post_type else 'text'::public.post_type end,
    p_text,
    p_visibility,
    v_post_status,
    v_media_count,
    p_linked_match_id,
    p_linked_tournament_id,
    case when p_publisher_type = 'team' then p_publisher_id else p_linked_team_id end,
    coalesce(p_linked_player_ids, '{}'),
    now(),
    v_published_at,
    now()
  );

  if v_media_count > 0 then
    for v_item in select * from jsonb_array_elements(p_media_items)
    loop
      v_media_id := gen_random_uuid();
      v_position := (v_item->>'position')::integer;
      v_staging_path := v_user_id::text || '/' || v_post_id::text || '/' || v_media_id::text || '/source.jpg';
      v_final_prefix := 'posts/' || v_post_id::text || '/' || v_media_id::text || '/v1/';

      insert into public.post_media (
        media_id,
        post_id,
        position,
        media_type,
        status,
        staging_path,
        final_prefix,
        source_width,
        source_height,
        pipeline_version,
        created_at,
        updated_at
      )
      values (
        v_media_id,
        v_post_id,
        v_position,
        'image',
        'awaiting_upload'::public.post_media_status,
        v_staging_path,
        v_final_prefix,
        (v_item->>'source_width')::integer,
        (v_item->>'source_height')::integer,
        1,
        now(),
        now()
      );

      v_media_results := v_media_results || jsonb_build_object(
        'media_id', v_media_id,
        'position', v_position,
        'staging_path', v_staging_path,
        'final_prefix', v_final_prefix
      );
    end loop;
  end if;

  return jsonb_build_object(
    'post_id', v_post_id,
    'status', v_post_status,
    'expected_media_count', v_media_count,
    'media', v_media_results
  );
end;
$$;

revoke all on function public.begin_post_publish from public;
grant execute on function public.begin_post_publish to authenticated;

create or replace function public.mark_post_media_uploaded(
  p_media_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, private, storage, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_post_id uuid;
  v_staging_path text;
  v_pipeline_version integer;
  v_expected integer;
  v_uploaded integer;
  v_status public.post_media_status;
  v_job_id uuid;
begin
  if v_user_id is null then
    raise exception 'Unauthenticated' using errcode = '401';
  end if;

  select pm.post_id, pm.staging_path, pm.pipeline_version, pm.status, p.expected_media_count
  into v_post_id, v_staging_path, v_pipeline_version, v_status, v_expected
  from public.post_media pm
  join public.posts p on p.post_id = pm.post_id
  where pm.media_id = p_media_id and p.created_by_user_id = v_user_id
  for update of pm;

  if not found then
    raise exception 'Media not found or unauthorized' using errcode = '404';
  end if;

  if v_status in ('uploaded', 'processing_feed', 'feed_ready', 'optimizing', 'optimized', 'optimization_failed') then
    return jsonb_build_object(
      'media_id', p_media_id,
      'status', v_status
    );
  end if;

  if not exists (
    select 1 from storage.objects
    where bucket_id = 'post-media-staging'
      and name = v_staging_path
  ) then
    raise exception 'Staging object not found in storage' using errcode = '404';
  end if;

  update public.post_media
  set status = 'uploaded'::public.post_media_status,
      last_processing_error = null,
      updated_at = now()
  where media_id = p_media_id;

  insert into private.media_processing_jobs (
    media_id,
    stage,
    pipeline_version,
    status
  )
  values (
    p_media_id,
    'feed',
    v_pipeline_version,
    'pending'
  )
  on conflict (media_id, stage, pipeline_version) do update
  set updated_at = now()
  returning job_id into v_job_id;

  perform private.dispatch_media_job(v_job_id);

  select count(*) into v_uploaded
  from public.post_media
  where post_id = v_post_id
    and status not in ('awaiting_upload', 'upload_failed');

  if v_uploaded >= v_expected then
    perform private.wake_post_media_worker(1);
  end if;

  return jsonb_build_object(
    'media_id', p_media_id,
    'status', 'uploaded',
    'job_id', v_job_id
  );
end;
$$;

revoke all on function public.mark_post_media_uploaded(uuid) from public, anon;
grant execute on function public.mark_post_media_uploaded(uuid) to authenticated;

create or replace function public.mark_media_feed_ready(
  p_media_id uuid,
  p_source_width integer,
  p_source_height integer,
  p_display_width integer,
  p_display_height integer,
  p_blurhash text,
  p_variants jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_post_id uuid;
  v_expected_count integer;
  v_ready_count integer;
  v_post_status public.post_status;
  v_pipeline_version integer;
  v_old_status public.post_media_status;
  v_opt_job_id uuid;
  v_now timestamptz := now();
begin
  select post_id, pipeline_version, status
  into v_post_id, v_pipeline_version, v_old_status
  from public.post_media
  where media_id = p_media_id
  for update;

  if not found then
    raise exception 'Media record not found' using errcode = '404';
  end if;

  if v_old_status not in ('feed_ready', 'optimizing', 'optimized', 'optimization_failed') then
    update public.post_media
    set
      status = 'feed_ready'::public.post_media_status,
      feed_ready_at = v_now,
      source_width = coalesce(p_source_width, source_width),
      source_height = coalesce(p_source_height, source_height),
      display_width = coalesce(p_display_width, p_source_width),
      display_height = coalesce(p_display_height, p_source_height),
      blurhash = p_blurhash,
      variants = coalesce(p_variants, '{}'::jsonb),
      processed_at = v_now,
      updated_at = v_now
    where media_id = p_media_id;

    insert into private.media_processing_jobs (
      media_id,
      stage,
      pipeline_version,
      status
    )
    values (
      p_media_id,
      'optimize',
      v_pipeline_version,
      'pending'
    )
    on conflict (media_id, stage, pipeline_version) do update
    set updated_at = now()
    returning job_id into v_opt_job_id;

    perform private.dispatch_media_job(v_opt_job_id);
  end if;

  select expected_media_count, status
  into v_expected_count, v_post_status
  from public.posts
  where post_id = v_post_id
  for update;

  select count(*) into v_ready_count
  from public.post_media
  where post_id = v_post_id
    and status in ('feed_ready', 'optimizing', 'optimized', 'optimization_failed');

  if v_post_status = 'publishing' and v_ready_count >= v_expected_count then
    update public.posts
    set
      status = 'active'::public.post_status,
      published_at = v_now,
      updated_at = v_now
    where post_id = v_post_id;

    v_post_status := 'active'::public.post_status;
  end if;

  return jsonb_build_object(
    'media_id', p_media_id,
    'post_id', v_post_id,
    'post_status', v_post_status,
    'all_ready', (v_ready_count >= v_expected_count)
  );
end;
$$;

revoke all on function public.mark_media_feed_ready(uuid, integer, integer, integer, integer, text, jsonb) from public, anon, authenticated;
grant execute on function public.mark_media_feed_ready(uuid, integer, integer, integer, integer, text, jsonb) to service_role;

-- -----------------------------------------------------------------------------
-- 7. CQRS-Lite Read Models & Projection Helpers
-- -----------------------------------------------------------------------------

create or replace function private.build_post_projections(
  p_post_ids uuid[],
  p_viewer_id uuid default auth.uid()
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_results jsonb;
begin
  if p_post_ids is null or cardinality(p_post_ids) = 0 then
    return '[]'::jsonb;
  end if;

  with target_posts as (
    select
      p.post_id,
      p.created_by_user_id,
      p.publisher_type,
      p.publisher_id,
      p.post_kind,
      p.text,
      p.visibility,
      p.status,
      p.expected_media_count,
      p.likes_count,
      p.comments_count,
      p.shares_count,
      p.created_at,
      p.published_at,
      p.linked_match_id,
      p.linked_tournament_id,
      p.linked_team_id
    from public.posts p
    where p.post_id = any(p_post_ids)
  ),
  posts_with_media as (
    select
      tp.*,
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'media_id', pm.media_id,
              'position', pm.position,
              'width', coalesce(pm.display_width, pm.source_width, 1080),
              'height', coalesce(pm.display_height, pm.source_height, 1080),
              'blurhash', pm.blurhash,
              'status', pm.status,
              'variants', pm.variants
            )
            order by pm.position
          )
          from public.post_media pm
          where pm.post_id = tp.post_id
        ),
        '[]'::jsonb
      ) as media_list
    from target_posts tp
  ),
  enriched as (
    select
      pwm.*,
      case pwm.publisher_type
        when 'team' then (
          select jsonb_build_object(
            'type', 'team',
            'id', t.team_id,
            'display_name', t.team_name,
            'username', null,
            'photo_url', t.logo_url
          )
          from public.teams t
          where t.team_id = pwm.publisher_id
        )
        when 'tournament' then (
          select jsonb_build_object(
            'type', 'tournament',
            'id', tr.tournament_id,
            'display_name', tr.name,
            'username', null,
            'photo_url', tr.logo_url
          )
          from public.tournaments tr
          where tr.tournament_id = pwm.publisher_id
        )
        else (
          select jsonb_build_object(
            'type', 'user',
            'id', pr.user_id,
            'display_name', pr.display_name,
            'username', pr.username,
            'photo_url', pr.profile_photo_url
          )
          from public.profiles pr
          where pr.user_id = pwm.created_by_user_id
        )
      end as publisher_info,
      (
        select jsonb_build_object(
          'type', 'user',
          'id', pr.user_id,
          'display_name', pr.display_name,
          'username', pr.username,
          'photo_url', pr.profile_photo_url
        )
        from public.profiles pr
        where pr.user_id = pwm.created_by_user_id
      ) as author_info,
      case
        when p_viewer_id is null then false
        else exists (
          select 1 from public.post_likes pl
          where pl.post_id = pwm.post_id and pl.user_id = p_viewer_id
        )
      end as viewer_liked,
      case
        when p_viewer_id is null then false
        else exists (
          select 1 from public.bookmarks bm
          where bm.post_id = pwm.post_id and bm.user_id = p_viewer_id
        )
      end as viewer_bookmarked,
      case
        when p_viewer_id is null or p_viewer_id = pwm.created_by_user_id then false
        else exists (
          select 1 from public.follows fl
          where fl.follower_id = p_viewer_id
            and fl.status = 'active'
            and fl.target_type::text = pwm.publisher_type::text
            and fl.target_id = pwm.publisher_id
        )
      end as viewer_following
    from posts_with_media pwm
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'post_id', e.post_id,
        'created_by_user_id', e.created_by_user_id,
        'publisher', e.publisher_info,
        'author', e.author_info,
        'post_kind', e.post_kind,
        'text', e.text,
        'visibility', e.visibility,
        'status', e.status,
        'expected_media_count', e.expected_media_count,
        'media', e.media_list,
        'counts', jsonb_build_object(
          'likes', e.likes_count,
          'comments', e.comments_count,
          'shares', e.shares_count
        ),
        'viewer', jsonb_build_object(
          'liked', e.viewer_liked,
          'bookmarked', e.viewer_bookmarked,
          'following_publisher', e.viewer_following
        ),
        'published_at', e.published_at,
        'created_at', e.created_at
      )
      order by array_position(p_post_ids, e.post_id)
    ),
    '[]'::jsonb
  ) into v_results
  from enriched e;

  return v_results;
end;
$$;

-- Home Feed RPC: Keyset pagination over global active posts
create or replace function public.get_home_feed(
  p_mode text default 'home',
  p_filter text default 'all',
  p_target_id uuid default null,
  p_cursor_published_at timestamptz default null,
  p_cursor_post_id uuid default null,
  p_limit integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_viewer_id uuid := auth.uid();
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
  v_post_ids uuid[];
begin
  -- Compatibility branching for legacy callers passing p_mode
  if p_mode = 'saved' then
    return public.get_saved_posts(p_cursor_published_at, p_cursor_post_id, v_limit);
  elsif p_mode in ('user', 'team', 'tournament') and p_target_id is not null then
    return public.get_profile_posts(
      p_target_id,
      p_mode::public.post_publisher_type,
      p_cursor_published_at,
      p_cursor_post_id,
      v_limit
    );
  end if;

  select array_agg(p.post_id)
  into v_post_ids
  from (
    select p.post_id
    from public.posts p
    where p.status = 'active'
      and (
        p_mode = 'home'
        or (
          p_mode = 'following'
          and v_viewer_id is not null
          and (
            p.created_by_user_id = v_viewer_id
            or exists (
              select 1
              from public.follows f
              where f.follower_id = v_viewer_id
                and f.status = 'active'
                and (
                  (f.target_type = 'user' and f.target_id = p.created_by_user_id)
                  or (f.target_type = 'team' and f.target_id = p.publisher_id)
                  or (f.target_type = 'tournament' and f.target_id = p.publisher_id)
                )
            )
          )
        )
      )
      and (
        v_viewer_id is null
        or not exists (
          select 1 from public.user_blocks ub
          where (ub.blocker_id = v_viewer_id and ub.blocked_id = p.created_by_user_id)
             or (ub.blocker_id = p.created_by_user_id and ub.blocked_id = v_viewer_id)
        )
      )
      and (
        p_cursor_published_at is null
        or p_cursor_post_id is null
        or (p.published_at, p.post_id) < (p_cursor_published_at, p_cursor_post_id)
      )
    order by p.published_at desc, p.post_id desc
    limit v_limit
  ) p;

  return private.build_post_projections(v_post_ids, v_viewer_id);
end;
$$;

-- Profile Posts RPC: Keyset pagination for user/team/tournament profiles
create or replace function public.get_profile_posts(
  p_publisher_id uuid,
  p_publisher_type public.post_publisher_type default 'user',
  p_cursor_published_at timestamptz default null,
  p_cursor_post_id uuid default null,
  p_limit integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_viewer_id uuid := auth.uid();
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
  v_post_ids uuid[];
begin
  select array_agg(p.post_id)
  into v_post_ids
  from (
    select p.post_id
    from public.posts p
    where p.status = 'active'
      and (
        (p_publisher_type = 'user' and p.created_by_user_id = p_publisher_id)
        or (p.publisher_type = p_publisher_type and p.publisher_id = p_publisher_id)
      )
      and (
        v_viewer_id is null
        or not exists (
          select 1 from public.user_blocks ub
          where (ub.blocker_id = v_viewer_id and ub.blocked_id = p.created_by_user_id)
             or (ub.blocker_id = p.created_by_user_id and ub.blocked_id = v_viewer_id)
        )
      )
      and (
        p_cursor_published_at is null
        or p_cursor_post_id is null
        or (p.published_at, p.post_id) < (p_cursor_published_at, p_cursor_post_id)
      )
    order by p.published_at desc, p.post_id desc
    limit v_limit
  ) p;

  return private.build_post_projections(v_post_ids, v_viewer_id);
end;
$$;

-- Saved Posts RPC: Keyset pagination for bookmarked posts
create or replace function public.get_saved_posts(
  p_cursor_saved_at timestamptz default null,
  p_cursor_post_id uuid default null,
  p_limit integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_viewer_id uuid := auth.uid();
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
  v_post_ids uuid[];
begin
  if v_viewer_id is null then
    return '[]'::jsonb;
  end if;

  select array_agg(b.post_id)
  into v_post_ids
  from (
    select b.post_id
    from public.bookmarks b
    join public.posts p on p.post_id = b.post_id
    where b.user_id = v_viewer_id
      and p.status = 'active'
      and not exists (
        select 1 from public.user_blocks ub
        where (ub.blocker_id = v_viewer_id and ub.blocked_id = p.created_by_user_id)
           or (ub.blocker_id = p.created_by_user_id and ub.blocked_id = v_viewer_id)
      )
      and (
        p_cursor_saved_at is null
        or p_cursor_post_id is null
        or (b.created_at, b.post_id) < (p_cursor_saved_at, p_cursor_post_id)
      )
    order by b.created_at desc, b.post_id desc
    limit v_limit
  ) b;

  return private.build_post_projections(v_post_ids, v_viewer_id);
end;
$$;

-- Post Detail RPC: Single post projection by post_id
create or replace function public.get_post_detail(
  p_post_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_viewer_id uuid := auth.uid();
  v_projections jsonb;
begin
  if not exists (
    select 1
    from public.posts p
    where p.post_id = p_post_id
      and p.status = 'active'
      and (
        v_viewer_id is null
        or not exists (
          select 1 from public.user_blocks ub
          where (ub.blocker_id = v_viewer_id and ub.blocked_id = p.created_by_user_id)
             or (ub.blocker_id = p.created_by_user_id and ub.blocked_id = v_viewer_id)
        )
      )
  ) then
    return null;
  end if;

  v_projections := private.build_post_projections(array[p_post_id], v_viewer_id);
  if jsonb_array_length(v_projections) > 0 then
    return v_projections->0;
  end if;

  return null;
end;
$$;

revoke all on function public.get_home_feed from public;
grant execute on function public.get_home_feed to anon, authenticated;

revoke all on function public.get_profile_posts from public;
grant execute on function public.get_profile_posts to anon, authenticated;

revoke all on function public.get_saved_posts from public;
grant execute on function public.get_saved_posts to anon, authenticated;

revoke all on function public.get_post_detail from public;
grant execute on function public.get_post_detail to anon, authenticated;

create or replace function public.set_post_like(
  p_post_id uuid,
  p_liked boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_current_count integer;
begin
  if v_user_id is null then
    raise exception 'Unauthenticated' using errcode = '401';
  end if;

  if p_liked then
    insert into public.post_likes (post_id, user_id)
    values (p_post_id, v_user_id)
    on conflict (post_id, user_id) do nothing;
  else
    delete from public.post_likes
    where post_id = p_post_id and user_id = v_user_id;
  end if;

  select likes_count into v_current_count
  from public.posts
  where post_id = p_post_id;

  return jsonb_build_object(
    'post_id', p_post_id,
    'liked', p_liked,
    'likes_count', coalesce(v_current_count, 0)
  );
end;
$$;

revoke all on function public.set_post_like from public;
grant execute on function public.set_post_like to authenticated;

create or replace function public.set_post_bookmark(
  p_post_id uuid,
  p_bookmarked boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Unauthenticated' using errcode = '401';
  end if;

  if p_bookmarked then
    insert into public.bookmarks (post_id, user_id)
    values (p_post_id, v_user_id)
    on conflict (user_id, post_id) do nothing;
  else
    delete from public.bookmarks
    where post_id = p_post_id and user_id = v_user_id;
  end if;

  return jsonb_build_object(
    'post_id', p_post_id,
    'bookmarked', p_bookmarked
  );
end;
$$;

revoke all on function public.set_post_bookmark from public;
grant execute on function public.set_post_bookmark to authenticated;
