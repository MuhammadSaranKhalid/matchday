-- Migration: harden_begin_post_publish_validations
-- Description:
--   Restores strict input validation in begin_post_publish:
--   1. Ensures jsonb_array_length(p_media_manifest) == p_expected_media_count.
--   2. Enforces media count between 0 and 4.
--   3. Enforces text presence or photo presence (cannot be both empty).
--   4. Enforces text length <= 2000 characters.

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
  v_media_count integer := coalesce(p_expected_media_count, 0);
  v_manifest_len integer := jsonb_array_length(coalesce(p_media_manifest, '[]'::jsonb));
begin
  if v_user_id is null then
    raise exception 'Unauthenticated' using errcode = '401';
  end if;

  -- Enforce public visibility constraint
  if p_visibility is distinct from 'public' then
    raise exception 'Only public posts are supported currently' using errcode = '400';
  end if;

  -- Enforce publisher permission
  if not public.can_publish_as(p_publisher_type, p_publisher_id, v_user_id) then
    raise exception 'Unauthorized publisher' using errcode = '403';
  end if;

  -- Enforce media count bounds
  if v_media_count < 0 or v_media_count > 4 then
    raise exception 'Media count must be between 0 and 4' using errcode = '400';
  end if;

  -- Enforce media manifest length equals expected media count
  if v_manifest_len <> v_media_count then
    raise exception 'Media manifest length (%) does not match expected_media_count (%)',
      v_manifest_len, v_media_count using errcode = '400';
  end if;

  -- Enforce content requirement (text or photos required)
  if (p_text is null or length(trim(p_text)) = 0) and v_media_count = 0 then
    raise exception 'Post must contain text or photos' using errcode = '400';
  end if;

  -- Enforce text length limit
  if p_text is not null and length(p_text) > 2000 then
    raise exception 'Text exceeds 2000 characters' using errcode = '400';
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
    case when v_media_count = 0 then 'active'::public.post_status else 'publishing'::public.post_status end,
    v_media_count,
    p_idempotency_key,
    p_linked_match_id,
    p_linked_tournament_id,
    p_linked_team_id,
    case when v_media_count = 0 then now() else null end
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
    'status', case when v_media_count = 0 then 'active' else 'publishing' end,
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
