-- =============================================================================
-- 20260917203000 · Fix Channel Read and Delivered Horizon Checks
-- =============================================================================
-- Fixes issue where members with NULL last_read_message_seq or
-- last_delivered_message_seq were erroneously flagged as non-members (code 42501).
-- =============================================================================

create or replace function public.mark_channel_read(
  p_channel_id uuid,
  p_through_seq bigint
)
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_now timestamptz := clock_timestamp();
  v_current_horizon bigint;
  v_read_receipts_enabled boolean;
begin
  if v_actor is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select coalesce(last_read_message_seq, 0) into v_current_horizon
    from public.channel_members
   where channel_id = p_channel_id
     and user_id = v_actor
     and status in ('active', 'pending');

  if not found then
    raise exception 'User is not a member of channel' using errcode = '42501';
  end if;

  -- Monotonic true-crossing guard
  if p_through_seq <= v_current_horizon then
    return;
  end if;

  select read_receipts_enabled into v_read_receipts_enabled
    from public.channel_policies
   where channel_id = p_channel_id;

  update public.channel_members
     set last_read_message_seq = p_through_seq,
         last_read_at = v_now,
         last_delivered_message_seq = greatest(coalesce(last_delivered_message_seq, 0), p_through_seq),
         last_delivered_at = case
           when coalesce(last_delivered_message_seq, 0) < p_through_seq then v_now
           else last_delivered_at
         end,
         updated_at = v_now
   where channel_id = p_channel_id
     and user_id = v_actor;

  if coalesce(v_read_receipts_enabled, true) then
    insert into public.channel_receipt_events (
      channel_id, user_id, receipt_type, through_message_seq, created_at
    ) values (
      p_channel_id, v_actor, 'read', p_through_seq, v_now
    );
  end if;
end;
$$;

create or replace function public.mark_channel_delivered(
  p_channel_id uuid,
  p_through_seq bigint
)
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_now timestamptz := clock_timestamp();
  v_current_horizon bigint;
  v_delivery_receipts_enabled boolean;
begin
  if v_actor is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  select coalesce(last_delivered_message_seq, 0) into v_current_horizon
    from public.channel_members
   where channel_id = p_channel_id
     and user_id = v_actor
     and status in ('active', 'pending');

  if not found then
    raise exception 'User is not a member of channel' using errcode = '42501';
  end if;

  -- Monotonic true-crossing guard
  if p_through_seq <= v_current_horizon then
    return;
  end if;

  select delivery_receipts_enabled into v_delivery_receipts_enabled
    from public.channel_policies
   where channel_id = p_channel_id;

  update public.channel_members
     set last_delivered_message_seq = p_through_seq,
         last_delivered_at = v_now,
         updated_at = v_now
   where channel_id = p_channel_id
     and user_id = v_actor;

  if coalesce(v_delivery_receipts_enabled, true) then
    insert into public.channel_receipt_events (
      channel_id, user_id, receipt_type, through_message_seq, created_at
    ) values (
      p_channel_id, v_actor, 'delivered', p_through_seq, v_now
    );
  end if;
end;
$$;

revoke all on function public.mark_channel_read(uuid, bigint) from public, anon;
grant execute on function public.mark_channel_read(uuid, bigint) to authenticated;

revoke all on function public.mark_channel_delivered(uuid, bigint) from public, anon;
grant execute on function public.mark_channel_delivered(uuid, bigint) to authenticated;
