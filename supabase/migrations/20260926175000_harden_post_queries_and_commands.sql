-- Harden Post Queries and Commands
--
-- 1. Centralized can_view_post predicate for authorization consistency across queries & commands.
-- 2. Include linked_match_id, linked_tournament_id, linked_team_id in private.build_post_projections.
-- 3. Fix get_profile_posts publisher scoping (publisher_type = p_publisher_type and publisher_id = p_publisher_id).
-- 4. Implement real filtering in get_home_feed for p_filter ('people', 'teams', 'tournaments', 'matches').
-- 5. Enforce can_view_post in set_post_like and set_post_bookmark.
-- 6. Add delete_post(p_post_id) RPC and revoke direct UPDATE/DELETE on posts & post_media from authenticated.
-- 7. Enforce public visibility in begin_post_publish.

-- 1. Canonical can_view_post predicate
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
  );
$$;

revoke all on function public.can_view_post(uuid, uuid) from public;
grant execute on function public.can_view_post(uuid, uuid) to anon, authenticated;

-- 2. Update private.build_post_projections to emit linked entity IDs
create or replace function private.build_post_projections(
  p_post_ids uuid[],
  p_viewer_id uuid default auth.uid()
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_results jsonb;
begin
  if p_post_ids is null or array_length(p_post_ids, 1) is null then
    return '[]'::jsonb;
  end if;

  with target_posts as (
    select
      p.post_id,
      p.created_by_user_id,
      p.publisher_type,
      p.publisher_id,
      p.post_kind,
      p.text,
      p.visibility,
      p.status,
      p.expected_media_count,
      p.likes_count,
      p.comments_count,
      p.shares_count,
      p.published_at,
      p.created_at,
      p.linked_match_id,
      p.linked_tournament_id,
      p.linked_team_id
    from public.posts p
    where p.post_id = any(p_post_ids)
  ),
  posts_with_media as (
    select
      tp.*,
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'media_id', pm.media_id,
              'position', pm.position,
              'width', coalesce(pm.display_width, pm.source_width, 1080),
              'height', coalesce(pm.display_height, pm.source_height, 1080),
              'blurhash', pm.blurhash,
              'status', pm.status,
              'variants', pm.variants
            )
            order by pm.position
          )
          from public.post_media pm
          where pm.post_id = tp.post_id
        ),
        '[]'::jsonb
      ) as media_list
    from target_posts tp
  ),
  enriched as (
    select
      pwm.*,
      case pwm.publisher_type
        when 'team' then (
          select jsonb_build_object(
            'type', 'team',
            'id', t.team_id,
            'display_name', t.team_name,
            'username', null,
            'photo_url', t.logo_url
          )
          from public.teams t
          where t.team_id = pwm.publisher_id
        )
        when 'tournament' then (
          select jsonb_build_object(
            'type', 'tournament',
            'id', tr.tournament_id,
            'display_name', tr.tournament_name,
            'username', null,
            'photo_url', tr.logo_url
          )
          from public.tournaments tr
          where tr.tournament_id = pwm.publisher_id
        )
        else (
          select jsonb_build_object(
            'type', 'user',
            'id', pr.user_id,
            'display_name', pr.display_name,
            'username', pr.username,
            'photo_url', pr.profile_photo_url
          )
          from public.profiles pr
          where pr.user_id = pwm.created_by_user_id
        )
      end as publisher_info,
      (
        select jsonb_build_object(
          'type', 'user',
          'id', pr.user_id,
          'display_name', pr.display_name,
          'username', pr.username,
          'photo_url', pr.profile_photo_url
        )
        from public.profiles pr
        where pr.user_id = pwm.created_by_user_id
      ) as author_info,
      case
        when p_viewer_id is null then false
        else exists (
          select 1 from public.post_likes pl
          where pl.post_id = pwm.post_id and pl.user_id = p_viewer_id
        )
      end as viewer_liked,
      case
        when p_viewer_id is null then false
        else exists (
          select 1 from public.bookmarks bm
          where bm.post_id = pwm.post_id and bm.user_id = p_viewer_id
        )
      end as viewer_bookmarked,
      case
        when p_viewer_id is null or p_viewer_id = pwm.created_by_user_id then false
        else exists (
          select 1 from public.follows fl
          where fl.follower_id = p_viewer_id
            and fl.status = 'active'
            and fl.target_type::text = pwm.publisher_type::text
            and fl.target_id = pwm.publisher_id
        )
      end as viewer_following
    from posts_with_media pwm
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'post_id', e.post_id,
        'created_by_user_id', e.created_by_user_id,
        'publisher', e.publisher_info,
        'author', e.author_info,
        'post_kind', e.post_kind,
        'text', e.text,
        'visibility', e.visibility,
        'status', e.status,
        'expected_media_count', e.expected_media_count,
        'media', e.media_list,
        'counts', jsonb_build_object(
          'likes', e.likes_count,
          'comments', e.comments_count,
          'shares', e.shares_count
        ),
        'viewer', jsonb_build_object(
          'liked', e.viewer_liked,
          'bookmarked', e.viewer_bookmarked,
          'following_publisher', e.viewer_following
        ),
        'published_at', e.published_at,
        'created_at', e.created_at,
        'linked_match_id', e.linked_match_id,
        'linked_tournament_id', e.linked_tournament_id,
        'linked_team_id', e.linked_team_id
      )
      order by array_position(p_post_ids, e.post_id)
    ),
    '[]'::jsonb
  ) into v_results
  from enriched e;

  return v_results;
end;
$$;

-- 3. Update get_profile_posts: publisher_type = p_publisher_type and publisher_id = p_publisher_id
create or replace function public.get_profile_posts(
  p_publisher_id uuid,
  p_publisher_type public.post_publisher_type default 'user',
  p_cursor_published_at timestamptz default null,
  p_cursor_post_id uuid default null,
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
  v_post_ids uuid[];
begin
  select array_agg(p.post_id)
  into v_post_ids
  from (
    select p.post_id
    from public.posts p
    where p.status = 'active'
      and p.publisher_type = p_publisher_type
      and p.publisher_id = p_publisher_id
      and (
        v_viewer_id is null
        or not exists (
          select 1 from public.user_blocks ub
          where (ub.blocker_id = v_viewer_id and ub.blocked_id = p.created_by_user_id)
             or (ub.blocker_id = p.created_by_user_id and ub.blocked_id = v_viewer_id)
        )
      )
      and (
        p_cursor_published_at is null
        or p_cursor_post_id is null
        or (p.published_at, p.post_id) < (p_cursor_published_at, p_cursor_post_id)
      )
    order by p.published_at desc, p.post_id desc
    limit v_limit
  ) p;

  return private.build_post_projections(v_post_ids, v_viewer_id);
end;
$$;

-- 4. Update get_home_feed: real filtering logic
create or replace function public.get_home_feed(
  p_mode text default 'home',
  p_filter text default 'all',
  p_target_id uuid default null,
  p_cursor_published_at timestamptz default null,
  p_cursor_post_id uuid default null,
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
  v_post_ids uuid[];
begin
  -- Compatibility branching for legacy callers passing p_mode
  if p_mode = 'saved' then
    return public.get_saved_posts(p_cursor_published_at, p_cursor_post_id, v_limit);
  elsif p_mode in ('user', 'team', 'tournament') and p_target_id is not null then
    return public.get_profile_posts(
      p_target_id,
      p_mode::public.post_publisher_type,
      p_cursor_published_at,
      p_cursor_post_id,
      v_limit
    );
  end if;

  select array_agg(p.post_id)
  into v_post_ids
  from (
    select p.post_id
    from public.posts p
    where p.status = 'active'
      and (
        p_mode = 'home'
        or (
          p_mode = 'following'
          and v_viewer_id is not null
          and (
            p.created_by_user_id = v_viewer_id
            or exists (
              select 1
              from public.follows f
              where f.follower_id = v_viewer_id
                and f.status = 'active'
                and (
                  (f.target_type = 'user' and f.target_id = p.created_by_user_id)
                  or (f.target_type = 'team' and f.target_id = p.publisher_id)
                  or (f.target_type = 'tournament' and f.target_id = p.publisher_id)
                )
            )
          )
        )
      )
      and (
        p_filter is null
        or p_filter in ('all', '')
        or (p_filter in ('people', 'user', 'users') and p.publisher_type = 'user')
        or (p_filter in ('teams', 'team') and p.publisher_type = 'team')
        or (p_filter in ('tournaments', 'tournament') and p.publisher_type = 'tournament')
        or (p_filter in ('matches', 'match') and (p.linked_match_id is not null or p.post_kind in ('match_announcement', 'match_result')))
      )
      and (
        v_viewer_id is null
        or not exists (
          select 1 from public.user_blocks ub
          where (ub.blocker_id = v_viewer_id and ub.blocked_id = p.created_by_user_id)
             or (ub.blocker_id = p.created_by_user_id and ub.blocked_id = v_viewer_id)
        )
      )
      and (
        p_cursor_published_at is null
        or p_cursor_post_id is null
        or (p.published_at, p.post_id) < (p_cursor_published_at, p_cursor_post_id)
      )
    order by p.published_at desc, p.post_id desc
    limit v_limit
  ) p;

  return private.build_post_projections(v_post_ids, v_viewer_id);
end;
$$;

-- 5. set_post_like and set_post_bookmark: target authorization via can_view_post
create or replace function public.set_post_like(
  p_post_id uuid,
  p_liked boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_current_count integer;
begin
  if v_user_id is null then
    raise exception 'Unauthenticated' using errcode = '401';
  end if;

  if not public.can_view_post(p_post_id, v_user_id) then
    raise exception 'Post not found or interaction not permitted' using errcode = '404';
  end if;

  if p_liked then
    insert into public.post_likes (post_id, user_id)
    values (p_post_id, v_user_id)
    on conflict (post_id, user_id) do nothing;
  else
    delete from public.post_likes
    where post_id = p_post_id and user_id = v_user_id;
  end if;

  select likes_count into v_current_count
  from public.posts
  where post_id = p_post_id;

  return jsonb_build_object(
    'post_id', p_post_id,
    'liked', p_liked,
    'likes_count', coalesce(v_current_count, 0)
  );
end;
$$;

create or replace function public.set_post_bookmark(
  p_post_id uuid,
  p_bookmarked boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Unauthenticated' using errcode = '401';
  end if;

  if not public.can_view_post(p_post_id, v_user_id) then
    raise exception 'Post not found or interaction not permitted' using errcode = '404';
  end if;

  if p_bookmarked then
    insert into public.bookmarks (post_id, user_id)
    values (p_post_id, v_user_id)
    on conflict (user_id, post_id) do nothing;
  else
    delete from public.bookmarks
    where post_id = p_post_id and user_id = v_user_id;
  end if;

  return jsonb_build_object(
    'post_id', p_post_id,
    'bookmarked', p_bookmarked
  );
end;
$$;

-- 6. Command RPC: delete_post
create or replace function public.delete_post(
  p_post_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_post record;
begin
  if v_uid is null then
    raise exception 'Unauthenticated' using errcode = '401';
  end if;

  select post_id, created_by_user_id, publisher_type, publisher_id
  into v_post
  from public.posts
  where post_id = p_post_id;

  if not found then
    return false;
  end if;

  if v_post.created_by_user_id <> v_uid 
     and not public.can_publish_as(v_post.publisher_type, v_post.publisher_id, v_uid) then
    raise exception 'Unauthorized to delete post' using errcode = '403';
  end if;

  update public.posts
  set status = 'deleted',
      updated_at = now()
  where post_id = p_post_id;

  return true;
end;
$$;

revoke all on function public.delete_post(uuid) from public;
grant execute on function public.delete_post(uuid) to authenticated;

-- 7. Enforce public visibility in begin_post_publish until private storage + access control are implemented
create or replace function public.begin_post_publish(
  p_publisher_type public.post_publisher_type,
  p_publisher_id uuid,
  p_post_kind public.post_kind,
  p_text text,
  p_expected_media_count integer default 0,
  p_visibility public.post_visibility default 'public',
  p_idempotency_key text default null,
  p_media_manifest jsonb default '[]'::jsonb,
  p_linked_match_id uuid default null,
  p_linked_tournament_id uuid default null,
  p_linked_team_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_post_id uuid;
  v_existing_post record;
  v_item jsonb;
  v_pos integer;
  v_media_id uuid;
  v_staging_path text;
  v_media_result jsonb := '[]'::jsonb;
begin
  if v_user_id is null then
    raise exception 'Unauthenticated' using errcode = '401';
  end if;

  -- Enforce public visibility constraint
  if p_visibility is distinct from 'public' then
    raise exception 'Only public posts are supported currently' using errcode = '400';
  end if;

  if not public.can_publish_as(p_publisher_type, p_publisher_id, v_user_id) then
    raise exception 'Unauthorized publisher' using errcode = '403';
  end if;

  if p_idempotency_key is not null then
    select post_id, status into v_existing_post
    from public.posts
    where idempotency_key = p_idempotency_key
      and created_by_user_id = v_user_id
    limit 1;

    if found then
      select coalesce(
        jsonb_agg(
          jsonb_build_object(
            'media_id', pm.media_id,
            'position', pm.position,
            'staging_path', pm.staging_path,
            'status', pm.status
          )
          order by pm.position
        ),
        '[]'::jsonb
      ) into v_media_result
      from public.post_media pm
      where pm.post_id = v_existing_post.post_id;

      return jsonb_build_object(
        'post_id', v_existing_post.post_id,
        'status', v_existing_post.status,
        'idempotent', true,
        'media', v_media_result
      );
    end if;
  end if;

  insert into public.posts (
    created_by_user_id,
    author_id,
    publisher_type,
    publisher_id,
    post_kind,
    text,
    visibility,
    status,
    expected_media_count,
    idempotency_key,
    linked_match_id,
    linked_tournament_id,
    linked_team_id,
    published_at
  )
  values (
    v_user_id,
    v_user_id,
    p_publisher_type,
    p_publisher_id,
    p_post_kind,
    p_text,
    p_visibility,
    case when coalesce(p_expected_media_count, 0) = 0 then 'active'::public.post_status else 'publishing'::public.post_status end,
    coalesce(p_expected_media_count, 0),
    p_idempotency_key,
    p_linked_match_id,
    p_linked_tournament_id,
    p_linked_team_id,
    case when coalesce(p_expected_media_count, 0) = 0 then now() else null end
  )
  returning post_id into v_post_id;

  v_pos := 0;
  for v_item in select * from jsonb_array_elements(coalesce(p_media_manifest, '[]'::jsonb)) loop
    v_media_id := coalesce((v_item->>'media_id')::uuid, gen_random_uuid());
    v_staging_path := format('staging/%s/%s/source.jpg', v_post_id, v_media_id);

    insert into public.post_media (
      media_id,
      post_id,
      position,
      staging_path,
      status,
      source_width,
      source_height,
      source_bytes,
      source_mime
    )
    values (
      v_media_id,
      v_post_id,
      v_pos,
      v_staging_path,
      'awaiting_upload',
      (v_item->>'width')::integer,
      (v_item->>'height')::integer,
      (v_item->>'bytes')::bigint,
      coalesce(v_item->>'mime', 'image/jpeg')
    );

    v_media_result := v_media_result || jsonb_build_array(
      jsonb_build_object(
        'media_id', v_media_id,
        'position', v_pos,
        'staging_path', v_staging_path,
        'status', 'awaiting_upload'
      )
    );
    v_pos := v_pos + 1;
  end loop;

  return jsonb_build_object(
    'post_id', v_post_id,
    'status', case when coalesce(p_expected_media_count, 0) = 0 then 'active' else 'publishing' end,
    'idempotent', false,
    'media', v_media_result
  );
end;
$$;

-- 8. Restrict direct client table mutations on posts and post_media:
-- Direct INSERT/UPDATE/DELETE should go through RPCs (begin_post_publish, delete_post, mark_post_media_uploaded, abandon_post_publish)
drop policy if exists "posts_update_authorized_publisher" on public.posts;
drop policy if exists "posts_delete_creator" on public.posts;
drop policy if exists "post_media_creator_all" on public.post_media;
drop policy if exists "post_media_insert_creator" on public.post_media;
drop policy if exists "post_media_update_creator" on public.post_media;
drop policy if exists "post_media_delete_creator" on public.post_media;

-- Allow only read on post_media for users; writes happen strictly through service_role or RPCs
create policy "post_media_read"
  on public.post_media
  for select
  to anon, authenticated
  using (true);
