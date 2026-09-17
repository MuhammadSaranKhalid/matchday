-- Integration after device_tokens. Queues are private; only the worker can
-- claim/ack jobs. Two queues prevent bulk announcements starving direct events.
-- pgmq / pg_net / pg_cron are declared in 20260101000000_shared_helpers.sql,
-- the extension catalogue. Creating the OBJECTS they provide belongs here; the
-- `create extension` lines do not. pg_cron was previously declared both here
-- and in 0610, with two different schema clauses, neither of which took effect.
-- Ensure clean state if queues exist from prior runs or partial resets
do $$
begin
  perform pgmq.drop_queue('notifications_push');
  perform pgmq.drop_queue('notifications_push_bulk');
exception when others then null;
end $$;
select pgmq.create('notifications_push');
select pgmq.create('notifications_push_bulk');


create or replace function public._notify_deliver(p_notification_ids uuid[], p_queue_name text)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_jobs jsonb[];
begin
  if p_queue_name not in ('notifications_push', 'notifications_push_bulk') then
    raise exception 'Invalid notification queue';
  end if;
  select array_agg(jsonb_build_object(
    'notification_id', n.notification_id, 'revision', n.group_count,
    'token_id', d.token_id, 'recipient_id', n.recipient_id,
    'title', n.title, 'body', n.body, 'route', n.route, 'type_key', n.type_key,
    'importance', t.importance)) into v_jobs
  from public.notifications n
  join public.notification_types t on t.key = n.type_key
  join public.device_tokens d on d.user_id = n.recipient_id
  where n.notification_id = any(p_notification_ids);
  if v_jobs is not null then
    perform pgmq.send_batch(p_queue_name, v_jobs);
  end if;
  insert into public.notification_deliveries
    (notification_id, revision, device_key, status)
  select n.notification_id, n.group_count, '', 'no_token'
  from public.notifications n where n.notification_id = any(p_notification_ids)
    and not exists (select 1 from public.device_tokens d where d.user_id = n.recipient_id)
  on conflict do nothing;
end;
$$;
revoke all on function public._notify_deliver(uuid[], text) from public, anon, authenticated;

-- Return bigint ids as strings; JavaScript numbers cannot represent all int8s.
--
-- BATCH SIZE IS PER-QUEUE POLICY and lives here rather than in the caller, so
-- the worker needs no knowledge of it. The signature stays one-argument on
-- purpose: adding `p_limit int default null` would create a SECOND overload
-- alongside the already-granted (text) version rather than replacing it.
--
-- Sizing. A job is one DEVICE, not one recipient (~1.5 devices per user), and
-- the cron wakes every 15s, so these are per-wake:
--   direct  50 × 4 wakes/min =   200 pushes/min
--   bulk   100 × 4 wakes/min =   400 pushes/min
-- The previous value of 10 for both meant ~20/min total, which put a
-- 50-person team announcement ~7 minutes behind and a 5,000-follower
-- tournament over twelve hours behind — and delayed an URGENT challenge by
-- minutes, which the per-row pg_net trigger it replaced delivered instantly.
--
-- Overlapping wakes are safe: the 120s visibility lease means a second
-- invocation claims different messages. Raise further against the FCM send
-- rate, not just observed queue depth.
create or replace function public.read_notification_jobs(p_queue text)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare v_jobs jsonb; v_limit int;
begin
  if p_queue not in ('notifications_push', 'notifications_push_bulk') then
    raise exception 'Invalid notification queue';
  end if;
  v_limit := case when p_queue = 'notifications_push' then 50 else 100 end;
  select coalesce(jsonb_agg(jsonb_build_object('msg_id', r.msg_id::text,
    'read_ct', r.read_ct, 'message', r.message)), '[]'::jsonb) into v_jobs
  from pgmq.read(p_queue, 120, v_limit) r;
  return v_jobs;
end;
$$;
revoke all on function public.read_notification_jobs(text) from public, anon, authenticated;
grant execute on function public.read_notification_jobs(text) to service_role;

create or replace function public.finish_notification_job(p_queue text, p_id bigint)
returns boolean language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if p_queue not in ('notifications_push', 'notifications_push_bulk') then
    raise exception 'Invalid notification queue';
  end if;
  return pgmq.archive(p_queue, p_id);
end;
$$;
revoke all on function public.finish_notification_job(text, bigint) from public, anon, authenticated;
grant execute on function public.finish_notification_job(text, bigint) to service_role;

-- Recheck settings at delivery time, including changes after enqueue.
create or replace function public.notification_push_status(p_id uuid, p_revision int)
returns text language sql stable security definer set search_path = public, pg_temp as $$
  select case
    when n.group_count <> p_revision then 'superseded'
    when not t.user_configurable then null
    when exists (select 1 from public.notification_mutes m
      where m.user_id = n.recipient_id and m.scope = n.entity_scope
        and m.entity_id = n.entity_id and (m.muted_until is null or m.muted_until > now())) then 'skipped_mute'
    when not coalesce((select enabled from public.notification_preferences p
      where p.user_id = n.recipient_id and p.category = t.category and p.channel = 'inapp'),
      'inapp' = any(t.default_channels)) then 'skipped_pref'
    when not coalesce((select enabled from public.notification_preferences p
      where p.user_id = n.recipient_id and p.category = t.category and p.channel = 'push'),
      'push' = any(t.default_channels)) then 'skipped_pref'
    else null end
  from public.notifications n join public.notification_types t on t.key = n.type_key
  where n.notification_id = p_id;
$$;
revoke all on function public.notification_push_status(uuid, int) from public, anon, authenticated;
grant execute on function public.notification_push_status(uuid, int) to service_role;

-- Wake a bounded worker on the schedule at the foot of this file. Failed HTTP
-- wakes leave queue jobs intact for the next wake. Secrets are provisioned
-- separately; never in SQL.
--
-- The 55s response timeout is longer than the 15s wake interval, so several
-- wakes can be in flight at once. That is intentional and safe: pg_net is
-- async (it never blocks the cron worker) and pgmq's visibility lease means
-- concurrent invocations claim disjoint messages.
create or replace function public.wake_notification_worker()
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_url text; v_key text;
begin
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'supabase_url' limit 1;
  select decrypted_secret into v_key from vault.decrypted_secrets where name = 'notification_worker_secret' limit 1;
  if v_url is null or v_key is null then
    raise warning 'Notification worker is not configured; jobs remain queued';
    return;
  end if;
  perform net.http_post(url := rtrim(v_url, '/') || '/functions/v1/send-push',
    headers := jsonb_build_object('content-type', 'application/json', 'x-worker-secret', v_key),
    body := '{}'::jsonb, timeout_milliseconds := 55000);
end;
$$;
revoke all on function public.wake_notification_worker() from public, anon, authenticated;
grant execute on function public.wake_notification_worker() to service_role;
do $$
begin
  if exists (select 1 from cron.job where jobname = 'notification-push-worker') then
    perform cron.unschedule('notification-push-worker');
  end if;
  perform cron.schedule(
    'notification-push-worker',
    '* * * * *',
    $sql$select public.wake_notification_worker();$sql$
  );
end $$;


