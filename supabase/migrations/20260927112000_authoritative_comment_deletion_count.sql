-- Migration: authoritative_comment_deletion_count
-- Description:
--   Updates delete_comment RPC to return authoritative deleted count and remaining post comments count.

drop function if exists public.delete_comment(uuid);

create or replace function public.delete_comment(
  p_comment_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_author_id uuid;
  v_post_creator_id uuid;
  v_post_id uuid;
  v_deleted_count integer;
  v_remaining_count integer;
begin
  if v_user_id is null then
    raise exception 'Unauthorized' using errcode = '401';
  end if;

  select c.author_id, p.created_by_user_id, c.post_id
  into v_author_id, v_post_creator_id, v_post_id
  from public.comments c
  join public.posts p on p.post_id = c.post_id
  where c.comment_id = p_comment_id;

  if not found then
    return jsonb_build_object(
      'deleted', false,
      'deleted_count', 0
    );
  end if;

  if v_user_id <> v_author_id and v_user_id <> v_post_creator_id then
    raise exception 'Forbidden: only comment author or post creator can delete' using errcode = '403';
  end if;

  with recursive descendants as (
    select comment_id from public.comments where comment_id = p_comment_id
    union all
    select c.comment_id from public.comments c
    join descendants d on d.comment_id = c.parent_comment_id
  )
  select count(*) into v_deleted_count from descendants;

  delete from public.comments where comment_id = p_comment_id;

  select count(*) into v_remaining_count from public.comments where post_id = v_post_id;

  -- Ensure posts table count is synchronized
  update public.posts
  set comments_count = v_remaining_count
  where post_id = v_post_id;

  return jsonb_build_object(
    'deleted', true,
    'post_id', v_post_id,
    'deleted_count', v_deleted_count,
    'comments_count', v_remaining_count
  );
end;
$$;

revoke all on function public.delete_comment(uuid) from public, anon;
grant execute on function public.delete_comment(uuid) to authenticated;
