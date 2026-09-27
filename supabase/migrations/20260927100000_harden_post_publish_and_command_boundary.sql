-- Migration: harden_post_publish_and_command_boundary
-- Description:
--   1. Adds idempotency_key to public.posts and unique partial index.
--   2. Ensures post_type has default and post_media has source_bytes and source_mime.
--   3. Drops legacy begin_post_publish overload and sets canonical RPC with user-scoped staging path.
--   4. Drops direct INSERT/UPDATE/DELETE policies on public.posts to enforce command RPC boundary.

-- 1. Schema adjustments on public.posts and public.post_media
alter table public.posts
  add column if not exists idempotency_key text;

create unique index if not exists idx_posts_idempotency_key
  on public.posts (created_by_user_id, idempotency_key)
  where idempotency_key is not null;

alter table public.posts
  alter column post_type set default 'photo'::public.post_type;

alter table public.post_media
  add column if not exists source_bytes bigint,
  add column if not exists source_mime text;

-- 2. Drop legacy begin_post_publish overload
drop function if exists public.begin_post_publish(
  public.post_publisher_type,
  uuid,
  public.post_kind,
  text,
  integer,
  jsonb,
  public.post_visibility,
  uuid,
  uuid,
  uuid
);

-- 3. Canonical begin_post_publish implementation
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
  v_final_prefix text;
  v_media_result jsonb := '[]'::jsonb;
  v_post_type public.post_type;
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

  -- Idempotency check: return existing post and staging tokens if already reserved
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

  v_post_type := case
    when coalesce(p_expected_media_count, 0) > 0 then 'photo'::public.post_type
    else 'text'::public.post_type
  end;

  insert into public.posts (
    created_by_user_id,
    author_id,
    publisher_type,
    publisher_id,
    post_kind,
    post_type,
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
    v_post_type,
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
    -- Staging path must begin with user ID to satisfy storage policy: (storage.foldername(name))[1] = auth.uid()::text
    v_staging_path := format('%s/%s/%s/source.jpg', v_user_id, v_post_id, v_media_id);
    v_final_prefix := format('%s/%s/%s', v_user_id, v_post_id, v_media_id);

    insert into public.post_media (
      media_id,
      post_id,
      position,
      staging_path,
      final_prefix,
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
      v_final_prefix,
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

revoke all on function public.begin_post_publish(
  public.post_publisher_type,
  uuid,
  public.post_kind,
  text,
  integer,
  public.post_visibility,
  text,
  jsonb,
  uuid,
  uuid,
  uuid
) from public, anon;

grant execute on function public.begin_post_publish(
  public.post_publisher_type,
  uuid,
  public.post_kind,
  text,
  integer,
  public.post_visibility,
  text,
  jsonb,
  uuid,
  uuid,
  uuid
) to authenticated;

-- 4. Enforce strict command boundary on public.posts
drop policy if exists "posts_insert_authorized_publisher" on public.posts;
drop policy if exists "posts_delete_authorized_publisher" on public.posts;
drop policy if exists "posts_update_authorized_publisher" on public.posts;

revoke insert, update, delete on table public.posts from authenticated, anon, public;
grant select on table public.posts to authenticated, anon;
