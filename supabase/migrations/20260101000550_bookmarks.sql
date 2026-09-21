-- Migration file: 20260101000550_bookmarks.sql

-- 0550 · bookmarks
-- Spec §6.17, §8.2.6. Private "save for later" on a post.
--
-- Bookmarks are 1:1 — one row per (user, post). They are PRIVATE — no other
-- user (not even the post's author) can see who bookmarked a post. RLS
-- enforces that on every operation.

-- Section: Tables and constraints

create table public.bookmarks(
  bookmark_id uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(user_id) on delete cascade,
  post_id     uuid not null references public.posts(post_id) on delete cascade,
  created_at  timestamptz not null default now(),
  unique (user_id, post_id)
);

-- Section: Indexes

create index bookmarks_user_created on public.bookmarks(user_id, created_at desc);

-- Section: Enable row-level security

-- RLS — owner-only on every operation. Bookmarks are private.
alter table public.bookmarks enable row level security;

-- Section: Policies

create policy "bookmarks_read_self" on public.bookmarks
  for select to authenticated
  using ((
    select
      auth.uid()) = user_id);

create policy "bookmarks_insert_self" on public.bookmarks
  for insert to authenticated
  with check ((
    select
      auth.uid()) = user_id);

create policy "bookmarks_delete_self" on public.bookmarks
  for delete to authenticated
  using ((
    select
      auth.uid()) = user_id);

-- Section: Indexes (continued)

-- Foreign-key indexes (Supabase advisor 0001_unindexed_foreign_keys)
-- Postgres does NOT index the referencing side of a foreign key for you. Every
-- one of these columns points at a parent that gets deleted or updated
-- (profiles on account deletion, matches/teams on cascade), and without an
-- index each such statement seq-scans this table once per affected parent row.
-- They are also the columns joined on when reading.
create index if not exists idx_bookmarks_post_id on public.bookmarks(post_id);
