# Messaging: table reference

> Generated from a disposable migration replay on 2026-09-13. PostgreSQL 17.6. This describes source, not hosted deployment. Regenerate with `scripts/database/generate_docs.py`.


[Handbook](README.md) · [Architecture](architecture.md) · [Relationship diagrams](relationships.md)

## chats

Conversation identity, including team and direct-message contexts.

Canonical declaration: [20260101000800_chats.sql](../../supabase/migrations/20260101000800_chats.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| chat_id | uuid | False | gen_random_uuid() |
| type | chat_type | False | — |
| team_id | uuid | True | — |
| match_id | uuid | True | — |
| last_message_at | timestamp with time zone | True | — |
| created_at | timestamp with time zone | False | now() |
| updated_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| chats_match_id_fkey | FOREIGN KEY (match_id) REFERENCES matches(match_id) ON DELETE CASCADE | False / False |
| chats_match_match_id_required | CHECK (type = 'match'::chat_type AND match_id IS NOT NULL OR type <> 'match'::chat_type) | False / False |
| chats_pkey | PRIMARY KEY (chat_id) | False / False |
| chats_team_id_fkey | FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE CASCADE | False / False |
| chats_team_team_id_required | CHECK (type = 'team'::chat_type AND team_id IS NOT NULL OR type <> 'team'::chat_type) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| chats_last_message_at | CREATE INDEX chats_last_message_at ON public.chats USING btree (last_message_at DESC NULLS LAST) |
| chats_match_unique | CREATE UNIQUE INDEX chats_match_unique ON public.chats USING btree (match_id) WHERE (match_id IS NOT NULL) |
| chats_pkey | CREATE UNIQUE INDEX chats_pkey ON public.chats USING btree (chat_id) |
| chats_team_unique | CREATE UNIQUE INDEX chats_team_unique ON public.chats USING btree (team_id) WHERE (team_id IS NOT NULL) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| chats_read_members | SELECT | ["authenticated"] | is_chat_member(chat_id) | — |
| chats_update_admin | UPDATE | ["authenticated"] | (EXISTS ( SELECT 1<br>   FROM chat_members<br>  WHERE ((chat_members.chat_id = chats.chat_id) AND (chat_members.user_id = ( SELECT auth.uid() AS uid)) AND (chat_members.role = 'admin'::chat_role) AND (chat_members.left_at IS NULL)))) | (EXISTS ( SELECT 1<br>   FROM chat_members<br>  WHERE ((chat_members.chat_id = chats.chat_id) AND (chat_members.user_id = ( SELECT auth.uid() AS uid)) AND (chat_members.role = 'admin'::chat_role) AND (chat_members.left_at IS NULL)))) |

### Triggers

| Name | Definition |
| --- | --- |
| chats_set_updated_at | CREATE TRIGGER chats_set_updated_at BEFORE UPDATE ON chats FOR EACH ROW EXECUTE FUNCTION set_updated_at() |

## chat_members

Per-user conversation membership, role and read/membership lifecycle.

Canonical declaration: [20260101000801_chat_members.sql](../../supabase/migrations/20260101000801_chat_members.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| membership_id | uuid | False | gen_random_uuid() |
| chat_id | uuid | False | — |
| user_id | uuid | False | — |
| role | chat_role | False | 'member'::chat_role |
| joined_at | timestamp with time zone | False | now() |
| left_at | timestamp with time zone | True | — |
| last_read_at | timestamp with time zone | True | — |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| chat_members_chat_id_fkey | FOREIGN KEY (chat_id) REFERENCES chats(chat_id) ON DELETE CASCADE | False / False |
| chat_members_pkey | PRIMARY KEY (membership_id) | False / False |
| chat_members_user_id_fkey | FOREIGN KEY (user_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |
| chat_members_user_unique | UNIQUE (chat_id, user_id) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| chat_members_active_chat_user | CREATE INDEX chat_members_active_chat_user ON public.chat_members USING btree (chat_id, user_id) WHERE (left_at IS NULL) |
| chat_members_chat | CREATE INDEX chat_members_chat ON public.chat_members USING btree (chat_id) |
| chat_members_pkey | CREATE UNIQUE INDEX chat_members_pkey ON public.chat_members USING btree (membership_id) |
| chat_members_user | CREATE INDEX chat_members_user ON public.chat_members USING btree (user_id) |
| chat_members_user_unique | CREATE UNIQUE INDEX chat_members_user_unique ON public.chat_members USING btree (chat_id, user_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| chat_members_read_self_or_chat | SELECT | ["authenticated"] | ((user_id = ( SELECT auth.uid() AS uid)) OR is_chat_member(chat_id)) | — |
| chat_members_update_self_or_admin | UPDATE | ["authenticated"] | ((user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1<br>   FROM chat_members admin<br>  WHERE ((admin.chat_id = chat_members.chat_id) AND (admin.user_id = ( SELECT auth.uid() AS uid)) AND (admin.role = 'admin'::chat_role) AND (admin.left_at IS NULL))))) | ((user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1<br>   FROM chat_members admin<br>  WHERE ((admin.chat_id = chat_members.chat_id) AND (admin.user_id = ( SELECT auth.uid() AS uid)) AND (admin.role = 'admin'::chat_role) AND (admin.left_at IS NULL))))) |

### Triggers

| Name | Definition |
| --- | --- |
| chat_members_before_update_role_guard | CREATE TRIGGER chat_members_before_update_role_guard BEFORE UPDATE ON chat_members FOR EACH ROW EXECUTE FUNCTION guard_chat_members_role_change() |

## messages

Persisted conversation messages and their lifecycle; Broadcast signals update clients.

Canonical declaration: [20260101000802_messages.sql](../../supabase/migrations/20260101000802_messages.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| message_id | uuid | False | gen_random_uuid() |
| chat_id | uuid | False | — |
| sender_id | uuid | True | — |
| body | text | False | — |
| message_type | text | False | 'text'::text |
| payload | jsonb | True | '{}'::jsonb |
| reply_to_id | uuid | True | — |
| created_at | timestamp with time zone | False | now() |
| edited_at | timestamp with time zone | True | — |
| deleted_at | timestamp with time zone | True | — |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| messages_body_check | CHECK (length(body) >= 1 AND length(body) <= 4000) | False / False |
| messages_chat_id_fkey | FOREIGN KEY (chat_id) REFERENCES chats(chat_id) ON DELETE CASCADE | False / False |
| messages_pkey | PRIMARY KEY (message_id) | False / False |
| messages_reply_to_id_fkey | FOREIGN KEY (reply_to_id) REFERENCES messages(message_id) ON DELETE SET NULL | False / False |
| messages_sender_id_fkey | FOREIGN KEY (sender_id) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_messages_sender_id | CREATE INDEX idx_messages_sender_id ON public.messages USING btree (sender_id) |
| messages_chat_created | CREATE INDEX messages_chat_created ON public.messages USING btree (chat_id, created_at DESC) |
| messages_pkey | CREATE UNIQUE INDEX messages_pkey ON public.messages USING btree (message_id) |
| messages_reply_to | CREATE INDEX messages_reply_to ON public.messages USING btree (reply_to_id) WHERE (reply_to_id IS NOT NULL) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| messages_insert_self | INSERT | ["authenticated"] | — | ((sender_id = ( SELECT auth.uid() AS uid)) AND is_chat_member(chat_id)) |
| messages_read_for_members | SELECT | ["authenticated"] | is_chat_member(chat_id) | — |
| messages_update_own | UPDATE | ["authenticated"] | (sender_id = ( SELECT auth.uid() AS uid)) | ((sender_id = ( SELECT auth.uid() AS uid)) AND ((edited_at IS NULL) OR (deleted_at IS NULL))) |

### Triggers

| Name | Definition |
| --- | --- |
| messages_after_insert_bump_chat | CREATE TRIGGER messages_after_insert_bump_chat AFTER INSERT ON messages FOR EACH ROW EXECUTE FUNCTION bump_chat_last_message_at() |
| messages_before_insert_dm_request_guard | CREATE TRIGGER messages_before_insert_dm_request_guard BEFORE INSERT ON messages FOR EACH ROW EXECUTE FUNCTION guard_dm_message_request_limit() |

## dm_channels

Canonical user-pair mapping for direct-message conversations.

Canonical declaration: [20260101000803_dm_channels.sql](../../supabase/migrations/20260101000803_dm_channels.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| chat_id | uuid | False | — |
| user_a | uuid | False | — |
| user_b | uuid | False | — |
| created_at | timestamp with time zone | False | now() |
| accepted_at | timestamp with time zone | True | — |
| accepted_by | uuid | True | — |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| dm_channels_accepted_by_fkey | FOREIGN KEY (accepted_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| dm_channels_chat_id_fkey | FOREIGN KEY (chat_id) REFERENCES chats(chat_id) ON DELETE CASCADE | False / False |
| dm_channels_pkey | PRIMARY KEY (chat_id) | False / False |
| dm_channels_unique_pair | UNIQUE (user_a, user_b) | False / False |
| dm_channels_user_a_fkey | FOREIGN KEY (user_a) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |
| dm_channels_user_b_fkey | FOREIGN KEY (user_b) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |
| dm_channels_users_order | CHECK (user_a < user_b) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| dm_channels_pkey | CREATE UNIQUE INDEX dm_channels_pkey ON public.dm_channels USING btree (chat_id) |
| dm_channels_unique_pair | CREATE UNIQUE INDEX dm_channels_unique_pair ON public.dm_channels USING btree (user_a, user_b) |
| dm_channels_user_a | CREATE INDEX dm_channels_user_a ON public.dm_channels USING btree (user_a) |
| dm_channels_user_b | CREATE INDEX dm_channels_user_b ON public.dm_channels USING btree (user_b) |
| idx_dm_channels_accepted_by | CREATE INDEX idx_dm_channels_accepted_by ON public.dm_channels USING btree (accepted_by) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| dm_channels_read_members | SELECT | ["authenticated"] | ((user_a = ( SELECT auth.uid() AS uid)) OR (user_b = ( SELECT auth.uid() AS uid))) | — |

### Triggers

No non-system triggers attached.
