-- =============================================================================
-- 20260917000000 · Chat v4.0 Architectural & Security Hardening
-- =============================================================================
-- Remediates:
-- 1. P0: Strict membership authorization on mark_channel_read & mark_channel_delivered.
-- 2. P1: Cross-channel reply validation in send_channel_message.
-- 3. P1: Hardened invite state transitions in accept_channel_invite and decline_channel_invite.
-- 4. P1: Historical receipt event tracking in channel_receipt_events.
-- 5. P1: Durable catch-up mutation stream in chat_changes.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Table: channel_receipt_events (Historical Horizon Audit Log)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.channel_receipt_events (
  receipt_event_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id          UUID NOT NULL REFERENCES public.chat_channels(channel_id) ON DELETE CASCADE,
  user_id             UUID NOT NULL REFERENCES public.profiles(user_id) ON DELETE CASCADE,
  receipt_type        TEXT NOT NULL, -- 'read' | 'delivered'
  through_message_seq BIGINT NOT NULL,
  occurred_at         TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX IF NOT EXISTS idx_channel_receipt_events_lookup 
  ON public.channel_receipt_events(channel_id, through_message_seq, user_id, receipt_type);

ALTER TABLE public.channel_receipt_events ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'channel_receipt_events' 
      AND policyname = 'Members can view receipt events'
  ) THEN
    CREATE POLICY "Members can view receipt events"
      ON public.channel_receipt_events FOR SELECT TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.channel_members cm
          WHERE cm.channel_id = channel_receipt_events.channel_id
            AND cm.user_id = auth.uid()
            AND cm.status IN ('active', 'pending')
        )
      );
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 2. Table: chat_changes (Durable Catch-Up Mutation Stream)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chat_changes (
  change_seq     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  channel_id     UUID NOT NULL REFERENCES public.chat_channels(channel_id) ON DELETE CASCADE,
  entity_type    TEXT NOT NULL, -- 'message' | 'reaction' | 'receipt' | 'member'
  entity_id      TEXT NOT NULL,
  operation      TEXT NOT NULL, -- 'insert' | 'update' | 'delete'
  payload        JSONB NOT NULL DEFAULT '{}'::jsonb,
  occurred_at    TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX IF NOT EXISTS idx_chat_changes_channel_seq
  ON public.chat_changes(channel_id, change_seq);

ALTER TABLE public.chat_changes ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'chat_changes' 
      AND policyname = 'Members can view chat changes'
  ) THEN
    CREATE POLICY "Members can view chat changes"
      ON public.chat_changes FOR SELECT TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM public.channel_members cm
          WHERE cm.channel_id = chat_changes.channel_id
            AND cm.user_id = auth.uid()
            AND cm.status IN ('active', 'pending')
        )
      );
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 3. Hardened RPC: mark_channel_read (Strict Member Authorization)
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
  v_new_seq BIGINT;
  v_channel_seq BIGINT;
  v_seq BIGINT;
  v_status public.chat_member_status;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'CHAT_UNAUTHENTICATED: Caller is not authenticated' USING ERRCODE = '42501';
  END IF;

  IF p_through_message_seq IS NULL OR p_through_message_seq <= 0 THEN
    RETURN NULL;
  END IF;

  -- 1. Explicit membership authorization check
  SELECT status INTO v_status
    FROM public.channel_members
   WHERE channel_id = p_channel_id
     AND user_id = v_actor;

  IF v_status IS NULL OR v_status NOT IN ('active', 'pending') THEN
    RAISE EXCEPTION 'CHAT_NOT_MEMBER: Caller is not an authorized member of this channel' USING ERRCODE = '42501';
  END IF;

  -- 2. Verify channel has messages
  SELECT last_message_seq INTO v_channel_seq
    FROM public.chat_channels
   WHERE channel_id = p_channel_id;

  IF v_channel_seq IS NULL OR v_channel_seq <= 0 THEN
    RETURN NULL;
  END IF;

  -- 3. Cap requested sequence to channel's latest sequence
  v_seq := LEAST(p_through_message_seq, v_channel_seq);

  -- 4. Advance member horizons
  UPDATE public.channel_members
     SET last_read_message_seq      = GREATEST(COALESCE(last_read_message_seq, 0), v_seq),
         last_read_at               = clock_timestamp(),
         last_delivered_message_seq = GREATEST(COALESCE(last_delivered_message_seq, 0), v_seq),
         last_delivered_at          = COALESCE(last_delivered_at, clock_timestamp()),
         updated_at                 = clock_timestamp()
   WHERE channel_id = p_channel_id
     AND user_id = v_actor
  RETURNING last_read_message_seq INTO v_new_seq;

  -- 5. Record historical receipt event
  INSERT INTO public.channel_receipt_events (
    channel_id, user_id, receipt_type, through_message_seq, occurred_at
  ) VALUES (
    p_channel_id, v_actor, 'read', v_seq, clock_timestamp()
  );

  -- 6. Append to durable catch-up change log
  INSERT INTO public.chat_changes (
    channel_id, entity_type, entity_id, operation, payload, occurred_at
  ) VALUES (
    p_channel_id, 'receipt', v_actor::TEXT, 'update',
    jsonb_build_object('type', 'read', 'user_id', v_actor, 'through_message_seq', v_seq),
    clock_timestamp()
  );

  RETURN v_new_seq;
END;
$$;

REVOKE ALL ON FUNCTION public.mark_channel_read(UUID, BIGINT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_channel_read(UUID, BIGINT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 4. Hardened RPC: mark_channel_delivered (Strict Member Authorization)
-- -----------------------------------------------------------------------------
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
  v_new_seq BIGINT;
  v_channel_seq BIGINT;
  v_seq BIGINT;
  v_status public.chat_member_status;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'CHAT_UNAUTHENTICATED: Caller is not authenticated' USING ERRCODE = '42501';
  END IF;

  IF p_through_message_seq IS NULL OR p_through_message_seq <= 0 THEN
    RETURN NULL;
  END IF;

  -- 1. Explicit membership authorization check
  SELECT status INTO v_status
    FROM public.channel_members
   WHERE channel_id = p_channel_id
     AND user_id = v_actor;

  IF v_status IS NULL OR v_status NOT IN ('active', 'pending') THEN
    RAISE EXCEPTION 'CHAT_NOT_MEMBER: Caller is not an authorized member of this channel' USING ERRCODE = '42501';
  END IF;

  SELECT last_message_seq INTO v_channel_seq
    FROM public.chat_channels
   WHERE channel_id = p_channel_id;

  IF v_channel_seq IS NULL OR v_channel_seq <= 0 THEN
    RETURN NULL;
  END IF;

  v_seq := LEAST(p_through_message_seq, v_channel_seq);

  UPDATE public.channel_members
     SET last_delivered_message_seq = GREATEST(COALESCE(last_delivered_message_seq, 0), v_seq),
         last_delivered_at          = clock_timestamp(),
         updated_at                 = clock_timestamp()
   WHERE channel_id = p_channel_id
     AND user_id = v_actor
  RETURNING last_delivered_message_seq INTO v_new_seq;

  INSERT INTO public.channel_receipt_events (
    channel_id, user_id, receipt_type, through_message_seq, occurred_at
  ) VALUES (
    p_channel_id, v_actor, 'delivered', v_seq, clock_timestamp()
  );

  INSERT INTO public.chat_changes (
    channel_id, entity_type, entity_id, operation, payload, occurred_at
  ) VALUES (
    p_channel_id, 'receipt', v_actor::TEXT, 'update',
    jsonb_build_object('type', 'delivered', 'user_id', v_actor, 'through_message_seq', v_seq),
    clock_timestamp()
  );

  RETURN v_new_seq;
END;
$$;

REVOKE ALL ON FUNCTION public.mark_channel_delivered(UUID, BIGINT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_channel_delivered(UUID, BIGINT) TO authenticated;

-- -----------------------------------------------------------------------------
-- 5. Hardened RPC: send_channel_message (Cross-Channel Reply & Policies)
-- -----------------------------------------------------------------------------
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

  -- 1. Idempotent retry check: if message_id exists
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

  -- 2. Authorization check
  IF NOT private.has_channel_permission(v_actor, p_channel_id, 'send_messages') THEN
    RAISE EXCEPTION 'CHAT_PERMISSION_DENIED: send_messages not permitted in this channel' USING ERRCODE = '42501';
  END IF;

  -- 3. Policy enforcement
  SELECT * INTO v_policy
    FROM public.channel_policies
   WHERE channel_id = p_channel_id;

  IF FOUND THEN
    IF p_message_type IN ('image', 'video', 'audio') AND NOT v_policy.media_enabled THEN
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
      FROM public.messages
     WHERE message_id = p_reply_to_message_id;

    IF v_reply_channel_id IS NULL OR v_reply_channel_id <> p_channel_id THEN
      RAISE EXCEPTION 'CHAT_CROSS_CHANNEL_REPLY: Referenced reply message belongs to a different channel' USING ERRCODE = '22023';
    END IF;
  END IF;

  -- 5. Message content validation
  IF p_message_type = 'text' AND (p_body IS NULL OR length(trim(p_body)) = 0) THEN
    RAISE EXCEPTION 'CHAT_EMPTY_BODY: Text message body cannot be empty' USING ERRCODE = '22023';
  END IF;

  -- 6. Insert authoritative message
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
    clock_timestamp(),
    clock_timestamp()
  )
  RETURNING * INTO v_new_msg;

  -- 7. Atomically update channel metadata
  UPDATE public.chat_channels
     SET last_message_seq = v_new_msg.message_seq,
         last_message_at  = v_new_msg.created_at,
         updated_at       = clock_timestamp()
   WHERE channel_id = p_channel_id;

  -- 8. Atomically advance sender's own horizons
  UPDATE public.channel_members
     SET last_read_message_seq      = GREATEST(COALESCE(last_read_message_seq, 0), v_new_msg.message_seq),
         last_read_at               = v_new_msg.created_at,
         last_delivered_message_seq = GREATEST(COALESCE(last_delivered_message_seq, 0), v_new_msg.message_seq),
         last_delivered_at          = v_new_msg.created_at,
         updated_at                 = clock_timestamp()
   WHERE channel_id = p_channel_id
     AND user_id = v_actor;

  -- 9. Append to durable catch-up change log
  INSERT INTO public.chat_changes (
    channel_id, entity_type, entity_id, operation, payload, occurred_at
  ) VALUES (
    p_channel_id, 'message', v_new_msg.message_id::TEXT, 'insert', to_jsonb(v_new_msg), v_new_msg.created_at
  );

  RETURN to_jsonb(v_new_msg);
END;
$$;

REVOKE ALL ON FUNCTION public.send_channel_message(UUID, UUID, public.chat_message_type, TEXT, UUID, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.send_channel_message(UUID, UUID, public.chat_message_type, TEXT, UUID, JSONB) TO authenticated;

-- -----------------------------------------------------------------------------
-- 6. Hardened RPC: accept_channel_invite & decline_channel_invite
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.accept_channel_invite(p_channel_id UUID)
RETURNS BOOLEAN
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
   WHERE channel_id = p_channel_id
     AND user_id = v_actor;

  IF v_current_status IS NULL THEN
    RAISE EXCEPTION 'CHAT_NOT_INVITED: No membership record found' USING ERRCODE = 'P0002';
  END IF;

  IF v_current_status <> 'pending' THEN
    RAISE EXCEPTION 'CHAT_INVALID_STATE_TRANSITION: Cannot accept invite in status %', v_current_status USING ERRCODE = '22023';
  END IF;

  -- Advance membership to active
  UPDATE public.channel_members
     SET status = 'active',
         responded_at = v_joined_at,
         joined_at = v_joined_at,
         updated_at = v_joined_at
   WHERE channel_id = p_channel_id
     AND user_id = v_actor;

  -- Record active membership period
  INSERT INTO public.channel_membership_periods (
    channel_id, user_id, joined_at
  ) VALUES (
    p_channel_id, v_actor, v_joined_at
  );

  -- Log member change
  INSERT INTO public.chat_changes (
    channel_id, entity_type, entity_id, operation, payload, occurred_at
  ) VALUES (
    p_channel_id, 'member', v_actor::TEXT, 'update',
    jsonb_build_object('user_id', v_actor, 'status', 'active'),
    v_joined_at
  );

  RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.accept_channel_invite(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.accept_channel_invite(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.decline_channel_invite(p_channel_id UUID)
RETURNS BOOLEAN
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
   WHERE channel_id = p_channel_id
     AND user_id = v_actor;

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
   WHERE channel_id = p_channel_id
     AND user_id = v_actor;

  -- Log member change
  INSERT INTO public.chat_changes (
    channel_id, entity_type, entity_id, operation, payload, occurred_at
  ) VALUES (
    p_channel_id, 'member', v_actor::TEXT, 'update',
    jsonb_build_object('user_id', v_actor, 'status', 'declined'),
    v_declined_at
  );

  RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.decline_channel_invite(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.decline_channel_invite(UUID) TO authenticated;
