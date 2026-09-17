-- =============================================================================
-- 20260916000002 · Guard against 0 sequence values and reset invalid 0 horizons
-- =============================================================================
-- Message sequences are positive integers (1, 2, 3...).
-- A channel with 0 messages has last_message_seq IS NULL.
-- Attempting to mark read/delivered on an empty channel or with seq <= 0 is a no-op.
-- =============================================================================

create or replace function public.mark_channel_read(
  p_channel_id uuid,
  p_through_message_seq bigint
)
returns bigint
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_new_seq bigint;
  v_channel_seq bigint;
  v_seq bigint;
begin
  if v_actor is null then
    raise exception 'Unauthenticated' using errcode = '42501';
  end if;

  if p_through_message_seq is null or p_through_message_seq <= 0 then
    return null;
  end if;

  select last_message_seq into v_channel_seq
    from public.chat_channels
   where channel_id = p_channel_id;

  -- Channel has no messages yet
  if v_channel_seq is null or v_channel_seq <= 0 then
    return null;
  end if;

  -- Cap through_message_seq to actual channel sequence (Spec §12.2 Rule 3)
  v_seq := least(p_through_message_seq, v_channel_seq);

  update public.channel_members
     set last_read_message_seq      = greatest(coalesce(last_read_message_seq, 0), v_seq),
         last_read_at               = now(),
         last_delivered_message_seq = greatest(coalesce(last_delivered_message_seq, 0), v_seq),
         last_delivered_at          = coalesce(last_delivered_at, now()),
         updated_at                 = now()
   where channel_id = p_channel_id
     and user_id = v_actor
  returning last_read_message_seq into v_new_seq;

  return coalesce(v_new_seq, v_seq);
end;
$$;

revoke all on function public.mark_channel_read(uuid, bigint) from public;
grant execute on function public.mark_channel_read(uuid, bigint) to authenticated;

create or replace function public.mark_channel_delivered(
  p_channel_id uuid,
  p_through_message_seq bigint
)
returns bigint
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_new_seq bigint;
  v_channel_seq bigint;
  v_seq bigint;
begin
  if v_actor is null then
    raise exception 'Unauthenticated' using errcode = '42501';
  end if;

  if p_through_message_seq is null or p_through_message_seq <= 0 then
    return null;
  end if;

  select last_message_seq into v_channel_seq
    from public.chat_channels
   where channel_id = p_channel_id;

  -- Channel has no messages yet
  if v_channel_seq is null or v_channel_seq <= 0 then
    return null;
  end if;

  -- Cap through_message_seq to actual channel sequence (Spec §12.3)
  v_seq := least(p_through_message_seq, v_channel_seq);

  update public.channel_members
     set last_delivered_message_seq = greatest(coalesce(last_delivered_message_seq, 0), v_seq),
         last_delivered_at          = now(),
         updated_at                 = now()
   where channel_id = p_channel_id
     and user_id = v_actor
  returning last_delivered_message_seq into v_new_seq;

  return coalesce(v_new_seq, v_seq);
end;
$$;

revoke all on function public.mark_channel_delivered(uuid, bigint) from public;
grant execute on function public.mark_channel_delivered(uuid, bigint) to authenticated;

-- Reset invalid 0 horizons to NULL
update public.channel_members
   set last_read_message_seq = null,
       last_read_at = null
 where last_read_message_seq = 0;

update public.channel_members
   set last_delivered_message_seq = null,
       last_delivered_at = null
 where last_delivered_message_seq = 0;
