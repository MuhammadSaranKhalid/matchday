-- Migration: reschedule_media_worker_recovery_cron
-- Description:
--   Explicitly unschedules any existing media-worker-recovery jobs and reschedules
--   to run predictably every 2 minutes ('*/2 * * * *').
--   Does NOT suppress errors with 'WHEN OTHERS THEN NULL'.

do $$
declare
  v_job record;
begin
  for v_job in (select jobid from cron.job where jobname = 'media-worker-recovery') loop
    perform cron.unschedule(v_job.jobid);
  end loop;

  perform cron.schedule(
    'media-worker-recovery',
    '*/2 * * * *',
    $cmd$select private.recover_stale_media_jobs();$cmd$
  );
end $$;
