begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, private, extensions;

select plan(49);

select enum_has_labels(
  'public',
  'post_media_status',
  array['pending_upload', 'uploaded', 'processing', 'ready', 'failed'],
  'post media exposes only the V1 lifecycle'
);

select hasnt_column('public', 'post_media', 'optimization_attempts');
select hasnt_column('public', 'post_media', 'feed_ready_at');
select hasnt_column('public', 'post_media', 'last_optimization_error');
select hasnt_column('public', 'post_media', 'optimized_at');
select hasnt_column('public', 'post_media', 'processing_generation');
select hasnt_column('public', 'post_media', 'processing_token');
select hasnt_table('private', 'media_processing_outbox');

select has_function('private', 'claim_post_media_for_processing', array['uuid']);
select has_function('private', 'release_post_media_for_retry', array['uuid', 'text']);
select has_function(
  'private',
  'mark_post_media_ready',
  array['uuid', 'integer', 'integer', 'integer', 'integer', 'text', 'jsonb']
);
select has_function('private', 'mark_post_media_failed', array['uuid', 'text']);
select hasnt_function('private', 'recover_stale_post_media');

select ok(
  not has_function_privilege('authenticated', 'private.claim_post_media_for_processing(uuid)', 'execute'),
  'authenticated clients cannot claim media jobs'
);
select ok(
  not has_function_privilege('authenticated', 'private.release_post_media_for_retry(uuid,text)', 'execute'),
  'authenticated clients cannot release media jobs'
);
select ok(
  not has_function_privilege('authenticated', 'private.mark_post_media_ready(uuid,integer,integer,integer,integer,text,jsonb)', 'execute'),
  'authenticated clients cannot complete media jobs'
);
select ok(
  not has_function_privilege('authenticated', 'private.mark_post_media_failed(uuid,text)', 'execute'),
  'authenticated clients cannot fail media jobs'
);

select ok(
  has_function_privilege('service_role', 'private.claim_post_media_for_processing(uuid)', 'execute'),
  'service role can claim media jobs'
);
select ok(
  has_function_privilege('service_role', 'private.release_post_media_for_retry(uuid,text)', 'execute'),
  'service role can release media jobs'
);
select ok(
  has_function_privilege('service_role', 'private.mark_post_media_ready(uuid,integer,integer,integer,integer,text,jsonb)', 'execute'),
  'service role can complete media jobs'
);
select ok(
  has_function_privilege('service_role', 'private.mark_post_media_failed(uuid,text)', 'execute'),
  'service role can fail media jobs'
);

select hasnt_function('public', 'claim_post_media_jobs');
select hasnt_function('public', 'finish_post_media_job');
select hasnt_function('public', 'retry_post_media_job');
select hasnt_function('public', 'mark_media_feed_ready');
select hasnt_function('public', 'mark_media_optimized');
select hasnt_function('private', 'dispatch_media_job');
select hasnt_function('private', 'wake_post_media_worker');

create temporary table media_v1_ids (
  label text primary key,
  id uuid not null
) on commit drop;

with inserted_post as (
  insert into public.posts (
    created_by_user_id,
    publisher_type,
    publisher_id,
    text,
    expected_media_count,
    status
  ) values (
    '00000000-0000-0000-0000-000000000001',
    'user',
    '00000000-0000-0000-0000-000000000001',
    'V1 media test',
    2,
    'publishing'
  )
  returning post_id
)
insert into media_v1_ids (label, id)
select 'post', post_id from inserted_post;

with inserted_media as (
  insert into public.post_media (
    post_id,
    position,
    status,
    staging_path,
    final_prefix,
    source_width,
    source_height,
    source_bytes,
    source_mime
  ) values
    (
      (select id from media_v1_ids where label = 'post'),
      0,
      'uploaded',
      'test/v1/first.jpg',
      'test/v1/first/v1',
      1200,
      800,
      1000,
      'image/jpeg'
    ),
    (
      (select id from media_v1_ids where label = 'post'),
      1,
      'uploaded',
      'test/v1/second.jpg',
      'test/v1/second/v1',
      1200,
      800,
      1000,
      'image/jpeg'
    )
  returning media_id, position
)
insert into media_v1_ids (label, id)
select case position when 0 then 'first' else 'second' end, media_id
from inserted_media;

grant select on media_v1_ids to authenticated;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000001',
  true
);

select is(
  (select count(*) from public.post_media where post_id = (
    select id from media_v1_ids where label = 'post'
  )),
  2::bigint,
  'the draft owner can read expected media rows'
);

select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-0000-0000-000000000002',
  true
);

select is(
  (select count(*) from public.post_media where post_id = (
    select id from media_v1_ids where label = 'post'
  )),
  0::bigint,
  'another authenticated user cannot read draft media rows'
);
reset role;

select matches(
  pg_get_functiondef('private.mark_post_media_ready(uuid,integer,integer,integer,integer,text,jsonb)'::regprocedure),
  'from public[.]post_media[[:space:][:print:]]+for update',
  'ready completion locks the media row'
);

select matches(
  pg_get_functiondef('private.mark_post_media_ready(uuid,integer,integer,integer,integer,text,jsonb)'::regprocedure),
  'from public[.]posts[[:space:][:print:]]+for update',
  'ready completion locks the parent post before all-ready publication'
);

select ok(
  (private.claim_post_media_for_processing(
    (select id from media_v1_ids where label = 'first')
  ) ->> 'claimed')::boolean,
  'uploaded media can be claimed'
);

select is(
  (select status::text from public.post_media where media_id = (
    select id from media_v1_ids where label = 'first'
  )),
  'processing',
  'claim changes uploaded to processing'
);

select is(
  (select processing_attempts from public.post_media where media_id = (
    select id from media_v1_ids where label = 'first'
  )),
  1,
  'claim increments processing attempts'
);

select ok(
  private.release_post_media_for_retry(
    (select id from media_v1_ids where label = 'first'),
    'storage_timeout'
  ),
  'transient failure releases a processing claim'
);

select is(
  (select status::text from public.post_media where media_id = (
    select id from media_v1_ids where label = 'first'
  )),
  'uploaded',
  'retry release returns media to uploaded'
);

select is(
  (select last_processing_error from public.post_media where media_id = (
    select id from media_v1_ids where label = 'first'
  )),
  'storage_timeout',
  'retry release records a safe error code'
);

select ok(
  (private.claim_post_media_for_processing(
    (select id from media_v1_ids where label = 'first')
  ) ->> 'claimed')::boolean,
  'released media can be claimed by the next BullMQ attempt'
);

select ok(
  (private.mark_post_media_ready(
    (select id from media_v1_ids where label = 'first'),
    1200,
    800,
    1080,
    720,
    'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
    '{"1080":{"path":"test/v1/first/v1/1080.webp","width":1080,"height":720}}'
  ) ->> 'ready')::boolean,
  'claimed media can become ready'
);

select is(
  (select status::text from public.posts where post_id = (
    select id from media_v1_ids where label = 'post'
  )),
  'publishing',
  'post remains unpublished while a sibling is not ready'
);

select ok(
  (private.claim_post_media_for_processing(
    (select id from media_v1_ids where label = 'second')
  ) ->> 'claimed')::boolean,
  'second media can be claimed'
);

select ok(
  (private.mark_post_media_ready(
    (select id from media_v1_ids where label = 'second'),
    1200,
    800,
    1080,
    720,
    'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
    '{"1080":{"path":"test/v1/second/v1/1080.webp","width":1080,"height":720}}'
  ) ->> 'post_published')::boolean,
  'the final ready transition publishes the parent post'
);

select is(
  (select status::text from public.posts where post_id = (
    select id from media_v1_ids where label = 'post'
  )),
  'active',
  'all-ready post is active exactly once'
);

select is(
  (private.mark_post_media_ready(
    (select id from media_v1_ids where label = 'second'),
    1200,
    800,
    1080,
    720,
    'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
    '{"1080":{"path":"test/v1/second/v1/1080.webp","width":1080,"height":720}}'
  ) ->> 'status'),
  'ready',
  'ready completion is idempotent'
);

update public.post_media
set status = 'processing', processing_started_at = now()
where media_id = (select id from media_v1_ids where label = 'first');

select ok(
  private.mark_post_media_failed(
    (select id from media_v1_ids where label = 'first'),
    'invalid_jpeg'
  ),
  'permanent failure marks claimed media failed'
);

select is(
  (select status::text from public.post_media where media_id = (
    select id from media_v1_ids where label = 'first'
  )),
  'failed',
  'permanent failure uses the single failed state'
);

select is(
  (select last_processing_error from public.post_media where media_id = (
    select id from media_v1_ids where label = 'first'
  )),
  'invalid_jpeg',
  'permanent failure records a safe error code'
);

with text_post as (
  insert into public.posts (
    created_by_user_id,
    publisher_type,
    publisher_id,
    text,
    expected_media_count,
    status
  ) values (
    '00000000-0000-0000-0000-000000000001',
    'user',
    '00000000-0000-0000-0000-000000000001',
    'Text-only V1 post',
    0,
    'active'
  )
  returning status
)
select is(
  (select status::text from text_post),
  'active',
  'text-only posts require no media processing'
);

select * from finish();
rollback;
