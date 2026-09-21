-- =============================================================================
-- Migration: 20260101000520_comments.sql
-- =============================================================================

-- 0520 · comments
-- Spec §6.8, §6.18, §8.2.6.
--
-- Single-level threading:
--   A comment is either a top-level comment on the post (parent_comment_id
--   null) OR a reply to a top-level comment (parent_comment_id set). The
--   `enforce_comment_single_level` BEFORE-INSERT/UPDATE trigger forbids a
--   reply-to-a-reply and cross-post replies.
--
-- Counter sync:
--   posts.comments_count is bumped by the AFTER-INSERT/UPDATE/DELETE trigger
--   below. Soft-delete (status flip away from 'active') decrements; restore
--   increments. Hard delete decrements only when the row was active.
--
-- Notification fan-out:
--   Top-level comment → notify post author. Reply → notify parent comment
--   author. Mentions in `mentioned_user_ids` → one notification per
--   @mentioned user (skip self + skip recipient already notified).
--
-- Edited stamp:
--   stamp_comment_edited_at sets edited_at when text or mentions change —
--   counter bumps don't trigger it (the trigger looks only at human-editable
--   columns).

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.comments (
  comment_id         uuid primary key default gen_random_uuid(),
  post_id            uuid not null
    references public.posts (post_id)
    on delete cascade,
  author_id          uuid not null
    references public.profiles (user_id)
    on delete cascade,
  parent_comment_id  uuid
    references public.comments (comment_id)
    on delete cascade,
  text               text not null check (length(text) between 1 and 500),
  mentioned_user_ids uuid[] not null default '{}',
  likes_count        integer not null default 0 check (likes_count >= 0),
  status             public.comment_status not null default 'active',
  created_at         timestamptz not null default now(),
  edited_at          timestamptz,
  updated_at         timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

create index comments_post_created
  on public.comments (post_id, created_at);

create index comments_parent
  on public.comments (parent_comment_id)
  where parent_comment_id is not null;

create index comments_author
  on public.comments (author_id);

create index comments_mentions_gin
  on public.comments using gin (mentioned_user_ids);

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger comments_set_updated_at
  before update on public.comments
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- enforce_comment_single_level — guards the threading invariant.
create or replace function public.enforce_comment_single_level()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_parent_post uuid;
  v_parent_parent uuid;
begin
  if new.parent_comment_id is null then
    return new;
  end if;
  select
    post_id,
    parent_comment_id
  into v_parent_post, v_parent_parent
  from public.comments
  where comment_id = new.parent_comment_id;
  if v_parent_post is null then
    raise exception 'Parent comment % not found', new.parent_comment_id
      using errcode = 'P0002';
  end if;
  if v_parent_post <> new.post_id then
    raise exception 'Reply must belong to the same post as its parent'
      using errcode = '23514';
  end if;
  if v_parent_parent is not null then
    raise exception 'Single-level threading only — cannot reply to a reply'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger comments_enforce_single_level
  before insert or update of parent_comment_id on public.comments
  for each row
  execute function public.enforce_comment_single_level();

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- bump_post_comments_count — keeps posts.comments_count in sync.
-- Soft-delete (status flip) decrements; restore increments.
create or replace function public.bump_post_comments_count()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'INSERT' then
    if new.status = 'active' then
      update
        public.posts
      set
        comments_count = comments_count + 1
      where
        post_id = new.post_id;
    end if;
    return new;
  elsif tg_op = 'UPDATE' then
    if old.status = 'active' and new.status <> 'active' then
      update
        public.posts
      set
        comments_count = greatest(comments_count - 1, 0)
      where
        post_id = new.post_id;
    elsif old.status <> 'active'
        and new.status = 'active' then
        update
          public.posts
        set
          comments_count = comments_count + 1
        where
          post_id = new.post_id;
    end if;
    return new;
  elsif tg_op = 'DELETE' then
    if old.status = 'active' then
      update
        public.posts
      set
        comments_count = greatest(comments_count - 1, 0)
      where
        post_id = old.post_id;
    end if;
    return old;
  end if;
  return null;
end;
$$;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger comments_bump_post_count
  after insert or update of status or delete on public.comments
  for each row
  execute function public.bump_post_comments_count();

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- stamp_comment_edited_at — only watches human-editable columns.
create or replace function public.stamp_comment_edited_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if
    new.text is distinct from old.text
    or new.mentioned_user_ids is distinct from old.mentioned_user_ids
  then
    new.edited_at = now();
  end if;
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger comments_stamp_edited_at
  before update on public.comments
  for each row
  execute function public.stamp_comment_edited_at();

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

-- NOTIFICATION TRIGGER MOVED → 20260101000620_notification_triggers.sql
--
-- notify_on_comment now calls public.notify() (0570), which is declared
-- AFTER this file. A plpgsql body referencing a not-yet-created function
-- compiles but fails at runtime (§12.0), so the trigger follows its dependency
-- — the same remedy the teams UPDATE policies got when they moved to 0210.
-- RLS — visible if parent post visible; insert by self; delete by author or
-- post owner (so the OP can clean up trolls without involving moderation).
alter table public.comments enable row level security;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

create policy "comments_read_if_post_visible"
  on public.comments
  for select
  to anon, authenticated
  using (
    exists (
      select
        1
      from public.posts p
      where
        p.post_id = comments.post_id
        and (
          p.status = 'active'
          or p.author_id = (
            select
              auth.uid()
          )
        )
    )
  );

create policy "comments_insert_self"
  on public.comments
  for insert
  to authenticated
  with check (
    (
      select
        auth.uid()
    ) = author_id
  );

create policy "comments_update_self"
  on public.comments
  for update
  to authenticated
  using (
    (
      select
        auth.uid()
    ) = author_id
  )
  with check (
    (
      select
        auth.uid()
    ) = author_id
  );

create policy "comments_delete_self_or_post_author"
  on public.comments
  for delete
  to authenticated
  using (
    (
      select
        auth.uid()
    ) = author_id
    or public.is_post_author(post_id)
  );

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- Realtime — Broadcast on every comment insert / update / delete.
-- Topic:  post:<post_id>:comments
-- Events:
--   'comment_added'    INSERT       — new comment or reply lands in the thread
--   'comment_updated'  UPDATE       — text/mentions edits, status flips
--                                     (active ↔ deleted ↔ reported), and
--                                     likes_count bumps from comment_likes
--   'comment_deleted'  DELETE       — hard delete (rare; admin/cleanup only)
--
-- A popular post can have hundreds of readers on its detail screen at once.
-- ONE publish reaches all subscribers via Broadcast; the postgres_changes
-- equivalent would have fanned RLS evaluation across every subscriber for
-- every row. The hot stream cost is constant in viewer count.
--
-- Counter sync (likes_count, comments_count) and notifications are unaffected
-- — those triggers (bump_post_comments_count, notify_on_comment, and the
-- comment_likes trigger that bumps likes_count) already fire independently.
-- The broadcast trigger simply pushes the resulting state to subscribers.
-- INSERT — new comment or reply.
create or replace function public.broadcast_new_comment()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform
    realtime.send(
      to_jsonb(new),
      'comment_added',
      'post:' || new.post_id::text || ':comments',
      true
    );
  return null;
end;
$$;

revoke all on function public.broadcast_new_comment() from public;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

drop trigger if exists comments_after_insert_broadcast on public.comments;

create trigger comments_after_insert_broadcast
  after insert on public.comments
  for each row
  execute function public.broadcast_new_comment();

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- UPDATE — edits, status flips, like-count bumps.
-- The WHEN clause keeps updated_at-only bumps (set by the set_updated_at
-- trigger) off the broadcast bus. Without it, every internal touch of a
-- comment row would fan out.
create or replace function public.broadcast_comment_updated()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform
    realtime.send(
      to_jsonb(new),
      'comment_updated',
      'post:' || new.post_id::text || ':comments',
      true
    );
  return null;
end;
$$;

revoke all on function public.broadcast_comment_updated() from public;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

drop trigger if exists comments_after_update_broadcast on public.comments;

create trigger comments_after_update_broadcast
  after update on public.comments
  for each row
  when
    (
      old.text is distinct from new.text
      or old.status is distinct from new.status
      or old.likes_count is distinct from new.likes_count
      or old.mentioned_user_ids is distinct from new.mentioned_user_ids
      or old.edited_at is distinct from new.edited_at
    )
  execute function public.broadcast_comment_updated();

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- DELETE — hard delete (most "delete" actions soft-delete via status flip,
-- which goes through the UPDATE path above; hard delete only happens via
-- admin cleanup or post cascade).
-- Payload is minimal — clients only need (comment_id, post_id) to splice the
-- row out of their local list.
create or replace function public.broadcast_comment_deleted()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform
    realtime.send(
      jsonb_build_object(
        'comment_id',
        old.comment_id,
        'post_id',
        old.post_id,
        'parent_comment_id',
        old.parent_comment_id
      ),
      'comment_deleted',
      'post:' || old.post_id::text || ':comments',
      true
    );
  return null;
end;
$$;

revoke all on function public.broadcast_comment_deleted() from public;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

drop trigger if exists comments_after_delete_broadcast on public.comments;

create trigger comments_after_delete_broadcast
  after delete on public.comments
  for each row
  execute function public.broadcast_comment_deleted();
