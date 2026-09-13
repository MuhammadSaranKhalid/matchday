-- Actual per-device outcomes; pgmq owns leases and retries. Never claim 'sent'
-- before FCM accepts. A crash between acceptance and persistence can duplicate
-- a push; the stable OS collapse identifier mitigates that unavoidable window.
create table public.notification_deliveries (
  notification_id uuid not null references public.notifications(notification_id) on delete cascade,
  revision integer not null check (revision >= 1),
  -- token_id snapshot, retained after token deletion. Empty for pre-fan-out skips.
  device_key text not null,
  channel text not null default 'push' check (channel = 'push'),
  status text not null check (status in ('sent', 'failed', 'skipped_pref', 'skipped_mute', 'no_token', 'invalid_token', 'superseded')),
  attempts integer not null default 0 check (attempts >= 0),
  error text,
  retryable boolean not null default false,
  provider_message_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (notification_id, revision, device_key, channel)
);
create index notification_deliveries_failed on public.notification_deliveries(updated_at desc)
  where status = 'failed';
create trigger notification_deliveries_set_updated_at before update on public.notification_deliveries
  for each row execute function public.set_updated_at();
alter table public.notification_deliveries enable row level security;
-- Operational details stay server-only (FCM errors must not leak device data).
revoke all on public.notification_deliveries from anon, authenticated;
grant all on public.notification_deliveries to service_role;
create policy notification_deliveries_service on public.notification_deliveries
  for all to service_role using (true) with check (true);
