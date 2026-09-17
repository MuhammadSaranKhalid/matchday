-- =============================================================================
-- 0809 · message_user_state — per-user message state (e.g. delete for me)
-- =============================================================================

create table public.message_user_state (
  message_id          uuid not null
                        references public.messages(message_id) on delete cascade,
  user_id             uuid not null
                        references public.profiles(user_id) on delete cascade,
  hidden_at           timestamptz,
  primary key (message_id, user_id)
);

alter table public.message_user_state enable row level security;
