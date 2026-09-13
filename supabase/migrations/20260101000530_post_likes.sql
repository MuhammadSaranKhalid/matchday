-- =============================================================================
-- 0530 · post_likes
-- =============================================================================
-- Spec §6.8, §6.18, §8.2.6 (the spec calls this `likes`; we name it
-- `post_likes` to disambiguate from comment_likes in 0540).
--
-- Lifecycle:
--   INSERT — user likes a post; bump_post_likes_count increments
--            posts.likes_count; notify_on_post_like fans out to the post
--            author (skips self-likes).
--   DELETE — user unlikes; counter decrements (clamped at 0).
--
-- Uniqueness: one row per (post, user). The unique constraint enforces the
-- "one like per user" rule without app-side bookkeeping.
-- =============================================================================

create table public.post_likes (
  like_id     uuid primary key default gen_random_uuid(),
  post_id     uuid not null
                  references public.posts(post_id) on delete cascade,
  user_id     uuid not null
                  references public.profiles(user_id) on delete cascade,
  created_at  timestamptz not null default now(),
  unique (post_id, user_id)
);

create index post_likes_post on public.post_likes (post_id);
create index post_likes_user on public.post_likes (user_id);

-- -----------------------------------------------------------------------------
-- bump_post_likes_count — keeps posts.likes_count in sync.
-- SECURITY DEFINER so a liker can update a post they don't own.
-- -----------------------------------------------------------------------------
create or replace function public.bump_post_likes_count()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'INSERT' then
    update public.posts set likes_count = likes_count + 1 where post_id = new.post_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.posts set likes_count = greatest(likes_count - 1, 0)
     where post_id = old.post_id;
    return old;
  end if;
  return null;
end;
$$;

create trigger post_likes_bump_count
  after insert or delete on public.post_likes
  for each row execute function public.bump_post_likes_count();

-- -----------------------------------------------------------------------------
-- NOTIFICATION TRIGGER MOVED → 20260101000620_notification_triggers.sql
--
-- notify_on_post_like now calls public.notify() (0570), which is declared
-- AFTER this file. A plpgsql body referencing a not-yet-created function
-- compiles but fails at runtime (§12.0), so the trigger follows its dependency
-- — the same remedy the teams UPDATE policies got when they moved to 0210.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- RLS — public read; insert/delete only by self.
-- -----------------------------------------------------------------------------
alter table public.post_likes enable row level security;

-- Read is intentionally public — the post detail surface lists "X, Y and 12
-- others liked this", and the explore surface ranks posts by like count
-- aggregates. Anyone holding a post_id can already see its likes_count;
-- exposing rows lets the UI render the avatar strip without an extra RPC.
create policy "post_likes_read_public"
  on public.post_likes for select
  to anon, authenticated
  using (true);

create policy "post_likes_insert_self"
  on public.post_likes for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "post_likes_delete_self"
  on public.post_likes for delete
  to authenticated
  using ((select auth.uid()) = user_id);
