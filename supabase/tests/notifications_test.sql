-- Run against a disposable database after `supabase db reset`:
--   docker exec -i <db> psql -U postgres -v ON_ERROR_STOP=1 < this-file
-- Every assertion is scoped to this file's own recipient. It must NOT count
-- rows table-wide: seed.sql already produces notifications, so a global
-- count(*) made the suite pass only on a pristine database and fail on a
-- standard reset.
begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;
select plan(23);
insert into auth.users(id) values
 ('10000000-0000-4000-8000-000000000001'), ('10000000-0000-4000-8000-000000000002');
insert into public.device_tokens(user_id, fcm_token, platform)
values ('10000000-0000-4000-8000-000000000001', 'test-one', 'android'),
       ('10000000-0000-4000-8000-000000000001', 'test-two', 'ios');
select public.notify(array['10000000-0000-4000-8000-000000000001'::uuid],
 'social.post.liked', '{"post_id":"20000000-0000-4000-8000-000000000001"}',
 '10000000-0000-4000-8000-000000000002', 'post', '20000000-0000-4000-8000-000000000001');
select is((select count(*)::int from public.notifications where recipient_id='10000000-0000-4000-8000-000000000001'), 1, 'one inbox row');
select is((select count(*)::int from pgmq.q_notifications_push), 2, 'one job per device');
select is((select icon_path from public.notifications where recipient_id='10000000-0000-4000-8000-000000000001'), 'v1/heart.svg', 'SVG path snapshot');
select is((select tone from public.notifications where recipient_id='10000000-0000-4000-8000-000000000001'), 'brand', 'independent tone snapshot');
select public.notify(array['10000000-0000-4000-8000-000000000001'::uuid],
 'social.post.liked', '{"post_id":"20000000-0000-4000-8000-000000000001"}',
 '10000000-0000-4000-8000-000000000002', 'post', '20000000-0000-4000-8000-000000000001');
select is((select group_count from public.notifications where recipient_id='10000000-0000-4000-8000-000000000001'), 2, 'unread event collapses');
select ok((select body like '2%' from public.notifications where recipient_id='10000000-0000-4000-8000-000000000001'), 'grouped copy renders count');
select is(public.notification_push_status((select notification_id from public.notifications where recipient_id='10000000-0000-4000-8000-000000000001'),1), 'superseded', 'old revision cannot overtake new copy');
update public.notifications set collapse_until = now() - interval '1 second' where recipient_id='10000000-0000-4000-8000-000000000001';
select public.notify(array['10000000-0000-4000-8000-000000000001'::uuid],
 'social.post.liked', '{"post_id":"20000000-0000-4000-8000-000000000001"}',
 '10000000-0000-4000-8000-000000000002', 'post', '20000000-0000-4000-8000-000000000001');
select is((select count(*)::int from public.notifications where recipient_id='10000000-0000-4000-8000-000000000001'), 2, 'expired group creates another unread row');
insert into public.notification_preferences values
 ('10000000-0000-4000-8000-000000000001', 'social', 'push', false, now());
select public.notify_one('10000000-0000-4000-8000-000000000001', 'social.follow', '{}', '10000000-0000-4000-8000-000000000002');
select is((select count(*)::int from pgmq.q_notifications_push), 6, 'push opt-out creates no jobs');
select is((select count(*)::int from notification_deliveries where status='skipped_pref'), 1, 'suppression audited');
insert into public.notification_mutes(user_id,scope,entity_id) values
 ('10000000-0000-4000-8000-000000000001','user','10000000-0000-4000-8000-000000000002');
select public.notify_one('10000000-0000-4000-8000-000000000001', 'social.follow', '{}', '10000000-0000-4000-8000-000000000002','user','10000000-0000-4000-8000-000000000002');
select is((select count(*)::int from notifications where recipient_id='10000000-0000-4000-8000-000000000001'), 3, 'mute suppresses inbox and push');
update public.notification_types set user_configurable=false where key='social.follow';
insert into public.notification_preferences values
 ('10000000-0000-4000-8000-000000000001', 'social', 'inapp', false, now());
select public.notify_one('10000000-0000-4000-8000-000000000001', 'social.follow', '{}', '10000000-0000-4000-8000-000000000002','user','10000000-0000-4000-8000-000000000002');
select is((select count(*)::int from pgmq.q_notifications_push), 8, 'mandatory notice bypasses preferences and mute');
select ok(not has_function_privilege('authenticated', 'public.notify(uuid[],text,jsonb,uuid,text,uuid)', 'execute'), 'clients cannot manufacture notifications');
select ok(not has_table_privilege('authenticated','public.notifications','update'), 'no whole-row update');
select ok(has_column_privilege('authenticated','public.notifications','is_read','update'), 'read acknowledgement allowed');
set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000002', true);
select is((select count(*)::int from public.notifications),0,'RLS hides another inbox');
reset role;
select ok(not has_function_privilege('authenticated','public.read_notification_jobs(text)','execute'), 'queue is worker-only');
select is(jsonb_array_length(public.read_notification_jobs('notifications_push')), 8, 'worker claims device jobs');
select is(jsonb_array_length(public.read_notification_jobs('notifications_push')), 0, 'active leases prevent a second claim');
select throws_ok($$insert into public.notification_types(key,category,title_template,body_template,icon,collapse_template)
 values ('social.invalid','social','title','body','bell','invalid')$$, '23514', null, 'collapse requires a positive window');
set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000001', true);
select is((select count(*)::int from public.list_notifications(null,null,2)),2,'inbox page is bounded');
select lives_ok($$update public.notifications set is_read=true$$, 'recipient can acknowledge');
select throws_ok($$update public.notifications set title='spoofed'$$, '42501', null, 'recipient cannot rewrite copy');
reset role;
select * from finish();
rollback;
