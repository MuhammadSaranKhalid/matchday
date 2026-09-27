-- Migration: comments_and_saved_posts_pagination_indexes
-- Description: Adds high-performance composite keyset pagination indexes for
--              top-level comments, nested replies, and saved posts.

-- 1. Index for top-level comments keyset pagination (post_id, created_at DESC, comment_id DESC)
create index if not exists idx_comments_top_level_keyset
  on public.comments (post_id, created_at desc, comment_id desc)
  where parent_comment_id is null and status = 'active';

-- 2. Index for comment replies keyset pagination (parent_comment_id, created_at ASC, comment_id ASC)
create index if not exists idx_comments_replies_keyset
  on public.comments (parent_comment_id, created_at asc, comment_id asc)
  where parent_comment_id is not null and status = 'active';

-- 3. Composite tie-break index for saved posts keyset pagination (user_id, created_at DESC, post_id DESC)
create index if not exists idx_bookmarks_user_keyset
  on public.bookmarks (user_id, created_at desc, post_id desc);
