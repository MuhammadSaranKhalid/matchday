-- =============================================================================
-- Migration: 20260101000860_safety_enforcement.sql
-- =============================================================================

-- Integration policies depend on social and messaging tables.

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

create policy posts_respect_blocks
  on public.posts
  as restrictive
  for select
  to authenticated
  using (not private.is_blocked_with(author_id));

create policy comments_respect_blocks
  on public.comments
  as restrictive
  for select
  to authenticated
  using (not private.is_blocked_with(author_id));

create policy messages_respect_blocks
  on public.messages
  as restrictive
  for select
  to authenticated
  using (not private.is_blocked_with(sender_id));

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- Triggers also protect writes made through security-definer RPCs.
create or replace function private.guard_blocked_interaction()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target uuid;
begin
  if tg_table_name = 'messages' then
    select
      cm.user_id
    into
      target
    from
      public.chat_channels cc
      join public.channel_members cm on cm.channel_id = cc.channel_id
    where
      cc.channel_id = new.channel_id
      and cc.kind = 'direct'
      and cm.user_id <> new.sender_id
    limit 1;
    if target is not null and exists (
      select
        1
      from
        public.user_blocks b
      where (b.blocker_id = new.sender_id and b.blocked_id = target) or (b.blocker_id = target and b.blocked_id = new.sender_id)) then
      raise exception 'Messaging is unavailable between these accounts'
        using errcode = '42501';
    end if;
  elsif tg_table_name = 'comments' then
    select
      author_id
    into
      target
    from
      public.posts
    where
      post_id = new.post_id;
    if exists (
      select
        1
      from
        public.user_blocks b
      where (b.blocker_id = new.author_id
        and b.blocked_id = target)
      or (b.blocker_id = target
        and b.blocked_id = new.author_id)) then
  raise exception 'Commenting is unavailable between these accounts'
      using errcode = '42501';
  end if;
elsif tg_table_name = 'follows'
    and new.target_type = 'user' then
    if exists (
      select
        1
      from
        public.user_blocks b
      where (b.blocker_id = new.follower_id
        and b.blocked_id = new.target_id)
      or (b.blocker_id = new.target_id
        and b.blocked_id = new.follower_id)) then
  raise exception 'Following is unavailable between these accounts'
    using errcode = '42501';
end if;
end if;
  return new;
end;
$$;

revoke all on function private.guard_blocked_interaction() from public;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger messages_block_guard
  before insert or update on public.messages
  for each row
  execute function private.guard_blocked_interaction();

create trigger comments_block_guard
  before insert or update on public.comments
  for each row
  execute function private.guard_blocked_interaction();

create trigger follows_block_guard
  before insert or update on public.follows
  for each row
  execute function private.guard_blocked_interaction();
