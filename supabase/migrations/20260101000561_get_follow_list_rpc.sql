-- Migration file: 20260101000561_get_follow_list_rpc.sql

-- 0561 · get_follow_list RPC
-- High-performance database RPC that returns a user's followers or following
-- with the caller's relationship flags (you_follow, they_follow_you).

-- Section: Functions

create or replace function public.get_follow_list(
  p_user_id uuid,
  p_direction text,
  p_limit int default 100,
  p_offset int default 0
)
  returns table(
    user_id uuid,
    display_name text,
    username text,
    avatar_url text,
    you_follow boolean,
    they_follow_you boolean)
  language plpgsql
  security definer
  set search_path = public,
  pg_temp
  as $$
declare
  v_actor uuid := auth.uid();
begin
  if p_direction = 'followers' then
    return query
    select
      f.follower_id as user_id,
      p.display_name,
      p.username,
      p.profile_photo_url as avatar_url,
      case when v_actor is not null then
        exists (
          select
            1
          from
            public.follows
          where
            follower_id = v_actor
            and target_type = 'user'
            and target_id = f.follower_id)
      else
        false
      end as you_follow,
      case when v_actor is not null then
        exists (
          select
            1
          from
            public.follows
          where
            follower_id = f.follower_id
            and target_type = 'user'
            and target_id = v_actor)
      else
        false
      end as they_follow_you
    from
      public.follows f
      join public.profiles p on p.user_id = f.follower_id
    where
      f.target_type = 'user'
      and f.target_id = p_user_id
    order by
      f.created_at desc
    limit coalesce(p_limit, 100)
    offset coalesce(p_offset, 0);
  else
    return query
    select
      f.target_id as user_id,
      p.display_name,
      p.username,
      p.profile_photo_url as avatar_url,
      case when v_actor is not null then
        exists (
          select
            1
          from
            public.follows
          where
            follower_id = v_actor
            and target_type = 'user'
            and target_id = f.target_id)
      else
        false
      end as you_follow,
      case when v_actor is not null then
        exists (
          select
            1
          from
            public.follows
          where
            follower_id = f.target_id
            and target_type = 'user'
            and target_id = v_actor)
      else
        false
      end as they_follow_you
    from
      public.follows f
      join public.profiles p on p.user_id = f.target_id
    where
      f.follower_id = p_user_id
      and f.target_type = 'user'
    order by
      f.created_at desc
    limit coalesce(p_limit, 100)
    offset coalesce(p_offset, 0);
  end if;
end;
$$;

grant execute on function public.get_follow_list(uuid, text, int, int) to authenticated, anon;
