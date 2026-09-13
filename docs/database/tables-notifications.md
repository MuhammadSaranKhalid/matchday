# Notifications: table reference

> Generated from a disposable migration replay on 2026-09-13. PostgreSQL 17.6. This describes source, not hosted deployment. Regenerate with `scripts/database/generate_docs.py`.


[Handbook](README.md) · [Architecture](architecture.md) · [Relationship diagrams](relationships.md)

## notification_icons

Admin-owned icon identity, immutable Storage path and upstream/license/checksum metadata.

Canonical declaration: [20260101000489_notification_icons.sql](../../supabase/migrations/20260101000489_notification_icons.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| key | text | False | — |
| storage_path | text | False | — |
| source_library | text | False | — |
| source_version | text | False | — |
| license | text | False | — |
| sha256 | text | False | — |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| notification_icons_key_check | CHECK (key ~ '^[a-z_]+$'::text) | False / False |
| notification_icons_pkey | PRIMARY KEY (key) | False / False |
| notification_icons_sha256_check | CHECK (sha256 ~ '^[0-9a-f]{64}$'::text) | False / False |
| notification_icons_storage_path_check | CHECK (storage_path ~ '^v[0-9]+/[a-z0-9-]+[.]svg$'::text) | False / False |
| notification_icons_storage_path_key | UNIQUE (storage_path) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| notification_icons_pkey | CREATE UNIQUE INDEX notification_icons_pkey ON public.notification_icons USING btree (key) |
| notification_icons_storage_path_key | CREATE UNIQUE INDEX notification_icons_storage_path_key ON public.notification_icons USING btree (storage_path) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | False | False | False |
| authenticated | True | False | False | False | False | False | False |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| notification_icons_read_all | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

No non-system triggers attached.

## notification_categories

Preference group names and ordering.

Canonical declaration: [20260101000490_notification_categories.sql](../../supabase/migrations/20260101000490_notification_categories.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| key | text | False | — |
| name | text | False | — |
| description | text | True | — |
| sort_order | integer | False | 0 |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| notification_categories_key_check | CHECK (key ~ '^[a-z]+$'::text) | False / False |
| notification_categories_pkey | PRIMARY KEY (key) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| notification_categories_pkey | CREATE UNIQUE INDEX notification_categories_pkey ON public.notification_categories USING btree (key) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | False | False | False |
| authenticated | True | False | False | False | False | False | False |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| notification_categories_read_all | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

No non-system triggers attached.

## notification_types

Data-driven templates, routes, presentation, channels and coalescing rules.

Canonical declaration: [20260101000491_notification_types.sql](../../supabase/migrations/20260101000491_notification_types.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| key | text | False | — |
| category | text | False | — |
| title_template | text | False | — |
| body_template | text | False | — |
| body_template_grouped | text | True | — |
| route_template | text | True | — |
| icon | text | False | — |
| tone | text | False | 'neutral'::text |
| tier | text | False | 'fyi'::text |
| importance | text | False | 'normal'::text |
| queue_name | text | False | 'notifications_push'::text |
| collapse_template | text | True | — |
| collapse_window | interval | True | — |
| default_channels | text[] | False | '{inapp,push}'::text[] |
| user_configurable | boolean | False | true |
| is_active | boolean | False | true |
| created_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| notification_types_category_fkey | FOREIGN KEY (category) REFERENCES notification_categories(key) | False / False |
| notification_types_collapse_coherent | CHECK (collapse_template IS NULL AND collapse_window IS NULL AND body_template_grouped IS NULL OR collapse_template IS NOT NULL AND collapse_window IS NOT NULL AND collapse_window > '00:00:00'::interval) | False / False |
| notification_types_default_channels_check | CHECK (default_channels <@ ARRAY['inapp'::text, 'push'::text]) | False / False |
| notification_types_icon_fkey | FOREIGN KEY (icon) REFERENCES notification_icons(key) | False / False |
| notification_types_importance_check | CHECK (importance = ANY (ARRAY['high'::text, 'normal'::text, 'low'::text])) | False / False |
| notification_types_key_check | CHECK (key ~ '^[a-z]+(\.[a-z_]+){1,3}$'::text) | False / False |
| notification_types_key_matches_category | CHECK (split_part(key, '.'::text, 1) = category) | False / False |
| notification_types_pkey | PRIMARY KEY (key) | False / False |
| notification_types_queue_name_check | CHECK (queue_name = ANY (ARRAY['notifications_push'::text, 'notifications_push_bulk'::text])) | False / False |
| notification_types_tier_check | CHECK (tier = ANY (ARRAY['now'::text, 'week'::text, 'fyi'::text])) | False / False |
| notification_types_tone_check | CHECK (tone = ANY (ARRAY['neutral'::text, 'brand'::text, 'success'::text, 'warning'::text, 'achievement'::text, 'danger'::text])) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| notification_types_category | CREATE INDEX notification_types_category ON public.notification_types USING btree (category) |
| notification_types_icon | CREATE INDEX notification_types_icon ON public.notification_types USING btree (icon) |
| notification_types_pkey | CREATE UNIQUE INDEX notification_types_pkey ON public.notification_types USING btree (key) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | False | False | False |
| authenticated | True | False | False | False | False | False | False |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| notification_types_read_all | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

No non-system triggers attached.

## notifications

Per-recipient rendered inbox snapshots, unread state and event-group revision.

Canonical declaration: [20260101000500_notifications.sql](../../supabase/migrations/20260101000500_notifications.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| notification_id | uuid | False | gen_random_uuid() |
| recipient_id | uuid | False | — |
| type_key | text | False | — |
| title | text | False | — |
| body | text | False | — |
| route | text | True | — |
| tier | text | False | 'fyi'::text |
| icon | text | False | 'bell'::text |
| icon_path | text | False | 'v1/bell.svg'::text |
| tone | text | False | 'neutral'::text |
| actor_id | uuid | True | — |
| entity_scope | text | True | — |
| entity_id | uuid | True | — |
| payload | jsonb | False | '{}'::jsonb |
| collapse_key | text | True | — |
| collapse_until | timestamp with time zone | True | — |
| group_count | integer | False | 1 |
| is_read | boolean | False | false |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| notifications_actor_id_fkey | FOREIGN KEY (actor_id) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| notifications_entity_complete | CHECK ((entity_scope IS NULL) = (entity_id IS NULL)) | False / False |
| notifications_entity_scope_check | CHECK (entity_scope = ANY (ARRAY['team'::text, 'match'::text, 'tournament'::text, 'post'::text, 'chat'::text, 'user'::text])) | False / False |
| notifications_group_count_check | CHECK (group_count >= 1) | False / False |
| notifications_pkey | PRIMARY KEY (notification_id) | False / False |
| notifications_recipient_id_fkey | FOREIGN KEY (recipient_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |
| notifications_tier_check | CHECK (tier = ANY (ARRAY['now'::text, 'week'::text, 'fyi'::text])) | False / False |
| notifications_tone_check | CHECK (tone = ANY (ARRAY['neutral'::text, 'brand'::text, 'success'::text, 'warning'::text, 'achievement'::text, 'danger'::text])) | False / False |
| notifications_type_key_fkey | FOREIGN KEY (type_key) REFERENCES notification_types(key) ON UPDATE CASCADE ON DELETE RESTRICT | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| notifications_actor | CREATE INDEX notifications_actor ON public.notifications USING btree (actor_id) |
| notifications_collapse | CREATE UNIQUE INDEX notifications_collapse ON public.notifications USING btree (recipient_id, collapse_key) WHERE ((collapse_key IS NOT NULL) AND (is_read = false)) |
| notifications_pkey | CREATE UNIQUE INDEX notifications_pkey ON public.notifications USING btree (notification_id) |
| notifications_recipient_created | CREATE INDEX notifications_recipient_created ON public.notifications USING btree (recipient_id, created_at DESC, notification_id DESC) |
| notifications_recipient_unread | CREATE INDEX notifications_recipient_unread ON public.notifications USING btree (recipient_id, created_at DESC) WHERE (is_read = false) |
| notifications_type_key | CREATE INDEX notifications_type_key ON public.notifications USING btree (type_key) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | False | False | False | False | False | False | False |
| authenticated | True | False | False | True | False | False | False |
| service_role | True | True | True | True | True | True | True |

Column-only grants (not implied by table-wide access):

| Role | Column | Privilege |
| --- | --- | --- |
| authenticated | is_read | UPDATE |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| notifications_delete_self | DELETE | ["authenticated"] | (( SELECT auth.uid() AS uid) = recipient_id) | — |
| notifications_read_self | SELECT | ["authenticated"] | (( SELECT auth.uid() AS uid) = recipient_id) | — |
| notifications_update_self | UPDATE | ["authenticated"] | (( SELECT auth.uid() AS uid) = recipient_id) | (( SELECT auth.uid() AS uid) = recipient_id) |

### Triggers

| Name | Definition |
| --- | --- |
| notifications_after_delete_broadcast | CREATE TRIGGER notifications_after_delete_broadcast AFTER DELETE ON notifications FOR EACH ROW EXECUTE FUNCTION broadcast_notification_deleted() |
| notifications_after_insert_broadcast | CREATE TRIGGER notifications_after_insert_broadcast AFTER INSERT ON notifications FOR EACH ROW EXECUTE FUNCTION broadcast_new_notification() |
| notifications_after_update_broadcast | CREATE TRIGGER notifications_after_update_broadcast AFTER UPDATE ON notifications FOR EACH ROW WHEN (old.is_read IS DISTINCT FROM new.is_read OR old.group_count IS DISTINCT FROM new.group_count) EXECUTE FUNCTION broadcast_notification_updated() |
| notifications_set_updated_at | CREATE TRIGGER notifications_set_updated_at BEFORE UPDATE ON notifications FOR EACH ROW EXECUTE FUNCTION set_updated_at() |

## notification_preferences

Sparse per-user/category/channel overrides; absence preserves catalogue defaults.

Canonical declaration: [20260101000501_notification_preferences.sql](../../supabase/migrations/20260101000501_notification_preferences.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| user_id | uuid | False | — |
| category | text | False | — |
| channel | text | False | — |
| enabled | boolean | False | — |
| updated_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| notification_preferences_category_fkey | FOREIGN KEY (category) REFERENCES notification_categories(key) ON DELETE CASCADE | False / False |
| notification_preferences_channel_check | CHECK (channel = ANY (ARRAY['inapp'::text, 'push'::text])) | False / False |
| notification_preferences_pkey | PRIMARY KEY (user_id, category, channel) | False / False |
| notification_preferences_user_id_fkey | FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| notification_preferences_category | CREATE INDEX notification_preferences_category ON public.notification_preferences USING btree (category) |
| notification_preferences_pkey | CREATE UNIQUE INDEX notification_preferences_pkey ON public.notification_preferences USING btree (user_id, category, channel) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | False | False | False | False | False | False | False |
| authenticated | True | True | True | True | False | False | False |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| notification_preferences_delete_self | DELETE | ["authenticated"] | (( SELECT auth.uid() AS uid) = user_id) | — |
| notification_preferences_insert_self | INSERT | ["authenticated"] | — | (( SELECT auth.uid() AS uid) = user_id) |
| notification_preferences_select_self | SELECT | ["authenticated"] | (( SELECT auth.uid() AS uid) = user_id) | — |
| notification_preferences_update_self | UPDATE | ["authenticated"] | (( SELECT auth.uid() AS uid) = user_id) | (( SELECT auth.uid() AS uid) = user_id) |

### Triggers

| Name | Definition |
| --- | --- |
| notification_preferences_set_updated_at | CREATE TRIGGER notification_preferences_set_updated_at BEFORE UPDATE ON notification_preferences FOR EACH ROW EXECUTE FUNCTION set_updated_at() |

## notification_mutes

Per-user scoped entity mutes and snoozes, including the follow bell.

Canonical declaration: [20260101000502_notification_mutes.sql](../../supabase/migrations/20260101000502_notification_mutes.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| user_id | uuid | False | — |
| scope | text | False | — |
| entity_id | uuid | False | — |
| muted_until | timestamp with time zone | True | — |
| created_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| notification_mutes_pkey | PRIMARY KEY (user_id, scope, entity_id) | False / False |
| notification_mutes_scope_check | CHECK (scope = ANY (ARRAY['team'::text, 'match'::text, 'tournament'::text, 'post'::text, 'chat'::text, 'user'::text])) | False / False |
| notification_mutes_user_id_fkey | FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| notification_mutes_entity | CREATE INDEX notification_mutes_entity ON public.notification_mutes USING btree (scope, entity_id) |
| notification_mutes_pkey | CREATE UNIQUE INDEX notification_mutes_pkey ON public.notification_mutes USING btree (user_id, scope, entity_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | False | False | False | False | False | False | False |
| authenticated | True | True | True | True | False | False | False |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| notification_mutes_delete_self | DELETE | ["authenticated"] | (( SELECT auth.uid() AS uid) = user_id) | — |
| notification_mutes_insert_self | INSERT | ["authenticated"] | — | (( SELECT auth.uid() AS uid) = user_id) |
| notification_mutes_select_self | SELECT | ["authenticated"] | (( SELECT auth.uid() AS uid) = user_id) | — |
| notification_mutes_update_self | UPDATE | ["authenticated"] | (( SELECT auth.uid() AS uid) = user_id) | (( SELECT auth.uid() AS uid) = user_id) |

### Triggers

No non-system triggers attached.

## notification_deliveries

Actual per-device/revision delivery outcomes. Queues own leases; this table does not.

Canonical declaration: [20260101000503_notification_deliveries.sql](../../supabase/migrations/20260101000503_notification_deliveries.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| notification_id | uuid | False | — |
| revision | integer | False | — |
| device_key | text | False | — |
| channel | text | False | 'push'::text |
| status | text | False | — |
| attempts | integer | False | 0 |
| error | text | True | — |
| retryable | boolean | False | false |
| provider_message_id | text | True | — |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| notification_deliveries_attempts_check | CHECK (attempts >= 0) | False / False |
| notification_deliveries_channel_check | CHECK (channel = 'push'::text) | False / False |
| notification_deliveries_notification_id_fkey | FOREIGN KEY (notification_id) REFERENCES notifications(notification_id) ON DELETE CASCADE | False / False |
| notification_deliveries_pkey | PRIMARY KEY (notification_id, revision, device_key, channel) | False / False |
| notification_deliveries_revision_check | CHECK (revision >= 1) | False / False |
| notification_deliveries_status_check | CHECK (status = ANY (ARRAY['sent'::text, 'failed'::text, 'skipped_pref'::text, 'skipped_mute'::text, 'no_token'::text, 'invalid_token'::text, 'superseded'::text])) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| notification_deliveries_failed | CREATE INDEX notification_deliveries_failed ON public.notification_deliveries USING btree (updated_at DESC) WHERE (status = 'failed'::text) |
| notification_deliveries_pkey | CREATE UNIQUE INDEX notification_deliveries_pkey ON public.notification_deliveries USING btree (notification_id, revision, device_key, channel) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | False | False | False | False | False | False | False |
| authenticated | False | False | False | False | False | False | False |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| notification_deliveries_service | ALL | ["service_role"] | true | true |

### Triggers

| Name | Definition |
| --- | --- |
| notification_deliveries_set_updated_at | CREATE TRIGGER notification_deliveries_set_updated_at BEFORE UPDATE ON notification_deliveries FOR EACH ROW EXECUTE FUNCTION set_updated_at() |

## device_tokens

Push destinations registered by the owning user; read by the trusted delivery worker.

Canonical declaration: [20260101000900_device_tokens.sql](../../supabase/migrations/20260101000900_device_tokens.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| token_id | uuid | False | gen_random_uuid() |
| user_id | uuid | False | — |
| fcm_token | text | False | — |
| platform | text | False | — |
| app_version | text | True | — |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |
| last_seen_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| device_tokens_pkey | PRIMARY KEY (token_id) | False / False |
| device_tokens_platform_check | CHECK (platform = ANY (ARRAY['ios'::text, 'android'::text, 'web'::text])) | False / False |
| device_tokens_unique_token | UNIQUE (fcm_token) | False / False |
| device_tokens_user_id_fkey | FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| device_tokens_last_seen | CREATE INDEX device_tokens_last_seen ON public.device_tokens USING btree (last_seen_at) |
| device_tokens_pkey | CREATE UNIQUE INDEX device_tokens_pkey ON public.device_tokens USING btree (token_id) |
| device_tokens_unique_token | CREATE UNIQUE INDEX device_tokens_unique_token ON public.device_tokens USING btree (fcm_token) |
| device_tokens_user | CREATE INDEX device_tokens_user ON public.device_tokens USING btree (user_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| device_tokens_self_delete | DELETE | ["authenticated"] | (( SELECT auth.uid() AS uid) = user_id) | — |
| device_tokens_self_insert | INSERT | ["authenticated"] | — | (( SELECT auth.uid() AS uid) = user_id) |
| device_tokens_self_select | SELECT | ["authenticated"] | (( SELECT auth.uid() AS uid) = user_id) | — |
| device_tokens_self_update | UPDATE | ["authenticated"] | (( SELECT auth.uid() AS uid) = user_id) | (( SELECT auth.uid() AS uid) = user_id) |

### Triggers

| Name | Definition |
| --- | --- |
| device_tokens_set_updated_at | CREATE TRIGGER device_tokens_set_updated_at BEFORE UPDATE ON device_tokens FOR EACH ROW EXECUTE FUNCTION set_updated_at() |
