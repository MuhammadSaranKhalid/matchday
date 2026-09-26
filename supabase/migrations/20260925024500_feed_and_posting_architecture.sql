-- =============================================================================
-- Migration: 20260925024500_feed_and_posting_architecture.sql
-- =============================================================================
-- Matchday Feed & Posting Architecture:
-- 1. Separates publisher identity (who) from authorization (why).
-- 2. Closes RLS vulnerability on personal post updates/deletions.
-- 3. Promotes media to first-class table public.post_media with async lifecycle.
-- 4. Establishes private post-media-staging storage and locks down final bucket writes.
-- 5. Introduces begin_post_publish, mark_media_feed_ready, get_home_feed,
--    set_post_like, and set_post_bookmark transactional RPCs.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Enums
-- -----------------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_type where typname = 'post_publisher_type') then
    create type public.post_publisher_type as enum (
      'user',
      'team',
      'tournament',
      'club'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'post_kind') then
    create type public.post_kind as enum (
      'standard',
      'recruitment',
      'match_announcement',
      'match_result',
      'tournament_update',
      'roster_update',
      'milestone'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'post_media_status') then
    create type public.post_media_status as enum (
      'awaiting_upload',
      'uploaded',
      'processing_feed',
      'feed_ready',
      'optimizing',
      'optimized',
      'upload_failed',
      'processing_failed',
      'optimization_failed'
    );
  end if;
end $$;

-- Add 'publishing' to post_status if not present
do $$
begin
  alter type public.post_status add value if not exists 'publishing' before 'active';
exception
  when duplicate_object then null;
end $$;

-- -----------------------------------------------------------------------------
-- 2. Posts table evolution
-- -----------------------------------------------------------------------------

alter table public.posts
  add column if not exists created_by_user_id uuid
    references public.profiles (user_id) on delete cascade,
  add column if not exists publisher_type public.post_publisher_type not null default 'user',
  add column if not exists publisher_id uuid,
  add column if not exists post_kind public.post_kind not null default 'standard',
  add column if not exists published_at timestamptz,
  add column if not exists expected_media_count integer not null default 0
    check (expected_media_count >= 0 and expected_media_count <= 4);

-- Backfill legacy posts
update public.posts
set
  created_by_user_id = coalesce(created_by_user_id, author_id),
  publisher_type = case
    when author_context = 'team_manager' then 'team'::public.post_publisher_type
    when author_context = 'tournament_organizer' then 'tournament'::public.post_publisher_type
    else 'user'::public.post_publisher_type
  end,
  publisher_id = coalesce(publisher_id, context_entity_id, author_id),
  post_kind = case
    when post_type = 'match_announcement' then 'match_announcement'::public.post_kind
    when post_type = 'recruitment' then 'recruitment'::public.post_kind
    when post_type = 'tournament_update' then 'tournament_update'::public.post_kind
    else 'standard'::public.post_kind
  end,
  published_at = coalesce(published_at, case when status = 'active' then created_at else null end),
  expected_media_count = coalesce(cardinality(media_urls), 0)
where created_by_user_id is null or publisher_id is null;

-- Enforce not-null invariants after backfill
alter table public.posts
  alter column created_by_user_id set not null,
  alter column publisher_id set not null;

-- Update content check constraint
alter table public.posts drop constraint if exists post_has_content;
alter table public.posts add constraint post_has_content
  check (
    expected_media_count >= 1
    or (text is not null and length(trim(text)) > 0)
  );

-- Keyset pagination index
create index if not exists idx_posts_published_pagination
  on public.posts (published_at desc, post_id desc)
  where status = 'active';

create index if not exists idx_posts_publisher_published
  on public.posts (publisher_type, publisher_id, published_at desc)
  where status = 'active';

-- -----------------------------------------------------------------------------
-- 3. Post media table (First-class media entities)
-- -----------------------------------------------------------------------------

create table if not exists public.post_media (
  media_id                 uuid primary key default gen_random_uuid(),
  post_id                  uuid not null
    references public.posts (post_id)
    on delete cascade,
  position                 integer not null
    check (position >= 0 and position < 4),
  media_type               text not null default 'image'
    check (media_type in ('image')),
  status                   public.post_media_status not null default 'awaiting_upload',
  staging_path             text,
  final_prefix             text,
  source_width             integer,
  source_height            integer,
  display_width            integer,
  display_height           integer,
  blurhash                 text,
  variants                 jsonb not null default '{}'::jsonb,
  pipeline_version         integer not null default 1,
  processing_attempts      integer not null default 0,
  last_processing_error    text,
  processing_started_at    timestamptz,
  processed_at             timestamptz,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now(),
  constraint post_media_post_position_unique unique (post_id, position)
);

create index if not exists idx_post_media_post_id
  on public.post_media (post_id, position);

create index if not exists idx_post_media_status_queue
  on public.post_media (status, created_at)
  where status in ('awaiting_upload', 'uploaded', 'processing_feed', 'feed_ready', 'optimizing');

-- Attach updated_at trigger
drop trigger if exists post_media_updated_at on public.post_media;
create trigger post_media_updated_at
  before update on public.post_media
  for each row execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- 4. Storage Buckets & Policies
-- -----------------------------------------------------------------------------

-- 4a. Private staging bucket for incoming client source files
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'post-media-staging',
  'post-media-staging',
  false,
  15 * 1024 * 1024, -- 15 MB cap for client preprocessed JPEG sources
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update set
  public = false,
  file_size_limit = 15 * 1024 * 1024;

-- Staging bucket RLS: Creator-only access keyed to auth.uid() folder prefix (storage.objects RLS enabled by default)
drop policy if exists "post_media_staging_owner_select" on storage.objects;
create policy "post_media_staging_owner_select"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'post-media-staging'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "post_media_staging_owner_insert" on storage.objects;
create policy "post_media_staging_owner_insert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'post-media-staging'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "post_media_staging_owner_update" on storage.objects;
create policy "post_media_staging_owner_update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'post-media-staging'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'post-media-staging'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

drop policy if exists "post_media_staging_owner_delete" on storage.objects;
create policy "post_media_staging_owner_delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'post-media-staging'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- 4b. Lock down public post-media bucket (only service_role writes final assets)
drop policy if exists "post_media_insert_author" on storage.objects;
drop policy if exists "post_media_update_author" on storage.objects;
drop policy if exists "post_media_delete_author" on storage.objects;

-- -----------------------------------------------------------------------------
-- 5. Authorization Helper
-- -----------------------------------------------------------------------------

create or replace function public.can_publish_as(
  p_publisher_type public.post_publisher_type,
  p_publisher_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case p_publisher_type
    when 'user' then
      p_publisher_id = p_user_id
    when 'team' then (
      public.can('team', p_publisher_id, 'team.post')
      or public.is_team_manager(p_publisher_id)
    )
    when 'tournament' then
      public.is_tournament_organizer(p_publisher_id)
    when 'club' then
      false
    else
      false
  end;
$$;

revoke all on function public.can_publish_as(public.post_publisher_type, uuid, uuid) from public;
grant execute on function public.can_publish_as(public.post_publisher_type, uuid, uuid) to authenticated, anon;

-- -----------------------------------------------------------------------------
-- 6. Hardened RLS Policies on posts
-- -----------------------------------------------------------------------------

drop policy if exists "posts_read_public" on public.posts;
drop policy if exists "posts_insert_self_or_manager" on public.posts;
drop policy if exists "posts_update_author_or_manager" on public.posts;
drop policy if exists "posts_delete_author_or_manager" on public.posts;

create policy "posts_read_active_or_creator"
  on public.posts
  for select
  to anon, authenticated
  using (
    status = 'active'
    or (
      (select auth.uid()) is not null
      and (select auth.uid()) = created_by_user_id
    )
  );

create policy "posts_insert_authorized_publisher"
  on public.posts
  for insert
  to authenticated
  with check (
    created_by_user_id = (select auth.uid())
    and author_id = (select auth.uid())
    and public.can_publish_as(publisher_type, publisher_id, (select auth.uid()))
  );

create policy "posts_update_authorized_publisher"
  on public.posts
  for update
  to authenticated
  using (
    (
      created_by_user_id = (select auth.uid())
      or (
        publisher_type = 'team'
        and (
          public.can('team', publisher_id, 'team.post')
          or public.is_team_manager(publisher_id)
        )
      )
      or (
        publisher_type = 'tournament'
        and public.is_tournament_organizer(publisher_id)
      )
    )
  )
  with check (
    -- Immutable publisher identities
    created_by_user_id = (select auth.uid())
  );

create policy "posts_delete_authorized_publisher"
  on public.posts
  for delete
  to authenticated
  using (
    created_by_user_id = (select auth.uid())
    or (
      publisher_type = 'team'
      and (
        public.can('team', publisher_id, 'team.post')
        or public.is_team_manager(publisher_id)
      )
    )
    or (
      publisher_type = 'tournament'
      and public.is_tournament_organizer(publisher_id)
    )
  );

-- -----------------------------------------------------------------------------
-- 7. RLS Policies on post_media
-- -----------------------------------------------------------------------------

alter table public.post_media enable row level security;

create policy "post_media_read_policy"
  on public.post_media
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.posts p
      where p.post_id = post_media.post_id
        and (
          p.status = 'active'
          or (
            (select auth.uid()) is not null
            and (select auth.uid()) = p.created_by_user_id
          )
        )
    )
  );

create policy "post_media_insert_creator"
  on public.post_media
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.posts p
      where p.post_id = post_media.post_id
        and p.created_by_user_id = (select auth.uid())
    )
  );

create policy "post_media_update_creator"
  on public.post_media
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.posts p
      where p.post_id = post_media.post_id
        and p.created_by_user_id = (select auth.uid())
    )
  );

create policy "post_media_delete_creator"
  on public.post_media
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.posts p
      where p.post_id = post_media.post_id
        and p.created_by_user_id = (select auth.uid())
    )
  );

-- -----------------------------------------------------------------------------
-- 8. Transactional RPCs: Publishing Lifecycle
-- -----------------------------------------------------------------------------

-- 8a. begin_post_publish: creates publishing session and returns upload staging contracts
create or replace function public.begin_post_publish(
  p_publisher_type public.post_publisher_type,
  p_publisher_id uuid,
  p_post_kind public.post_kind,
  p_text text,
  p_expected_media_count integer default 0,
  p_linked_match_id uuid default null,
  p_linked_tournament_id uuid default null,
  p_linked_team_id uuid default null,
  p_linked_player_ids uuid[] default '{}',
  p_visibility public.post_visibility default 'public',
  p_media_items jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid;
  v_post_id uuid;
  v_post_status public.post_status;
  v_published_at timestamptz;
  v_media_count integer;
  v_item jsonb;
  v_media_id uuid;
  v_position integer;
  v_staging_path text;
  v_final_prefix text;
  v_media_results jsonb := '[]'::jsonb;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Unauthenticated' using errcode = '401';
  end if;

  if not public.can_publish_as(p_publisher_type, p_publisher_id, v_user_id) then
    raise exception 'Not authorized to publish as this entity' using errcode = '403';
  end if;

  v_media_count := coalesce(p_expected_media_count, 0);
  if v_media_count < 0 or v_media_count > 4 then
    raise exception 'Media count must be between 0 and 4' using errcode = '400';
  end if;

  if v_media_count = 0 and (p_text is null or length(trim(p_text)) = 0) then
    raise exception 'Post must have either text or photos' using errcode = '400';
  end if;

  if p_text is not null and length(p_text) > 2000 then
    raise exception 'Post text cannot exceed 2000 characters' using errcode = '400';
  end if;

  if jsonb_array_length(coalesce(p_media_items, '[]'::jsonb)) <> v_media_count then
    raise exception 'Media items array must match expected_media_count' using errcode = '400';
  end if;

  v_post_id := gen_random_uuid();

  -- Text-only posts become active immediately
  if v_media_count = 0 then
    v_post_status := 'active'::public.post_status;
    v_published_at := now();
  else
    v_post_status := 'publishing'::public.post_status;
    v_published_at := null;
  end if;

  insert into public.posts (
    post_id,
    created_by_user_id,
    author_id,
    author_context,
    context_entity_id,
    publisher_type,
    publisher_id,
    post_kind,
    post_type,
    text,
    visibility,
    status,
    expected_media_count,
    linked_match_id,
    linked_tournament_id,
    linked_team_id,
    linked_player_ids,
    created_at,
    published_at,
    updated_at
  )
  values (
    v_post_id,
    v_user_id,
    v_user_id,
    case
      when p_publisher_type = 'team' then 'team_manager'::public.post_author_context
      when p_publisher_type = 'tournament' then 'tournament_organizer'::public.post_author_context
      else 'personal'::public.post_author_context
    end,
    case
      when p_publisher_type in ('team', 'tournament') then p_publisher_id
      else null
    end,
    p_publisher_type,
    p_publisher_id,
    p_post_kind,
    case when v_media_count > 0 then 'photo'::public.post_type else 'text'::public.post_type end,
    p_text,
    p_visibility,
    v_post_status,
    v_media_count,
    p_linked_match_id,
    p_linked_tournament_id,
    case when p_publisher_type = 'team' then p_publisher_id else p_linked_team_id end,
    coalesce(p_linked_player_ids, '{}'),
    now(),
    v_published_at,
    now()
  );

  -- Insert media records
  if v_media_count > 0 then
    for v_item in select * from jsonb_array_elements(p_media_items)
    loop
      v_media_id := gen_random_uuid();
      v_position := (v_item->>'position')::integer;
      v_staging_path := v_user_id::text || '/' || v_post_id::text || '/' || v_media_id::text || '/source.jpg';
      v_final_prefix := 'posts/' || v_post_id::text || '/' || v_media_id::text || '/v1/';

      insert into public.post_media (
        media_id,
        post_id,
        position,
        media_type,
        status,
        staging_path,
        final_prefix,
        source_width,
        source_height,
        pipeline_version,
        created_at,
        updated_at
      )
      values (
        v_media_id,
        v_post_id,
        v_position,
        'image',
        'awaiting_upload'::public.post_media_status,
        v_staging_path,
        v_final_prefix,
        (v_item->>'source_width')::integer,
        (v_item->>'source_height')::integer,
        1,
        now(),
        now()
      );

      v_media_results := v_media_results || jsonb_build_object(
        'media_id', v_media_id,
        'position', v_position,
        'staging_path', v_staging_path,
        'final_prefix', v_final_prefix
      );
    end loop;
  end if;

  return jsonb_build_object(
    'post_id', v_post_id,
    'status', v_post_status,
    'expected_media_count', v_media_count,
    'media', v_media_results
  );
end;
$$;

revoke all on function public.begin_post_publish from public;
grant execute on function public.begin_post_publish to authenticated;

-- 8b. mark_media_feed_ready: Called by image worker when 1080 + BlurHash asset is ready
create or replace function public.mark_media_feed_ready(
  p_media_id uuid,
  p_source_width integer,
  p_source_height integer,
  p_display_width integer,
  p_display_height integer,
  p_blurhash text,
  p_variants jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_post_id uuid;
  v_expected_count integer;
  v_ready_count integer;
  v_post_status public.post_status;
  v_now timestamptz := now();
begin
  select post_id into v_post_id
  from public.post_media
  where media_id = p_media_id
  for update;

  if not found then
    raise exception 'Media record not found' using errcode = '404';
  end if;

  update public.post_media
  set
    status = 'feed_ready'::public.post_media_status,
    source_width = coalesce(p_source_width, source_width),
    source_height = coalesce(p_source_height, source_height),
    display_width = coalesce(p_display_width, p_source_width),
    display_height = coalesce(p_display_height, p_source_height),
    blurhash = p_blurhash,
    variants = coalesce(p_variants, '{}'::jsonb),
    processed_at = v_now,
    updated_at = v_now
  where media_id = p_media_id;

  -- Lock post row for evaluation
  select expected_media_count, status
  into v_expected_count, v_post_status
  from public.posts
  where post_id = v_post_id
  for update;

  select count(*) into v_ready_count
  from public.post_media
  where post_id = v_post_id
    and status in ('feed_ready', 'optimizing', 'optimized');

  -- If all attached media are at least feed_ready, activate the post
  if v_post_status = 'publishing' and v_ready_count >= v_expected_count then
    update public.posts
    set
      status = 'active'::public.post_status,
      published_at = v_now,
      updated_at = v_now
    where post_id = v_post_id;

    v_post_status := 'active'::public.post_status;
  end if;

  return jsonb_build_object(
    'media_id', p_media_id,
    'post_id', v_post_id,
    'post_status', v_post_status,
    'all_ready', (v_ready_count >= v_expected_count)
  );
end;
$$;

revoke all on function public.mark_media_feed_ready from public;
grant execute on function public.mark_media_feed_ready to authenticated, service_role;

-- -----------------------------------------------------------------------------
-- 9. Consolidated Read Model: get_home_feed RPC
-- -----------------------------------------------------------------------------

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
  v_results jsonb;
begin
  with filtered_posts as (
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
      p.created_at,
      p.published_at,
      p.linked_match_id,
      p.linked_tournament_id,
      p.linked_team_id
    from public.posts p
    where p.status = 'active'
      -- Mode filtering
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
        or (
          p_mode = 'user'
          and p_target_id is not null
          and p.created_by_user_id = p_target_id
        )
        or (
          p_mode = 'team'
          and p_target_id is not null
          and (p.publisher_id = p_target_id or p.linked_team_id = p_target_id)
        )
        or (
          p_mode = 'saved'
          and v_viewer_id is not null
          and exists (
            select 1 from public.bookmarks b
            where b.post_id = p.post_id and b.user_id = v_viewer_id
          )
        )
      )
      -- Bidirectional block filtering
      and (
        v_viewer_id is null
        or not exists (
          select 1 from public.user_blocks ub
          where (ub.blocker_id = v_viewer_id and ub.blocked_id = p.created_by_user_id)
             or (ub.blocker_id = p.created_by_user_id and ub.blocked_id = v_viewer_id)
        )
      )
      -- Keyset pagination: (published_at, post_id) < (cursor_published_at, cursor_post_id)
      and (
        p_cursor_published_at is null
        or p_cursor_post_id is null
        or (p.published_at, p.post_id) < (p_cursor_published_at, p_cursor_post_id)
      )
    order by p.published_at desc, p.post_id desc
    limit v_limit
  ),
  posts_with_media as (
    select
      fp.*,
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
          where pm.post_id = fp.post_id
        ),
        '[]'::jsonb
      ) as media_list
    from filtered_posts fp
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
            'display_name', tr.name,
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
        when v_viewer_id is null then false
        else exists (
          select 1 from public.post_likes pl
          where pl.post_id = pwm.post_id and pl.user_id = v_viewer_id
        )
      end as viewer_liked,
      case
        when v_viewer_id is null then false
        else exists (
          select 1 from public.bookmarks bm
          where bm.post_id = pwm.post_id and bm.user_id = v_viewer_id
        )
      end as viewer_bookmarked,
      case
        when v_viewer_id is null or v_viewer_id = pwm.created_by_user_id then false
        else exists (
          select 1 from public.follows fl
          where fl.follower_id = v_viewer_id
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
        'created_at', e.created_at
      )
      order by e.published_at desc, e.post_id desc
    ),
    '[]'::jsonb
  ) into v_results
  from enriched e;

  return v_results;
end;
$$;

revoke all on function public.get_home_feed from public;
grant execute on function public.get_home_feed to anon, authenticated;

-- -----------------------------------------------------------------------------
-- 10. Desired-State Interactivity: Likes & Bookmarks
-- -----------------------------------------------------------------------------

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

revoke all on function public.set_post_like from public;
grant execute on function public.set_post_like to authenticated;

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

revoke all on function public.set_post_bookmark from public;
grant execute on function public.set_post_bookmark to authenticated;
