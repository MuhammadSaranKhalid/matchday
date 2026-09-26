-- =============================================================================
-- Migration: 20260926120000_post_media_worker_queue.sql
-- =============================================================================
-- Supabase Queues (PGMQ) + Vercel Stateless Worker Architecture:
-- 1. Creates durable post_media_feed and post_media_optimize queues.
-- 2. Restricts post_media table and mark_media_feed_ready to service_role only.
-- 3. Adds mark_post_media_uploaded RPC for Flutter client.
-- 4. Establishes private.media_worker_slots to bound Vercel concurrency.
-- 5. Implements claim_post_media_jobs, finish_post_media_job, retry_post_media_job,
--    and mark_media_optimized for the Vercel worker.
-- 6. Configures private.wake_post_media_worker and pg_cron recovery scheduler.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Queues Initialization (PGMQ)
-- -----------------------------------------------------------------------------

create extension if not exists pgmq with schema extensions;
create extension if not exists pg_net with schema extensions;

do $$
begin
  if not exists (select 1 from pgmq.list_queues() where queue_name = 'post_media_feed') then
    perform pgmq.create('post_media_feed');
  end if;

  if not exists (select 1 from pgmq.list_queues() where queue_name = 'post_media_optimize') then
    perform pgmq.create('post_media_optimize');
  end if;
end $$;

-- -----------------------------------------------------------------------------
-- 2. Table Lifecycle Fields on post_media
-- -----------------------------------------------------------------------------

alter table public.post_media
  add column if not exists optimization_attempts integer not null default 0,
  add column if not exists feed_ready_at timestamptz,
  add column if not exists optimized_at timestamptz;

-- -----------------------------------------------------------------------------
-- 3. Lockdown Client Mutation on post_media
-- Clients must never manipulate processing state or fake variant records.
-- -----------------------------------------------------------------------------

drop policy if exists "post_media_insert_creator" on public.post_media;
drop policy if exists "post_media_update_creator" on public.post_media;
drop policy if exists "post_media_delete_creator" on public.post_media;

revoke insert, update, delete on public.post_media from anon, authenticated;

-- -----------------------------------------------------------------------------
-- 4. Tighten Staging Storage Bucket
-- Staging accepts JPEG only and forbids overwriting once uploaded.
-- -----------------------------------------------------------------------------

update storage.buckets
set allowed_mime_types = array['image/jpeg']
where id = 'post-media-staging';

drop policy if exists "post_media_staging_owner_update" on storage.objects;

-- -----------------------------------------------------------------------------
-- 5. Internal Worker Slots (Concurrency Leases)
-- -----------------------------------------------------------------------------

create schema if not exists private;

create table if not exists private.media_worker_slots (
  slot_id smallint primary key,
  leased_by uuid,
  lease_until timestamptz
);

insert into private.media_worker_slots (slot_id)
values (1), (2), (3), (4)
on conflict do nothing;

create or replace function public.acquire_media_worker_slot(
  p_worker_id uuid,
  p_lease_seconds integer default 270
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
-- 6. Vercel Wake-Up Function (pg_net)
-- -----------------------------------------------------------------------------

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
  -- Check vault for worker URL & secret
  select decrypted_secret into v_url
  from vault.decrypted_secrets
  where name = 'vercel_media_worker_url'
  limit 1;

  select decrypted_secret into v_secret
  from vault.decrypted_secrets
  where name = 'vercel_media_worker_secret'
  limit 1;

  if v_url is null or v_secret is null then
    -- Silently log warning so transaction doesn't fail if secrets aren't set yet
    raise warning 'Vercel media worker URL or secret not found in vault';
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

-- -----------------------------------------------------------------------------
-- 7. Client Upload Confirmation RPC (mark_post_media_uploaded)
-- -----------------------------------------------------------------------------

create or replace function public.mark_post_media_uploaded(
  p_media_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, storage, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_post_id uuid;
  v_staging_path text;
  v_pipeline_version integer;
  v_expected integer;
  v_uploaded integer;
  v_status public.post_media_status;
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

  -- Enqueue job in durable high-priority feed queue
  perform pgmq.send(
    'post_media_feed',
    jsonb_build_object(
      'media_id', p_media_id,
      'pipeline_version', v_pipeline_version
    )
  );

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
    'status', 'uploaded'
  );
end;
$$;

revoke all on function public.mark_post_media_uploaded(uuid) from public, anon;
grant execute on function public.mark_post_media_uploaded(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- 8. Worker Job Management RPCs (service_role only)
-- -----------------------------------------------------------------------------

create or replace function public.claim_post_media_jobs(
  p_stage text,
  p_qty integer default 1
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_queue text;
  v_qty integer;
  v_result jsonb;
begin
  v_queue := case p_stage
    when 'feed' then 'post_media_feed'
    when 'optimize' then 'post_media_optimize'
    else null
  end;

  if v_queue is null then
    raise exception 'Invalid stage: %', p_stage using errcode = '400';
  end if;

  -- Bounded batch size
  v_qty := case when p_stage = 'feed' then least(greatest(p_qty, 1), 2) else 1 end;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'msg_id', r.msg_id::text,
        'read_ct', r.read_ct,
        'message', r.message
      )
    ),
    '[]'::jsonb
  )
  into v_result
  from pgmq.read(v_queue, 180, v_qty) r;

  return v_result;
end;
$$;

revoke all on function public.claim_post_media_jobs(text, integer) from public, anon, authenticated;
grant execute on function public.claim_post_media_jobs(text, integer) to service_role;

create or replace function public.finish_post_media_job(
  p_stage text,
  p_msg_id bigint
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_queue text;
begin
  v_queue := case p_stage
    when 'feed' then 'post_media_feed'
    when 'optimize' then 'post_media_optimize'
    else null
  end;

  if v_queue is null then
    raise exception 'Invalid stage: %', p_stage using errcode = '400';
  end if;

  return pgmq.archive(v_queue, p_msg_id);
end;
$$;

revoke all on function public.finish_post_media_job(text, bigint) from public, anon, authenticated;
grant execute on function public.finish_post_media_job(text, bigint) to service_role;

create or replace function public.retry_post_media_job(
  p_stage text,
  p_msg_id bigint,
  p_delay_seconds integer
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_queue text;
begin
  v_queue := case p_stage
    when 'feed' then 'post_media_feed'
    when 'optimize' then 'post_media_optimize'
    else null
  end;

  if v_queue is null then
    raise exception 'Invalid stage: %', p_stage using errcode = '400';
  end if;

  perform pgmq.set_vt(
    v_queue,
    p_msg_id,
    least(greatest(p_delay_seconds, 5), 600)
  );
end;
$$;

revoke all on function public.retry_post_media_job(text, bigint, integer) from public, anon, authenticated;
grant execute on function public.retry_post_media_job(text, bigint, integer) to service_role;

-- -----------------------------------------------------------------------------
-- 9. Updated mark_media_feed_ready & mark_media_optimized (service_role only)
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
set search_path = public, pg_temp
as $$
declare
  v_post_id uuid;
  v_expected_count integer;
  v_ready_count integer;
  v_post_status public.post_status;
  v_pipeline_version integer;
  v_old_status public.post_media_status;
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

    -- Enqueue background secondary optimization (Priority 2)
    perform pgmq.send(
      'post_media_optimize',
      jsonb_build_object(
        'media_id', p_media_id,
        'pipeline_version', v_pipeline_version
      )
    );
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

-- Security fix: ONLY service_role may declare media feed-ready
revoke all on function public.mark_media_feed_ready(uuid, integer, integer, integer, integer, text, jsonb) from public, anon, authenticated;
grant execute on function public.mark_media_feed_ready(uuid, integer, integer, integer, integer, text, jsonb) to service_role;

-- Finalize secondary optimization
create or replace function public.mark_media_optimized(
  p_media_id uuid,
  p_variants jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, storage, pg_temp
as $$
declare
  v_staging_path text;
  v_existing_variants jsonb;
begin
  select staging_path, variants
  into v_staging_path, v_existing_variants
  from public.post_media
  where media_id = p_media_id
  for update;

  if not found then
    raise exception 'Media not found' using errcode = '404';
  end if;

  update public.post_media
  set
    status = 'optimized'::public.post_media_status,
    optimized_at = now(),
    variants = coalesce(v_existing_variants, '{}'::jsonb) || coalesce(p_variants, '{}'::jsonb),
    updated_at = now()
  where media_id = p_media_id;

  -- Delete temporary staging file to clean up storage
  if v_staging_path is not null then
    delete from storage.objects
    where bucket_id = 'post-media-staging'
      and name = v_staging_path;
  end if;

  return jsonb_build_object(
    'media_id', p_media_id,
    'status', 'optimized'
  );
end;
$$;

revoke all on function public.mark_media_optimized(uuid, jsonb) from public, anon, authenticated;
grant execute on function public.mark_media_optimized(uuid, jsonb) to service_role;

-- -----------------------------------------------------------------------------
-- 10. Recovery Cron (pg_cron)
-- Wakes Vercel if backlog exists in queues.
-- -----------------------------------------------------------------------------

create or replace function public.recover_post_media_workers()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_feed bigint := 0;
  v_opt bigint := 0;
begin
  select queue_length into v_feed from pgmq.metrics('post_media_feed');
  select queue_length into v_opt from pgmq.metrics('post_media_optimize');

  if coalesce(v_feed, 0) > 0 or coalesce(v_opt, 0) > 0 then
    perform private.wake_post_media_worker(4);
  end if;
exception
  when others then null;
end;
$$;

revoke all on function public.recover_post_media_workers() from public, anon, authenticated;
grant execute on function public.recover_post_media_workers() to service_role;

-- Schedule recovery cron if pg_cron extension is available
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule('post-media-worker-recovery');
    perform cron.schedule(
      'post-media-worker-recovery',
      '* * * * *',
      $cron$ select public.recover_post_media_workers(); $cron$
    );
  end if;
exception
  when others then null;
end $$;
