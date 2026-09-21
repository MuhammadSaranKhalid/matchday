-- =============================================================================
-- Migration: 20260101000850_content_reports.sql
-- =============================================================================

-- Reports are private to their author and the service-role moderation operator.

-- -----------------------------------------------------------------------------
-- Tables and constraints
-- -----------------------------------------------------------------------------

create table public.content_reports (
  report_id   uuid primary key default gen_random_uuid(),
  reporter_id uuid not null
    references public.profiles (user_id)
    on delete cascade,
  target_kind text not null check (
    target_kind in ('user', 'post', 'comment', 'message')
  ),
  target_id   uuid not null,
  reason      text not null check (
    reason in (
      'Spam',
      'Harassment or bullying',
      'Hate or violence',
      'Sexual content',
      'Child safety',
      'Other'
    )
  ),
  details     text not null default '' check (length(details) <= 2000),
  status      text not null default 'open' check (
    status in ('open', 'reviewed', 'actioned', 'dismissed')
  ),
  created_at  timestamptz not null default now(),
  reviewed_at timestamptz
);

-- -----------------------------------------------------------------------------
-- Indexes
-- -----------------------------------------------------------------------------

create index content_reports_reporter
  on public.content_reports (reporter_id);

create index content_reports_open
  on public.content_reports (created_at)
  where status = 'open';

-- -----------------------------------------------------------------------------
-- Enable row-level security
-- -----------------------------------------------------------------------------

alter table public.content_reports enable row level security;

-- -----------------------------------------------------------------------------
-- Permissions
-- -----------------------------------------------------------------------------

revoke all on public.content_reports from anon, authenticated;

grant select, insert on public.content_reports to authenticated;

-- -----------------------------------------------------------------------------
-- Policies
-- -----------------------------------------------------------------------------

create policy reports_read_own
  on public.content_reports
  for select
  to authenticated
  using (
    reporter_id = (
      select
        auth.uid()
    )
  );

create policy reports_insert_own
  on public.content_reports
  for insert
  to authenticated
  with check (
    reporter_id = (
      select
        auth.uid()
    )
    and status = 'open'
    and reviewed_at is null
  );

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

-- Invoker rights ensure private messages can only be reported by a reader.
create or replace function private.validate_content_report()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if
    not (
      case new.target_kind
        when 'user' then exists (
          select
            1
          from public.profiles
          where user_id = new.target_id
        )
        when 'post' then exists (
          select
            1
          from public.posts
          where post_id = new.target_id
        )
        when 'comment' then exists (
          select
            1
          from public.comments
          where comment_id = new.target_id
        )
        when 'message' then exists (
          select
            1
          from public.messages
          where message_id = new.target_id
        )
        else false
      end
    )
  then
    raise exception 'Content is no longer available' using errcode = '42501';
  end if;
  return new;
end;
$$;

revoke all on function private.validate_content_report() from public;

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------

create trigger validate_content_report
  before insert on public.content_reports
  for each row
  execute function private.validate_content_report();
