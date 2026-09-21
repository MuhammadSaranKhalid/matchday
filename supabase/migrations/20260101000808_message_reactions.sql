-- Migration file: 20260101000808_message_reactions.sql

-- 0808 · message_reactions — emoji reactions

-- Section: Tables and constraints

create table public.message_reactions(
  message_id uuid not null references public.messages(message_id) on delete cascade,
  user_id    uuid not null references public.profiles(user_id) on delete cascade,
  reaction   text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  removed_at timestamptz,
  primary key (message_id, user_id, reaction),
  constraint reaction_length check (char_length(reaction) between 1 and 32)
);

-- Section: Indexes

create index message_reactions_message_idx on public.message_reactions(message_id)
where
  removed_at is null;

-- Section: Triggers

create trigger message_reactions_set_updated_at
  before update on public.message_reactions for each row
  execute function public.set_updated_at();

-- Section: Enable row-level security

alter table public.message_reactions enable row level security;
