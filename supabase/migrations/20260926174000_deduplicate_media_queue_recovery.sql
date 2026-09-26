-- Deduplicate PGMQ messages in dispatch_media_job and fix recovery stale check
--
-- Problem:
-- 1. dispatch_media_job() unconditionally called pgmq.send() whenever invoked.
--    When recover_stale_media_jobs() ran every 2 minutes for a job whose worker
--    failed to wake or was delayed, a brand new PGMQ queue message was inserted
--    every 2 minutes, causing unbounded queue message duplication.
-- 2. recover_stale_media_jobs() checked created_at < now() - interval '2 minutes'.
--    Because created_at never changes on redispatch, a stuck job was continuously
--    re-queued every 2 minutes without giving the new dispatch time to settle.
--
-- Solution:
-- 1. In dispatch_media_job(), check if an unarchived message for the same jobId
--    already exists in the queue table (pgmq.q_<queue>).
--    - If it already exists and its vt is in the future, reset vt to 0 via pgmq.set_vt()
--      so it is immediately claimable.
--    - Only insert a new pgmq message if no active message exists.
--    - Update updated_at = now() on media_processing_jobs.
-- 2. In recover_stale_media_jobs(), check coalesce(updated_at, created_at) < now() - interval '2 minutes',
--    ensuring redispatched jobs are given a full 2-minute window before being considered stale again.

create or replace function private.dispatch_media_job(
  p_job_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_job record;
  v_queue text;
  v_payload jsonb;
  v_existing_msg_id bigint;
  v_existing_vt timestamptz;
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

  -- Check if an unarchived message already exists in the queue for this job
  execute format(
    'select msg_id, vt from pgmq.%I where (message->>''jobId'')::uuid = $1 limit 1',
    'q_' || v_queue
  )
  into v_existing_msg_id, v_existing_vt
  using p_job_id;

  if v_existing_msg_id is not null then
    -- Message already exists; if not currently visible, reset visibility to 0 (now)
    if v_existing_vt > clock_timestamp() then
      perform pgmq.set_vt(v_queue, v_existing_msg_id, 0);
    end if;
  else
    -- No message exists in the active queue; enqueue a new one
    v_payload := jsonb_build_object(
      'schemaVersion', 1,
      'jobId', v_job.job_id,
      'mediaId', v_job.media_id,
      'stage', v_job.stage,
      'pipelineVersion', v_job.pipeline_version
    );
    perform pgmq.send(v_queue, v_payload);
  end if;

  update private.media_processing_jobs
  set status = 'dispatched',
      updated_at = now()
  where job_id = p_job_id;
end;
$$;

revoke all on function private.dispatch_media_job(uuid) from public, anon, authenticated;
grant execute on function private.dispatch_media_job(uuid) to service_role;

-- recover_stale_media_jobs: use updated_at to prevent re-dispatch storms
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
