-- Execute after the release schema in a transaction on a disposable LOCAL DB.
-- All fixtures and schema changes are rolled back by the caller.
insert into auth.users(id, email, raw_user_meta_data) values
 ('f0140000-0000-4000-8000-000000000001','release-a@example.invalid','{"display_name":"Release A"}'),
 ('f0140000-0000-4000-8000-000000000002','release-b@example.invalid','{"display_name":"Release B"}'),
 ('f0140000-0000-4000-8000-000000000003','release-c@example.invalid','{"display_name":"Release C"}');
insert into public.posts(post_id,author_id,post_type,text) values
 ('f0140000-0000-4000-8000-000000000011','f0140000-0000-4000-8000-000000000002','text','Safety fixture');
insert into public.matches(match_id, format) values ('f0140000-0000-4000-8000-000000000031', '{}');
insert into public.match_players(match_id,team_side,user_id,display_name) values ('f0140000-0000-4000-8000-000000000031','team_a','f0140000-0000-4000-8000-000000000001','Release A');
insert into public.chats(chat_id,type) values ('f0140000-0000-4000-8000-000000000021','dm');
insert into public.chat_members(chat_id,user_id) values
 ('f0140000-0000-4000-8000-000000000021','f0140000-0000-4000-8000-000000000001'),
 ('f0140000-0000-4000-8000-000000000021','f0140000-0000-4000-8000-000000000002');
insert into public.dm_channels(chat_id,user_a,user_b,accepted_at) values
 ('f0140000-0000-4000-8000-000000000021','f0140000-0000-4000-8000-000000000001','f0140000-0000-4000-8000-000000000002',now());
select set_config('request.jwt.claim.sub','f0140000-0000-4000-8000-000000000001',true);
select set_config('request.jwt.claims','{"sub":"f0140000-0000-4000-8000-000000000001","role":"authenticated"}',true);
set local role authenticated;
insert into public.content_reports(reporter_id,target_kind,target_id,reason) values
 ('f0140000-0000-4000-8000-000000000001','post','f0140000-0000-4000-8000-000000000011','Spam');
insert into public.user_blocks(blocker_id,blocked_id) values
 ('f0140000-0000-4000-8000-000000000001','f0140000-0000-4000-8000-000000000002');
do $$ begin
 if exists(select 1 from public.posts where post_id='f0140000-0000-4000-8000-000000000011') then raise exception 'Blocked post leaked'; end if;
 begin
   insert into public.user_blocks(blocker_id,blocked_id) values ('f0140000-0000-4000-8000-000000000002','f0140000-0000-4000-8000-000000000003');
   raise exception 'Spoofed blocker accepted';
 exception when insufficient_privilege then null; end;
 begin
   insert into public.messages(chat_id,sender_id,body) values ('f0140000-0000-4000-8000-000000000021','f0140000-0000-4000-8000-000000000001','Blocked send');
   raise exception 'Blocked message accepted';
 exception when insufficient_privilege then null; end;
 begin
   insert into public.comments(post_id,author_id,text) values ('f0140000-0000-4000-8000-000000000011','f0140000-0000-4000-8000-000000000001','Blocked comment');
   raise exception 'Blocked comment accepted';
 exception when insufficient_privilege then null; end;
end $$;
reset role;
select set_config('request.jwt.claim.sub','f0140000-0000-4000-8000-000000000002',true);
select set_config('request.jwt.claims','{"sub":"f0140000-0000-4000-8000-000000000002","role":"authenticated"}',true);
set local role authenticated;
do $$ begin
 if exists(select 1 from public.content_reports where target_id='f0140000-0000-4000-8000-000000000011') then raise exception 'Private report leaked'; end if;
 begin
   insert into public.messages(chat_id,sender_id,body) values ('f0140000-0000-4000-8000-000000000021','f0140000-0000-4000-8000-000000000002','Reciprocal blocked send');
   raise exception 'Reciprocal block bypassed';
 exception when insufficient_privilege then null; end;
end $$;
reset role;
select set_config('request.jwt.claim.sub','f0140000-0000-4000-8000-000000000001',true);
select set_config('request.jwt.claims','{"sub":"f0140000-0000-4000-8000-000000000001","role":"authenticated"}',true);
set local role authenticated;
delete from public.user_blocks where blocker_id='f0140000-0000-4000-8000-000000000001';
insert into public.messages(chat_id,sender_id,body) values ('f0140000-0000-4000-8000-000000000021','f0140000-0000-4000-8000-000000000001','Unblocked send');
select public.delete_user();
reset role;
do $$ begin
 if exists(select 1 from public.match_players where match_id='f0140000-0000-4000-8000-000000000031' and (display_name <> 'Deleted player' or user_id is not null)) then raise exception 'Lineup identity retained'; end if;
 if exists(select 1 from auth.users where id='f0140000-0000-4000-8000-000000000001') then raise exception 'Account was not deleted'; end if;
 if exists(select 1 from public.messages where chat_id='f0140000-0000-4000-8000-000000000021' and body='Unblocked send') then raise exception 'Deleted message text retained'; end if;
end $$;
select 'Play safety and deletion checks passed' as result;
