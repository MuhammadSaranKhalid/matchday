-- =============================================================================
-- 0802 · messages — the chat ledger + realtime + push fan-out
-- =============================================================================
-- WHAT THIS TABLE IS
-- ------------------
-- The source-of-truth ledger for every line of text in every chat. Soft-
-- deleted (deleted_at) instead of removed so quotes / replies always
-- resolve and an audit of "what was sent here" is possible.
--
-- Both `edited_at` and `deleted_at` are nullable and editable by the
-- sender via the messages_update_own policy below; the policy enforces
-- that a single UPDATE statement can't set both at once.
-- =============================================================================

create table public.messages (
  message_id      uuid primary key default gen_random_uuid(),
  chat_id         uuid not null references public.chats(chat_id) on delete cascade,
  -- ON DELETE SET NULL so a profile delete (delete_user RPC in 0700)
  -- preserves the message but anonymises the sender. UI renders
  -- "Deleted user" when sender_id is null.
  sender_id       uuid references public.profiles(user_id) on delete set null,
  body            text not null check (length(body) between 1 and 2000),
  created_at      timestamptz not null default now(),
  edited_at       timestamptz,
  deleted_at      timestamptz
);

-- Hot read path: "latest messages in this chat", paginated by created_at.
create index messages_chat_created on public.messages (chat_id, created_at desc);

alter table public.messages enable row level security;

-- =============================================================================
-- RLS
-- =============================================================================
-- READ:   any active member of the chat (the chat list and the open
--         chat screen both read every message in the channel).
-- INSERT: any active member, AND the row's sender_id must equal the
--         caller (no impersonation).
-- UPDATE: the sender only — to edit body OR soft-delete. The XOR check
--         on (edited_at, deleted_at) prevents a single statement from
--         setting both, which would conflate "edited" with "deleted"
--         in the audit trail.
-- DELETE: no policy. Hard delete is denied. Soft-delete via UPDATE
--         is the only path; cascade-delete (chat or profile) is the
--         only way to remove a row.
-- =============================================================================
create policy "messages_read_for_members"
  on public.messages for select
  using (public.is_chat_member(chat_id));

create policy "messages_insert_self"
  on public.messages for insert
  to authenticated
  with check (
    sender_id = (select auth.uid())
    and public.is_chat_member(chat_id)
  );

create policy "messages_update_own"
  on public.messages for update
  to authenticated
  using (sender_id = (select auth.uid()))
  with check (
    sender_id = (select auth.uid())
    and (edited_at is null or deleted_at is null)
  );

-- =============================================================================
-- bump_chat_last_message_at — keep the inbox in sync
-- =============================================================================
-- An AFTER INSERT trigger on messages that updates chats.last_message_at
-- so the chat list can sort by recency without a per-row aggregate.
-- =============================================================================
create or replace function public.bump_chat_last_message_at()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
begin
  update public.chats
     set last_message_at = new.created_at,
         updated_at      = new.created_at
   where chat_id = new.chat_id;
  return new;
end;
$$;

create trigger messages_after_insert_bump_chat
  after insert on public.messages
  for each row execute function public.bump_chat_last_message_at();

-- =============================================================================
-- Realtime — two channels per inserted message
-- =============================================================================
-- 1. `chat:<chat_id>:messages` — the hot stream. ONE publish per insert;
--    every member currently subscribed to this chat's screen receives
--    the new message in their existing socket.
--
-- 2. `user:<member_id>:notifications` — the per-member ping. One small
--    publish for each OTHER active member of the chat so their chat
--    list can update unread badges without polling. The body is capped
--    at 160 chars for the preview; the chat screen reads the full body
--    from channel #1.
--
-- Both publishes run in the same transaction as the INSERT so a reader
-- doing an immediate refetch always sees the row that triggered the
-- broadcast.
--
-- COST SHAPE
-- ----------
-- The hot stream is O(1) per insert regardless of chat size; only
-- subscribers pay. The per-member ping is O(N members) per insert with
-- a tiny payload — acceptable for v1 chat sizes.
-- =============================================================================
create or replace function public.broadcast_new_message()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_member_id uuid;
  v_payload   jsonb;
  v_preview   text;
begin
  -- Hot-stream payload — shape mirrors the chat screen's renderer.
  v_payload := jsonb_build_object(
    'message_id', new.message_id,
    'chat_id',    new.chat_id,
    'sender_id',  new.sender_id,
    'body',       new.body,
    'created_at', new.created_at
  );

  perform realtime.send(
    v_payload,
    'new_message',
    'chat:' || new.chat_id::text || ':messages',
    true
  );

  -- Per-member ping for chat-list badge + unread updates.
  v_preview := left(new.body, 160);

  for v_member_id in
    select user_id
      from public.chat_members
     where chat_id   = new.chat_id
       and user_id   is not null
       and user_id   is distinct from new.sender_id
       and left_at   is null
  loop
    perform realtime.send(
      jsonb_build_object(
        'chat_id',      new.chat_id,
        'message_id',   new.message_id,
        'sender_id',    new.sender_id,
        'body_preview', v_preview,
        'created_at',   new.created_at
      ),
      'chat_updated',
      'user:' || v_member_id::text || ':notifications',
      true
    );
  end loop;

  return null;
end;
$$;

revoke all on function public.broadcast_new_message() from public;

create trigger messages_after_insert_broadcast
  after insert on public.messages
  for each row execute function public.broadcast_new_message();

-- =============================================================================
-- Push fan-out for chat messages (FCM/APNs via the send-push Edge Function)
-- =============================================================================
-- This is the BACKGROUND delivery path. While the recipient is
-- foregrounded, the broadcast above handles in-app rendering and FCM
-- silences the OS banner. While the recipient is backgrounded, the
-- Edge Function reads device_tokens (0900) and pushes the body to
-- every device they're signed in on.
--
-- Depends on `vault.decrypted_secrets` carrying supabase_url and
-- service_role_key. See 0900 device_tokens for the bootstrap notes.
--
-- Failure shape: any error in pg_net is caught and demoted to a warning.
-- A failed push must not abort the message insert; the in-app
-- broadcast above already covers the foreground case.
-- =============================================================================
create or replace function public.invoke_send_push_message()
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
      '[invoke_send_push_message] vault secrets missing (url_present=%, key_present=%)',
      v_url is not null, v_key is not null;
    return new;
  end if;

  perform net.http_post(
    url     := rtrim(v_url, '/') || '/functions/v1/send-push',
    headers := jsonb_build_object(
      'content-type',  'application/json',
      'authorization', 'Bearer ' || v_key
    ),
    body    := jsonb_build_object('message_id', new.message_id)
  );
  return new;
exception
  when others then
    raise warning '[invoke_send_push_message] failed for message_id=%: %',
      new.message_id, sqlerrm;
    return new;
end;
$$;

create trigger messages_invoke_send_push
  after insert on public.messages
  for each row execute function public.invoke_send_push_message();
