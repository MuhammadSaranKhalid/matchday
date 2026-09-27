-- =============================================================================
-- Migration: 20260927101500_harden_comments_security_and_can_view_post.sql
-- Description:
--   1. Harden public.can_view_post to explicitly evaluate post visibility (public vs private/followers).
--   2. Introduce security definer command RPCs for comments:
--      - public.create_comment(p_post_id, p_text, p_parent_comment_id, p_mentioned_user_ids)
--      - public.delete_comment(p_comment_id)
--      Both strictly enforce can_view_post and actor ownership.
--   3. Revoke direct INSERT, UPDATE, DELETE on public.comments from authenticated and anon.
-- =============================================================================

-- 1. Canonical can_view_post predicate evaluating status, moderation/blocks, AND visibility
create or replace function public.can_view_post(
  p_post_id uuid,
  p_viewer_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.posts p
    where p.post_id = p_post_id
      and (
        p.status = 'active'
        or (p_viewer_id is not null and p.created_by_user_id = p_viewer_id)
      )
      and (
        p_viewer_id is null
        or not exists (
          select 1 from public.user_blocks ub
          where (ub.blocker_id = p_viewer_id and ub.blocked_id = p.created_by_user_id)
             or (ub.blocker_id = p.created_by_user_id and ub.blocked_id = p_viewer_id)
        )
      )
      and (
        p.visibility = 'public'
        or (p_viewer_id is not null and p.created_by_user_id = p_viewer_id)
      )
  );
$$;

revoke all on function public.can_view_post(uuid, uuid) from public;
grant execute on function public.can_view_post(uuid, uuid) to anon, authenticated;

-- 2. Command RPC: create_comment
create or replace function public.create_comment(
  p_post_id uuid,
  p_text text,
  p_parent_comment_id uuid default null,
  p_mentioned_user_ids uuid[] default '{}'::uuid[]
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_comment_id uuid;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'Unauthorized' using errcode = '401';
  end if;

  if not public.can_view_post(p_post_id, v_user_id) then
    raise exception 'Forbidden: cannot view or comment on this post' using errcode = '403';
  end if;

  if p_text is null or length(trim(p_text)) = 0 or length(p_text) > 500 then
    raise exception 'Comment text must be between 1 and 500 characters' using errcode = '22000';
  end if;

  insert into public.comments (
    post_id,
    author_id,
    parent_comment_id,
    text,
    mentioned_user_ids,
    status
  )
  values (
    p_post_id,
    v_user_id,
    p_parent_comment_id,
    trim(p_text),
    coalesce(p_mentioned_user_ids, '{}'::uuid[]),
    'active'
  )
  returning comment_id into v_comment_id;

  select jsonb_build_object(
    'comment_id', c.comment_id,
    'post_id', c.post_id,
    'author_id', c.author_id,
    'parent_comment_id', c.parent_comment_id,
    'text', c.text,
    'mentioned_user_ids', c.mentioned_user_ids,
    'likes_count', c.likes_count,
    'is_liked', false,
    'replies_count', 0,
    'status', c.status,
    'created_at', c.created_at,
    'edited_at', c.edited_at,
    'author', jsonb_build_object(
      'display_name', p.display_name,
      'username', p.username,
      'profile_photo_url', p.profile_photo_url
    )
  )
  into v_result
  from public.comments c
  join public.profiles p on p.user_id = c.author_id
  where c.comment_id = v_comment_id;

  return v_result;
end;
$$;

revoke all on function public.create_comment(uuid, text, uuid, uuid[]) from public;
grant execute on function public.create_comment(uuid, text, uuid, uuid[]) to authenticated;

-- 3. Command RPC: delete_comment
create or replace function public.delete_comment(
  p_comment_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_author_id uuid;
  v_post_creator_id uuid;
begin
  if v_user_id is null then
    raise exception 'Unauthorized' using errcode = '401';
  end if;

  select c.author_id, p.created_by_user_id
  into v_author_id, v_post_creator_id
  from public.comments c
  join public.posts p on p.post_id = c.post_id
  where c.comment_id = p_comment_id;

  if not found then
    return; -- Idempotent if already deleted
  end if;

  if v_user_id <> v_author_id and v_user_id <> v_post_creator_id then
    raise exception 'Forbidden: only comment author or post creator can delete' using errcode = '403';
  end if;

  delete from public.comments where comment_id = p_comment_id;
end;
$$;

revoke all on function public.delete_comment(uuid) from public;
grant execute on function public.delete_comment(uuid) to authenticated;

-- 4. Revoke direct table mutations on public.comments
drop policy if exists "comments_insert_self" on public.comments;
drop policy if exists "comments_update_self" on public.comments;
drop policy if exists "comments_delete_self_or_post_author" on public.comments;

revoke insert, update, delete on table public.comments from authenticated, anon;
