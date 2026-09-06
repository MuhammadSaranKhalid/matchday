-- =============================================================================
-- 0540 · comment_likes
-- =============================================================================
-- Mirrors post_likes (0530) but for comments. Spec §8.2.6 lists
-- `comments.likesCount` without naming a table, so we follow the same
-- pattern: a separate junction table with a (comment, user) unique index
-- and a counter-bump trigger that keeps comments.likes_count fresh.
--
-- No notification fan-out today — comment-like notifications are noise on
-- spec §6.10 and the design hasn't asked for them. Add a notify_on_
-- comment_like trigger here later if it becomes a feature.
-- =============================================================================

create table public.comment_likes (
  like_id     uuid primary key default gen_random_uuid(),
  comment_id  uuid not null
                  references public.comments(comment_id) on delete cascade,
  user_id     uuid not null
                  references public.profiles(user_id) on delete cascade,
  created_at  timestamptz not null default now(),
  unique (comment_id, user_id)
);

create index comment_likes_comment on public.comment_likes (comment_id);
create index comment_likes_user    on public.comment_likes (user_id);

-- -----------------------------------------------------------------------------
-- bump_comment_likes_count — keeps comments.likes_count in sync.
-- -----------------------------------------------------------------------------
create or replace function public.bump_comment_likes_count()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'INSERT' then
    update public.comments set likes_count = likes_count + 1
     where comment_id = new.comment_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.comments set likes_count = greatest(likes_count - 1, 0)
     where comment_id = old.comment_id;
    return old;
  end if;
  return null;
end;
$$;

create trigger comment_likes_bump_count
  after insert or delete on public.comment_likes
  for each row execute function public.bump_comment_likes_count();

-- -----------------------------------------------------------------------------
-- RLS — public read; insert/delete only by self.
-- -----------------------------------------------------------------------------
alter table public.comment_likes enable row level security;

-- Read is intentionally public — mirrors post_likes. Comment threads show
-- "liked by 3" + a tappable avatar row; the count alone isn't enough.
create policy "comment_likes_read_public"
  on public.comment_likes for select
  to anon, authenticated
  using (true);

create policy "comment_likes_insert_self"
  on public.comment_likes for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "comment_likes_delete_self"
  on public.comment_likes for delete
  to authenticated
  using ((select auth.uid()) = user_id);
