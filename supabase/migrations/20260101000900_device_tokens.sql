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
  for select to authenticated using ((select auth.uid()) = user_id);

create policy "device_tokens_self_insert" on public.device_tokens
  for insert to authenticated with check ((select auth.uid()) = user_id);

create policy "device_tokens_self_update" on public.device_tokens
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "device_tokens_self_delete" on public.device_tokens
  for delete to authenticated using ((select auth.uid()) = user_id);

-- -----------------------------------------------------------------------------
-- Push delivery is queued in 0910; no per-row HTTP trigger.
