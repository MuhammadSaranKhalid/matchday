-- =============================================================================
-- Migration: 20260926180000_comments_cqrs_and_viewer_bookmarked_at.sql
-- =============================================================================
--
-- 1. Updates private.build_post_projections to include 'bookmarked_at' in viewer object.
-- 2. Creates public.set_comment_like desired-state RPC with can_view_post check.
-- 3. Creates public.get_post_comments keyset-paginated read projection.
-- 4. Creates public.get_comment_replies keyset-paginated read projection.
-- =============================================================================

-- 1. Update private.build_post_projections to return bookmarked_at in viewer
create or replace function private.build_post_projections(
  p_post_ids uuid[],
  p_viewer_id uuid default auth.uid()
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_result jsonb;
begin
  if p_post_ids is null or array_length(p_post_ids, 1) is null then
    return '[]'::jsonb;
  end if;

  with ordered_ids as (
    select id, ord
    from unnest(p_post_ids) with ordinality as t(id, ord)
  ),
  post_rows as (
    select
      p.post_id,
      p.created_by_user_id,
      p.publisher_type,
      p.publisher_id,
      p.post_kind,
      p.text,
      p.expected_media_count,
      p.likes_count,
      p.comments_count,
      p.shares_count,
      p.created_at,
      p.published_at,
      p.status,
      p.linked_match_id,
      p.linked_tournament_id,
      p.linked_team_id
    from public.posts p
    where p.post_id = any(p_post_ids)
  ),
  creator_profiles as (
    select
      p.user_id,
      p.display_name,
      p.username,
      p.profile_photo_url
    from public.profiles p
    where p.user_id in (select created_by_user_id from post_rows)
  ),
  team_publishers as (
    select
      t.team_id,
      t.team_name as display_name,
      t.logo_url
    from public.teams t
    where t.team_id in (
      select publisher_id from post_rows where publisher_type = 'team'
    )
  ),
  tournament_publishers as (
    select
      tr.tournament_id,
      tr.tournament_name as display_name,
      tr.logo_url
    from public.tournaments tr
    where tr.tournament_id in (
      select publisher_id from post_rows where publisher_type = 'tournament'
    )
  ),
  post_media_agg as (
    select
      pm.post_id,
      jsonb_agg(
        jsonb_build_object(
          'media_id', pm.media_id,
          'media_type', pm.media_type,
          'position', pm.position,
          'status', pm.status,
          'variants', pm.variants,
          'blurhash', pm.blurhash,
          'width', coalesce(pm.display_width, pm.source_width, 1080),
          'height', coalesce(pm.display_height, pm.source_height, 1080)
        ) order by pm.position
      ) as media
    from public.post_media pm
    where pm.post_id = any(p_post_ids)
    group by pm.post_id
  )
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'post_id', p.post_id,
      'created_by_user_id', p.created_by_user_id,
      'publisher', case
        when p.publisher_type = 'team' then jsonb_build_object(
          'type', 'team',
          'id', p.publisher_id,
          'display_name', coalesce(tp.display_name, 'Team'),
          'name', coalesce(tp.display_name, 'Team'),
          'photo_url', tp.logo_url
        )
        when p.publisher_type = 'tournament' then jsonb_build_object(
          'type', 'tournament',
          'id', p.publisher_id,
          'display_name', coalesce(trp.display_name, 'Tournament'),
          'name', coalesce(trp.display_name, 'Tournament'),
          'photo_url', trp.logo_url
        )
        else jsonb_build_object(
          'type', 'user',
          'id', p.publisher_id,
          'display_name', coalesce(cp.display_name, 'User'),
          'name', coalesce(cp.display_name, 'User'),
          'username', cp.username,
          'photo_url', cp.profile_photo_url
        )
      end,
      'post_kind', p.post_kind,
      'text', p.text,
      'media', coalesce(pma.media, '[]'::jsonb),
      'counts', jsonb_build_object(
        'likes', p.likes_count,
        'comments', p.comments_count,
        'shares', p.shares_count
      ),
      'viewer', jsonb_build_object(
        'is_liked', (vl.post_id is not null),
        'is_bookmarked', (vb.bookmarked_at is not null),
        'is_following_publisher', coalesce(vf.is_following, false),
        'bookmarked_at', vb.bookmarked_at
      ),
      'published_at', coalesce(p.published_at, p.created_at),
      'created_at', p.created_at,
      'linked_match_id', p.linked_match_id,
      'linked_tournament_id', p.linked_tournament_id,
      'linked_team_id', p.linked_team_id
    ) order by o.ord
  ), '[]'::jsonb)
  into v_result
  from ordered_ids o
  join post_rows p on p.post_id = o.id
  left join creator_profiles cp on cp.user_id = p.created_by_user_id
  left join team_publishers tp on tp.team_id = p.publisher_id and p.publisher_type = 'team'
  left join tournament_publishers trp on trp.tournament_id = p.publisher_id and p.publisher_type = 'tournament'
  left join post_media_agg pma on pma.post_id = p.post_id
  left join lateral (
    select 1 as post_id from public.post_likes l
    where l.post_id = p.post_id and l.user_id = p_viewer_id
  ) vl on true
  left join lateral (
    select b.created_at as bookmarked_at from public.bookmarks b
    where b.post_id = p.post_id and b.user_id = p_viewer_id
  ) vb on true
  left join lateral (
    select exists (
      select 1 from public.follows f
      where f.follower_id = p_viewer_id
        and f.status = 'active'
        and f.target_id = p.publisher_id
        and f.target_type::text = p.publisher_type::text
    ) as is_following
  ) vf on true;

  return v_result;
end;
$$;

revoke all on function private.build_post_projections from public;
grant execute on function private.build_post_projections to authenticated, anon;


-- 2. Desired-state Comment Likes RPC
create or replace function public.set_comment_like(
  p_comment_id uuid,
  p_liked boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_post_id uuid;
  v_likes_count integer;
  v_is_liked boolean;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select post_id into v_post_id
  from public.comments
  where comment_id = p_comment_id and status = 'active';

  if v_post_id is null then
    raise exception 'Comment not found or not active';
  end if;

  if not public.can_view_post(v_post_id, v_user_id) then
    raise exception 'Cannot interact with this post';
  end if;

  if p_liked then
    insert into public.comment_likes (comment_id, user_id)
    values (p_comment_id, v_user_id)
    on conflict (comment_id, user_id) do nothing;
    v_is_liked := true;
  else
    delete from public.comment_likes
    where comment_id = p_comment_id and user_id = v_user_id;
    v_is_liked := false;
  end if;

  select likes_count into v_likes_count
  from public.comments
  where comment_id = p_comment_id;

  return jsonb_build_object(
    'comment_id', p_comment_id,
    'is_liked', v_is_liked,
    'likes_count', coalesce(v_likes_count, 0)
  );
end;
$$;

revoke all on function public.set_comment_like from public;
grant execute on function public.set_comment_like to authenticated;


-- 3. Keyset-paginated Top-Level Comments Read Projection
create or replace function public.get_post_comments(
  p_post_id uuid,
  p_cursor_created_at timestamptz default null,
  p_cursor_comment_id uuid default null,
  p_limit integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_viewer_id uuid := auth.uid();
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
  v_result jsonb;
begin
  if not public.can_view_post(p_post_id, v_viewer_id) then
    return '[]'::jsonb;
  end if;

  select coalesce(jsonb_agg(c_row), '[]'::jsonb)
  into v_result
  from (
    select
      c.comment_id,
      c.post_id,
      c.author_id,
      c.parent_comment_id,
      c.text,
      c.mentioned_user_ids,
      c.likes_count,
      c.status,
      c.created_at,
      c.edited_at,
      jsonb_build_object(
        'display_name', p.display_name,
        'username', p.username,
        'profile_photo_url', p.profile_photo_url
      ) as author,
      (
        select count(*)::int
        from public.comments r
        where r.parent_comment_id = c.comment_id
          and r.status = 'active'
      ) as replies_count,
      (
        v_viewer_id is not null and exists (
          select 1 from public.comment_likes cl
          where cl.comment_id = c.comment_id and cl.user_id = v_viewer_id
        )
      ) as is_liked
    from public.comments c
    join public.profiles p on p.user_id = c.author_id
    where c.post_id = p_post_id
      and c.parent_comment_id is null
      and c.status = 'active'
      and (
        p_cursor_created_at is null
        or p_cursor_comment_id is null
        or (c.created_at, c.comment_id) < (p_cursor_created_at, p_cursor_comment_id)
      )
    order by c.created_at desc, c.comment_id desc
    limit v_limit
  ) c_row;

  return v_result;
end;
$$;

revoke all on function public.get_post_comments from public;
grant execute on function public.get_post_comments to anon, authenticated;


-- 4. Keyset-paginated Comment Replies Read Projection
create or replace function public.get_comment_replies(
  p_parent_comment_id uuid,
  p_cursor_created_at timestamptz default null,
  p_cursor_comment_id uuid default null,
  p_limit integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_viewer_id uuid := auth.uid();
  v_post_id uuid;
  v_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
  v_result jsonb;
begin
  select post_id into v_post_id
  from public.comments
  where comment_id = p_parent_comment_id and status = 'active';

  if v_post_id is null or not public.can_view_post(v_post_id, v_viewer_id) then
    return '[]'::jsonb;
  end if;

  select coalesce(jsonb_agg(r_row), '[]'::jsonb)
  into v_result
  from (
    select
      c.comment_id,
      c.post_id,
      c.author_id,
      c.parent_comment_id,
      c.text,
      c.mentioned_user_ids,
      c.likes_count,
      c.status,
      c.created_at,
      c.edited_at,
      jsonb_build_object(
        'display_name', p.display_name,
        'username', p.username,
        'profile_photo_url', p.profile_photo_url
      ) as author,
      0 as replies_count,
      (
        v_viewer_id is not null and exists (
          select 1 from public.comment_likes cl
          where cl.comment_id = c.comment_id and cl.user_id = v_viewer_id
        )
      ) as is_liked
    from public.comments c
    join public.profiles p on p.user_id = c.author_id
    where c.parent_comment_id = p_parent_comment_id
      and c.status = 'active'
      and (
        p_cursor_created_at is null
        or p_cursor_comment_id is null
        or (c.created_at, c.comment_id) > (p_cursor_created_at, p_cursor_comment_id)
      )
    order by c.created_at asc, c.comment_id asc
    limit v_limit
  ) r_row;

  return v_result;
end;
$$;

revoke all on function public.get_comment_replies from public;
grant execute on function public.get_comment_replies to anon, authenticated;
