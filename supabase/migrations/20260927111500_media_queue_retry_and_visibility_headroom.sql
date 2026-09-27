-- Migration: media_queue_retry_and_visibility_headroom
-- Description:
--   1. Increases PGMQ claim visibility timeout headroom (90s for feed, 180s for optimize).
--   2. Updates retry_post_media_job to set job status = 'retry_wait' and available_at = now() + delay.
--   3. Updates recover_stale_media_jobs to detect expired retry_wait jobs and wake worker.

-- 1. claim_post_media_jobs with increased VT headroom
create or replace function public.claim_post_media_jobs(
  p_stage text,
  p_qty integer default 1
)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_queue text;
  v_vt integer;
  v_rec record;
  v_jobs jsonb := '[]'::jsonb;
  v_job_id uuid;
begin
  v_queue := case p_stage
    when 'feed' then 'post_media_feed'
    when 'optimize' then 'post_media_optimize'
    else null
  end;

  if v_queue is null then
    raise exception 'Invalid queue stage %', p_stage;
  end if;

  v_vt := case p_stage
    when 'feed' then 90
    when 'optimize' then 180
    else 90
  end;

  for v_rec in (
    select msg_id, read_ct, message
    from pgmq.read(v_queue, v_vt, least(greatest(coalesce(p_qty, 1), 1), 10))
  ) loop
    begin
      v_job_id := (v_rec.message->>'jobId')::uuid;
      if v_job_id is not null then
        update private.media_processing_jobs
        set status = 'processing',
            attempts = attempts + 1,
            processing_started_at = now(),
            updated_at = now()
        where job_id = v_job_id;
      end if;
    exception when others then
      null;
    end;

    v_jobs := v_jobs || jsonb_build_array(
      jsonb_build_object(
        'msg_id', v_rec.msg_id::text,
        'read_ct', v_rec.read_ct,
        'message', v_rec.message
      )
    );
  end loop;

  return v_jobs;
end;
$$;

revoke all on function public.claim_post_media_jobs(text, integer) from public, anon, authenticated;
grant execute on function public.claim_post_media_jobs(text, integer) to service_role;

-- 2. retry_post_media_job sets explicit retry_wait and available_at
create or replace function public.retry_post_media_job(
  p_stage text,
  p_msg_id bigint,
  p_delay_seconds integer default 30
)
returns boolean
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_queue text;
  v_delay integer := coalesce(p_delay_seconds, 30);
  v_job_id uuid;
begin
  v_queue := case p_stage
    when 'feed' then 'post_media_feed'
    when 'optimize' then 'post_media_optimize'
    else null
  end;

  if v_queue is null then
    raise exception 'Invalid queue stage %', p_stage;
  end if;

  -- Extract jobId from the message payload in the queue table
  execute format(
    'select (message->>''jobId'')::uuid from pgmq.%I where msg_id = $1 limit 1',
    'q_' || v_queue
  )
  into v_job_id
  using p_msg_id;

  if v_job_id is not null then
    update private.media_processing_jobs
    set status = 'retry_wait',
        available_at = now() + (v_delay * interval '1 second'),
        updated_at = now()
    where job_id = v_job_id;
  end if;

  return pgmq.set_vt(v_queue, p_msg_id, v_delay);
end;
$$;

revoke all on function public.retry_post_media_job(text, bigint, integer) from public, anon, authenticated;
grant execute on function public.retry_post_media_job(text, bigint, integer) to service_role;

-- 3. recover_stale_media_jobs checks retry_wait as well
create or replace function private.recover_stale_media_jobs()
returns void
language plpgsql
security definer
set search_path = private, public, pg_temp
as $$
declare
  v_job record;
  v_requeued integer := 0;
begin
  for v_job in (
    select job_id
    from private.media_processing_jobs
    where (
      (status in ('pending', 'dispatched') and coalesce(updated_at, created_at) < now() - interval '2 minutes')
      or (status = 'processing' and coalesce(processing_started_at, updated_at) < now() - interval '3 minutes')
      or (status = 'retry_wait' and available_at <= now())
    )
    and completed_at is null
    and attempts < 5
    limit 10
  ) loop
    perform private.dispatch_media_job(v_job.job_id);
    v_requeued := v_requeued + 1;
  end loop;

  if v_requeued > 0 then
    perform private.wake_post_media_worker(1);
  end if;
end;
$$;

revoke all on function private.recover_stale_media_jobs() from public, anon, authenticated;
grant execute on function private.recover_stale_media_jobs() to service_role;
