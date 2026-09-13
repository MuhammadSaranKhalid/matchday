# Posts and social activity: table reference

> Generated from a disposable migration replay on 2026-09-13. PostgreSQL 17.6. This describes source, not hosted deployment. Regenerate with `scripts/database/generate_docs.py`.


[Handbook](README.md) · [Architecture](architecture.md) · [Relationship diagrams](relationships.md)

## posts

Content, context and linked entities, media metadata and denormalized engagement counters.

Canonical declaration: [20260101000510_posts.sql](../../supabase/migrations/20260101000510_posts.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| post_id | uuid | False | gen_random_uuid() |
| author_id | uuid | False | — |
| author_context | post_author_context | False | 'personal'::post_author_context |
| context_entity_id | uuid | True | — |
| post_type | post_type | False | — |
| text | text | True | — |
| media_urls | text[] | False | '{}'::text[] |
| media | jsonb | False | '[]'::jsonb |
| linked_match_id | uuid | True | — |
| linked_tournament_id | uuid | True | — |
| linked_team_id | uuid | True | — |
| linked_player_ids | uuid[] | False | '{}'::uuid[] |
| auto_generated | boolean | False | false |
| visibility | post_visibility | False | 'public'::post_visibility |
| is_pinned | boolean | False | false |
| likes_count | integer | False | 0 |
| comments_count | integer | False | 0 |
| shares_count | integer | False | 0 |
| status | post_status | False | 'active'::post_status |
| created_at | timestamp with time zone | False | now() |
| edited_at | timestamp with time zone | True | — |
| updated_at | timestamp with time zone | False | now() |

- **media:** Per-image metadata [{url, blurhash, width, height}], max 4. Supersedes media_urls (kept in sync for compatibility).

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| post_author_context_consistency | CHECK (author_context = 'personal'::post_author_context AND context_entity_id IS NULL OR author_context = 'team_manager'::post_author_context AND context_entity_id IS NOT NULL OR author_context = 'tournament_organizer'::post_author_context AND context_entity_id IS NOT NULL) | False / False |
| post_has_content | CHECK (post_type = 'photo'::post_type AND (cardinality(media_urls) >= 1 OR jsonb_array_length(media) >= 1) OR text IS NOT NULL AND length(TRIM(BOTH FROM text)) > 0) | False / False |
| posts_author_id_fkey | FOREIGN KEY (author_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |
| posts_comments_count_check | CHECK (comments_count >= 0) | False / False |
| posts_likes_count_check | CHECK (likes_count >= 0) | False / False |
| posts_linked_match_id_fkey | FOREIGN KEY (linked_match_id) REFERENCES matches(match_id) ON DELETE SET NULL | False / False |
| posts_linked_team_id_fkey | FOREIGN KEY (linked_team_id) REFERENCES teams(team_id) ON DELETE SET NULL | False / False |
| posts_linked_tournament_id_fkey | FOREIGN KEY (linked_tournament_id) REFERENCES tournaments(tournament_id) ON DELETE SET NULL | False / False |
| posts_media_shape | CHECK (jsonb_typeof(media) = 'array'::text AND jsonb_array_length(media) <= 4) | False / False |
| posts_media_urls_check | CHECK (cardinality(media_urls) <= 4) | False / False |
| posts_pkey | PRIMARY KEY (post_id) | False / False |
| posts_shares_count_check | CHECK (shares_count >= 0) | False / False |
| posts_text_check | CHECK (text IS NULL OR length(text) <= 2000) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| posts_author_created | CREATE INDEX posts_author_created ON public.posts USING btree (author_id, created_at DESC) |
| posts_context_entity | CREATE INDEX posts_context_entity ON public.posts USING btree (context_entity_id) WHERE (context_entity_id IS NOT NULL) |
| posts_linked_match | CREATE INDEX posts_linked_match ON public.posts USING btree (linked_match_id) WHERE (linked_match_id IS NOT NULL) |
| posts_linked_players_gin | CREATE INDEX posts_linked_players_gin ON public.posts USING gin (linked_player_ids) |
| posts_linked_team | CREATE INDEX posts_linked_team ON public.posts USING btree (linked_team_id) WHERE (linked_team_id IS NOT NULL) |
| posts_linked_tournament | CREATE INDEX posts_linked_tournament ON public.posts USING btree (linked_tournament_id) WHERE (linked_tournament_id IS NOT NULL) |
| posts_pkey | CREATE UNIQUE INDEX posts_pkey ON public.posts USING btree (post_id) |
| posts_status_created | CREATE INDEX posts_status_created ON public.posts USING btree (status, created_at DESC) WHERE (status = 'active'::post_status) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| posts_delete_author_or_manager | DELETE | ["authenticated"] | ((( SELECT auth.uid() AS uid) = author_id) OR can_act_for_post_context(author_context, context_entity_id)) | — |
| posts_insert_self_or_manager | INSERT | ["authenticated"] | — | ((( SELECT auth.uid() AS uid) = author_id) AND can_act_for_post_context(author_context, context_entity_id)) |
| posts_read_public | SELECT | ["anon", "authenticated"] | ((status = 'active'::post_status) OR (( SELECT auth.uid() AS uid) = author_id)) | — |
| posts_update_author_or_manager | UPDATE | ["authenticated"] | ((( SELECT auth.uid() AS uid) = author_id) OR can_act_for_post_context(author_context, context_entity_id)) | ((( SELECT auth.uid() AS uid) = author_id) OR can_act_for_post_context(author_context, context_entity_id)) |

### Triggers

| Name | Definition |
| --- | --- |
| posts_set_updated_at | CREATE TRIGGER posts_set_updated_at BEFORE UPDATE ON posts FOR EACH ROW EXECUTE FUNCTION set_updated_at() |
| posts_stamp_edited_at | CREATE TRIGGER posts_stamp_edited_at BEFORE UPDATE ON posts FOR EACH ROW EXECUTE FUNCTION stamp_post_edited_at() |

## comments

Post comments and single-level replies, including mentions and edit state.

Canonical declaration: [20260101000520_comments.sql](../../supabase/migrations/20260101000520_comments.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| comment_id | uuid | False | gen_random_uuid() |
| post_id | uuid | False | — |
| author_id | uuid | False | — |
| parent_comment_id | uuid | True | — |
| text | text | False | — |
| mentioned_user_ids | uuid[] | False | '{}'::uuid[] |
| likes_count | integer | False | 0 |
| status | comment_status | False | 'active'::comment_status |
| created_at | timestamp with time zone | False | now() |
| edited_at | timestamp with time zone | True | — |
| updated_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| comments_author_id_fkey | FOREIGN KEY (author_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |
| comments_likes_count_check | CHECK (likes_count >= 0) | False / False |
| comments_parent_comment_id_fkey | FOREIGN KEY (parent_comment_id) REFERENCES comments(comment_id) ON DELETE CASCADE | False / False |
| comments_pkey | PRIMARY KEY (comment_id) | False / False |
| comments_post_id_fkey | FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE | False / False |
| comments_text_check | CHECK (length(text) >= 1 AND length(text) <= 500) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| comments_author | CREATE INDEX comments_author ON public.comments USING btree (author_id) |
| comments_mentions_gin | CREATE INDEX comments_mentions_gin ON public.comments USING gin (mentioned_user_ids) |
| comments_parent | CREATE INDEX comments_parent ON public.comments USING btree (parent_comment_id) WHERE (parent_comment_id IS NOT NULL) |
| comments_pkey | CREATE UNIQUE INDEX comments_pkey ON public.comments USING btree (comment_id) |
| comments_post_created | CREATE INDEX comments_post_created ON public.comments USING btree (post_id, created_at) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| comments_delete_self_or_post_author | DELETE | ["authenticated"] | ((( SELECT auth.uid() AS uid) = author_id) OR is_post_author(post_id)) | — |
| comments_insert_self | INSERT | ["authenticated"] | — | (( SELECT auth.uid() AS uid) = author_id) |
| comments_read_if_post_visible | SELECT | ["anon", "authenticated"] | (EXISTS ( SELECT 1<br>   FROM posts p<br>  WHERE ((p.post_id = comments.post_id) AND ((p.status = 'active'::post_status) OR (p.author_id = ( SELECT auth.uid() AS uid)))))) | — |
| comments_update_self | UPDATE | ["authenticated"] | (( SELECT auth.uid() AS uid) = author_id) | (( SELECT auth.uid() AS uid) = author_id) |

### Triggers

| Name | Definition |
| --- | --- |
| comments_after_delete_broadcast | CREATE TRIGGER comments_after_delete_broadcast AFTER DELETE ON comments FOR EACH ROW EXECUTE FUNCTION broadcast_comment_deleted() |
| comments_after_insert_broadcast | CREATE TRIGGER comments_after_insert_broadcast AFTER INSERT ON comments FOR EACH ROW EXECUTE FUNCTION broadcast_new_comment() |
| comments_after_update_broadcast | CREATE TRIGGER comments_after_update_broadcast AFTER UPDATE ON comments FOR EACH ROW WHEN (old.text IS DISTINCT FROM new.text OR old.status IS DISTINCT FROM new.status OR old.likes_count IS DISTINCT FROM new.likes_count OR old.mentioned_user_ids IS DISTINCT FROM new.mentioned_user_ids OR old.edited_at IS DISTINCT FROM new.edited_at) EXECUTE FUNCTION broadcast_comment_updated() |
| comments_bump_post_count | CREATE TRIGGER comments_bump_post_count AFTER INSERT OR DELETE OR UPDATE OF status ON comments FOR EACH ROW EXECUTE FUNCTION bump_post_comments_count() |
| comments_enforce_single_level | CREATE TRIGGER comments_enforce_single_level BEFORE INSERT OR UPDATE OF parent_comment_id ON comments FOR EACH ROW EXECUTE FUNCTION enforce_comment_single_level() |
| comments_notify | CREATE TRIGGER comments_notify AFTER INSERT ON comments FOR EACH ROW EXECUTE FUNCTION notify_on_comment() |
| comments_set_updated_at | CREATE TRIGGER comments_set_updated_at BEFORE UPDATE ON comments FOR EACH ROW EXECUTE FUNCTION set_updated_at() |
| comments_stamp_edited_at | CREATE TRIGGER comments_stamp_edited_at BEFORE UPDATE ON comments FOR EACH ROW EXECUTE FUNCTION stamp_comment_edited_at() |

## post_likes

Unique user/post reactions; triggers maintain counters and notify the post author.

Canonical declaration: [20260101000530_post_likes.sql](../../supabase/migrations/20260101000530_post_likes.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| like_id | uuid | False | gen_random_uuid() |
| post_id | uuid | False | — |
| user_id | uuid | False | — |
| created_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| post_likes_pkey | PRIMARY KEY (like_id) | False / False |
| post_likes_post_id_fkey | FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE | False / False |
| post_likes_post_id_user_id_key | UNIQUE (post_id, user_id) | False / False |
| post_likes_user_id_fkey | FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| post_likes_pkey | CREATE UNIQUE INDEX post_likes_pkey ON public.post_likes USING btree (like_id) |
| post_likes_post | CREATE INDEX post_likes_post ON public.post_likes USING btree (post_id) |
| post_likes_post_id_user_id_key | CREATE UNIQUE INDEX post_likes_post_id_user_id_key ON public.post_likes USING btree (post_id, user_id) |
| post_likes_user | CREATE INDEX post_likes_user ON public.post_likes USING btree (user_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| post_likes_delete_self | DELETE | ["authenticated"] | (( SELECT auth.uid() AS uid) = user_id) | — |
| post_likes_insert_self | INSERT | ["authenticated"] | — | (( SELECT auth.uid() AS uid) = user_id) |
| post_likes_read_public | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

| Name | Definition |
| --- | --- |
| post_likes_bump_count | CREATE TRIGGER post_likes_bump_count AFTER INSERT OR DELETE ON post_likes FOR EACH ROW EXECUTE FUNCTION bump_post_likes_count() |
| post_likes_notify | CREATE TRIGGER post_likes_notify AFTER INSERT ON post_likes FOR EACH ROW EXECUTE FUNCTION notify_on_post_like() |

## comment_likes

Unique user/comment reactions; triggers maintain comment counters.

Canonical declaration: [20260101000540_comment_likes.sql](../../supabase/migrations/20260101000540_comment_likes.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| like_id | uuid | False | gen_random_uuid() |
| comment_id | uuid | False | — |
| user_id | uuid | False | — |
| created_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| comment_likes_comment_id_fkey | FOREIGN KEY (comment_id) REFERENCES comments(comment_id) ON DELETE CASCADE | False / False |
| comment_likes_comment_id_user_id_key | UNIQUE (comment_id, user_id) | False / False |
| comment_likes_pkey | PRIMARY KEY (like_id) | False / False |
| comment_likes_user_id_fkey | FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| comment_likes_comment | CREATE INDEX comment_likes_comment ON public.comment_likes USING btree (comment_id) |
| comment_likes_comment_id_user_id_key | CREATE UNIQUE INDEX comment_likes_comment_id_user_id_key ON public.comment_likes USING btree (comment_id, user_id) |
| comment_likes_pkey | CREATE UNIQUE INDEX comment_likes_pkey ON public.comment_likes USING btree (like_id) |
| comment_likes_user | CREATE INDEX comment_likes_user ON public.comment_likes USING btree (user_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| comment_likes_delete_self | DELETE | ["authenticated"] | (( SELECT auth.uid() AS uid) = user_id) | — |
| comment_likes_insert_self | INSERT | ["authenticated"] | — | (( SELECT auth.uid() AS uid) = user_id) |
| comment_likes_read_public | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

| Name | Definition |
| --- | --- |
| comment_likes_bump_count | CREATE TRIGGER comment_likes_bump_count AFTER INSERT OR DELETE ON comment_likes FOR EACH ROW EXECUTE FUNCTION bump_comment_likes_count() |

## bookmarks

A user’s saved posts.

Canonical declaration: [20260101000550_bookmarks.sql](../../supabase/migrations/20260101000550_bookmarks.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| bookmark_id | uuid | False | gen_random_uuid() |
| user_id | uuid | False | — |
| post_id | uuid | False | — |
| created_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| bookmarks_pkey | PRIMARY KEY (bookmark_id) | False / False |
| bookmarks_post_id_fkey | FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE | False / False |
| bookmarks_user_id_fkey | FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |
| bookmarks_user_id_post_id_key | UNIQUE (user_id, post_id) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| bookmarks_pkey | CREATE UNIQUE INDEX bookmarks_pkey ON public.bookmarks USING btree (bookmark_id) |
| bookmarks_user_created | CREATE INDEX bookmarks_user_created ON public.bookmarks USING btree (user_id, created_at DESC) |
| bookmarks_user_id_post_id_key | CREATE UNIQUE INDEX bookmarks_user_id_post_id_key ON public.bookmarks USING btree (user_id, post_id) |
| idx_bookmarks_post_id | CREATE INDEX idx_bookmarks_post_id ON public.bookmarks USING btree (post_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| bookmarks_delete_self | DELETE | ["authenticated"] | (( SELECT auth.uid() AS uid) = user_id) | — |
| bookmarks_insert_self | INSERT | ["authenticated"] | — | (( SELECT auth.uid() AS uid) = user_id) |
| bookmarks_read_self | SELECT | ["authenticated"] | (( SELECT auth.uid() AS uid) = user_id) | — |

### Triggers

No non-system triggers attached.

## follows

Polymorphic social edges to a user, team or tournament. Notification mutes are stored separately.

Canonical declaration: [20260101000560_follows.sql](../../supabase/migrations/20260101000560_follows.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| follow_id | uuid | False | gen_random_uuid() |
| follower_id | uuid | False | — |
| target_type | follow_target_type | False | — |
| target_id | uuid | False | — |
| status | follow_status | False | 'active'::follow_status |
| created_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| follows_follower_id_fkey | FOREIGN KEY (follower_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |
| follows_follower_id_target_type_target_id_key | UNIQUE (follower_id, target_type, target_id) | False / False |
| follows_pkey | PRIMARY KEY (follow_id) | False / False |
| no_self_follow | CHECK (NOT (target_type = 'user'::follow_target_type AND target_id = follower_id)) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| follows_follower | CREATE INDEX follows_follower ON public.follows USING btree (follower_id) |
| follows_follower_id_target_type_target_id_key | CREATE UNIQUE INDEX follows_follower_id_target_type_target_id_key ON public.follows USING btree (follower_id, target_type, target_id) |
| follows_pkey | CREATE UNIQUE INDEX follows_pkey ON public.follows USING btree (follow_id) |
| follows_target | CREATE INDEX follows_target ON public.follows USING btree (target_type, target_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| follows_delete_self | DELETE | ["authenticated"] | (( SELECT auth.uid() AS uid) = follower_id) | — |
| follows_insert_self | INSERT | ["authenticated"] | — | (( SELECT auth.uid() AS uid) = follower_id) |
| follows_read_public | SELECT | ["anon", "authenticated"] | true | — |
| follows_update_self | UPDATE | ["authenticated"] | (( SELECT auth.uid() AS uid) = follower_id) | (( SELECT auth.uid() AS uid) = follower_id) |

### Triggers

| Name | Definition |
| --- | --- |
| follows_notify | CREATE TRIGGER follows_notify AFTER INSERT ON follows FOR EACH ROW EXECUTE FUNCTION notify_on_follow() |
