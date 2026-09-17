-- Blocking is account-scoped. Only the blocker can manage their list.
create table public.user_blocks (
  blocker_id uuid not null references public.profiles(user_id) on delete cascade,
  blocked_id uuid not null references public.profiles(user_id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
create index user_blocks_blocked_id on public.user_blocks(blocked_id);
alter table public.user_blocks enable row level security;
revoke all on public.user_blocks from anon, authenticated;
grant select, insert, delete on public.user_blocks to authenticated;
create policy blocks_read_own on public.user_blocks for select to authenticated using (blocker_id = (select auth.uid()));
create policy blocks_insert_own on public.user_blocks for insert to authenticated with check (blocker_id = (select auth.uid()));
create policy blocks_delete_own on public.user_blocks for delete to authenticated using (blocker_id = (select auth.uid()));
create schema if not exists private;
grant usage on schema private to authenticated;
-- A narrowly scoped policy helper; never accepts a caller identity.
create or replace function private.is_blocked_with(target uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists (
    select 1 from public.user_blocks b
    where (b.blocker_id = auth.uid() and b.blocked_id = target)
       or (b.blocked_id = auth.uid() and b.blocker_id = target)
  );
$$;
revoke all on function private.is_blocked_with(uuid) from public;
grant execute on function private.is_blocked_with(uuid) to authenticated;
