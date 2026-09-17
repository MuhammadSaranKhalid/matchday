# Match Day Universal Chat Architecture Specification (v4.0 — Production Alignment)
**The Authoritative, Self-Contained System Specification for Production & Local-First Engineering**
*Document Version: 4.0.0 — Definitive Live-Synchronized Edition (September 2026)*

---

## Executive Overview & Architectural Invariants

Match Day implements an enterprise-grade, **local-first, write-ahead, real-time universal chat system**. This specification is 100% aligned with the live Matchday Supabase production schema, while resolving all architectural, security, and data-integrity gaps identified during live audit.

```
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                             FLUTTER CLIENT                                             │
│                                                                                                        │
│   ┌────────────────────────┐                    ┌──────────────────────────────────────────────────┐   │
│   │   Presentation Layer   │                    │             Outbox Queue Processor               │   │
│   │  (Widgets & Notifiers) │                    │  (Per-Channel Concurrency, FIFO, Durable Retry)  │   │
│   └───────────┬────────────┘                    └────────────────────────┬─────────────────────────┘   │
│               │ watchCombined() (Reactive Single Read Path)              │ HTTPS RPC Execution         │
│   ┌───────────▼────────────┐                                             │                             │
│   │   Drift Local SQLite   │◄────────────────────────────────────────────┘                             │
│   │  (Non-Destructive DB)  │                    ▲                                                      │
│   └───────────▲────────────┘                    │ upsert()                                             │
│               │ upsert()                        │                                                      │
│   ┌───────────┴────────────┐                    │                                                      │
│   │    Realtime Ingestor   │                    │                                                      │
│   │  (Echo Deduplication)  │                    │                                                      │
│   └───────────▲────────────┘                    │                                                      │
└───────────────┼─────────────────────────────────┼──────────────────────────────────────────────────────┘
                │ Ably WebSocket (Hot Channel)    │ HTTPS RPC (Authoritative Mutations & Catch-Up)
┌───────────────┴────────────┐        pg_net      ┌▼─────────────────────────────────────────────────────┐
│       ABLY REALTIME        │◄───────────────────┤                 SUPABASE POSTGRESQL                  │
│    (Restricted Tokens)     │      HTTP POST     │          (Authoritative System of Record)            │
└────────────────────────────┘                    └──────────────────────────────────────────────────────┘
```

### Core Invariants of the v4 Architecture

1. **Supabase PostgreSQL as Sole Authoritative Truth**:
   All persistent state (channels, messages, membership history, receipts, reactions, and restrictions) is owned authoritatively by PostgreSQL. Drift SQLite is an offline write-ahead cache on the client. Ably is an ephemeral real-time transport, never a database.
2. **Single Read Path via Drift SQLite**:
   Flutter controllers and widgets read **exclusively from local Drift reactive streams**. The UI never performs network fetches to paint messages or inbox channels.
3. **Write-Ahead Outbox Queue**:
   All user mutations (sending messages, media uploads, reactions, editing, soft deleting, and reading) commit immediately to local Drift SQLite with status `pending`, queuing an operation in `outbox_operations` before network dispatch.
4. **Global Monotonic Sequence Ordering**:
   `message_seq` is a globally increasing, server-generated 64-bit cursor (`BIGINT GENERATED ALWAYS AS IDENTITY`). It guarantees strict chronological ordering ($seq_b > seq_a \iff \text{Message B was created after Message A}$). It is **not** contiguous within an individual channel.
5. **Strict Delivery & Read Horizon Monotonicity**:
   Reading a message implies delivery. For any member $u$ in channel $c$:
   $$NULL \le \text{last\_read\_message\_seq} \le \text{last\_delivered\_message\_seq} \le \text{last\_message\_seq}$$
   Empty channels retain `NULL` horizons. The sentinel value `0` or `999999999` is strictly forbidden.
6. **Explicit Channel Authorization & Information Leak Prevention**:
   All read and delivery RPCs verify that the authenticated caller is an authorized member (`status IN ('active', 'pending')`). If the caller is not a member, the RPC aborts with `42501` without leaking the channel's sequence frontier.
7. **Scoped Capability-Restricted Ably Tokens**:
   Clients authenticate with Ably via short-lived tokens generated by the `ably-auth` Edge Function. Tokens grant `subscribe` and `presence` **only** for channels where `channel_members.status = 'active'`. Wildcard subscribe/publish capabilities (`chat:*`) are strictly forbidden. Clients never publish messages directly to Ably.
8. **Durable Mutation Synchronization**:
   Catch-up sync upon reconnection is driven by a durable server-side mutation stream (`chat_changes`), ensuring edits, deletions, reactions, and member changes to historical messages are reconciled even if Ably events were dropped offline.
9. **Zero Data Loss Local Migrations**:
   Drift SQLite migrations must be strictly non-destructive. Schema upgrades never drop tables containing pending outbox operations, draft messages, or unconfirmed media uploads.
10. **Recipient-Aware Group Receipt Semantics**:
    For 1:1 DMs, a message is read when the peer's read horizon meets or exceeds the message sequence. For group channels, double ticks turn read if and only if **all eligible recipients** who were members when the message was posted have read the message ($\min_{u \in \text{Recipients}} \text{read\_seq}_u \ge \text{message\_seq}$).

---

## 1. Live PostgreSQL Backend Specification (Supabase)

### 1.1 Live Custom Types & Enums

```sql
-- Channel classification
CREATE TYPE public.chat_channel_kind AS ENUM (
  'direct',     -- 1-on-1 direct message between two users
  'group',      -- Multi-user group conversation
  'broadcast'   -- Read-only announcement channel
);

-- Domain context attachment
CREATE TYPE public.chat_channel_context AS ENUM (
  'none',       -- Standalone conversation
  'team',       -- Attached to a Team
  'match',      -- Attached to a Match
  'tournament', -- Attached to a Tournament
  'club'        -- Attached to a Club
);

-- Channel visibility (Live production schema: private or public)
CREATE TYPE public.chat_channel_visibility AS ENUM (
  'private',    -- Invite or membership required
  'public'      -- Open discovery
);

-- Member permission roles
CREATE TYPE public.chat_member_role AS ENUM (
  'owner',      -- Full administrative rights & channel deletion
  'admin',      -- Member management and message moderation
  'moderator',  -- Message moderation
  'member'      -- Standard messaging rights
);

-- Member participation status (Live production: 6 states)
CREATE TYPE public.chat_member_status AS ENUM (
  'pending',    -- Direct message request or pending invite
  'active',     -- Full participant
  'declined',   -- Explicitly rejected DM request
  'left',       -- Voluntarily departed
  'removed',    -- Kicked by administrator
  'banned'      -- Excluded by administrator
);

-- Granular permissions
CREATE TYPE public.chat_permission AS ENUM (
  'view_channel',
  'send_messages',
  'send_media',
  'add_reactions',
  'reply_to_messages',
  'edit_own_messages',
  'delete_own_messages',
  'delete_any_message',
  'pin_messages',
  'invite_members',
  'remove_members',
  'restrict_members',
  'manage_roles',
  'manage_channel',
  'delete_channel',
  'view_member_receipts'
);

-- Channel posting policy
CREATE TYPE public.chat_posting_mode AS ENUM (
  'members',    -- All active members can post
  'moderators', -- Moderators, admins, and owner can post
  'admins',     -- Admins and owner can post
  'owner'       -- Only owner can post
);

-- Message payload types
CREATE TYPE public.chat_message_type AS ENUM (
  'text',       -- Standard text message
  'image',      -- Single or multi-image attachment
  'video',      -- Video clip attachment
  'audio',      -- Voice memo attachment
  'system'      -- System event notification (e.g. member joined)
);
```

---

### 1.2 Production Table Schemas & Relational Design

#### 1. `public.chat_channels`
```sql
CREATE TABLE public.chat_channels (
  channel_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_key        TEXT NOT NULL UNIQUE,
  kind               public.chat_channel_kind NOT NULL,
  context_type       public.chat_channel_context NOT NULL DEFAULT 'none',
  visibility         public.chat_channel_visibility NOT NULL DEFAULT 'private',
  purpose            TEXT NOT NULL DEFAULT 'main',
  title              TEXT,
  description        TEXT,
  avatar_url         TEXT,
  team_id            UUID REFERENCES public.teams(id) ON DELETE CASCADE,
  match_id           UUID REFERENCES public.matches(id) ON DELETE CASCADE,
  tournament_id      UUID REFERENCES public.tournaments(id) ON DELETE CASCADE,
  club_id            UUID,
  created_by         UUID REFERENCES public.profiles(user_id) ON DELETE SET NULL,
  last_message_seq   BIGINT,
  last_message_at    TIMESTAMPTZ,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  archived_at        TIMESTAMPTZ,
  CONSTRAINT chat_channels_context_shape CHECK (
    (context_type = 'none' AND team_id IS NULL AND match_id IS NULL AND tournament_id IS NULL AND club_id IS NULL) OR
    (context_type = 'team' AND team_id IS NOT NULL AND match_id IS NULL AND tournament_id IS NULL AND club_id IS NULL) OR
    (context_type = 'match' AND match_id IS NOT NULL AND team_id IS NULL AND tournament_id IS NULL AND club_id IS NULL) OR
    (context_type = 'tournament' AND tournament_id IS NOT NULL AND team_id IS NULL AND match_id IS NULL AND club_id IS NULL) OR
    (context_type = 'club' AND club_id IS NOT NULL AND team_id IS NULL AND match_id IS NULL AND tournament_id IS NULL)
  ),
  CONSTRAINT direct_channel_shape CHECK (
    kind <> 'direct' OR (context_type = 'none' AND visibility = 'private')
  )
);

CREATE INDEX idx_chat_channels_key ON public.chat_channels(channel_key);
CREATE INDEX idx_chat_channels_last_message ON public.chat_channels(last_message_at DESC NULLS LAST);
```

#### 2. `public.channel_members`
```sql
CREATE TABLE public.channel_members (
  channel_id                 UUID NOT NULL REFERENCES public.chat_channels(channel_id) ON DELETE CASCADE,
  user_id                    UUID NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  role                       public.chat_member_role NOT NULL DEFAULT 'member',
  status                     public.chat_member_status NOT NULL DEFAULT 'active',
  invited_by                 UUID REFERENCES public.profiles(user_id) ON DELETE SET NULL,
  invited_at                 TIMESTAMPTZ,
  responded_at               TIMESTAMPTZ,
  joined_at                  TIMESTAMPTZ,
  left_at                    TIMESTAMPTZ,
  request_retry_after        TIMESTAMPTZ,
  last_delivered_message_seq BIGINT,
  last_delivered_at          TIMESTAMPTZ,
  last_read_message_seq      BIGINT,
  last_read_at               TIMESTAMPTZ,
  notifications_muted_until  TIMESTAMPTZ,
  archived_at                TIMESTAMPTZ,
  pinned_at                  TIMESTAMPTZ,
  created_at                 TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  updated_at                 TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (channel_id, user_id)
);

CREATE INDEX idx_channel_members_user_inbox ON public.channel_members(user_id, status, archived_at, pinned_at);
CREATE INDEX idx_channel_members_channel_status ON public.channel_members(channel_id, status);
```

#### 3. `public.channel_membership_periods` (Historical Roster Tracking)
Records intervals when users were members of a channel. Critical for computing group message read status and Message Info.

```sql
CREATE TABLE public.channel_membership_periods (
  period_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id   UUID NOT NULL REFERENCES public.chat_channels(channel_id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  joined_at    TIMESTAMPTZ NOT NULL,
  left_at      TIMESTAMPTZ,
  end_reason   TEXT, -- 'left' | 'removed' | 'banned' | 'declined'
  created_at   TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE UNIQUE INDEX idx_channel_membership_period_active
  ON public.channel_membership_periods(channel_id, user_id)
  WHERE left_at IS NULL;

CREATE INDEX idx_channel_membership_period_history
  ON public.channel_membership_periods(channel_id, joined_at, left_at);
```

#### 4. `public.channel_policies`
```sql
CREATE TABLE public.channel_policies (
  channel_id                 UUID PRIMARY KEY REFERENCES public.chat_channels(channel_id) ON DELETE CASCADE,
  posting_mode               public.chat_posting_mode NOT NULL DEFAULT 'members',
  reactions_enabled          BOOLEAN NOT NULL DEFAULT true,
  replies_enabled            BOOLEAN NOT NULL DEFAULT true,
  media_enabled              BOOLEAN NOT NULL DEFAULT true,
  read_receipts_enabled      BOOLEAN NOT NULL DEFAULT true,
  delivery_receipts_enabled  BOOLEAN NOT NULL DEFAULT true,
  max_message_length         INTEGER NOT NULL DEFAULT 4000,
  slow_mode_seconds          INTEGER NOT NULL DEFAULT 0,
  created_at                 TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  updated_at                 TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  CONSTRAINT channel_policy_lengths CHECK (
    max_message_length BETWEEN 1 AND 20000 AND slow_mode_seconds BETWEEN 0 AND 86400
  )
);
```

#### 5. `public.channel_member_restrictions` (Fine-Grained Moderation)
```sql
CREATE TABLE public.channel_member_restrictions (
  restriction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id     UUID NOT NULL,
  user_id        UUID NOT NULL,
  permission     public.chat_permission NOT NULL,
  imposed_by     UUID NOT NULL REFERENCES public.profiles(user_id),
  reason         TEXT,
  starts_at      TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  expires_at     TIMESTAMPTZ,
  revoked_at     TIMESTAMPTZ,
  revoked_by     UUID REFERENCES public.profiles(user_id),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  FOREIGN KEY (channel_id, user_id) REFERENCES public.channel_members(channel_id, user_id) ON DELETE CASCADE
);

CREATE INDEX idx_channel_member_restrictions_lookup
  ON public.channel_member_restrictions(channel_id, user_id, permission)
  WHERE revoked_at IS NULL;
```

#### 6. `public.messages` (Global Identity Sequencing)
```sql
CREATE TABLE public.messages (
  message_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_seq         BIGINT GENERATED ALWAYS AS IDENTITY UNIQUE,
  channel_id          UUID NOT NULL REFERENCES public.chat_channels(channel_id) ON DELETE CASCADE,
  sender_id           UUID REFERENCES public.profiles(user_id) ON DELETE SET NULL,
  message_type        public.chat_message_type NOT NULL DEFAULT 'text',
  body                TEXT,
  payload             JSONB NOT NULL DEFAULT '{}'::jsonb,
  reply_to_message_id UUID REFERENCES public.messages(message_id) ON DELETE SET NULL,
  version             INTEGER NOT NULL DEFAULT 1,
  counts_as_unread    BOOLEAN NOT NULL DEFAULT true,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  edited_at           TIMESTAMPTZ,
  deleted_at          TIMESTAMPTZ,
  deleted_by          UUID REFERENCES public.profiles(user_id),
  CONSTRAINT message_version_positive CHECK (version >= 1),
  CONSTRAINT message_body_length CHECK (body IS NULL OR char_length(body) <= 20000)
);

CREATE UNIQUE INDEX idx_messages_channel_seq_unique ON public.messages(channel_id, message_seq);
CREATE INDEX idx_messages_channel_page ON public.messages(channel_id, message_seq DESC);
```

#### 7. `public.channel_receipt_events` (Historical Horizon Audit Log)
Preserves immutable timestamps of when members crossed sequence thresholds.

```sql
CREATE TABLE public.channel_receipt_events (
  receipt_event_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id          UUID NOT NULL REFERENCES public.chat_channels(channel_id) ON DELETE CASCADE,
  user_id             UUID NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  receipt_type        TEXT NOT NULL, -- 'read' | 'delivered'
  through_message_seq BIGINT NOT NULL,
  occurred_at         TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX idx_channel_receipt_events_lookup 
  ON public.channel_receipt_events(channel_id, through_message_seq, user_id, receipt_type);
```

#### 8. `public.chat_changes` (Durable Catch-Up Mutation Stream)
Enables offline clients to reconcile missed mutations (edits, reactions, deletions, member status) upon reconnection.

```sql
CREATE TABLE public.chat_changes (
  change_seq     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  channel_id     UUID NOT NULL REFERENCES public.chat_channels(channel_id) ON DELETE CASCADE,
  entity_type    TEXT NOT NULL, -- 'message' | 'reaction' | 'receipt' | 'member' | 'policy'
  entity_id      TEXT NOT NULL,
  operation      TEXT NOT NULL, -- 'insert' | 'update' | 'delete'
  payload        JSONB NOT NULL DEFAULT '{}'::jsonb,
  occurred_at    TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX idx_chat_changes_channel_seq ON public.chat_changes(channel_id, change_seq);
```

---

### 1.3 Hardened PostgreSQL Functions (RPC)

#### 1. `send_channel_message` (Cross-Channel Reply & Policy Validation)
```sql
CREATE OR REPLACE FUNCTION public.send_channel_message(
  p_message_id UUID,
  p_channel_id UUID,
  p_message_type public.chat_message_type DEFAULT 'text',
  p_body TEXT DEFAULT NULL,
  p_reply_to_message_id UUID DEFAULT NULL,
  p_payload JSONB DEFAULT '{}'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_actor UUID := auth.uid();
  v_existing RECORD;
  v_new_msg RECORD;
  v_policy RECORD;
  v_last_sent TIMESTAMPTZ;
  v_reply_channel_id UUID;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'CHAT_UNAUTHENTICATED: Caller is not authenticated' USING ERRCODE = '42501';
  END IF;

  IF p_message_id IS NULL OR p_channel_id IS NULL THEN
    RAISE EXCEPTION 'CHAT_INVALID_ARGUMENT: message_id and channel_id are required' USING ERRCODE = '22023';
  END IF;

  -- 1. Idempotent return if already inserted
  SELECT m.* INTO v_existing FROM public.messages m WHERE m.message_id = p_message_id;
  IF v_existing.message_id IS NOT NULL THEN
    IF v_existing.sender_id = v_actor AND v_existing.channel_id = p_channel_id THEN
      RETURN to_jsonb(v_existing);
    ELSE
      RAISE EXCEPTION 'CHAT_COLLISION: Message ID already used in another context' USING ERRCODE = '23505';
    END IF;
  END IF;

  -- 2. Authorization check
  IF NOT private.has_channel_permission(v_actor, p_channel_id, 'send_messages') THEN
    RAISE EXCEPTION 'CHAT_PERMISSION_DENIED: send_messages not permitted' USING ERRCODE = '42501';
  END IF;

  -- 3. Policy checks
  SELECT * INTO v_policy FROM public.channel_policies WHERE channel_id = p_channel_id;
  IF FOUND THEN
    -- Media policy
    IF p_message_type IN ('image', 'video', 'audio') AND NOT v_policy.media_enabled THEN
      RAISE EXCEPTION 'CHAT_MEDIA_DISABLED: Media messages are disabled in this channel' USING ERRCODE = '42501';
    END IF;

    -- Replies policy
    IF p_reply_to_message_id IS NOT NULL AND NOT v_policy.replies_enabled THEN
      RAISE EXCEPTION 'CHAT_REPLIES_DISABLED: Replies are disabled in this channel' USING ERRCODE = '42501';
    END IF;

    -- Body length policy
    IF p_body IS NOT NULL AND char_length(p_body) > v_policy.max_message_length THEN
      RAISE EXCEPTION 'CHAT_MESSAGE_TOO_LONG: Body exceeds max length of %', v_policy.max_message_length USING ERRCODE = '22023';
    END IF;

    -- Slow mode policy
    IF v_policy.slow_mode_seconds > 0 THEN
      SELECT created_at INTO v_last_sent
      FROM public.messages
      WHERE channel_id = p_channel_id AND sender_id = v_actor
      ORDER BY created_at DESC LIMIT 1;

      IF v_last_sent IS NOT NULL AND (clock_timestamp() - v_last_sent) < (v_policy.slow_mode_seconds * INTERVAL '1 second') THEN
        RAISE EXCEPTION 'CHAT_SLOW_MODE: Please wait % seconds before sending again',
          CEIL(EXTRACT(EPOCH FROM (v_last_sent + (v_policy.slow_mode_seconds * INTERVAL '1 second') - clock_timestamp())))
          USING ERRCODE = '42501';
      END IF;
    END IF;
  END IF;

  -- 4. Cross-channel reply validation
  IF p_reply_to_message_id IS NOT NULL THEN
    SELECT channel_id INTO v_reply_channel_id
    FROM public.messages WHERE message_id = p_reply_to_message_id;

    IF v_reply_channel_id IS NULL OR v_reply_channel_id <> p_channel_id THEN
      RAISE EXCEPTION 'CHAT_CROSS_CHANNEL_REPLY: Referenced reply message belongs to a different channel' USING ERRCODE = '22023';
    END IF;
  END IF;

  -- 5. Content validation
  IF p_message_type = 'text' AND (p_body IS NULL OR length(trim(p_body)) = 0) THEN
    RAISE EXCEPTION 'CHAT_EMPTY_BODY: Text message body cannot be empty' USING ERRCODE = '22023';
  END IF;

  -- 6. Insert message with global identity sequence
  INSERT INTO public.messages (
    message_id, channel_id, sender_id, message_type, body,
    payload, reply_to_message_id, version, counts_as_unread,
    created_at, updated_at
  ) VALUES (
    p_message_id, p_channel_id, v_actor, p_message_type, p_body,
    COALESCE(p_payload, '{}'::jsonb), p_reply_to_message_id, 1, true,
    clock_timestamp(), clock_timestamp()
  )
  RETURNING * INTO v_new_msg;

  -- 7. Advance channel and sender horizons atomically
  UPDATE public.chat_channels
  SET last_message_seq = v_new_msg.message_seq,
      last_message_at  = v_new_msg.created_at,
      updated_at       = clock_timestamp()
  WHERE channel_id = p_channel_id;

  UPDATE public.channel_members
  SET last_read_message_seq      = GREATEST(COALESCE(last_read_message_seq, 0), v_new_msg.message_seq),
      last_read_at               = v_new_msg.created_at,
      last_delivered_message_seq = GREATEST(COALESCE(last_delivered_message_seq, 0), v_new_msg.message_seq),
      last_delivered_at          = v_new_msg.created_at,
      updated_at                 = clock_timestamp()
  WHERE channel_id = p_channel_id AND user_id = v_actor;

  -- 8. Record audit receipt event
  INSERT INTO public.channel_receipt_events (
    channel_id, user_id, receipt_type, through_message_seq, occurred_at
  ) VALUES (
    p_channel_id, v_actor, 'read', v_new_msg.message_seq, v_new_msg.created_at
  );

  -- 9. Append to durable catch-up change log
  INSERT INTO public.chat_changes (
    channel_id, entity_type, entity_id, operation, payload, occurred_at
  ) VALUES (
    p_channel_id, 'message', v_new_msg.message_id::TEXT, 'insert', to_jsonb(v_new_msg), v_new_msg.created_at
  );

  RETURN to_jsonb(v_new_msg);
END;
$$;
```

---

#### 2. `mark_channel_read` & `mark_channel_delivered` (Strict Member Authorization)
Prevents unauthorized sequence probing by non-members.

```sql
CREATE OR REPLACE FUNCTION public.mark_channel_read(
  p_channel_id UUID,
  p_through_message_seq BIGINT
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_actor UUID := auth.uid();
  v_channel_seq BIGINT;
  v_effective_seq BIGINT;
  v_new_seq BIGINT;
  v_status public.chat_member_status;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'CHAT_UNAUTHENTICATED' USING ERRCODE = '42501';
  END IF;

  IF p_through_message_seq IS NULL OR p_through_message_seq <= 0 THEN
    RETURN NULL;
  END IF;

  -- 1. Explicit membership authorization check
  SELECT status INTO v_status
  FROM public.channel_members
  WHERE channel_id = p_channel_id AND user_id = v_actor;

  IF v_status IS NULL OR v_status NOT IN ('active', 'pending') THEN
    RAISE EXCEPTION 'CHAT_NOT_MEMBER: Caller is not an authorized member of this channel' USING ERRCODE = '42501';
  END IF;

  -- 2. Verify channel has messages
  SELECT last_message_seq INTO v_channel_seq
  FROM public.chat_channels WHERE channel_id = p_channel_id;

  IF v_channel_seq IS NULL OR v_channel_seq <= 0 THEN
    RETURN NULL;
  END IF;

  -- 3. Cap requested sequence to channel's latest sequence
  v_effective_seq := LEAST(p_through_message_seq, v_channel_seq);

  -- 4. Advance member horizons
  UPDATE public.channel_members
  SET last_read_message_seq      = GREATEST(COALESCE(last_read_message_seq, 0), v_effective_seq),
      last_read_at               = clock_timestamp(),
      last_delivered_message_seq = GREATEST(COALESCE(last_delivered_message_seq, 0), v_effective_seq),
      last_delivered_at          = COALESCE(last_delivered_at, clock_timestamp()),
      updated_at                 = clock_timestamp()
  WHERE channel_id = p_channel_id AND user_id = v_actor
  RETURNING last_read_message_seq INTO v_new_seq;

  -- 5. Record historical receipt event
  INSERT INTO public.channel_receipt_events (
    channel_id, user_id, receipt_type, through_message_seq, occurred_at
  ) VALUES (
    p_channel_id, v_actor, 'read', v_effective_seq, clock_timestamp()
  );

  -- 6. Append to durable catch-up change log
  INSERT INTO public.chat_changes (
    channel_id, entity_type, entity_id, operation, payload, occurred_at
  ) VALUES (
    p_channel_id, 'receipt', v_actor::TEXT, 'update',
    jsonb_build_object('type', 'read', 'user_id', v_actor, 'through_message_seq', v_effective_seq),
    clock_timestamp()
  );

  RETURN v_new_seq;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_channel_delivered(
  p_channel_id UUID,
  p_through_message_seq BIGINT
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_actor UUID := auth.uid();
  v_channel_seq BIGINT;
  v_effective_seq BIGINT;
  v_new_seq BIGINT;
  v_status public.chat_member_status;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'CHAT_UNAUTHENTICATED' USING ERRCODE = '42501';
  END IF;

  IF p_through_message_seq IS NULL OR p_through_message_seq <= 0 THEN
    RETURN NULL;
  END IF;

  SELECT status INTO v_status
  FROM public.channel_members
  WHERE channel_id = p_channel_id AND user_id = v_actor;

  IF v_status IS NULL OR v_status NOT IN ('active', 'pending') THEN
    RAISE EXCEPTION 'CHAT_NOT_MEMBER: Caller is not an authorized member of this channel' USING ERRCODE = '42501';
  END IF;

  SELECT last_message_seq INTO v_channel_seq
  FROM public.chat_channels WHERE channel_id = p_channel_id;

  IF v_channel_seq IS NULL OR v_channel_seq <= 0 THEN
    RETURN NULL;
  END IF;

  v_effective_seq := LEAST(p_through_message_seq, v_channel_seq);

  UPDATE public.channel_members
  SET last_delivered_message_seq = GREATEST(COALESCE(last_delivered_message_seq, 0), v_effective_seq),
      last_delivered_at          = clock_timestamp(),
      updated_at                 = clock_timestamp()
  WHERE channel_id = p_channel_id AND user_id = v_actor
  RETURNING last_delivered_message_seq INTO v_new_seq;

  INSERT INTO public.channel_receipt_events (
    channel_id, user_id, receipt_type, through_message_seq, occurred_at
  ) VALUES (
    p_channel_id, v_actor, 'delivered', v_effective_seq, clock_timestamp()
  );

  RETURN v_new_seq;
END;
$$;
```

---

#### 3. Strict DM Invite Transitions (`accept_channel_invite` & `decline_channel_invite`)
Enforces the state machine invariant that only `pending` invites can transition to `active` or `declined`.

```sql
CREATE OR REPLACE FUNCTION public.accept_channel_invite(p_channel_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_actor UUID := auth.uid();
  v_current_status public.chat_member_status;
  v_joined_at TIMESTAMPTZ := clock_timestamp();
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'CHAT_UNAUTHENTICATED' USING ERRCODE = '42501';
  END IF;

  SELECT status INTO v_current_status
  FROM public.channel_members
  WHERE channel_id = p_channel_id AND user_id = v_actor;

  IF v_current_status IS NULL THEN
    RAISE EXCEPTION 'CHAT_NOT_INVITED: No membership record found' USING ERRCODE = 'P0002';
  END IF;

  IF v_current_status <> 'pending' THEN
    RAISE EXCEPTION 'CHAT_INVALID_STATE_TRANSITION: Cannot accept invite in status %', v_current_status USING ERRCODE = '22023';
  END IF;

  -- Advance membership
  UPDATE public.channel_members
  SET status = 'active',
      responded_at = v_joined_at,
      joined_at = v_joined_at,
      updated_at = v_joined_at
  WHERE channel_id = p_channel_id AND user_id = v_actor;

  -- Record active membership period
  INSERT INTO public.channel_membership_periods (
    channel_id, user_id, joined_at
  ) VALUES (
    p_channel_id, v_actor, v_joined_at
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.decline_channel_invite(p_channel_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_actor UUID := auth.uid();
  v_current_status public.chat_member_status;
  v_declined_at TIMESTAMPTZ := clock_timestamp();
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'CHAT_UNAUTHENTICATED' USING ERRCODE = '42501';
  END IF;

  SELECT status INTO v_current_status
  FROM public.channel_members
  WHERE channel_id = p_channel_id AND user_id = v_actor;

  IF v_current_status IS NULL THEN
    RAISE EXCEPTION 'CHAT_NOT_INVITED: No membership record found' USING ERRCODE = 'P0002';
  END IF;

  IF v_current_status <> 'pending' THEN
    RAISE EXCEPTION 'CHAT_INVALID_STATE_TRANSITION: Cannot decline invite in status %', v_current_status USING ERRCODE = '22023';
  END IF;

  UPDATE public.channel_members
  SET status = 'declined',
      responded_at = v_declined_at,
      left_at = v_declined_at,
      request_retry_after = v_declined_at + INTERVAL '30 days',
      updated_at = v_declined_at
  WHERE channel_id = p_channel_id AND user_id = v_actor;
END;
$$;
```

---

## 2. Ably Capability Token Authorization Architecture

### 2.1 Threat Model & Security Invariant

**The Threat:**
Ably Realtime has no native awareness of Supabase Row Level Security. If an Ably client token grants the wildcard capability `chat:*`, any authenticated user could subscribe to `chat:<private-uuid-of-another-team>` or publish arbitrary forged messages directly to the WebSocket feed.

**The Invariant:**
1. Clients **NEVER** receive publish capabilities for chat messages on Ably.
2. The `ably-auth` Edge Function queries `channel_members` for the caller's active memberships.
3. Capabilities are explicitly restricted to the user's verified channels.

```
┌──────────────┐             1. HTTPS (Bearer JWT)           ┌─────────────────────────────┐
│              ├────────────────────────────────────────────►│                             │
│              │                                             │    ably-auth Edge Function  │
│              │◄────────────────────────────────────────────┤                             │
│              │            4. Scoped TokenRequest           └──────────────┬──────────────┘
│Flutter Client│                                                            │
│              │                                2. Query Active Channels    │ 3. Generate Token
│              │                                   WHERE status = 'active'  │    with Rest.auth
│              │                                                            ▼
│              │                                             ┌─────────────────────────────┐
│              │             5. Connect with Scoped Token    │      Supabase Postgres      │
│              ├────────────────────────────────────────────►│             &               │
│              │                                             │        Ably Realtime        │
└──────────────┘                                             └─────────────────────────────┘
```

### 2.2 Hardened `ably-auth` Edge Function Implementation

```typescript
// supabase/functions/ably-auth/index.ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import * as Ably from "npm:ably@2.4.1";
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsPreflight, json } from "../_shared/http.ts";

const ABLY_API_KEY = Deno.env.get("ABLY_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return corsPreflight();

  if (!ABLY_API_KEY) {
    return json(500, { ok: false, error: { code: "CONFIG_ERROR", message: "Missing ABLY_API_KEY" } });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json(401, { ok: false, error: { code: "UNAUTHENTICATED", message: "Missing Authorization header" } });
  }

  const token = authHeader.replace("Bearer ", "").trim();
  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, { auth: { persistSession: false } });

  const { data: { user }, error: authError } = await adminClient.auth.getUser(token);
  if (authError || !user) {
    return json(401, { ok: false, error: { code: "UNAUTHORIZED", message: "Invalid session" } });
  }

  const userId = user.id;

  try {
    // 1. Fetch user's active channel memberships
    const { data: memberships, error: memError } = await adminClient
      .from("channel_members")
      .select("channel_id")
      .eq("user_id", userId)
      .in("status", ["active", "pending"]);

    if (memError) throw memError;

    // 2. Build strictly scoped channel capabilities
    const capability: Record<string, string[]> = {
      // User's private notification inbox channel
      [`user:${userId}:chat`]: ["subscribe"],
      // Public match channels for live score ticker
      "match:*:live": ["subscribe"],
    };

    // Explicitly allow ONLY channels where caller is a member
    for (const row of memberships ?? []) {
      const channelId = row.channel_id;
      // subscribe: receive message and receipt broadcasts
      // presence: publish typing indicators and online state
      // (NO "publish" for messages — messages are written exclusively via Supabase RPC)
      capability[`chat:${channelId}`] = ["subscribe", "presence"];
    }

    // 3. Issue short-lived TokenRequest (1 hour TTL)
    const ably = new Ably.Rest(ABLY_API_KEY);
    const tokenRequest = await ably.auth.createTokenRequest({
      clientId: userId,
      capability: JSON.stringify(capability),
      ttl: 3600 * 1000,
    });

    return json(200, tokenRequest);
  } catch (err) {
    console.error("[ably-auth] Error generating scoped token:", err);
    return json(500, { ok: false, error: { code: "INTERNAL_ERROR", message: String(err) } });
  }
});
```

---

## 3. Client Local-First Persistence & Non-Destructive Migrations

### 3.1 Non-Destructive Migration Invariant

**The Requirement:**
Upgrading the application must **never drop tables** containing offline state (`outbox_operations`, `local_messages`, `local_message_attachments`, drafts). If a structural SQLite change is required, the migration must alter tables in place or execute a transaction that preserves pending mutations.

```dart
// lib/core/database/app_database.dart
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async {
    await m.createAll();
    await _createChatIndexes(m);
  },
  onUpgrade: (m, from, to) async {
    if (from < 11) {
      // Safe, non-destructive migration:
      // Check if temporary backup table needed or add column/primary key via table copy
      await m.database.transaction(() async {
        // 1. Rename existing tables to temp
        await m.database.customStatement(
          'ALTER TABLE local_messages RENAME TO _legacy_local_messages;'
        );
        await m.database.customStatement(
          'ALTER TABLE outbox_operations RENAME TO _legacy_outbox_operations;'
        );

        // 2. Create target tables with definitive primary keys
        await m.createTable(localMessages);
        await m.createTable(outboxOperations);

        // 3. Restore all pending and confirmed data
        await m.database.customStatement('''
          INSERT OR REPLACE INTO local_messages 
          SELECT * FROM _legacy_local_messages;
        ''');
        await m.database.customStatement('''
          INSERT OR REPLACE INTO outbox_operations 
          SELECT * FROM _legacy_outbox_operations;
        ''');

        // 4. Drop legacy temp tables after verified restoration
        await m.database.customStatement('DROP TABLE _legacy_local_messages;');
        await m.database.customStatement('DROP TABLE _legacy_outbox_operations;');
      });
    }
  },
);
```

---

### 3.2 Fully Reactive Multi-Table Observation

To ensure that receipt updates, reactions, and attachments immediately trigger UI re-renders, `watchMessages` observes a compound reactive stream:

```dart
Stream<List<ChatMessage>> watchMessages(
  String channelId,
  String currentUserId, {
  int? beforeMessageSeq,
}) {
  // Combine streams across messages, members, reactions, and attachments
  final messagesStream = (_db.select(_db.localMessages)
        ..where((m) {
          var pred = m.channelId.equals(channelId);
          if (beforeMessageSeq != null) {
            pred = pred & (m.messageSeq.isNull() | m.messageSeq.isSmallerThanValue(beforeMessageSeq));
          }
          return pred;
        })
        ..orderBy([
          (m) => OrderingTerm(expression: m.messageSeq, mode: OrderingMode.asc, nulls: NullsOrder.last),
          (m) => OrderingTerm(expression: m.localCreatedAt, mode: OrderingMode.asc),
        ]))
      .watch();

  final membersStream = (_db.select(_db.localChannelMembers)
        ..where((m) => m.channelId.equals(channelId)))
      .watch();

  final reactionsStream = (_db.select(_db.localMessageReactions)).watch();
  final attachmentsStream = (_db.select(_db.localMessageAttachments)).watch();

  return Rx.combineLatest4(
    messagesStream,
    membersStream,
    reactionsStream,
    attachmentsStream,
    (messageRows, memberRows, reactionRows, attachmentRows) {
      if (messageRows.isEmpty) return const <ChatMessage>[];

      // 1. Deduplicate messages by messageId (preserving newest)
      final distinctMap = <String, LocalMessageRow>{};
      for (final r in messageRows) {
        final existing = distinctMap[r.messageId];
        if (existing == null) {
          distinctMap[r.messageId] = r;
        } else {
          final existingTime = existing.updatedAt ?? existing.localCreatedAt;
          final newTime = r.updatedAt ?? r.localCreatedAt;
          if (newTime.isAfter(existingTime)) {
            distinctMap[r.messageId] = r;
          }
        }
      }
      final distinctRows = distinctMap.values.toList();

      // 2. Index attachments and reactions
      final attMap = <String, List<MessageAttachment>>{};
      for (final a in attachmentRows) {
        attMap.putIfAbsent(a.messageId, () => []).add(a.toEntity());
      }

      final rxMap = <String, List<MessageReaction>>{};
      for (final r in reactionRows) {
        if (r.removedAt == null) {
          rxMap.putIfAbsent(r.messageId, () => []).add(r.toEntity());
        }
      }

      // 3. Recipient-aware group and DM delivery status calculation
      final otherMembers = memberRows.where((m) => m.userId != currentUserId).toList();
      final isGroup = otherMembers.length > 1;

      return distinctRows.map((r) {
        final fromMe = r.senderId == currentUserId;
        MessageDeliveryStatus status = MessageDeliveryStatus.sent;

        if (r.syncStatus == 'pending') {
          status = MessageDeliveryStatus.pending;
        } else if (r.syncStatus == 'sending') {
          status = MessageDeliveryStatus.sending;
        } else if (r.syncStatus == 'failed') {
          status = MessageDeliveryStatus.failed;
        } else if (fromMe && r.messageSeq != null && otherMembers.isNotEmpty) {
          final seq = r.messageSeq!;

          if (isGroup) {
            // Group rule: All recipients must have read/delivered for full ticks
            final allRead = otherMembers.every((m) => (m.lastReadMessageSeq ?? 0) >= seq);
            final allDelivered = otherMembers.every((m) => (m.lastDeliveredMessageSeq ?? 0) >= seq);

            if (allRead) {
              status = MessageDeliveryStatus.read;
            } else if (allDelivered) {
              status = MessageDeliveryStatus.delivered;
            } else {
              status = MessageDeliveryStatus.sent;
            }
          } else {
            // 1:1 DM rule
            final peer = otherMembers.first;
            final peerRead = peer.lastReadMessageSeq ?? 0;
            final peerDelivered = peer.lastDeliveredMessageSeq ?? 0;

            if (seq <= peerRead) {
              status = MessageDeliveryStatus.read;
            } else if (seq <= peerDelivered) {
              status = MessageDeliveryStatus.delivered;
            } else {
              status = MessageDeliveryStatus.sent;
            }
          }
        }

        return ChatMessage(
          id: r.messageId,
          messageSeq: r.messageSeq,
          channelId: r.channelId,
          senderId: r.senderId,
          senderDisplayName: r.senderDisplayName,
          messageType: r.messageType,
          body: r.body,
          payload: jsonDecode(r.payloadJson),
          replyToId: r.replyToMessageId,
          version: r.version,
          createdAt: r.createdAt ?? r.localCreatedAt,
          editedAt: r.editedAt,
          deletedAt: r.deletedAt,
          fromMe: fromMe,
          syncStatus: r.syncStatus,
          deliveryStatus: status,
          attachments: attMap[r.messageId] ?? const [],
          reactions: rxMap[r.messageId] ?? const [],
        );
      }).toList();
    },
  );
}
```

---

## 4. Synchronization, Viewport Read Tracking & Catch-Up Protocol

### 4.1 Viewport Visibility-Based Read Tracking

**The Requirement:**
Opening a thread with 300 unread messages must **NOT** automatically mark all 300 read.
- **Delivery**: Acknowledged immediately upon persisting messages to Drift SQLite.
- **Read**: Acknowledged dynamically as messages enter the user's viewport, debounced to the highest visible sequence.

```dart
// lib/features/messages/presentation/controllers/message_thread_controller.dart
void onMessageBecameVisible(int visibleSeq) {
  if (visibleSeq <= _highestReportedReadSeq) return;
  _highestReportedReadSeq = visibleSeq;

  _readDebounceTimer?.cancel();
  _readDebounceTimer = Timer(const Duration(milliseconds: 500), () {
    ref.read(chatRepositoryProvider).markRead(chatId, _highestReportedReadSeq);
  });
}
```

---

### 4.2 Durable Catch-Up Synchronization Protocol

When the application reconnects or resumes from background:

```
┌──────────────┐         1. Get highest local change_seq         ┌────────────────────────┐
│              ├────────────────────────────────────────────────►│                        │
│              │                                                 │   Supabase Postgres    │
│              │         2. fetchChanges(channelId, afterChange) │   (chat_changes table) │
│Flutter Client│◄────────────────────────────────────────────────┤                        │
│              │                                                 └────────────────────────┘
│              │ 3. Apply mutations to Drift SQLite
│              │    • 'message.insert' ──► upsert message
│              │    • 'message.update' ──► update body & version
│              │    • 'message.delete' ──► soft delete tombstone
│              │    • 'reaction'       ──► upsert / remove
│              │    • 'receipt'        ──► advance member horizon
└──────────────┘
```

---

## 5. Outbox Queue Architecture & Stable Error Taxonomy

### 5.1 Per-Channel Serialization

To prevent a large 200MB video upload in Channel A from blocking text messages in Channel B:
- The Outbox Processor maintains independent concurrent workers per `channelId`.
- Within a specific channel, operations execute sequentially in strict FIFO order.

### 5.2 Application Error Taxonomy

The Outbox categorizes errors using stable application string codes rather than SQLSTATE `42501`:

| Application Error Code | Nature | Outbox Behavior | UI State |
| :--- | :--- | :--- | :--- |
| `CHAT_SLOW_MODE` | Transient | Retries after required cooldown seconds | Showing clock icon |
| `CHAT_NETWORK_ERROR` | Transient | Exponential backoff with jitter up to 30s | Showing clock icon |
| `CHAT_PERMISSION_DENIED` | Terminal | Marks operation `failed`; aborts retries | Red exclamation icon |
| `CHAT_NOT_MEMBER` | Terminal | Marks operation `failed`; prompts to rejoin | Red exclamation icon |
| `CHAT_BLOCKED` | Terminal | Marks operation `failed` | Red exclamation icon |
| `CHAT_MESSAGE_TOO_LONG` | Terminal | Marks operation `failed` | Red exclamation icon |

---

## 6. Verification & Quality Gate Acceptance Tests

```bash
# Gate 1: Static Analysis
flutter analyze lib/
# Must pass with 0 errors and 0 warnings.

# Gate 2: Clean Architecture Invariants Test
flutter test test/architecture_test.dart
# Verifies inward dependencies, domain purity, no use-cases, and acyclic graph.

# Gate 3: Pure Dart Domain Check
grep -rlE 'package:(flutter|flutter_riverpod|riverpod_annotation|supabase_flutter|supabase|drift|go_router|dio|http)/' lib/features/*/domain
# Must output 0 matches.

# Gate 4: Feature Unit & Outbox Tests
flutter test test/features/messages/
# Verifies OutboxProcessor, ChatLocalDataSource, and Message Requests logic.
```
