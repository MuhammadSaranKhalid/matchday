-- =============================================================================
-- Migration: 20260926185000_fix_build_post_projections_media_dimensions.sql
-- =============================================================================
-- Fixes column references in private.build_post_projections:
-- post_media table columns are display_width/source_width and display_height/source_height,
-- not width and height.
-- =============================================================================

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
          'post_id', pm.post_id,
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
        and f.target_id = p.publisher_id
        and f.target_type = p.publisher_type::public.follow_target_type
    ) as is_following
  ) vf on true;

  return v_result;
end;
$$;

revoke all on function private.build_post_projections from public;
grant execute on function private.build_post_projections to authenticated, anon;
