-- Migration: unify_post_identity_and_drop_legacy_columns
-- Description:
--   1. Migrates notify_on_team_post to use canonical publisher_type/publisher_id/created_by_user_id.
--   2. Migrates notify_on_post_like and notify_on_comment to use created_by_user_id.
--   3. Migrates is_post_author to check created_by_user_id = auth.uid().
--   4. Migrates my_deletion_objects and delete_user to check created_by_user_id.
--   5. Drops legacy columns from public.posts: author_id, author_context, context_entity_id, post_type.
--   6. Drops legacy can_act_for_post_context function and post_author_context enum.

-- 1. Rewrite notify_on_team_post
create or replace function public.notify_on_team_post()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_recipients uuid[];
  v_team_id uuid;
begin
  -- Only fire when a post is active and speaking on behalf of a team
  if new.status <> 'active' or new.publisher_type <> 'team' then
    return new;
  end if;

  -- On UPDATE, only fire if transitioning into active status from inactive/draft
  if tg_op = 'UPDATE' and old.status = new.status then
    return new;
  end if;

  v_team_id := new.publisher_id;
  if v_team_id is null then
    return new;
  end if;

  select coalesce(array_agg(distinct u.user_id), '{}')
  into v_recipients
  from (
    select tm.user_id
    from public.team_members tm
    where tm.team_id = v_team_id
      and tm.status = 'active'
      and tm.user_id is not null
    union
    select f.follower_id as user_id
    from public.follows f
    where f.target_type = 'team' and f.target_id = v_team_id
  ) u;

  if cardinality(v_recipients) > 0 then
    perform public.notify(
      v_recipients,
      'team.post.published',
      jsonb_build_object('team_id', v_team_id, 'post_id', new.post_id),
      new.created_by_user_id,
      'team',
      v_team_id
    );
  end if;
  return new;
end;
$$;

-- 2. Rewrite notify_on_post_like
create or replace function public.notify_on_post_like()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_author_id uuid;
begin
  select created_by_user_id
  into v_author_id
  from public.posts
  where post_id = new.post_id;

  if v_author_id is null then
    return new;
  end if;

  perform public.notify(
    array[v_author_id],
    'social.post.liked',
    jsonb_build_object('post_id', new.post_id, 'actor_id', new.user_id),
    new.user_id,
    'post',
    new.post_id
  );
  return new;
end;
$$;

-- 3. Rewrite notify_on_comment
create or replace function public.notify_on_comment()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_recipient_id uuid;
  v_type_key text;
  v_payload jsonb;
begin
  v_payload := jsonb_build_object(
    'post_id', new.post_id,
    'comment_id', new.comment_id,
    'parent_comment_id', new.parent_comment_id,
    'actor_id', new.author_id
  );

  if new.parent_comment_id is null then
    select created_by_user_id
    into v_recipient_id
    from public.posts
    where post_id = new.post_id;
    v_type_key := 'social.post.commented';
  else
    select author_id
    into v_recipient_id
    from public.comments
    where comment_id = new.parent_comment_id;
    v_type_key := 'social.comment.replied';
  end if;

  if v_recipient_id is not null then
    perform public.notify(
      array[v_recipient_id],
      v_type_key,
      v_payload,
      new.author_id,
      'post',
      new.post_id
    );
  end if;

  if coalesce(cardinality(new.mentioned_user_ids), 0) > 0 then
    perform public.notify(
      array(
        select m
        from unnest(new.mentioned_user_ids) as m
        where v_recipient_id is null or m <> v_recipient_id
      ),
      'social.mention',
      jsonb_build_object(
        'post_id', new.post_id,
        'comment_id', new.comment_id,
        'actor_id', new.author_id
      ),
      new.author_id,
      'post',
      new.post_id
    );
  end if;

  return new;
end;
$$;

-- 4. Rewrite is_post_author
create or replace function public.is_post_author(
  p_post_id uuid
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
      and p.created_by_user_id = auth.uid()
  );
$$;

-- 5. Rewrite my_deletion_objects
drop function if exists public.my_deletion_objects();

create or replace function public.my_deletion_objects()
returns table (bucket_id text, name text)
language sql
stable
security definer
set search_path = ''
as $$
  select
    o.bucket_id,
    o.name
  from storage.objects o
  where
    auth.uid() is not null
    and (
      o.owner_id = auth.uid()::text
      or (o.bucket_id = 'avatars' and split_part(o.name, '/', 1) = auth.uid()::text)
      or (
        o.bucket_id = 'post-media'
        and exists (
          select 1
          from public.posts p
          where
            p.created_by_user_id = auth.uid()
            and p.post_id::text = split_part(o.name, '/', 1)
        )
      )
    )
  order by o.bucket_id, o.name
  limit 100;
$$;

revoke all on function public.my_deletion_objects() from public, anon;
grant execute on function public.my_deletion_objects() to authenticated;

-- 6. Rewrite delete_user storage check to use created_by_user_id
create or replace function public.delete_user()
returns void
language plpgsql
security definer
set search_path = public, auth, storage, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_sport uuid;
  v_unclaimed_id uuid;
  mp record;
begin
  if v_uid is null then
    raise exception 'Unauthenticated' using errcode = '401';
  end if;

  select s.sport_id into v_sport
  from public.sports s
  where s.slug = 'cricket'
  limit 1;

  for mp in
    select mp.match_id, mp.user_id, mp.display_name
    from public.match_players mp
    join public.matches m on m.match_id = mp.match_id and m.sport_id = v_sport
    where mp.user_id = v_uid
  loop
    insert into public.unclaimed_players (sport_id, display_name, added_by)
    values (v_sport, 'Deleted player', null)
    returning unclaimed_id into v_unclaimed_id;

    update public.match_players mp
    set
      display_name = 'Deleted player',
      jersey_number = null,
      user_id = null,
      unclaimed_id = v_unclaimed_id
    from public.matches m
    where mp.match_id = m.match_id and mp.user_id = v_uid and m.sport_id = v_sport;
  end loop;

  update public.matches set created_by = null where created_by = v_uid;
  update public.cricket_match_deliveries set recorded_by = null where recorded_by = v_uid;
  update public.team_members set added_by = null where added_by = v_uid;
  update public.unclaimed_players set added_by = null where added_by = v_uid;

  delete from public.cricket_unclaimed_player_profiles cup
  using public.unclaimed_players up
  where cup.unclaimed_id = up.unclaimed_id and up.claimed_by_user_id = v_uid;

  update public.unclaimed_players
  set
    display_name = 'Deleted player',
    phone_number = null,
    email = null,
    claimed_by_user_id = null,
    claimed_at = null
  where claimed_by_user_id = v_uid;

  update public.messages
  set
    body = 'This message was deleted',
    payload = '{}'::jsonb,
    deleted_at = now()
  where sender_id = v_uid;

  if exists (
    select 1
    from storage.objects o
    where
      o.owner_id = v_uid::text
      or (o.bucket_id = 'avatars' and split_part(o.name, '/', 1) = v_uid::text)
      or (
        o.bucket_id = 'post-media'
        and exists (
          select 1
          from public.posts p
          where p.created_by_user_id = v_uid and p.post_id::text = split_part(o.name, '/', 1)
        )
      )
  ) then
    raise exception 'Remove uploaded files before completing account deletion';
  end if;

  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_user() from public;
grant execute on function public.delete_user() to authenticated;

-- 7. Drop legacy columns, constraints, functions, and types
alter table public.posts drop constraint if exists post_author_context_consistency;
drop function if exists public.can_act_for_post_context cascade;
drop index if exists public.idx_posts_author_context;
drop index if exists public.idx_posts_author_id;

alter table public.posts drop column if exists author_id cascade;
alter table public.posts drop column if exists author_context cascade;
alter table public.posts drop column if exists context_entity_id cascade;
alter table public.posts drop column if exists post_type cascade;

drop type if exists public.post_author_context cascade;
