-- =============================================================================
-- 0817 · realtime_authorization — Supabase Realtime Authorization Policies
-- =============================================================================

create or replace function public._try_topic_uuid(p_topic text, p_pos int)
returns uuid
language sql
immutable
set search_path = public, pg_temp
as $$
  select case
    when split_part(p_topic, ':', p_pos)
         ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    then split_part(p_topic, ':', p_pos)::uuid
    else null
  end;
$$;

grant execute on function public._try_topic_uuid(text, int) to authenticated, anon;

drop policy if exists "realtime_join_authorized" on realtime.messages;

create policy "realtime_join_authorized"
  on realtime.messages
  for select
  to authenticated
  using (
    realtime.messages.extension = 'broadcast'
    and (
      (
        split_part((select realtime.topic()), ':', 1) = 'user'
        and split_part((select realtime.topic()), ':', 2) = (select auth.uid())::text
      )
      or (
        split_part((select realtime.topic()), ':', 1) = 'match'
      )
      or (
        split_part((select realtime.topic()), ':', 1) = 'tournament'
      )
      or (
        split_part((select realtime.topic()), ':', 1) = 'post'
      )
      or (
        split_part((select realtime.topic()), ':', 1) = 'chat'
        and public.is_chat_member(
          public._try_topic_uuid((select realtime.topic()), 2)
        )
      )
    )
  );

drop policy if exists "realtime_send_typing_self" on realtime.messages;

create policy "realtime_send_typing_self"
  on realtime.messages
  for insert
  to authenticated
  with check (
    realtime.messages.extension = 'broadcast'
    and split_part((select realtime.topic()), ':', 1) = 'chat'
    and split_part((select realtime.topic()), ':', 3) = 'typing'
    and public.is_chat_member(
      public._try_topic_uuid((select realtime.topic()), 2)
    )
  );

do $$
begin
  alter publication supabase_realtime add table public.teams;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.team_members;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.unclaimed_players;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.posts;
exception when duplicate_object then null;
end $$;
