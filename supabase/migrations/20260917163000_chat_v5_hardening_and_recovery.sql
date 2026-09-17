-- =============================================================================
-- 20260917163000 · Chat V5 Hardening, Invariant Backfill & Durable Recovery
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. P0 Secret & Schema Hardening
-- -----------------------------------------------------------------------------
-- Revoke all execute permissions on the secret Ably auth header helper.
-- Only service_role / internal functions may access the master Ably API key.
REVOKE ALL ON FUNCTION private.get_ably_auth_header() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.get_ably_auth_header() TO service_role;

REVOKE USAGE ON SCHEMA private FROM PUBLIC, anon;

-- -----------------------------------------------------------------------------
-- 2. P1 Table Grants Least Privilege
-- -----------------------------------------------------------------------------
-- Direct client table mutations must be revoked; writes must flow strictly
-- through authorized, security definer RPC functions.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLE
  public.messages,
  public.channel_members,
  public.chat_channels,
  public.channel_policies,
  public.message_attachments,
  public.message_reactions,
  public.channel_receipt_events,
  public.chat_changes
FROM PUBLIC, anon, authenticated;

GRANT SELECT ON TABLE
  public.messages,
  public.channel_members,
  public.chat_channels,
  public.channel_policies,
  public.message_attachments,
  public.message_reactions,
  public.channel_receipt_events,
  public.chat_changes
TO authenticated;

GRANT ALL ON TABLE
  public.messages,
  public.channel_members,
  public.chat_channels,
  public.channel_policies,
  public.message_attachments,
  public.message_reactions,
  public.channel_receipt_events,
  public.chat_changes
TO service_role;

-- -----------------------------------------------------------------------------
-- 3. P1 Receipts: True-Crossing Semantics & Policy Enforcement
-- -----------------------------------------------------------------------------
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
  v_seq BIGINT;
  v_status public.chat_member_status;
  v_old_read_seq BIGINT;
  v_old_delivered_seq BIGINT;
  v_new_seq BIGINT;
  v_read_enabled BOOLEAN := true;
  v_delivery_enabled BOOLEAN := true;
  v_now TIMESTAMPTZ := clock_timestamp();
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'CHAT_UNAUTHENTICATED: Caller is not authenticated' USING ERRCODE = '42501';
  END IF;

  IF p_through_message_seq IS NULL OR p_through_message_seq <= 0 THEN
    RETURN NULL;
  END IF;

  -- 1. Explicit membership authorization check
  SELECT status, last_read_message_seq, last_delivered_message_seq
    INTO v_status, v_old_read_seq, v_old_delivered_seq
    FROM public.channel_members
   WHERE channel_id = p_channel_id
     AND user_id = v_actor;

  IF v_status IS NULL OR v_status NOT IN ('active', 'pending') THEN
    RAISE EXCEPTION 'CHAT_NOT_MEMBER: Caller is not an authorized member of this channel' USING ERRCODE = '42501';
  END IF;

  -- 2. Check channel policies
  SELECT read_receipts_enabled, delivery_receipts_enabled
    INTO v_read_enabled, v_delivery_enabled
    FROM public.channel_policies
   WHERE channel_id = p_channel_id;

  IF v_read_enabled IS FALSE THEN
    -- Read receipts disabled by policy
    RETURN COALESCE(v_old_read_seq, 0);
  END IF;

  -- 3. Verify channel has messages & cap sequence
  SELECT last_message_seq INTO v_channel_seq
    FROM public.chat_channels
   WHERE channel_id = p_channel_id;

  IF v_channel_seq IS NULL OR v_channel_seq <= 0 THEN
    RETURN NULL;
  END IF;

  v_seq := LEAST(p_through_message_seq, v_channel_seq);

  -- 4. True-crossing check: only mutate if sequence strictly advances
  IF v_seq <= COALESCE(v_old_read_seq, 0) THEN
    RETURN COALESCE(v_old_read_seq, 0);
  END IF;

  -- 5. Advance read horizon (and delivered horizon if reading implies delivery)
  IF v_delivery_enabled IS NOT FALSE AND v_seq > COALESCE(v_old_delivered_seq, 0) THEN
    UPDATE public.channel_members
       SET last_read_message_seq      = v_seq,
           last_read_at               = v_now,
           last_delivered_message_seq = v_seq,
           last_delivered_at          = v_now,
           updated_at                 = v_now
     WHERE channel_id = p_channel_id
       AND user_id = v_actor
    RETURNING last_read_message_seq INTO v_new_seq;

    -- Record delivery event
    INSERT INTO public.channel_receipt_events (
      channel_id, user_id, receipt_type, through_message_seq, occurred_at
    ) VALUES (
      p_channel_id, v_actor, 'delivered', v_seq, v_now
    );

    INSERT INTO public.chat_changes (
      channel_id, entity_type, entity_id, operation, payload, occurred_at
    ) VALUES (
      p_channel_id, 'receipt', v_actor::TEXT, 'update',
      jsonb_build_object('type', 'delivered', 'user_id', v_actor, 'through_message_seq', v_seq),
      v_now
    );
  ELSE
    UPDATE public.channel_members
       SET last_read_message_seq = v_seq,
           last_read_at          = v_now,
           updated_at            = v_now
     WHERE channel_id = p_channel_id
       AND user_id = v_actor
    RETURNING last_read_message_seq INTO v_new_seq;
  END IF;

  -- Record read event
  INSERT INTO public.channel_receipt_events (
    channel_id, user_id, receipt_type, through_message_seq, occurred_at
  ) VALUES (
    p_channel_id, v_actor, 'read', v_seq, v_now
  );

  INSERT INTO public.chat_changes (
    channel_id, entity_type, entity_id, operation, payload, occurred_at
  ) VALUES (
    p_channel_id, 'receipt', v_actor::TEXT, 'update',
    jsonb_build_object('type', 'read', 'user_id', v_actor, 'through_message_seq', v_seq),
    v_now
  );

  RETURN v_new_seq;
END;
$$;

REVOKE ALL ON FUNCTION public.mark_channel_read(UUID, BIGINT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mark_channel_read(UUID, BIGINT) TO authenticated;

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
  v_seq BIGINT;
  v_status public.chat_member_status;
  v_old_delivered_seq BIGINT;
  v_new_seq BIGINT;
  v_delivery_enabled BOOLEAN := true;
  v_now TIMESTAMPTZ := clock_timestamp();
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'CHAT_UNAUTHENTICATED: Caller is not authenticated' USING ERRCODE = '42501';
  END IF;

  IF p_through_message_seq IS NULL OR p_through_message_seq <= 0 THEN
    RETURN NULL;
  END IF;

  SELECT status, last_delivered_message_seq
    INTO v_status, v_old_delivered_seq
    FROM public.channel_members
   WHERE channel_id = p_channel_id
     AND user_id = v_actor;

  IF v_status IS NULL OR v_status NOT IN ('active', 'pending') THEN
    RAISE EXCEPTION 'CHAT_NOT_MEMBER: Caller is not an authorized member of this channel' USING ERRCODE = '42501';
  END IF;

  SELECT delivery_receipts_enabled INTO v_delivery_enabled
    FROM public.channel_policies
   WHERE channel_id = p_channel_id;

  IF v_delivery_enabled IS FALSE THEN
    RETURN COALESCE(v_old_delivered_seq, 0);
  END IF;

  SELECT last_message_seq INTO v_channel_seq
    FROM public.chat_channels
   WHERE channel_id = p_channel_id;

  IF v_channel_seq IS NULL OR v_channel_seq <= 0 THEN
    RETURN NULL;
  END IF;

  v_seq := LEAST(p_through_message_seq, v_channel_seq);

  -- True-crossing check
  IF v_seq <= COALESCE(v_old_delivered_seq, 0) THEN
    RETURN COALESCE(v_old_delivered_seq, 0);
  END IF;

  UPDATE public.channel_members
     SET last_delivered_message_seq = v_seq,
         last_delivered_at          = v_now,
         updated_at                 = v_now
   WHERE channel_id = p_channel_id
     AND user_id = v_actor
  RETURNING last_delivered_message_seq INTO v_new_seq;

  INSERT INTO public.channel_receipt_events (
    channel_id, user_id, receipt_type, through_message_seq, occurred_at
  ) VALUES (
    p_channel_id, v_actor, 'delivered', v_seq, v_now
  );

  INSERT INTO public.chat_changes (
    channel_id, entity_type, entity_id, operation, payload, occurred_at
  ) VALUES (
    p_channel_id, 'receipt', v_actor::TEXT, 'update',
    jsonb_build_object('type', 'delivered', 'user_id', v_actor, 'through_message_seq', v_seq),
    v_now
  );

  RETURN v_new_seq;
END;
$$;

REVOKE ALL ON FUNCTION public.mark_channel_delivered(UUID, BIGINT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mark_channel_delivered(UUID, BIGINT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 4. P1 Channel Metadata Invariant & Backfill
-- -----------------------------------------------------------------------------
-- One-time backfill of missing or inconsistent channel last message horizons
WITH channel_stats AS (
  SELECT
    m.channel_id,
    MAX(m.message_seq) AS max_seq,
    MAX(m.created_at) AS max_created_at
  FROM public.messages m
  GROUP BY m.channel_id
)
UPDATE public.chat_channels cc
SET
  last_message_seq = cs.max_seq,
  last_message_at = COALESCE(cs.max_created_at, cc.last_message_at, cc.created_at),
  updated_at = clock_timestamp()
FROM channel_stats cs
WHERE cc.channel_id = cs.channel_id
  AND (cc.last_message_seq IS NULL OR cc.last_message_seq <> cs.max_seq);

-- Permanent trigger to keep chat_channels.last_message_seq & last_message_at in sync
CREATE OR REPLACE FUNCTION public.sync_channel_last_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
BEGIN
  UPDATE public.chat_channels
     SET last_message_seq = GREATEST(COALESCE(last_message_seq, 0), NEW.message_seq),
         last_message_at  = NEW.created_at,
         updated_at       = clock_timestamp()
   WHERE channel_id = NEW.channel_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_channel_last_message ON public.messages;
CREATE TRIGGER trg_sync_channel_last_message
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.sync_channel_last_message();

-- -----------------------------------------------------------------------------
-- 5. P1 Membership Period Backfill & Lifecycle Coverage
-- -----------------------------------------------------------------------------
-- One-time backfill: active members lacking an open membership period
INSERT INTO public.channel_membership_periods (
  channel_id,
  user_id,
  joined_at,
  left_at
)
SELECT
  cm.channel_id,
  cm.user_id,
  COALESCE(cm.joined_at, cm.created_at, now()),
  NULL
FROM public.channel_members cm
WHERE cm.status = 'active'
  AND NOT EXISTS (
    SELECT 1 FROM public.channel_membership_periods p
    WHERE p.channel_id = cm.channel_id
      AND p.user_id = cm.user_id
      AND p.left_at IS NULL
  );

-- Comprehensive trigger to maintain membership periods for all membership sources
CREATE OR REPLACE FUNCTION public.sync_channel_membership_period()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_now TIMESTAMPTZ := clock_timestamp();
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.status = 'active' THEN
      INSERT INTO public.channel_membership_periods (
        channel_id, user_id, joined_at
      ) VALUES (
        NEW.channel_id, NEW.user_id, COALESCE(NEW.joined_at, v_now)
      ) ON CONFLICT (channel_id, user_id) WHERE left_at IS NULL DO NOTHING;
    END IF;
    RETURN NEW;

  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.status <> 'active' AND NEW.status = 'active' THEN
      -- Joined / Reactivated
      INSERT INTO public.channel_membership_periods (
        channel_id, user_id, joined_at
      ) VALUES (
        NEW.channel_id, NEW.user_id, COALESCE(NEW.joined_at, v_now)
      ) ON CONFLICT (channel_id, user_id) WHERE left_at IS NULL DO NOTHING;
    ELSIF OLD.status = 'active' AND NEW.status <> 'active' THEN
      -- Left / Removed / Declined
      UPDATE public.channel_membership_periods
         SET left_at = COALESCE(NEW.left_at, v_now),
             end_reason = NEW.status
       WHERE channel_id = NEW.channel_id
         AND user_id = NEW.user_id
         AND left_at IS NULL;
    END IF;
    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.channel_membership_periods
       SET left_at = v_now,
           end_reason = 'deleted'
     WHERE channel_id = OLD.channel_id
       AND user_id = OLD.user_id
       AND left_at IS NULL;
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_channel_membership_period ON public.channel_members;
CREATE TRIGGER trg_sync_channel_membership_period
  AFTER INSERT OR UPDATE OR DELETE ON public.channel_members
  FOR EACH ROW EXECUTE FUNCTION public.sync_channel_membership_period();

-- -----------------------------------------------------------------------------
-- 6. P1 Match Membership Lifecycle Synchronization
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sync_match_player_chat()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_channel_id UUID;
  v_now TIMESTAMPTZ := clock_timestamp();
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF OLD.user_id IS NOT NULL AND (NEW.user_id IS NULL OR NEW.user_id <> OLD.user_id) THEN
      SELECT channel_id INTO v_channel_id
        FROM public.chat_channels
       WHERE match_id = OLD.match_id AND purpose = 'main'
       LIMIT 1;

      IF v_channel_id IS NOT NULL THEN
        UPDATE public.channel_members
           SET status     = 'left',
               left_at    = v_now,
               updated_at = v_now
         WHERE channel_id = v_channel_id
           AND user_id = OLD.user_id;
      END IF;
    END IF;

    IF NEW.user_id IS NOT NULL AND (OLD.user_id IS NULL OR NEW.user_id <> OLD.user_id) THEN
      SELECT channel_id INTO v_channel_id
        FROM public.chat_channels
       WHERE match_id = NEW.match_id AND purpose = 'main'
       LIMIT 1;

      IF v_channel_id IS NOT NULL THEN
        INSERT INTO public.channel_members (
          channel_id, user_id, role, status, joined_at
        ) VALUES (
          v_channel_id, NEW.user_id, 'member', 'active', v_now
        ) ON CONFLICT (channel_id, user_id) DO UPDATE
          SET status = 'active',
              left_at = NULL,
              updated_at = v_now;
      END IF;
    END IF;

    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.user_id IS NOT NULL THEN
      SELECT channel_id INTO v_channel_id
        FROM public.chat_channels
       WHERE match_id = OLD.match_id AND purpose = 'main'
       LIMIT 1;

      IF v_channel_id IS NOT NULL THEN
        UPDATE public.channel_members
           SET status     = 'left',
               left_at    = v_now,
               updated_at = v_now
         WHERE channel_id = v_channel_id
           AND user_id = OLD.user_id;
      END IF;
    END IF;
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS match_players_after_update_sync_chat ON public.match_players;
CREATE TRIGGER match_players_after_update_sync_chat
  AFTER UPDATE ON public.match_players
  FOR EACH ROW EXECUTE FUNCTION public.sync_match_player_chat();

DROP TRIGGER IF EXISTS match_players_after_delete_sync_chat ON public.match_players;
CREATE TRIGGER match_players_after_delete_sync_chat
  AFTER DELETE ON public.match_players
  FOR EACH ROW EXECUTE FUNCTION public.sync_match_player_chat();

-- -----------------------------------------------------------------------------
-- 7. P1 Entity-Owned Leave Protection
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.leave_channel(p_channel_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_actor UUID := auth.uid();
  v_context_type public.chat_channel_context;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'CHAT_UNAUTHENTICATED: Caller is not authenticated' USING ERRCODE = '42501';
  END IF;

  SELECT context_type INTO v_context_type
    FROM public.chat_channels
   WHERE channel_id = p_channel_id;

  IF v_context_type IN ('team', 'match', 'tournament') THEN
    RAISE EXCEPTION 'CHAT_ENTITY_LEAVE_FORBIDDEN: Cannot leave entity-owned channel directly. Membership is managed by the % domain.', v_context_type
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.channel_members
     SET status     = 'left',
         left_at    = clock_timestamp(),
         updated_at = clock_timestamp()
   WHERE channel_id = p_channel_id
     AND user_id = v_actor;

  -- Append to durable chat_changes
  INSERT INTO public.chat_changes (
    channel_id, entity_type, entity_id, operation, payload, occurred_at
  ) VALUES (
    p_channel_id, 'member', v_actor::TEXT, 'update',
    jsonb_build_object('user_id', v_actor, 'status', 'left'),
    clock_timestamp()
  );

  RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.leave_channel(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.leave_channel(UUID) TO authenticated;

-- -----------------------------------------------------------------------------
-- 8. P1 get_or_create_direct_channel Responsibility Separation
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_or_create_direct_channel(p_target_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_actor UUID := auth.uid();
  v_low UUID;
  v_high UUID;
  v_key TEXT;
  v_channel_id UUID;
  v_target_follows_actor BOOLEAN := false;
  v_target_status public.chat_member_status;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'CHAT_UNAUTHENTICATED' USING ERRCODE = '42501';
  END IF;

  IF p_target_user_id IS NULL OR p_target_user_id = v_actor THEN
    RAISE EXCEPTION 'CHAT_INVALID_ARGUMENT: Invalid target user for direct message' USING ERRCODE = '22023';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.user_blocks
     WHERE (blocker_id = v_actor AND blocked_id = p_target_user_id)
        OR (blocker_id = p_target_user_id AND blocked_id = v_actor)
  ) THEN
    RAISE EXCEPTION 'CHAT_BLOCKED: Direct messaging is unavailable between these accounts' USING ERRCODE = '42501';
  END IF;

  IF v_actor < p_target_user_id THEN
    v_low := v_actor;
    v_high := p_target_user_id;
  ELSE
    v_low := p_target_user_id;
    v_high := v_actor;
  END IF;

  v_key := 'dm:' || v_low::TEXT || ':' || v_high::TEXT;

  INSERT INTO public.chat_channels (
    channel_key, kind, context_type, visibility, created_by
  )
  VALUES (
    v_key, 'direct', 'none', 'private', v_actor
  )
  ON CONFLICT (channel_key) DO UPDATE
    SET updated_at = clock_timestamp()
  RETURNING channel_id INTO v_channel_id;

  SELECT EXISTS (
    SELECT 1 FROM public.follows f
     WHERE follower_id = p_target_user_id
       AND target_type = 'user'
       AND target_id = v_actor
  ) INTO v_target_follows_actor;

  IF v_target_follows_actor THEN
    v_target_status := 'active';
  ELSE
    v_target_status := 'pending';
  END IF;

  -- Insert actor membership if not existing (DO NOT overwrite existing status/reopen)
  INSERT INTO public.channel_members (
    channel_id, user_id, role, status, joined_at
  )
  VALUES (
    v_channel_id, v_actor, 'member', 'active', clock_timestamp()
  )
  ON CONFLICT (channel_id, user_id) DO NOTHING;

  -- Insert target membership if not existing
  INSERT INTO public.channel_members (
    channel_id, user_id, role, status, invited_by, invited_at
  )
  VALUES (
    v_channel_id, p_target_user_id, 'member', v_target_status, v_actor, clock_timestamp()
  )
  ON CONFLICT (channel_id, user_id) DO NOTHING;

  INSERT INTO public.channel_policies (channel_id)
  VALUES (v_channel_id)
  ON CONFLICT (channel_id) DO NOTHING;

  RETURN v_channel_id;
END;
$$;

REVOKE ALL ON FUNCTION public.get_or_create_direct_channel(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_or_create_direct_channel(UUID) TO authenticated;

-- -----------------------------------------------------------------------------
-- 9. P1 DM 1-Message Request Attempt Enforcement (No Delete Bypass)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.guard_dm_request_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_kind public.chat_channel_kind;
  v_other_status public.chat_member_status;
  v_other_invited_at TIMESTAMPTZ;
  v_prior_count INTEGER;
BEGIN
  SELECT kind INTO v_kind
    FROM public.chat_channels
   WHERE channel_id = NEW.channel_id;

  IF v_kind = 'direct' THEN
    SELECT status, COALESCE(invited_at, created_at)
      INTO v_other_status, v_other_invited_at
      FROM public.channel_members
     WHERE channel_id = NEW.channel_id
       AND user_id <> NEW.sender_id
     LIMIT 1;

    IF v_other_status = 'pending' THEN
      -- Count ALL message attempts regardless of deletion tombstone
      SELECT count(*) INTO v_prior_count
        FROM public.messages
       WHERE channel_id = NEW.channel_id
         AND sender_id = NEW.sender_id
         AND created_at >= v_other_invited_at;

      IF v_prior_count >= 1 THEN
        RAISE EXCEPTION 'CHAT_DM_REQUEST_LIMIT: Cannot send more messages until the recipient accepts your message request'
          USING ERRCODE = '42501';
      END IF;
    ELSIF v_other_status IN ('declined', 'banned', 'removed') THEN
      RAISE EXCEPTION 'CHAT_RECIPIENT_UNAVAILABLE: Cannot send messages to this recipient'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- -----------------------------------------------------------------------------
-- 10. P1 Permission Checks, Versioning & chat_changes on Mutations
-- -----------------------------------------------------------------------------
-- set_message_reaction
CREATE OR REPLACE FUNCTION public.set_message_reaction(
  p_message_id UUID,
  p_reaction TEXT,
  p_selected BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_actor UUID := auth.uid();
  v_channel_id UUID;
  v_now TIMESTAMPTZ := clock_timestamp();
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'CHAT_UNAUTHENTICATED' USING ERRCODE = '42501';
  END IF;

  SELECT channel_id INTO v_channel_id
    FROM public.messages
   WHERE message_id = p_message_id;

  IF v_channel_id IS NULL THEN
    RAISE EXCEPTION 'CHAT_MESSAGE_NOT_FOUND: Message not found' USING ERRCODE = 'P0002';
  END IF;

  -- 1. Channel policy check
  IF NOT EXISTS (
    SELECT 1 FROM public.channel_policies
     WHERE channel_id = v_channel_id AND reactions_enabled IS TRUE
  ) THEN
    RAISE EXCEPTION 'CHAT_REACTIONS_DISABLED: Reactions are disabled for this channel' USING ERRCODE = '42501';
  END IF;

  -- 2. Capability check
  IF NOT private.has_channel_permission(v_actor, v_channel_id, 'add_reactions') THEN
    RAISE EXCEPTION 'CHAT_PERMISSION_DENIED: add_reactions not allowed' USING ERRCODE = '42501';
  END IF;

  IF p_selected THEN
    INSERT INTO public.message_reactions (
      message_id, user_id, reaction, created_at, updated_at, removed_at
    ) VALUES (
      p_message_id, v_actor, p_reaction, v_now, v_now, NULL
    )
    ON CONFLICT (message_id, user_id, reaction) DO UPDATE
      SET removed_at = NULL,
          updated_at = v_now;

    -- Append to durable chat_changes
    INSERT INTO public.chat_changes (
      channel_id, entity_type, entity_id, operation, payload, occurred_at
    ) VALUES (
      v_channel_id, 'reaction', p_message_id::TEXT, 'insert',
      jsonb_build_object('message_id', p_message_id, 'user_id', v_actor, 'reaction', p_reaction, 'selected', true),
      v_now
    );
  ELSE
    UPDATE public.message_reactions
       SET removed_at = v_now,
           updated_at = v_now
     WHERE message_id = p_message_id
       AND user_id = v_actor
       AND reaction = p_reaction;

    -- Append to durable chat_changes
    INSERT INTO public.chat_changes (
      channel_id, entity_type, entity_id, operation, payload, occurred_at
    ) VALUES (
      v_channel_id, 'reaction', p_message_id::TEXT, 'delete',
      jsonb_build_object('message_id', p_message_id, 'user_id', v_actor, 'reaction', p_reaction, 'selected', false),
      v_now
    );
  END IF;

  RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.set_message_reaction(UUID, TEXT, BOOLEAN) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_message_reaction(UUID, TEXT, BOOLEAN) TO authenticated;

-- edit_channel_message
CREATE OR REPLACE FUNCTION public.edit_channel_message(
  p_message_id UUID,
  p_expected_version INTEGER,
  p_body TEXT,
  p_payload JSONB DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_actor UUID := auth.uid();
  v_msg RECORD;
  v_now TIMESTAMPTZ := clock_timestamp();
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'CHAT_UNAUTHENTICATED' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_msg
    FROM public.messages
   WHERE message_id = p_message_id;

  IF v_msg.message_id IS NULL THEN
    RAISE EXCEPTION 'CHAT_MESSAGE_NOT_FOUND: Message not found' USING ERRCODE = 'P0002';
  END IF;

  IF v_msg.sender_id <> v_actor THEN
    RAISE EXCEPTION 'CHAT_PERMISSION_DENIED: Only the message author can edit this message' USING ERRCODE = '42501';
  END IF;

  IF NOT private.has_channel_permission(v_actor, v_msg.channel_id, 'edit_own_messages') THEN
    RAISE EXCEPTION 'CHAT_PERMISSION_DENIED: edit_own_messages not allowed' USING ERRCODE = '42501';
  END IF;

  IF v_msg.deleted_at IS NOT NULL THEN
    RAISE EXCEPTION 'CHAT_MESSAGE_DELETED: Cannot edit a deleted message' USING ERRCODE = '22023';
  END IF;

  IF v_msg.version <> p_expected_version THEN
    RAISE EXCEPTION 'CHAT_CONCURRENT_MODIFICATION: Version conflict (% vs %)', v_msg.version, p_expected_version
      USING ERRCODE = '40001';
  END IF;

  UPDATE public.messages
     SET body       = COALESCE(p_body, body),
         payload    = COALESCE(p_payload, payload),
         version    = version + 1,
         edited_at  = v_now,
         updated_at = v_now
   WHERE message_id = p_message_id
  RETURNING * INTO v_msg;

  -- Append to durable chat_changes
  INSERT INTO public.chat_changes (
    channel_id, entity_type, entity_id, operation, payload, occurred_at
  ) VALUES (
    v_msg.channel_id, 'message', v_msg.message_id::TEXT, 'update', to_jsonb(v_msg), v_now
  );

  RETURN to_jsonb(v_msg);
END;
$$;

REVOKE ALL ON FUNCTION public.edit_channel_message(UUID, INTEGER, TEXT, JSONB) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.edit_channel_message(UUID, INTEGER, TEXT, JSONB) TO authenticated;

-- delete_channel_message
CREATE OR REPLACE FUNCTION public.delete_channel_message(p_message_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_actor UUID := auth.uid();
  v_msg RECORD;
  v_can_delete BOOLEAN := false;
  v_now TIMESTAMPTZ := clock_timestamp();
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'CHAT_UNAUTHENTICATED' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_msg
    FROM public.messages
   WHERE message_id = p_message_id;

  IF v_msg.message_id IS NULL THEN
    RETURN TRUE; -- Idempotent
  END IF;

  IF v_msg.sender_id = v_actor THEN
    v_can_delete := private.has_channel_permission(v_actor, v_msg.channel_id, 'delete_own_messages');
  ELSE
    v_can_delete := private.has_channel_permission(v_actor, v_msg.channel_id, 'delete_any_message');
  END IF;

  IF NOT v_can_delete THEN
    RAISE EXCEPTION 'CHAT_PERMISSION_DENIED: Permission denied to delete message' USING ERRCODE = '42501';
  END IF;

  -- Monotonically increment version on deletion tombstone
  UPDATE public.messages
     SET deleted_at = v_now,
         deleted_by = v_actor,
         version    = version + 1,
         updated_at = v_now
   WHERE message_id = p_message_id
  RETURNING * INTO v_msg;

  -- Append to durable chat_changes
  INSERT INTO public.chat_changes (
    channel_id, entity_type, entity_id, operation, payload, occurred_at
  ) VALUES (
    v_msg.channel_id, 'message', v_msg.message_id::TEXT, 'delete',
    jsonb_build_object('message_id', v_msg.message_id, 'version', v_msg.version, 'deleted_at', v_msg.deleted_at, 'deleted_by', v_actor),
    v_now
  );

  RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_channel_message(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_channel_message(UUID) TO authenticated;

-- send_channel_message
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
  v_now TIMESTAMPTZ := clock_timestamp();
  v_wait_seconds INTEGER;
  v_att JSONB;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'CHAT_UNAUTHENTICATED: Caller is not authenticated' USING ERRCODE = '42501';
  END IF;

  IF p_message_id IS NULL OR p_channel_id IS NULL THEN
    RAISE EXCEPTION 'CHAT_INVALID_ARGUMENT: message_id and channel_id are required' USING ERRCODE = '22023';
  END IF;

  -- 1. Client forbidden to author system messages
  IF p_message_type = 'system' THEN
    RAISE EXCEPTION 'CHAT_INVALID_MESSAGE_TYPE: System messages cannot be sent by clients' USING ERRCODE = '42501';
  END IF;

  -- 2. Idempotent retry check
  SELECT m.* INTO v_existing
    FROM public.messages m
   WHERE m.message_id = p_message_id;

  IF v_existing.message_id IS NOT NULL THEN
    IF v_existing.sender_id = v_actor AND v_existing.channel_id = p_channel_id THEN
      RETURN to_jsonb(v_existing);
    ELSE
      RAISE EXCEPTION 'CHAT_COLLISION: Message ID already used in another context' USING ERRCODE = '23505';
    END IF;
  END IF;

  -- 3. Authorization check
  IF NOT private.has_channel_permission(v_actor, p_channel_id, 'send_messages') THEN
    RAISE EXCEPTION 'CHAT_PERMISSION_DENIED: send_messages not permitted in this channel' USING ERRCODE = '42501';
  END IF;

  -- 4. Policy enforcement
  SELECT * INTO v_policy
    FROM public.channel_policies
   WHERE channel_id = p_channel_id;

  IF FOUND THEN
    IF p_message_type IN ('image', 'video', 'audio', 'file') AND NOT v_policy.media_enabled THEN
      RAISE EXCEPTION 'CHAT_MEDIA_DISABLED: Media messages are disabled in this channel' USING ERRCODE = '42501';
    END IF;

    IF p_reply_to_message_id IS NOT NULL AND NOT v_policy.replies_enabled THEN
      RAISE EXCEPTION 'CHAT_REPLIES_DISABLED: Replies are disabled in this channel' USING ERRCODE = '42501';
    END IF;

    IF p_body IS NOT NULL AND char_length(p_body) > v_policy.max_message_length THEN
      RAISE EXCEPTION 'CHAT_MESSAGE_TOO_LONG: Body exceeds max length of %', v_policy.max_message_length USING ERRCODE = '22023';
    END IF;

    IF v_policy.slow_mode_seconds > 0 THEN
      SELECT created_at INTO v_last_sent
        FROM public.messages
       WHERE channel_id = p_channel_id
         AND sender_id = v_actor
       ORDER BY created_at DESC
       LIMIT 1;

      IF v_last_sent IS NOT NULL AND (v_now - v_last_sent) < (v_policy.slow_mode_seconds * INTERVAL '1 second') THEN
        v_wait_seconds := CEIL(EXTRACT(EPOCH FROM (v_last_sent + (v_policy.slow_mode_seconds * INTERVAL '1 second') - v_now)));
        RAISE EXCEPTION 'CHAT_SLOW_MODE: Please wait % seconds before sending again', v_wait_seconds
          USING ERRCODE = '42501',
                DETAIL = jsonb_build_object('code', 'CHAT_SLOW_MODE', 'retry_after_seconds', v_wait_seconds)::text;
      END IF;
    END IF;
  END IF;

  -- 5. Cross-channel reply validation
  IF p_reply_to_message_id IS NOT NULL THEN
    SELECT channel_id INTO v_reply_channel_id
      FROM public.messages
     WHERE message_id = p_reply_to_message_id;

    IF v_reply_channel_id IS NULL OR v_reply_channel_id <> p_channel_id THEN
      RAISE EXCEPTION 'CHAT_CROSS_CHANNEL_REPLY: Referenced reply message belongs to a different channel' USING ERRCODE = '22023';
    END IF;
  END IF;

  -- 6. Message content validation
  IF p_message_type = 'text' AND (p_body IS NULL OR length(trim(p_body)) = 0) THEN
    RAISE EXCEPTION 'CHAT_EMPTY_BODY: Text message body cannot be empty' USING ERRCODE = '22023';
  END IF;

  -- 7. Insert authoritative message
  INSERT INTO public.messages (
    message_id,
    channel_id,
    sender_id,
    message_type,
    body,
    payload,
    reply_to_message_id,
    version,
    counts_as_unread,
    created_at,
    updated_at
  )
  VALUES (
    p_message_id,
    p_channel_id,
    v_actor,
    p_message_type,
    p_body,
    COALESCE(p_payload, '{}'::jsonb),
    p_reply_to_message_id,
    1,
    true,
    v_now,
    v_now
  )
  RETURNING * INTO v_new_msg;

  -- 8. Relational attachment persistence
  IF p_payload ? 'attachment' THEN
    v_att := p_payload->'attachment';
    INSERT INTO public.message_attachments (
      attachment_id,
      message_id,
      storage_path,
      mime_type,
      file_name,
      size_bytes,
      width,
      height,
      duration_ms,
      created_at
    ) VALUES (
      COALESCE((v_att->>'attachment_id')::uuid, gen_random_uuid()),
      v_new_msg.message_id,
      v_att->>'storage_path',
      COALESCE(v_att->>'mime_type', 'application/octet-stream'),
      v_att->>'file_name',
      (v_att->>'size_bytes')::bigint,
      (v_att->>'width')::integer,
      (v_att->>'height')::integer,
      (v_att->>'duration_ms')::bigint,
      v_now
    ) ON CONFLICT (attachment_id) DO NOTHING;
  END IF;

  -- 9. Atomically advance channel latest message horizon
  UPDATE public.chat_channels
     SET last_message_seq = v_new_msg.message_seq,
         last_message_at  = v_new_msg.created_at,
         updated_at       = v_now
   WHERE channel_id = p_channel_id;

  -- 10. Atomically advance sender's own horizons
  UPDATE public.channel_members
     SET last_read_message_seq      = GREATEST(COALESCE(last_read_message_seq, 0), v_new_msg.message_seq),
         last_read_at               = v_new_msg.created_at,
         last_delivered_message_seq = GREATEST(COALESCE(last_delivered_message_seq, 0), v_new_msg.message_seq),
         last_delivered_at          = v_new_msg.created_at,
         updated_at                 = v_now
   WHERE channel_id = p_channel_id
     AND user_id = v_actor;

  -- 11. Append to durable catch-up change log
  INSERT INTO public.chat_changes (
    channel_id, entity_type, entity_id, operation, payload, occurred_at
  ) VALUES (
    p_channel_id, 'message', v_new_msg.message_id::TEXT, 'insert', to_jsonb(v_new_msg), v_new_msg.created_at
  );

  RETURN to_jsonb(v_new_msg);
END;
$$;

REVOKE ALL ON FUNCTION public.send_channel_message(UUID, UUID, public.chat_message_type, TEXT, UUID, JSONB) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.send_channel_message(UUID, UUID, public.chat_message_type, TEXT, UUID, JSONB) TO authenticated;

-- -----------------------------------------------------------------------------
-- 11. P1 Ably Event Broadcasts (Hardened & Versioned)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.broadcast_message_mutation_to_ably()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_auth_header TEXT;
  v_channel_id TEXT;
  v_envelope JSONB;
BEGIN
  v_channel_id := 'chat:' || NEW.channel_id::TEXT;
  v_auth_header := private.get_ably_auth_header();

  IF v_auth_header IS NULL THEN
    RETURN NEW;
  END IF;

  -- 1. Soft-delete event
  IF NEW.deleted_at IS NOT NULL AND (OLD.deleted_at IS NULL) THEN
    v_envelope := jsonb_build_object(
      'name', 'message.deleted',
      'data', jsonb_build_object(
        'event_id', gen_random_uuid(),
        'type', 'message.deleted',
        'channel_id', NEW.channel_id,
        'entity_id', NEW.message_id,
        'entity_version', NEW.version,
        'occurred_at', NEW.deleted_at,
        'data', jsonb_build_object(
          'message_id', NEW.message_id,
          'channel_id', NEW.channel_id,
          'deleted_by', NEW.deleted_by,
          'deleted_at', NEW.deleted_at,
          'version', NEW.version
        )
      )
    );

    PERFORM net.http_post(
      url := 'https://rest.ably.io/channels/' || v_channel_id || '/messages',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', v_auth_header
      ),
      body := v_envelope
    );
    RETURN NEW;
  END IF;

  -- 2. Edit event
  IF NEW.edited_at IS NOT NULL AND (OLD.edited_at IS NULL OR NEW.edited_at > OLD.edited_at) THEN
    v_envelope := jsonb_build_object(
      'name', 'message.edited',
      'data', jsonb_build_object(
        'event_id', gen_random_uuid(),
        'event_seq', NEW.message_seq,
        'type', 'message.edited',
        'channel_id', NEW.channel_id,
        'entity_id', NEW.message_id,
        'entity_version', NEW.version,
        'occurred_at', NEW.edited_at,
        'data', jsonb_build_object(
          'message_id', NEW.message_id,
          'message_seq', NEW.message_seq,
          'channel_id', NEW.channel_id,
          'sender_id', NEW.sender_id,
          'body', NEW.body,
          'payload', NEW.payload,
          'version', NEW.version,
          'edited_at', NEW.edited_at
        )
      )
    );

    PERFORM net.http_post(
      url := 'https://rest.ably.io/channels/' || v_channel_id || '/messages',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', v_auth_header
      ),
      body := v_envelope
    );
    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;

-- Trigger functions should ONLY be executable by service_role / internal engine
REVOKE ALL ON FUNCTION public.broadcast_message_mutation_to_ably() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.broadcast_message_mutation_to_ably() TO service_role;

REVOKE ALL ON FUNCTION public.broadcast_message_to_ably() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.broadcast_message_to_ably() TO service_role;

REVOKE ALL ON FUNCTION public.broadcast_reaction_to_ably() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.broadcast_reaction_to_ably() TO service_role;

REVOKE ALL ON FUNCTION public.broadcast_receipt_to_ably() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.broadcast_receipt_to_ably() TO service_role;

-- -----------------------------------------------------------------------------
-- 12. P2 Exact Mute/Pin/Archive Timestamps in list_my_chats
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.list_my_chats();

CREATE OR REPLACE FUNCTION public.list_my_chats()
RETURNS TABLE (
  chat_id                    UUID,
  channel_key                TEXT,
  kind                       public.chat_channel_kind,
  context_type               public.chat_channel_context,
  team_id                    UUID,
  match_id                   UUID,
  last_message_seq           BIGINT,
  last_message_at            TIMESTAMPTZ,
  created_at                 TIMESTAMPTZ,
  updated_at                 TIMESTAMPTZ,
  title                      TEXT,
  team_name                  TEXT,
  team_logo_url              TEXT,
  team_logo_monogram         TEXT,
  team_primary_color         TEXT,
  dm_other_user_id           UUID,
  dm_other_user_name         TEXT,
  dm_other_user_username     TEXT,
  dm_other_user_avatar_url   TEXT,
  you_follow                 BOOLEAN,
  they_follow_you            BOOLEAN,
  last_message_body          TEXT,
  last_message_sender_id     UUID,
  last_message_from_me       BOOLEAN,
  unread_count               INT,
  is_accepted                BOOLEAN,
  is_pinned                  BOOLEAN,
  is_archived                BOOLEAN,
  is_muted                   BOOLEAN,
  pinned_at                  TIMESTAMPTZ,
  archived_at                TIMESTAMPTZ,
  notifications_muted_until  TIMESTAMPTZ,
  last_read_message_seq      BIGINT,
  last_read_at               TIMESTAMPTZ,
  last_delivered_message_seq BIGINT,
  last_delivered_at          TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  v_actor UUID := auth.uid();
BEGIN
  IF v_actor IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    cc.channel_id AS chat_id,
    cc.channel_key,
    cc.kind,
    cc.context_type,
    cc.team_id,
    cc.match_id,
    cc.last_message_seq,
    cc.last_message_at,
    cc.created_at,
    cc.updated_at,
    -- Title resolution
    CASE
      WHEN cc.kind = 'direct' THEN other_p.display_name
      WHEN cc.context_type = 'team' THEN t.team_name
      WHEN cc.context_type = 'tournament' THEN tour.tournament_name
      WHEN cc.context_type = 'match' THEN COALESCE(mt_a.team_name, 'Team A') || ' vs ' || COALESCE(mt_b.team_name, 'Team B')
      ELSE cc.title
    END AS title,
    CASE
      WHEN cc.context_type = 'tournament' THEN tour.tournament_name
      ELSE t.team_name
    END AS team_name,
    CASE
      WHEN cc.context_type = 'tournament' THEN tour.logo_url
      ELSE t.logo_url
    END AS team_logo_url,
    CASE
      WHEN cc.context_type = 'tournament' THEN
        UPPER(SUBSTRING(REGEXP_REPLACE(tour.tournament_name, '[^a-zA-Z0-9]', '', 'g') FROM 1 FOR 3))
      WHEN t.team_name IS NOT NULL THEN
        UPPER(SUBSTRING(REGEXP_REPLACE(t.team_name, '[^a-zA-Z0-9]', '', 'g') FROM 1 FOR 3))
      ELSE NULL
    END AS team_logo_monogram,
    t.primary_color AS team_primary_color,
    other_p.user_id AS dm_other_user_id,
    other_p.display_name AS dm_other_user_name,
    other_p.username AS dm_other_user_username,
    other_p.avatar_url AS dm_other_user_avatar_url,
    -- Graph relationship
    EXISTS (
      SELECT 1 FROM public.follows f
       WHERE f.follower_id = v_actor
         AND f.target_type = 'user'
         AND f.target_id = other_cm.user_id
    ) AS you_follow,
    EXISTS (
      SELECT 1 FROM public.follows f
       WHERE f.follower_id = other_cm.user_id
         AND f.target_type = 'user'
         AND f.target_id = v_actor
    ) AS they_follow_you,
    -- Last message preview
    lm.body AS last_message_body,
    lm.sender_id AS last_message_sender_id,
    (lm.sender_id = v_actor) AS last_message_from_me,
    -- Monotonic unread count
    GREATEST(0, (
      SELECT COUNT(*)::INT
        FROM public.messages m
       WHERE m.channel_id = cc.channel_id
         AND m.message_seq > COALESCE(cm.last_read_message_seq, 0)
         AND m.sender_id <> v_actor
         AND m.deleted_at IS NULL
         AND m.counts_as_unread IS TRUE
    )) AS unread_count,
    -- Acceptance status
    (cm.status = 'active') AS is_accepted,
    (cm.pinned_at IS NOT NULL) AS is_pinned,
    (cm.archived_at IS NOT NULL) AS is_archived,
    (cm.notifications_muted_until IS NOT NULL AND cm.notifications_muted_until > clock_timestamp()) AS is_muted,
    cm.pinned_at,
    cm.archived_at,
    cm.notifications_muted_until,
    cm.last_read_message_seq,
    cm.last_read_at,
    cm.last_delivered_message_seq,
    cm.last_delivered_at
  FROM public.channel_members cm
  JOIN public.chat_channels cc ON cc.channel_id = cm.channel_id
  LEFT JOIN public.teams t ON t.team_id = cc.team_id
  LEFT JOIN public.tournaments tour ON tour.tournament_id = cc.tournament_id
  -- Match teams
  LEFT JOIN public.matches m_match ON m_match.match_id = cc.match_id
  LEFT JOIN public.teams mt_a ON mt_a.team_id = m_match.team_a_id
  LEFT JOIN public.teams mt_b ON mt_b.team_id = m_match.team_b_id
  -- Direct chat other party
  LEFT JOIN public.channel_members other_cm
    ON other_cm.channel_id = cc.channel_id
   AND other_cm.user_id <> v_actor
   AND cc.kind = 'direct'
  LEFT JOIN public.profiles other_p ON other_p.user_id = other_cm.user_id
  -- Latest message
  LEFT JOIN LATERAL (
    SELECT m.body, m.sender_id
      FROM public.messages m
     WHERE m.channel_id = cc.channel_id
       AND m.deleted_at IS NULL
     ORDER BY m.message_seq DESC
     LIMIT 1
  ) lm ON true
  WHERE cm.user_id = v_actor
    AND cm.status IN ('active', 'pending')
  ORDER BY
    (cm.pinned_at IS NOT NULL) DESC,
    COALESCE(cc.last_message_at, cc.created_at) DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.list_my_chats() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_my_chats() TO authenticated;

-- -----------------------------------------------------------------------------
-- 13. P0 Exhaustive Function EXECUTE Hardening Sweep
-- -----------------------------------------------------------------------------
-- Revoke all function execute privileges across public schema from public & anon
DO $$
DECLARE
  r RECORD;
  n INT := 0;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS sig
      FROM pg_proc p
      JOIN pg_namespace ns ON ns.oid = p.pronamespace
     WHERE ns.nspname = 'public'
       AND p.prokind IN ('f', 'p')
       AND NOT EXISTS (
         SELECT 1
           FROM pg_depend d
          WHERE d.objid = p.oid
            AND d.classid = 'pg_proc'::regclass
            AND d.deptype = 'e'
       )
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM public, anon', r.sig);
    n := n + 1;
  END LOOP;
  RAISE NOTICE 'Function grants hardened: % functions', n;
END $$;

-- Deliberate public exceptions:
GRANT EXECUTE ON FUNCTION public.get_follow_list(UUID, TEXT, INT, INT) TO anon;
GRANT EXECUTE ON FUNCTION public._try_topic_uuid(TEXT, INT) TO anon;

-- Deliberate authenticated application RPCs:
GRANT EXECUTE ON FUNCTION public.list_my_chats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_channel_message(UUID, UUID, public.chat_message_type, TEXT, UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.edit_channel_message(UUID, INTEGER, TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_channel_message(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_message_reaction(UUID, TEXT, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_channel_read(UUID, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_channel_delivered(UUID, BIGINT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_channel_invite(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.decline_channel_invite(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.leave_channel(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_direct_channel(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_group_channel(TEXT, TEXT, TEXT, UUID[]) TO authenticated;
