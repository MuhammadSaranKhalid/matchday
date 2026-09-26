-- =============================================================================
-- Migration: 20260926130000_media_processing_jobs.sql
-- =============================================================================
-- Canonical Job Ledger & Provider-Neutral Dispatch:
-- 1. Creates private.media_processing_jobs to track image jobs independently
--    from transport (PGMQ today, Cloud Tasks tomorrow).
-- 2. Implements private.dispatch_media_job(job_id) as the narrow transport adapter.
-- 3. Updates mark_post_media_uploaded to create & dispatch 'feed' jobs.
-- 4. Updates mark_media_feed_ready to create & dispatch 'optimize' jobs.
-- 5. Adds record_media_job_outcome RPC for worker status reporting.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Canonical Media Processing Jobs Table
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

-- -----------------------------------------------------------------------------
-- 2. Transport Dispatch Adapter
-- Infrastructure-specific: routes canonical job to PGMQ today.
-- -----------------------------------------------------------------------------

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

  -- Canonical provider-neutral job contract (Point 15)
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

-- -----------------------------------------------------------------------------
-- 3. Update mark_post_media_uploaded to use canonical job ledger
-- -----------------------------------------------------------------------------

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

  -- Idempotent retry after response loss
  if v_status in ('uploaded', 'processing_feed', 'feed_ready', 'optimizing', 'optimized', 'optimization_failed') then
    return jsonb_build_object(
      'media_id', p_media_id,
      'status', v_status
    );
  end if;

  -- Verify staging object actually exists in post-media-staging
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

  -- Create canonical job in ledger
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

  -- Dispatch via today's transport
  perform private.dispatch_media_job(v_job_id);

  select count(*) into v_uploaded
  from public.post_media
  where post_id = v_post_id
    and status not in ('awaiting_upload', 'upload_failed');

  -- Once all source files for this post are uploaded, wake Vercel worker
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

-- -----------------------------------------------------------------------------
-- 4. Update mark_media_feed_ready to create optimize job in ledger
-- -----------------------------------------------------------------------------

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

  -- Only perform update and enqueue optimization if not already at/past feed_ready
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

    -- Create canonical optimize job in ledger
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

    -- Dispatch via today's transport
    perform private.dispatch_media_job(v_opt_job_id);
  end if;

  -- Lock post row for evaluation
  select expected_media_count, status
  into v_expected_count, v_post_status
  from public.posts
  where post_id = v_post_id
  for update;

  select count(*) into v_ready_count
  from public.post_media
  where post_id = v_post_id
    and status in ('feed_ready', 'optimizing', 'optimized', 'optimization_failed');

  -- If all attached media are at least feed_ready, activate the post
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
-- 5. Worker Job Ledger Outcome RPC (service_role only)
-- -----------------------------------------------------------------------------

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
