-- =============================================================================
-- 0900 · device_tokens + send-push trigger
-- =============================================================================
-- Backs FCM push delivery. The Flutter client upserts one row per signed-in
-- device on every sign-in / token refresh; the server-side trigger fires the
-- `send-push` Edge Function whenever a notifications row is inserted, which
-- fans the message out to every device the recipient is registered on.
--
-- Lifecycle:
--   sign-in  → upsert (user_id, fcm_token) keyed by fcm_token (unique)
--   refresh  → upsert (same row replaced by token PK)
--   sign-out → delete by fcm_token
--   dead token (FCM returns 404 UNREGISTERED) → Edge Function deletes the row
--
-- Per-token uniqueness:
--   `device_tokens_unique_token` ensures one user owns a given device token at
--   a time. If user B signs in on a device where user A was previously signed
--   in, the upsert replaces A's row.
-- =============================================================================

create table public.device_tokens (
  token_id     uuid primary key default gen_random_uuid(),
  user_id      uuid not null
                    references public.profiles(user_id) on delete cascade,
  fcm_token    text not null,
  platform     text not null
    constraint device_tokens_platform_check
    check (platform in ('ios', 'android', 'web')),
  app_version  text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  -- Touched by the client on every upsert; distinct from `updated_at` so a
  -- liveness sweep can prune tokens that haven't reported in for N days
  -- without paying attention to every trigger-driven row update.
  last_seen_at timestamptz not null default now(),
  constraint device_tokens_unique_token unique (fcm_token)
);

create index device_tokens_user      on public.device_tokens (user_id);
create index device_tokens_last_seen on public.device_tokens (last_seen_at);

create trigger device_tokens_set_updated_at
  before update on public.device_tokens
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- RLS — the signed-in user can only touch their own rows. The Edge Function
-- reads via the service role (bypasses RLS) so it can find tokens for any
-- recipient.
-- -----------------------------------------------------------------------------
alter table public.device_tokens enable row level security;

create policy "device_tokens_self_select" on public.device_tokens
  for select to authenticated using (auth.uid() = user_id);

create policy "device_tokens_self_insert" on public.device_tokens
  for insert to authenticated with check (auth.uid() = user_id);

create policy "device_tokens_self_update" on public.device_tokens
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "device_tokens_self_delete" on public.device_tokens
  for delete to authenticated using (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- invoke_send_push — fire the Edge Function on every new notifications row.
--
-- Uses pg_net (Supabase ships it pre-installed; the extension lives in
-- `extensions`) plus Supabase Vault for the two env-specific values:
--
--   supabase_url      — the project's base URL (e.g. https://<ref>.supabase.co)
--   service_role_key  — the sb_secret_* key that authenticates against the
--                       send-push Edge Function
--
-- Bootstrap once per environment:
--   select vault.create_secret('https://<ref>.supabase.co', 'supabase_url');
--   select vault.create_secret('<sb_secret_…>', 'service_role_key');
--
-- The function is `security definer` so the implicit pg_net call runs as
-- postgres (pg_net's wrapper is owned by supabase_admin) and the reads from
-- vault.decrypted_secrets succeed regardless of the inserting user's
-- privileges. See https://supabase.com/docs/guides/database/vault.
-- -----------------------------------------------------------------------------
create extension if not exists pg_net with schema extensions;

create or replace function public.invoke_send_push()
returns trigger
language plpgsql
security definer
set search_path = public, net, vault, pg_temp
as $$
declare
  v_url text;
  v_key text;
begin
  select decrypted_secret into v_url
    from vault.decrypted_secrets where name = 'supabase_url' limit 1;
  select decrypted_secret into v_key
    from vault.decrypted_secrets where name = 'service_role_key' limit 1;

  if v_url is null or v_key is null then
    raise warning
      '[invoke_send_push] vault secrets missing (url_present=%, key_present=%)',
      v_url is not null, v_key is not null;
    return new;
  end if;

  perform net.http_post(
    url     := rtrim(v_url, '/') || '/functions/v1/send-push',
    headers := jsonb_build_object(
      'content-type',  'application/json',
      'authorization', 'Bearer ' || v_key
    ),
    body    := jsonb_build_object('notification_id', new.notification_id)
  );
  return new;
exception
  when others then
    -- Never let push delivery failures abort the notifications insert.
    -- The in-app realtime stream already covers the foreground case; a
    -- failed push delivery only affects backgrounded devices for this one
    -- notification.
    raise warning '[invoke_send_push] failed for notification_id=%: %',
      new.notification_id, sqlerrm;
    return new;
end;
$$;

create trigger notifications_invoke_send_push
  after insert on public.notifications
  for each row execute function public.invoke_send_push();
