-- =============================================================================
-- 20260916000001 · Fix chat member horizons capping & delivery acknowledgment
-- =============================================================================
-- In accordance with Spec §12.2 & §12.3:
-- 1. mark_channel_read & mark_channel_delivered must be capped to chat_channels.last_message_seq
--    (cannot acknowledge future sequences or sentinel values like 999999999).
-- 2. Reading a message implies delivery: mark_channel_read advances last_delivered_message_seq
--    to at least the read horizon.
-- 3. Cleanup existing corrupted horizon rows where seq > last_message_seq.
-- =============================================================================

-- 1. Replace mark_channel_read
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

  select coalesce(last_message_seq, 0) into v_channel_seq
    from public.chat_channels
   where channel_id = p_channel_id;

  -- Cap through_message_seq to actual channel sequence (Spec §12.2 Rule 3)
  v_seq := least(coalesce(p_through_message_seq, v_channel_seq), coalesce(v_channel_seq, 0));

  update public.channel_members
     set last_read_message_seq      = least(greatest(coalesce(last_read_message_seq, 0), v_seq), coalesce(v_channel_seq, 0)),
         last_read_at               = now(),
         last_delivered_message_seq = least(greatest(coalesce(last_delivered_message_seq, 0), v_seq), coalesce(v_channel_seq, 0)),
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

-- 2. Replace mark_channel_delivered
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

  select coalesce(last_message_seq, 0) into v_channel_seq
    from public.chat_channels
   where channel_id = p_channel_id;

  -- Cap through_message_seq to actual channel sequence (Spec §12.3)
  v_seq := least(coalesce(p_through_message_seq, v_channel_seq), coalesce(v_channel_seq, 0));

  update public.channel_members
     set last_delivered_message_seq = least(greatest(coalesce(last_delivered_message_seq, 0), v_seq), coalesce(v_channel_seq, 0)),
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

-- 3. Cleanup existing corrupted horizon values in channel_members
update public.channel_members cm
   set last_read_message_seq = cc.last_message_seq
  from public.chat_channels cc
 where cm.channel_id = cc.channel_id
   and cm.last_read_message_seq > coalesce(cc.last_message_seq, 0);

update public.channel_members cm
   set last_delivered_message_seq = cc.last_message_seq
  from public.chat_channels cc
 where cm.channel_id = cc.channel_id
   and cm.last_delivered_message_seq > coalesce(cc.last_message_seq, 0);

-- 4. Advance last_delivered_message_seq to match last_read_message_seq where delivered was null
update public.channel_members
   set last_delivered_message_seq = last_read_message_seq,
       last_delivered_at = coalesce(last_read_at, now())
 where last_read_message_seq is not null
   and (last_delivered_message_seq is null or last_delivered_message_seq < last_read_message_seq);
