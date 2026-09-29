-- Matchday V1 media lifecycle.
-- PostgreSQL stores durable business state; BullMQ owns execution attempts.

-- Remove the legacy HTTP-woken PGMQ processing path.
do $$
declare
  v_job_id bigint;
begin
  select jobid into v_job_id
  from cron.job
  where jobname = 'media-worker-recovery'
  limit 1;

  if v_job_id is not null then
    perform cron.unschedule(v_job_id);
  end if;
end
$$;

drop function if exists public.claim_post_media_jobs(text, integer);
drop function if exists public.finish_post_media_job(text, bigint);
drop function if exists public.retry_post_media_job(text, bigint, integer);
drop function if exists public.mark_media_feed_ready(uuid, integer, integer, integer, integer, text, jsonb);
drop function if exists public.mark_media_optimized(uuid, jsonb);
drop function if exists public.mark_post_media_uploaded(uuid);
drop function if exists public.acquire_media_worker_slot(uuid, integer);
drop function if exists public.release_media_worker_slot(integer, uuid);
drop function if exists public.record_media_job_outcome(uuid, text, text);
drop function if exists private.dispatch_media_job(uuid);
drop function if exists private.recover_stale_media_jobs();
drop function if exists private.wake_post_media_worker(integer);

drop function if exists public.begin_post_publish(
  public.post_publisher_type,
  uuid,
  public.post_kind,
  text,
  integer,
  public.post_visibility,
  text,
  jsonb,
  uuid,
  uuid,
  uuid
);
drop function if exists public.abandon_post_publish(uuid);

drop table if exists private.media_processing_jobs;
drop table if exists private.media_worker_slots;

do $$
begin
  if exists (
    select 1 from pgmq.list_queues() where queue_name = 'post_media_feed'
  ) then
    perform pgmq.drop_queue('post_media_feed');
  end if;
end
$$;

do $$
begin
  if exists (
    select 1 from pgmq.list_queues() where queue_name = 'post_media_optimize'
  ) then
    perform pgmq.drop_queue('post_media_optimize');
  end if;
end
$$;

-- Replace the development enum rather than carrying feed/optimize states.
alter table public.post_media
  alter column status drop default;

alter type public.post_media_status rename to post_media_status_legacy;

create type public.post_media_status as enum (
  'pending_upload',
  'uploaded',
  'processing',
  'ready',
  'failed'
);

alter table public.post_media
  alter column status type public.post_media_status
  using (
    case status::text
      when 'awaiting_upload' then 'pending_upload'
      when 'uploaded' then 'uploaded'
      when 'processing_feed' then 'processing'
      when 'feed_ready' then 'ready'
      when 'optimizing' then 'processing'
      when 'optimized' then 'ready'
      when 'upload_failed' then 'failed'
      when 'processing_failed' then 'failed'
      when 'optimization_failed' then 'failed'
    end
  )::public.post_media_status;

alter table public.post_media
  alter column status set default 'pending_upload'::public.post_media_status,
  drop column if exists optimization_attempts,
  drop column if exists feed_ready_at,
  drop column if exists last_optimization_error,
  drop column if exists optimized_at;

drop type public.post_media_status_legacy;

create index if not exists idx_post_media_uploaded_recovery
  on public.post_media (updated_at, media_id)
  where status = 'uploaded';

create index if not exists idx_post_media_processing_recovery
  on public.post_media (processing_started_at, media_id)
  where status = 'processing';

drop policy if exists "post_media_read" on public.post_media;
drop policy if exists "post_media_read_policy" on public.post_media;

create policy "post_media_read_active_or_creator"
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

create or replace function private.claim_post_media_for_processing(
  p_media_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_media public.post_media%rowtype;
begin
  select *
  into v_media
  from public.post_media
  where media_id = p_media_id
  for update;

  if not found then
    return jsonb_build_object('claimed', false, 'status', 'missing');
  end if;

  if v_media.status = 'ready' then
    return jsonb_build_object('claimed', false, 'status', 'ready');
  end if;

  if v_media.status <> 'uploaded' then
    return jsonb_build_object('claimed', false, 'status', v_media.status::text);
  end if;

  update public.post_media
  set status = 'processing',
      processing_started_at = now(),
      processing_attempts = processing_attempts + 1,
      last_processing_error = null
  where media_id = p_media_id
  returning * into v_media;

  return jsonb_build_object(
    'claimed', true,
    'status', v_media.status::text,
    'media_id', v_media.media_id,
    'post_id', v_media.post_id,
    'staging_path', v_media.staging_path,
    'final_prefix', v_media.final_prefix,
    'pipeline_version', v_media.pipeline_version,
    'attempt', v_media.processing_attempts
  );
end;
$$;

create or replace function private.release_post_media_for_retry(
  p_media_id uuid,
  p_error text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.post_media
  set status = 'uploaded',
      processing_started_at = null,
      last_processing_error = left(nullif(p_error, ''), 500)
  where media_id = p_media_id
    and status = 'processing';

  return found;
end;
$$;

create or replace function private.mark_post_media_failed(
  p_media_id uuid,
  p_error text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.post_media
  set status = 'failed',
      processing_started_at = null,
      processed_at = now(),
      last_processing_error = left(nullif(p_error, ''), 500)
  where media_id = p_media_id
    and status = 'processing';

  return found;
end;
$$;

create or replace function private.mark_post_media_ready(
  p_media_id uuid,
  p_source_width integer,
  p_source_height integer,
  p_display_width integer,
  p_display_height integer,
  p_blurhash text,
  p_variants jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_post_id uuid;
  v_status public.post_media_status;
  v_expected integer;
  v_ready integer;
  v_post_published boolean := false;
begin
  select post_id, status
  into v_post_id, v_status
  from public.post_media
  where media_id = p_media_id
  for update;

  if not found then
    return jsonb_build_object('ready', false, 'status', 'missing', 'post_published', false);
  end if;

  perform 1
  from public.posts
  where post_id = v_post_id
  for update;

  if v_status = 'ready' then
    select status = 'active'
    into v_post_published
    from public.posts
    where post_id = v_post_id;

    return jsonb_build_object(
      'ready', true,
      'status', 'ready',
      'post_published', coalesce(v_post_published, false)
    );
  end if;

  if v_status <> 'processing' then
    return jsonb_build_object(
      'ready', false,
      'status', v_status::text,
      'post_published', false
    );
  end if;

  if p_source_width <= 0 or p_source_height <= 0
     or p_display_width <= 0 or p_display_height <= 0
     or jsonb_typeof(p_variants) <> 'object' then
    raise exception 'Invalid processed media metadata' using errcode = '22023';
  end if;

  update public.post_media
  set status = 'ready',
      source_width = p_source_width,
      source_height = p_source_height,
      display_width = p_display_width,
      display_height = p_display_height,
      blurhash = nullif(p_blurhash, ''),
      variants = p_variants,
      processing_started_at = null,
      last_processing_error = null,
      processed_at = now()
  where media_id = p_media_id;

  select expected_media_count
  into v_expected
  from public.posts
  where post_id = v_post_id;

  select count(*)
  into v_ready
  from public.post_media
  where post_id = v_post_id
    and status = 'ready';

  if v_expected > 0 and v_ready = v_expected then
    update public.posts
    set status = 'active',
        published_at = coalesce(published_at, now()),
        updated_at = now()
    where post_id = v_post_id
      and status = 'publishing';

    select status = 'active'
    into v_post_published
    from public.posts
    where post_id = v_post_id;
  end if;

  return jsonb_build_object(
    'ready', true,
    'status', 'ready',
    'post_published', coalesce(v_post_published, false)
  );
end;
$$;

create or replace function private.recover_stale_post_media(
  p_stale_before timestamptz,
  p_limit integer default 100
)
returns setof uuid
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_limit < 1 or p_limit > 500 then
    raise exception 'Invalid recovery limit' using errcode = '22023';
  end if;

  return query
  with candidates as (
    select pm.media_id, pm.status
    from public.post_media pm
    where (
      pm.status = 'uploaded'
      and pm.updated_at <= p_stale_before
    ) or (
      pm.status = 'processing'
      and pm.processing_started_at <= p_stale_before
    )
    order by coalesce(pm.processing_started_at, pm.updated_at), pm.media_id
    for update skip locked
    limit p_limit
  ), released as (
    update public.post_media pm
    set status = 'uploaded',
        processing_started_at = null,
        last_processing_error = case
          when c.status = 'processing' then 'stale_processing_claim'
          else pm.last_processing_error
        end
    from candidates c
    where pm.media_id = c.media_id
      and c.status = 'processing'
    returning pm.media_id
  )
  select c.media_id
  from candidates c
  order by c.media_id;
end;
$$;

revoke all on function private.claim_post_media_for_processing(uuid) from public, anon, authenticated;
revoke all on function private.release_post_media_for_retry(uuid, text) from public, anon, authenticated;
revoke all on function private.mark_post_media_ready(uuid, integer, integer, integer, integer, text, jsonb) from public, anon, authenticated;
revoke all on function private.mark_post_media_failed(uuid, text) from public, anon, authenticated;
revoke all on function private.recover_stale_post_media(timestamptz, integer) from public, anon, authenticated;

grant usage on schema private to service_role;
grant execute on function private.claim_post_media_for_processing(uuid) to service_role;
grant execute on function private.release_post_media_for_retry(uuid, text) to service_role;
grant execute on function private.mark_post_media_ready(uuid, integer, integer, integer, integer, text, jsonb) to service_role;
grant execute on function private.mark_post_media_failed(uuid, text) to service_role;
grant execute on function private.recover_stale_post_media(timestamptz, integer) to service_role;
